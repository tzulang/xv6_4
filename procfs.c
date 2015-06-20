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

int  atoi(const char *s);
int  itoa(int num , char *stringNum );

#define BASE_DIRENT_NUM 1000
#define BASE_DNUM_LIM BASE_DIRENT_NUM+ NPROC
#define CMDLINE_DNUM 2000
#define CWD_DNUM 3000
#define EXE_DNUM 4000
#define FDINFO_DNUM 5000
#define STATUS_DNUM 6000

static inline uint PID_PART(uint x) { return (x % 1000);}

int procfsInum;
int first=1;
 

int
procfsisdir(struct inode *ip) {

 if (first){
    procfsInum= ip->inum;
    ip->minor =0;
    first= 0;
  }


  if (ip->inum == procfsInum)
	  return 1;

  if (ip->inum >= BASE_DIRENT_NUM && ip->inum <BASE_DNUM_LIM)
    return 1;

 /// cprintf(" ########## %d \n", ip->inum / CWD_DNUM);
  if (ip->inum / CWD_DNUM  == 1){
    return 1;
  }
  
  else return 0;
}

void 
procfsiread(struct inode* dp, struct inode *ip) 
{
	// ip->flags = i_valid;
	// ip->major = 2;

 // cprintf("**** iread  inmu dp %d ip %d\n", dp->inum, ip->inum);
  //if (ip->inum >= BASE_DIRENT_NUM) {
    ip->type = T_DEV;
    ip->major = PROCFS;
    ip->size = 0;
    ip->flags |= I_VALID;
  //}
//ip->type == T_DEV && devsw[ip->major].isdir && devsw[ip->major].isdir(ip)
  // cprintf("**** iread  inmu dp %d ip %d\n", dp->inum, ip->inum);

  // cprintf("**** iread  type %d isdir %d  isdir(ip) %d\n",  ip->type, devsw[ip->major].isdir, devsw[ip->major].isdir(ip));
  // cprintf("**** iread  major dp %d ip %d\n", dp->major, ip->major);
  // cprintf("**** iread  minor dp %d ip %d\n", dp->minor, ip->minor);
    
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
  de.inum = procfsInum;
  memmove(de.name, ".", 2);
  memmove(buf, (char*)&de, sizeof(de));

  //create "prev dir" reference -procfs Dir
  de.inum = ROOTINO;
  memmove(de.name, "..", 3);
  memmove(buf + sizeof(de), (char*)&de, sizeof(de));

  // return the current running processes pids
  pidCount = getProcPIDS(pids);

  //push Pids as file entries
  for (pidIndex = 0; pidIndex< pidCount; pidIndex++){

      de.inum = pids[pidIndex] + BASE_DIRENT_NUM ;
      
      stringNumLength = itoa(  pids[pidIndex], stringNum );

      memmove(de.name, stringNum, stringNumLength+1);
      memmove(buf + bufOff * sizeof(de), (char*)&de, sizeof(de));
      bufOff++;

  }

  return (bufOff)* sizeof(de);
}



int getProcEntry(uint pid ,char *buf, struct inode *ip) {

  struct dirent de;

  
  struct proc *p;
  procLock();

  p = getProc(pid);
  
  procRelease();
  if (!p){
    cprintf ( " pid %d\n  ", pid );
	  return 0;
  }


  //create "this dir" reference
  de.inum = ip->inum;

  //cprintf(" ********* %d\n", ip->inum);
  memmove(de.name, ".", 2);
  memmove(buf, (char*)&de, sizeof(de));

  //create "prev dir" reference -root Dir
  de.inum = procfsInum;
  memmove(de.name, "..", 3);
  memmove(buf + sizeof(de), (char*)&de, sizeof(de));

  //create "cmdline " reference
  
  de.inum = CMDLINE_DNUM+pid;
  // cprintf("######### %d %p\n", de.inum, r);
  
  memmove(de.name, "cmdline", 8);
  memmove(buf + 2*sizeof(de), (char*)&de, sizeof(de));

  //create "cwd " reference
  de.inum = CWD_DNUM + pid;
  memmove(de.name, "cwd", 4);
  memmove(buf + 3*sizeof(de), (char*)&de, sizeof(de));

  //create "exe " reference
  de.inum = EXE_DNUM + pid;
  memmove(de.name, "exe", 4);
  memmove(buf + 4*sizeof(de), (char*)&de, sizeof(de));

  //create "fdinfo " reference -root Dir
  de.inum = FDINFO_DNUM + pid;
  memmove(de.name, "fdinfo", 7);
  memmove(buf + 5*sizeof(de), (char*)&de, sizeof(de));

  //create "status " reference -root Dir
  de.inum = STATUS_DNUM + pid;
  memmove(de.name, "status", 7);
  memmove(buf + 6*sizeof(de), (char*)&de, sizeof(de));

  return 7 * sizeof(de);
}



int
procfsread(struct inode *ip, char *dst, int off, int n) {
  char buf[1024];
  int size ,i ;

    // cprintf("***********    %d \n", ip->inum);
    if (first){
      procfsInum= ip->inum;
      ip->minor =0;
      first= 0;
    }
    
	  if (ip->inum == procfsInum) {
		  size = getProcList(buf, ip);
          
    }

    uint pid = PID_PART(ip->inum);

    struct proc * p= getProc(pid);
    
    //cprintf ("p.pid %d *** num %d, pid %d *** %s \n", p->pid, ip->inum ,pid, p->cmdline);

    if (ip->inum >= BASE_DIRENT_NUM && ip->inum<=BASE_DNUM_LIM ){
		     
         size = getProcEntry(pid,buf, ip);
    }

    if ( ip-> inum >= CMDLINE_DNUM) {


        if(!p)
         return 0;


        switch (ip->inum-pid){
         
              case CMDLINE_DNUM:
                            // cprintf("here p %d cmd %s\n", p->pid, p->cmdline);
                            size = strlen(p->cmdline);

                            memmove(buf, p->cmdline, size);

                            for (i =1 ; i < MAXARGS; i++){
                            	if (p->args[i]){

                            		memmove(buf+size, " ", 1);
                            		size++ ;
                            		memmove(buf+size, p->args[i], strlen(p->args[i]));
                            		//cprintf("here %s \n",p->args[i]);
                            		size+= strlen(p->args[i]);
                            	}
                            }

//                            size++;
							memmove(buf+size, "\n",1);
							size++;
                            break;
              case CWD_DNUM:
                            size= readi(p->exe, (char*)&dst, off, sizeof(struct dirent));
                            // memmove(buf, (char*)&p->exe, size);
                            cprintf("Here \n");
                            break;
              // case EXE_DNUM:

              //               return readi(p->exe, dst, off, n);
              //               // readi(dp, (char*)&de, off, sizeof(de)) 
              //               break; 

        }
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

int atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
    n = n*10 + *s++ - '0';
  return n;
}


