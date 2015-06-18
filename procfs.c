#include "types.h"
#include "stat.h"
#include "defs.h"
#include "param.h"
#include "traps.h"
#include "spinlock.h"
#include "fs.h"
#include "file.h"
#include "memlayout.h"
#include "mmu.h"
#include "proc.h"
#include "x86.h"


extern int getProcPIDS (int *pids);
extern struct proc* getProc (int pid);
extern void procLock();
extern void procRelease();

int  itoa(int num , char *stringNum );

#define BASE_INUM 1000;
#define CMDLINE_INUM 10001;
#define CWD_INUM 10002;
#define EXE_INUM 10003;
#define FDINFO_INUM 10004;
#define STATUS_INUM 10005;


int procfsInum;
int first=1;
 
int
procfsisdir(struct inode *ip) {

 if (first){
    procfsInum= ip->inum;
    first= 0;
  }


  if (ip->inum == procfsInum)
	  return 1;
  else return 0;
}

void 
procfsiread(struct inode* dp, struct inode *ip) 
{
	// ip->flags = i_valid;
	// ip->major = 2;
  //if (ip->inum == 1234) {
    ip->type = T_DEV;
    ip->major = PROCFS;
    ip->size = 0;
    ip->flags |= I_VALID;

}

int getProcList(char *buf, struct inode *pidIp) {
  struct dirent de;
  int pidCount;
  int bufOff= 2;
  
  int pids [NPROC];
  int pidIndex; 


  char stringNum[64];
  int  stringNumLength;


  //create "this dir" reference
  de.inum = pidIp->inum;
  memmove(de.name, ".", 2);
  memmove(buf, (char*)&de, sizeof(de));

  //create "prev dir" reference -procfs Dir
  de.inum = procfsInum;
  memmove(de.name, "..", 3);
  memmove(buf + sizeof(de), (char*)&de, sizeof(de));

  // return the current running processes pids
  pidCount = getProcPIDS(pids);

  //push Pids as file entries
  for (pidIndex = 0; pidIndex< pidCount; pidIndex++){

      de.inum = pidIndex + BASE_INUM ;
      stringNumLength = itoa(  pids[pidIndex], stringNum );

      memmove(de.name, stringNum, stringNumLength+1);
      memmove(buf + bufOff * sizeof(de), (char*)&de, sizeof(de));
      bufOff++;

  }

  return (bufOff)* sizeof(de);
}



int getProcEntry(char StringPid ,char *buf) {

  struct dirent de;
  int pidCount;
  int bufOff= 2;

  int pid = atoi(StringPid);
  struct proc *p;
  procLock();

  p = getProc(pid);

  procRelease();
  if (!p){
	  return 0;
  }


  //create "this dir" reference
  de.inum = procfsInum;
  memmove(de.name, ".", 2);
  memmove(buf, (char*)&de, sizeof(de));

  //create "prev dir" reference -root Dir
  de.inum = ROOTINO;
  memmove(de.name, "..", 3);
  memmove(buf + sizeof(de), (char*)&de, sizeof(de));

  //create "cmdline " reference
  de.inum = CMDLINE_INUM;
  memmove(de.name, "cmdline", 8);
  memmove(buf + 2*sizeof(de), (char*)&de, sizeof(de));

  //create "cwd " reference
  de.inum = CWD_INUM;
  memmove(de.name, "cwd", 4);
  memmove(buf + 3*sizeof(de), (char*)&de, sizeof(de));

  //create "exe " reference
  de.inum = EXE_INUM;
  memmove(de.name, "exe", 4);
  memmove(buf + 4*sizeof(de), (char*)&de, sizeof(de));

  //create "fdinfo " reference -root Dir
  de.inum = FDINFO_INUM;
  memmove(de.name, "fdinfo", 7);
  memmove(buf + 5*sizeof(de), (char*)&de, sizeof(de));

  //create "status " reference -root Dir
  de.inum = FDINFO_INUM;
  memmove(de.name, "status", 7);
  memmove(buf + 6*sizeof(de), (char*)&de, sizeof(de));

  return 7 * sizeof(de);
}



int
procfsread(struct inode *ip, char *dst, int off, int n) {
  char buf[1024];
  int size;

  if (procfsInum == -1)
    procfsInum = ip->inum;

  if (ip->inum == procfsInum) {
    size = getProcList(buf	);
  }
  if (ip->inum == 1234) {
    memmove(buf, "Hello world\n", 13);
    size = 13;
  }

  if (off < size) {
    int rr = size - off;
    rr = rr < n ? rr : n;
    memmove(dst, buf + off, rr);
    return rr;
  }

  return 0;
}

int
procfswrite(struct inode *ip, char *buf, int n)
{
  return 0;
}

void
procfsinit(void)
{
  devsw[PROCFS].isdir = procfsisdir;
  devsw[PROCFS].iread = procfsiread;
  devsw[PROCFS].write = procfswrite;
  devsw[PROCFS].read = procfsread;
}



//receives an integer and set stringNum to its string representation
// return the number of charachters in string num;

int  itoa(int num , char *stringNum ){

  int i, rem, len = 0, n;

    n = num;
    while (n != 0)
    {
        len++;
        n /= 10;
    }
    for (i = 0; i < len; i++)
    {
        rem = num % 10;
        num = num / 10;
        stringNum[len - (i + 1)] = rem + '0';
    }
    stringNum[len] = '\0';
//    cprintf("%s %d \n", stringNum ,len);
    return len;
}
 
