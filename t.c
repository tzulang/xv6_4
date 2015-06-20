#include "types.h"
#include "user.h"
#include "fcntl.h"

int main(int argc, char **argv){


	if (argc >=2){
		int fd1= open("README", O_RDONLY );
		int fd2= open("t", O_WRONLY );
		int fd3= open("test", O_CREATE );
		
		int pip[2];

		if (pipe(pip)<0 ){
			printf(1,"pipe exit \n");
			exit();
		}
		int pid= fork();

	    if (pid<0 ){
			printf(1, "fork exit \n");
			exit();
		}

		if (pid==0){
			close(pip[1]);
			printf(1,"\n child %d starts Endless loop with open fds %d %d  %d %d \n\n",getpid() ,fd1, fd2,fd3, pip[0]);

			for(;;);
		} else	{
			close(pip[0]);
			printf(1,"\n father  %d waits for child with open fds %d %d  %d %d \n\n", getpid(), fd1, fd2,fd3, pip[1]);
			wait();
			printf(1,"father end waiting \n");

		}
		
	}
	
	 
	 printf(1, " exit here \n");
	exit();

	return 0;

}			