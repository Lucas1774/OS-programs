#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <time.h>
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

// global message content since it can't be accessed at custom signal handler
char content[3];

// @param shared memory
// @return number of processes alive
int get_alive(SharedData data, int number_of_children, Semaphore semaphore, int semaphore_id)
{
	// Find the index of the first occurrence of the sentinel value (0) in the array
	int index = 0;
	// lock
	semaphore.sem_op = -1;
	semop(semaphore_id, &semaphore, 1);
	while (index < number_of_children && data.array[index] != 0)
	{
		index++;
	}
	// unlock
	semaphore.sem_op = 1;
	semop(semaphore_id, &semaphore, 1);
	return index;
}

// Adds the current process to the shared data
// @param data The structure to add the item to
void add_self(SharedData *data, int number_of_children, Semaphore semaphore, int semaphore_id)
{
	int alive = get_alive(*data, number_of_children, semaphore, semaphore_id);
	// lock
	semaphore.sem_op = -1;
	semop(semaphore_id, &semaphore, 1);
	// Add the current process ID at end of array
	data->array[alive] = getpid();
	// unlock
	semaphore.sem_op = 1;
	semop(semaphore_id, &semaphore, 1);
}

// gets a random pid different from this process' from the participants
// @param data The structure to get the pid from
int get_non_self_pid(SharedData *data, int number_of_children, Semaphore semaphore, int semaphore_id)
{
	int alive = get_alive(*data, number_of_children, semaphore, semaphore_id);
	// lock
	semaphore.sem_op = -1;
	semop(semaphore_id, &semaphore, 1);
	// pick attacker (not this)
	int attacker = getpid();
	int attacker_id;
	while (getpid() == attacker)
	{
		attacker_id = rand() % alive;
		attacker = data->array[attacker_id];
	}
	// unlock
	semaphore.sem_op = 1;
	semop(semaphore_id, &semaphore, 1);
	return attacker;
}

void react_defending()
{
	printf("El hijo %d ha repelido un ataque\n", getpid());
	fflush(stdout);
	// no need to set to OK, OK is default
}

void react_dying()
{
	printf("El hijo %d ha sido emboscado mientras realizaba un ataque\n", getpid());
	fflush(stdout);
	strcpy(content, "KO");
}

int main(int argc, char **argv)
{
	setbuf(stdout, NULL);
	int seed = time(NULL) + getpid();
	srand(seed);
	// parse args
	char *filename = argv[1];
	int descriptor1 = atoi(argv[2]);
	int descriptor2 = atoi(argv[3]);
	int number_of_children = atoi(argv[4]);

	// pipe
	int barrier[] = {descriptor1, descriptor2};

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

	// play nice!
	add_self(&children_status, number_of_children, semaphore, semaphore_id);
	close(barrier[1]);
	Message message;
	char token;
	while (1)
	{
		read(barrier[0], &token, 1);

		strcpy(content, "OK"); // before it gets attacked or not it is ok
		int does_defend = rand() % 2;
		if (does_defend == 1)
		{
			signal(SIGUSR1, react_defending);
			usleep(100000);
		}
		else
		{
			signal(SIGUSR1, react_dying);
			usleep(100000);
			int attacked_pid = get_non_self_pid(&children_status, number_of_children, semaphore, semaphore_id);
			printf("Proceso %d atacando al proceso %d\n", getpid(), attacked_pid);
			fflush(stdout);
			kill(attacked_pid, SIGUSR1);
		}
		usleep(100000);

		message.sender = getpid();
		strcpy(message.content, content);
		msgsnd(message_queue_id, (struct msgbuf *)&message, sizeof(Message), 0);
	}
}