#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/msg.h>
#include <sys/shm.h>
#include <sys/sem.h>
#include <sys/signal.h>

// Useless wrapper for abstraction
typedef struct
{
    int *array;
} SharedData;

typedef struct
{
    int sender;
    char content[3];
} Message;

// Useless wrapper for abstraction
typedef struct sembuf Semaphore;

// @param shared memory
// @return number of processes alive
int get_alive(SharedData data, int number_of_children, Semaphore semaphore, int semaphore_id)
{
    // Find the index of the first occurrence of the sentinel value (0) in the array
    int index = 0;
    // lock
    semaphore.sem_op = -1;
    semop(semaphore_id, &semaphore, 1);
    while (index <= number_of_children && data.array[index] != 0)
    {
        index++;
    }
    // unlock
    semaphore.sem_op = 1;
    semop(semaphore_id, &semaphore, 1);
    return index;
}

// Removes an item from an array by value
// @param data The structure to remove the item from
// @param value The value of the item to remove
void remove_child(SharedData *data, int number_of_children, int value, Semaphore semaphore, int semaphore_id)
{
    int alive = get_alive(*data, number_of_children, semaphore, semaphore_id);
    // lock
    semaphore.sem_op = -1;
    semop(semaphore_id, &semaphore, 1);
    // look for index
    int index = -1;
    for (int i = 0; i < alive; i++)
    {
        if (data->array[i] == value)
        {
            index = i;
            break;
        }
    }
    if (index != -1)
    {
        for (int i = index; i < alive; i++)
        {
            // ye good old current == next
            data->array[i] = data->array[i + 1];
        }
    }
    // 0 as sentinel value
    data->array[number_of_children - 1] = 0;
    // unlock
    semaphore.sem_op = 1;
    semop(semaphore_id, &semaphore, 1);
}

int main(int argc, char *argv[])
{
    setbuf(stdout, NULL);
    // parse args
    char *filename = argv[1];
    int number_of_children = atoi(argv[2]);

    // pipe
    int barrier[2];
    pipe(barrier);

    // stringify
    int descriptor_size = sysconf(_SC_OPEN_MAX);
    char descriptor1[descriptor_size];
    char descriptor2[descriptor_size];
    char number_of_children_str[3];
    sprintf(descriptor1, "%d", barrier[0]);
    sprintf(descriptor2, "%d", barrier[1]);
    sprintf(number_of_children_str, "%d", number_of_children);

    // data management
    key_t key = ftok(filename, 'A');
    int message_queue_id = msgget(key, 0777 | IPC_CREAT);
    if (message_queue_id == -1)
    {
        perror("msgget");
        exit(EXIT_FAILURE);
    }
    int shared_memory_id = shmget(key, number_of_children * sizeof(int), 0777 | IPC_CREAT);
    if (shared_memory_id == -1)
    {
        perror("shmget");
        exit(EXIT_FAILURE);
    }

    SharedData children_status;
    children_status.array = (int *)shmat(shared_memory_id, 0, 0);
    for (int i = 0; i < number_of_children; i++)
    {
        children_status.array[i] = 0;
    }

    // semaphore init
    Semaphore semaphore;
    semaphore.sem_num = 0;
    semaphore.sem_flg = 0;
    int semaphore_id = semget(key, 1, 0700 | IPC_CREAT);
    if (semaphore_id == -1)
    {
        perror("semget");
        exit(EXIT_FAILURE);
    }
    semctl(semaphore_id, 0, SETVAL, 1);

    // run children
    for (int i = 0; i < number_of_children; i++)
    {
        int pid = fork();
        if (pid == 0)
        {
            execlp("./hijo",
                   "hijo",
                   filename,
                   descriptor1,
                   descriptor2,
                   number_of_children_str,
                   NULL);
            exit(EXIT_SUCCESS);
        }
        else if (pid < 0)
        {
            perror("fork");
            exit(EXIT_FAILURE);
        }
    }
    usleep(10000);
    int alive = get_alive(children_status, number_of_children, semaphore, semaphore_id);
    while (alive < number_of_children)
    {
        usleep(10000);
        alive = get_alive(children_status, number_of_children, semaphore, semaphore_id);
    }

    // play nice!
    Message messages[number_of_children];
    int message_size = sizeof(Message);
    close(barrier[0]);
    while (alive > 1)
    {
        printf("Iniciando ronda de ataques\n");
        fflush(stdout);

        char token = 'a';
        for (int i = 0; i < alive; i++)
        {
            write(barrier[1], &token, sizeof(char));
        }

        for (int i = 0; i < alive; i++)
        {
            msgrcv(message_queue_id, &messages[i], message_size, 0, 0);
        }

        Message message;
        for (int i = 0; i < alive; i++)
        {
            message = messages[i];
            printf("mensaje recibido: %d %s\n", message.sender, message.content);
            fflush(stdout);
            if (strcmp(message.content, "KO") == 0)
            {
                kill(message.sender, SIGKILL);
                waitpid(message.sender, NULL, 0);
                printf("El hijo %d ha sido eliminado\n", message.sender);
                fflush(stdout);
                remove_child(&children_status, number_of_children, message.sender, semaphore, semaphore_id);
            }
        }
        alive = get_alive(children_status, number_of_children, semaphore, semaphore_id);
        printf("Ronda de ataques terminada\n");
        fflush(stdout);
        printf("Procesos vivos: %d\n", alive);
        fflush(stdout);
        for (int i = 0; i < alive; i++)
        {
            printf("%d ", children_status.array[i]);
            fflush(stdout);
        }
        printf("\n\n");
        fflush(stdout);
    }
    FILE *stack = fopen("resultado", "w");
    if (alive == 1)
    {
        kill(children_status.array[0], SIGKILL);
        fprintf(stack, "El hijo %d ha ganado\n", children_status.array[0]);
        fflush(stdout);
    }
    else
    {
        fprintf(stack, "Empate\n");
        fflush(stdout);
    }
    system("ipcrm -a");
    system("ipcs -q");
    system("ipcs -s");
    return 0;
}
