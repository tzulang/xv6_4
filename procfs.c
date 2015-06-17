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
void  itoa(int i, char stringNum *);

#define BASE_INUM 1000;

int procfsInum;
int first=1;
 
procfsisdir(struct inode *ip) {
  if (first){
    procfsInum= ip->inum;
    first= 0;
  }


  return (ip->inum == procfsInum);
}

void 
procfsiread(struct inode* dp, struct inode *ip) 
{
	// ip->flags = i_valid;
	// ip->major = 2;
  if (ip->inum == 1234) {
    ip->type = T_DEV;
    ip->major = PROCFS;
    ip->size = 0;
    ip->flags |= I_VALID;
  }
}

int getProcList(char *buf) {
  struct dirent de;
  int pidCount;
  int bufOff= 2;
  
  int pids [NPROC];
  int pidIndex; 


  char stringNum[64];
  int  stringNumLength;

  de.inum = procfsInum;
  memmove(de.name, ".", 2);
  memmove(buf, (char*)&de, sizeof(de));

  de.inum = ROOTINO;
  memmove(de.name, "..", 3);
  memmove(buf + sizeof(de), (char*)&de, sizeof(de));


  int pidCount = getProcPID(pids);
  
  for (pidIndex = 0; pidIndex< pidCount; pidIndex++){
      de.inum = BASE_INUM + pidIndex;
      stringLength = itoa(  pids[pidIndex], stringNumLength );

      memmove(de.name, stringNum, stringLength+1);
      memmove(buf + sizeof(de), (char*)&de, sizeof(de));
  }


  return 3 * sizeof(de);
}



int
procfsread(struct inode *ip, char *dst, int off, int n) {
  char buf[512];
  int size;

  if (procfsInum == -1)
    procfsInum = ip->inum;

  if (ip->inum == procfsInum) {
    size = createprocentries(buf);
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

int  itoa(int i, char stringNum *){

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
    return len;
}
 
