
_t:     file format elf32-i386


Disassembly of section .text:

00000000 <main>:
#include "types.h"
#include "user.h"
#include "fcntl.h"

int main(int argc, char **argv){
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	53                   	push   %ebx
   4:	83 e4 f0             	and    $0xfffffff0,%esp
   7:	83 ec 40             	sub    $0x40,%esp


	if (argc >=2){
   a:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
   e:	0f 8e 4e 01 00 00    	jle    162 <main+0x162>
		int fd1= open("README", O_RDONLY );
  14:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1b:	00 
  1c:	c7 04 24 30 09 00 00 	movl   $0x930,(%esp)
  23:	e8 fb 03 00 00       	call   423 <open>
  28:	89 44 24 3c          	mov    %eax,0x3c(%esp)
		int fd2= open("t", O_WRONLY );
  2c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  33:	00 
  34:	c7 04 24 37 09 00 00 	movl   $0x937,(%esp)
  3b:	e8 e3 03 00 00       	call   423 <open>
  40:	89 44 24 38          	mov    %eax,0x38(%esp)
		int fd3= open("test", O_CREATE );
  44:	c7 44 24 04 00 02 00 	movl   $0x200,0x4(%esp)
  4b:	00 
  4c:	c7 04 24 39 09 00 00 	movl   $0x939,(%esp)
  53:	e8 cb 03 00 00       	call   423 <open>
  58:	89 44 24 34          	mov    %eax,0x34(%esp)
		
		int pip[2];

		if (pipe(pip)<0 ){
  5c:	8d 44 24 28          	lea    0x28(%esp),%eax
  60:	89 04 24             	mov    %eax,(%esp)
  63:	e8 8b 03 00 00       	call   3f3 <pipe>
  68:	85 c0                	test   %eax,%eax
  6a:	79 19                	jns    85 <main+0x85>
			printf(1,"pipe exit \n");
  6c:	c7 44 24 04 3e 09 00 	movl   $0x93e,0x4(%esp)
  73:	00 
  74:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  7b:	e8 e3 04 00 00       	call   563 <printf>
			exit();
  80:	e8 5e 03 00 00       	call   3e3 <exit>
		}
		int pid= fork();
  85:	e8 51 03 00 00       	call   3db <fork>
  8a:	89 44 24 30          	mov    %eax,0x30(%esp)

	    if (pid<0 ){
  8e:	83 7c 24 30 00       	cmpl   $0x0,0x30(%esp)
  93:	79 19                	jns    ae <main+0xae>
			printf(1, "fork exit \n");
  95:	c7 44 24 04 4a 09 00 	movl   $0x94a,0x4(%esp)
  9c:	00 
  9d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  a4:	e8 ba 04 00 00       	call   563 <printf>
			exit();
  a9:	e8 35 03 00 00       	call   3e3 <exit>
		}

		if (pid==0){
  ae:	83 7c 24 30 00       	cmpl   $0x0,0x30(%esp)
  b3:	75 4b                	jne    100 <main+0x100>
			close(pip[1]);
  b5:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  b9:	89 04 24             	mov    %eax,(%esp)
  bc:	e8 4a 03 00 00       	call   40b <close>
			printf(1,"\n child %d starts Endless loop with open fds %d %d  %d %d \n\n",getpid() ,fd1, fd2,fd3, pip[0]);
  c1:	8b 5c 24 28          	mov    0x28(%esp),%ebx
  c5:	e8 99 03 00 00       	call   463 <getpid>
  ca:	89 5c 24 18          	mov    %ebx,0x18(%esp)
  ce:	8b 54 24 34          	mov    0x34(%esp),%edx
  d2:	89 54 24 14          	mov    %edx,0x14(%esp)
  d6:	8b 54 24 38          	mov    0x38(%esp),%edx
  da:	89 54 24 10          	mov    %edx,0x10(%esp)
  de:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  e2:	89 54 24 0c          	mov    %edx,0xc(%esp)
  e6:	89 44 24 08          	mov    %eax,0x8(%esp)
  ea:	c7 44 24 04 58 09 00 	movl   $0x958,0x4(%esp)
  f1:	00 
  f2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  f9:	e8 65 04 00 00       	call   563 <printf>

			for(;;);
  fe:	eb fe                	jmp    fe <main+0xfe>
		} else	{
			close(pip[0]);
 100:	8b 44 24 28          	mov    0x28(%esp),%eax
 104:	89 04 24             	mov    %eax,(%esp)
 107:	e8 ff 02 00 00       	call   40b <close>
			printf(1,"\n father  %d waits for child with open fds %d %d  %d %d \n\n", getpid(), fd1, fd2,fd3, pip[1]);
 10c:	8b 5c 24 2c          	mov    0x2c(%esp),%ebx
 110:	e8 4e 03 00 00       	call   463 <getpid>
 115:	89 5c 24 18          	mov    %ebx,0x18(%esp)
 119:	8b 54 24 34          	mov    0x34(%esp),%edx
 11d:	89 54 24 14          	mov    %edx,0x14(%esp)
 121:	8b 54 24 38          	mov    0x38(%esp),%edx
 125:	89 54 24 10          	mov    %edx,0x10(%esp)
 129:	8b 54 24 3c          	mov    0x3c(%esp),%edx
 12d:	89 54 24 0c          	mov    %edx,0xc(%esp)
 131:	89 44 24 08          	mov    %eax,0x8(%esp)
 135:	c7 44 24 04 98 09 00 	movl   $0x998,0x4(%esp)
 13c:	00 
 13d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
 144:	e8 1a 04 00 00       	call   563 <printf>
			wait();
 149:	e8 9d 02 00 00       	call   3eb <wait>
			printf(1,"father end waiting \n");
 14e:	c7 44 24 04 d3 09 00 	movl   $0x9d3,0x4(%esp)
 155:	00 
 156:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
 15d:	e8 01 04 00 00       	call   563 <printf>
		}
		
	}
	
	 
	 printf(1, " exit here \n");
 162:	c7 44 24 04 e8 09 00 	movl   $0x9e8,0x4(%esp)
 169:	00 
 16a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
 171:	e8 ed 03 00 00       	call   563 <printf>
	exit();
 176:	e8 68 02 00 00       	call   3e3 <exit>

0000017b <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
 17b:	55                   	push   %ebp
 17c:	89 e5                	mov    %esp,%ebp
 17e:	57                   	push   %edi
 17f:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
 180:	8b 4d 08             	mov    0x8(%ebp),%ecx
 183:	8b 55 10             	mov    0x10(%ebp),%edx
 186:	8b 45 0c             	mov    0xc(%ebp),%eax
 189:	89 cb                	mov    %ecx,%ebx
 18b:	89 df                	mov    %ebx,%edi
 18d:	89 d1                	mov    %edx,%ecx
 18f:	fc                   	cld    
 190:	f3 aa                	rep stos %al,%es:(%edi)
 192:	89 ca                	mov    %ecx,%edx
 194:	89 fb                	mov    %edi,%ebx
 196:	89 5d 08             	mov    %ebx,0x8(%ebp)
 199:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
 19c:	5b                   	pop    %ebx
 19d:	5f                   	pop    %edi
 19e:	5d                   	pop    %ebp
 19f:	c3                   	ret    

000001a0 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
 1a0:	55                   	push   %ebp
 1a1:	89 e5                	mov    %esp,%ebp
 1a3:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
 1a6:	8b 45 08             	mov    0x8(%ebp),%eax
 1a9:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while((*s++ = *t++) != 0)
 1ac:	90                   	nop
 1ad:	8b 45 08             	mov    0x8(%ebp),%eax
 1b0:	8d 50 01             	lea    0x1(%eax),%edx
 1b3:	89 55 08             	mov    %edx,0x8(%ebp)
 1b6:	8b 55 0c             	mov    0xc(%ebp),%edx
 1b9:	8d 4a 01             	lea    0x1(%edx),%ecx
 1bc:	89 4d 0c             	mov    %ecx,0xc(%ebp)
 1bf:	0f b6 12             	movzbl (%edx),%edx
 1c2:	88 10                	mov    %dl,(%eax)
 1c4:	0f b6 00             	movzbl (%eax),%eax
 1c7:	84 c0                	test   %al,%al
 1c9:	75 e2                	jne    1ad <strcpy+0xd>
    ;
  return os;
 1cb:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 1ce:	c9                   	leave  
 1cf:	c3                   	ret    

000001d0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 1d0:	55                   	push   %ebp
 1d1:	89 e5                	mov    %esp,%ebp
  while(*p && *p == *q)
 1d3:	eb 08                	jmp    1dd <strcmp+0xd>
    p++, q++;
 1d5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 1d9:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
  while(*p && *p == *q)
 1dd:	8b 45 08             	mov    0x8(%ebp),%eax
 1e0:	0f b6 00             	movzbl (%eax),%eax
 1e3:	84 c0                	test   %al,%al
 1e5:	74 10                	je     1f7 <strcmp+0x27>
 1e7:	8b 45 08             	mov    0x8(%ebp),%eax
 1ea:	0f b6 10             	movzbl (%eax),%edx
 1ed:	8b 45 0c             	mov    0xc(%ebp),%eax
 1f0:	0f b6 00             	movzbl (%eax),%eax
 1f3:	38 c2                	cmp    %al,%dl
 1f5:	74 de                	je     1d5 <strcmp+0x5>
    p++, q++;
  return (uchar)*p - (uchar)*q;
 1f7:	8b 45 08             	mov    0x8(%ebp),%eax
 1fa:	0f b6 00             	movzbl (%eax),%eax
 1fd:	0f b6 d0             	movzbl %al,%edx
 200:	8b 45 0c             	mov    0xc(%ebp),%eax
 203:	0f b6 00             	movzbl (%eax),%eax
 206:	0f b6 c0             	movzbl %al,%eax
 209:	29 c2                	sub    %eax,%edx
 20b:	89 d0                	mov    %edx,%eax
}
 20d:	5d                   	pop    %ebp
 20e:	c3                   	ret    

0000020f <strlen>:

uint
strlen(char *s)
{
 20f:	55                   	push   %ebp
 210:	89 e5                	mov    %esp,%ebp
 212:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
 215:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
 21c:	eb 04                	jmp    222 <strlen+0x13>
 21e:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 222:	8b 55 fc             	mov    -0x4(%ebp),%edx
 225:	8b 45 08             	mov    0x8(%ebp),%eax
 228:	01 d0                	add    %edx,%eax
 22a:	0f b6 00             	movzbl (%eax),%eax
 22d:	84 c0                	test   %al,%al
 22f:	75 ed                	jne    21e <strlen+0xf>
    ;
  return n;
 231:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 234:	c9                   	leave  
 235:	c3                   	ret    

00000236 <memset>:

void*
memset(void *dst, int c, uint n)
{
 236:	55                   	push   %ebp
 237:	89 e5                	mov    %esp,%ebp
 239:	83 ec 0c             	sub    $0xc,%esp
  stosb(dst, c, n);
 23c:	8b 45 10             	mov    0x10(%ebp),%eax
 23f:	89 44 24 08          	mov    %eax,0x8(%esp)
 243:	8b 45 0c             	mov    0xc(%ebp),%eax
 246:	89 44 24 04          	mov    %eax,0x4(%esp)
 24a:	8b 45 08             	mov    0x8(%ebp),%eax
 24d:	89 04 24             	mov    %eax,(%esp)
 250:	e8 26 ff ff ff       	call   17b <stosb>
  return dst;
 255:	8b 45 08             	mov    0x8(%ebp),%eax
}
 258:	c9                   	leave  
 259:	c3                   	ret    

0000025a <strchr>:

char*
strchr(const char *s, char c)
{
 25a:	55                   	push   %ebp
 25b:	89 e5                	mov    %esp,%ebp
 25d:	83 ec 04             	sub    $0x4,%esp
 260:	8b 45 0c             	mov    0xc(%ebp),%eax
 263:	88 45 fc             	mov    %al,-0x4(%ebp)
  for(; *s; s++)
 266:	eb 14                	jmp    27c <strchr+0x22>
    if(*s == c)
 268:	8b 45 08             	mov    0x8(%ebp),%eax
 26b:	0f b6 00             	movzbl (%eax),%eax
 26e:	3a 45 fc             	cmp    -0x4(%ebp),%al
 271:	75 05                	jne    278 <strchr+0x1e>
      return (char*)s;
 273:	8b 45 08             	mov    0x8(%ebp),%eax
 276:	eb 13                	jmp    28b <strchr+0x31>
}

char*
strchr(const char *s, char c)
{
  for(; *s; s++)
 278:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 27c:	8b 45 08             	mov    0x8(%ebp),%eax
 27f:	0f b6 00             	movzbl (%eax),%eax
 282:	84 c0                	test   %al,%al
 284:	75 e2                	jne    268 <strchr+0xe>
    if(*s == c)
      return (char*)s;
  return 0;
 286:	b8 00 00 00 00       	mov    $0x0,%eax
}
 28b:	c9                   	leave  
 28c:	c3                   	ret    

0000028d <gets>:

char*
gets(char *buf, int max)
{
 28d:	55                   	push   %ebp
 28e:	89 e5                	mov    %esp,%ebp
 290:	83 ec 28             	sub    $0x28,%esp
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 293:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 29a:	eb 4c                	jmp    2e8 <gets+0x5b>
    cc = read(0, &c, 1);
 29c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 2a3:	00 
 2a4:	8d 45 ef             	lea    -0x11(%ebp),%eax
 2a7:	89 44 24 04          	mov    %eax,0x4(%esp)
 2ab:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
 2b2:	e8 44 01 00 00       	call   3fb <read>
 2b7:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(cc < 1)
 2ba:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 2be:	7f 02                	jg     2c2 <gets+0x35>
      break;
 2c0:	eb 31                	jmp    2f3 <gets+0x66>
    buf[i++] = c;
 2c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
 2c5:	8d 50 01             	lea    0x1(%eax),%edx
 2c8:	89 55 f4             	mov    %edx,-0xc(%ebp)
 2cb:	89 c2                	mov    %eax,%edx
 2cd:	8b 45 08             	mov    0x8(%ebp),%eax
 2d0:	01 c2                	add    %eax,%edx
 2d2:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 2d6:	88 02                	mov    %al,(%edx)
    if(c == '\n' || c == '\r')
 2d8:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 2dc:	3c 0a                	cmp    $0xa,%al
 2de:	74 13                	je     2f3 <gets+0x66>
 2e0:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 2e4:	3c 0d                	cmp    $0xd,%al
 2e6:	74 0b                	je     2f3 <gets+0x66>
gets(char *buf, int max)
{
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 2e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
 2eb:	83 c0 01             	add    $0x1,%eax
 2ee:	3b 45 0c             	cmp    0xc(%ebp),%eax
 2f1:	7c a9                	jl     29c <gets+0xf>
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
      break;
  }
  buf[i] = '\0';
 2f3:	8b 55 f4             	mov    -0xc(%ebp),%edx
 2f6:	8b 45 08             	mov    0x8(%ebp),%eax
 2f9:	01 d0                	add    %edx,%eax
 2fb:	c6 00 00             	movb   $0x0,(%eax)
  return buf;
 2fe:	8b 45 08             	mov    0x8(%ebp),%eax
}
 301:	c9                   	leave  
 302:	c3                   	ret    

00000303 <stat>:

int
stat(char *n, struct stat *st)
{
 303:	55                   	push   %ebp
 304:	89 e5                	mov    %esp,%ebp
 306:	83 ec 28             	sub    $0x28,%esp
  int fd;
  int r;
  
  
  fd = open(n, O_RDONLY);
 309:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 310:	00 
 311:	8b 45 08             	mov    0x8(%ebp),%eax
 314:	89 04 24             	mov    %eax,(%esp)
 317:	e8 07 01 00 00       	call   423 <open>
 31c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0)
 31f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 323:	79 07                	jns    32c <stat+0x29>
    return -1;
 325:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
 32a:	eb 23                	jmp    34f <stat+0x4c>
  r = fstat(fd, st);
 32c:	8b 45 0c             	mov    0xc(%ebp),%eax
 32f:	89 44 24 04          	mov    %eax,0x4(%esp)
 333:	8b 45 f4             	mov    -0xc(%ebp),%eax
 336:	89 04 24             	mov    %eax,(%esp)
 339:	e8 fd 00 00 00       	call   43b <fstat>
 33e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  close(fd);
 341:	8b 45 f4             	mov    -0xc(%ebp),%eax
 344:	89 04 24             	mov    %eax,(%esp)
 347:	e8 bf 00 00 00       	call   40b <close>
  return r;
 34c:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
 34f:	c9                   	leave  
 350:	c3                   	ret    

00000351 <atoi>:

int
atoi(const char *s)
{
 351:	55                   	push   %ebp
 352:	89 e5                	mov    %esp,%ebp
 354:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
 357:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
 35e:	eb 25                	jmp    385 <atoi+0x34>
    n = n*10 + *s++ - '0';
 360:	8b 55 fc             	mov    -0x4(%ebp),%edx
 363:	89 d0                	mov    %edx,%eax
 365:	c1 e0 02             	shl    $0x2,%eax
 368:	01 d0                	add    %edx,%eax
 36a:	01 c0                	add    %eax,%eax
 36c:	89 c1                	mov    %eax,%ecx
 36e:	8b 45 08             	mov    0x8(%ebp),%eax
 371:	8d 50 01             	lea    0x1(%eax),%edx
 374:	89 55 08             	mov    %edx,0x8(%ebp)
 377:	0f b6 00             	movzbl (%eax),%eax
 37a:	0f be c0             	movsbl %al,%eax
 37d:	01 c8                	add    %ecx,%eax
 37f:	83 e8 30             	sub    $0x30,%eax
 382:	89 45 fc             	mov    %eax,-0x4(%ebp)
atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 385:	8b 45 08             	mov    0x8(%ebp),%eax
 388:	0f b6 00             	movzbl (%eax),%eax
 38b:	3c 2f                	cmp    $0x2f,%al
 38d:	7e 0a                	jle    399 <atoi+0x48>
 38f:	8b 45 08             	mov    0x8(%ebp),%eax
 392:	0f b6 00             	movzbl (%eax),%eax
 395:	3c 39                	cmp    $0x39,%al
 397:	7e c7                	jle    360 <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
 399:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 39c:	c9                   	leave  
 39d:	c3                   	ret    

0000039e <memmove>:

void*
memmove(void *vdst, void *vsrc, int n)
{
 39e:	55                   	push   %ebp
 39f:	89 e5                	mov    %esp,%ebp
 3a1:	83 ec 10             	sub    $0x10,%esp
  char *dst, *src;
  
  dst = vdst;
 3a4:	8b 45 08             	mov    0x8(%ebp),%eax
 3a7:	89 45 fc             	mov    %eax,-0x4(%ebp)
  src = vsrc;
 3aa:	8b 45 0c             	mov    0xc(%ebp),%eax
 3ad:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0)
 3b0:	eb 17                	jmp    3c9 <memmove+0x2b>
    *dst++ = *src++;
 3b2:	8b 45 fc             	mov    -0x4(%ebp),%eax
 3b5:	8d 50 01             	lea    0x1(%eax),%edx
 3b8:	89 55 fc             	mov    %edx,-0x4(%ebp)
 3bb:	8b 55 f8             	mov    -0x8(%ebp),%edx
 3be:	8d 4a 01             	lea    0x1(%edx),%ecx
 3c1:	89 4d f8             	mov    %ecx,-0x8(%ebp)
 3c4:	0f b6 12             	movzbl (%edx),%edx
 3c7:	88 10                	mov    %dl,(%eax)
{
  char *dst, *src;
  
  dst = vdst;
  src = vsrc;
  while(n-- > 0)
 3c9:	8b 45 10             	mov    0x10(%ebp),%eax
 3cc:	8d 50 ff             	lea    -0x1(%eax),%edx
 3cf:	89 55 10             	mov    %edx,0x10(%ebp)
 3d2:	85 c0                	test   %eax,%eax
 3d4:	7f dc                	jg     3b2 <memmove+0x14>
    *dst++ = *src++;
  return vdst;
 3d6:	8b 45 08             	mov    0x8(%ebp),%eax
}
 3d9:	c9                   	leave  
 3da:	c3                   	ret    

000003db <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 3db:	b8 01 00 00 00       	mov    $0x1,%eax
 3e0:	cd 40                	int    $0x40
 3e2:	c3                   	ret    

000003e3 <exit>:
SYSCALL(exit)
 3e3:	b8 02 00 00 00       	mov    $0x2,%eax
 3e8:	cd 40                	int    $0x40
 3ea:	c3                   	ret    

000003eb <wait>:
SYSCALL(wait)
 3eb:	b8 03 00 00 00       	mov    $0x3,%eax
 3f0:	cd 40                	int    $0x40
 3f2:	c3                   	ret    

000003f3 <pipe>:
SYSCALL(pipe)
 3f3:	b8 04 00 00 00       	mov    $0x4,%eax
 3f8:	cd 40                	int    $0x40
 3fa:	c3                   	ret    

000003fb <read>:
SYSCALL(read)
 3fb:	b8 05 00 00 00       	mov    $0x5,%eax
 400:	cd 40                	int    $0x40
 402:	c3                   	ret    

00000403 <write>:
SYSCALL(write)
 403:	b8 10 00 00 00       	mov    $0x10,%eax
 408:	cd 40                	int    $0x40
 40a:	c3                   	ret    

0000040b <close>:
SYSCALL(close)
 40b:	b8 15 00 00 00       	mov    $0x15,%eax
 410:	cd 40                	int    $0x40
 412:	c3                   	ret    

00000413 <kill>:
SYSCALL(kill)
 413:	b8 06 00 00 00       	mov    $0x6,%eax
 418:	cd 40                	int    $0x40
 41a:	c3                   	ret    

0000041b <exec>:
SYSCALL(exec)
 41b:	b8 07 00 00 00       	mov    $0x7,%eax
 420:	cd 40                	int    $0x40
 422:	c3                   	ret    

00000423 <open>:
SYSCALL(open)
 423:	b8 0f 00 00 00       	mov    $0xf,%eax
 428:	cd 40                	int    $0x40
 42a:	c3                   	ret    

0000042b <mknod>:
SYSCALL(mknod)
 42b:	b8 11 00 00 00       	mov    $0x11,%eax
 430:	cd 40                	int    $0x40
 432:	c3                   	ret    

00000433 <unlink>:
SYSCALL(unlink)
 433:	b8 12 00 00 00       	mov    $0x12,%eax
 438:	cd 40                	int    $0x40
 43a:	c3                   	ret    

0000043b <fstat>:
SYSCALL(fstat)
 43b:	b8 08 00 00 00       	mov    $0x8,%eax
 440:	cd 40                	int    $0x40
 442:	c3                   	ret    

00000443 <link>:
SYSCALL(link)
 443:	b8 13 00 00 00       	mov    $0x13,%eax
 448:	cd 40                	int    $0x40
 44a:	c3                   	ret    

0000044b <mkdir>:
SYSCALL(mkdir)
 44b:	b8 14 00 00 00       	mov    $0x14,%eax
 450:	cd 40                	int    $0x40
 452:	c3                   	ret    

00000453 <chdir>:
SYSCALL(chdir)
 453:	b8 09 00 00 00       	mov    $0x9,%eax
 458:	cd 40                	int    $0x40
 45a:	c3                   	ret    

0000045b <dup>:
SYSCALL(dup)
 45b:	b8 0a 00 00 00       	mov    $0xa,%eax
 460:	cd 40                	int    $0x40
 462:	c3                   	ret    

00000463 <getpid>:
SYSCALL(getpid)
 463:	b8 0b 00 00 00       	mov    $0xb,%eax
 468:	cd 40                	int    $0x40
 46a:	c3                   	ret    

0000046b <sbrk>:
SYSCALL(sbrk)
 46b:	b8 0c 00 00 00       	mov    $0xc,%eax
 470:	cd 40                	int    $0x40
 472:	c3                   	ret    

00000473 <sleep>:
SYSCALL(sleep)
 473:	b8 0d 00 00 00       	mov    $0xd,%eax
 478:	cd 40                	int    $0x40
 47a:	c3                   	ret    

0000047b <uptime>:
SYSCALL(uptime)
 47b:	b8 0e 00 00 00       	mov    $0xe,%eax
 480:	cd 40                	int    $0x40
 482:	c3                   	ret    

00000483 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 483:	55                   	push   %ebp
 484:	89 e5                	mov    %esp,%ebp
 486:	83 ec 18             	sub    $0x18,%esp
 489:	8b 45 0c             	mov    0xc(%ebp),%eax
 48c:	88 45 f4             	mov    %al,-0xc(%ebp)
  write(fd, &c, 1);
 48f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 496:	00 
 497:	8d 45 f4             	lea    -0xc(%ebp),%eax
 49a:	89 44 24 04          	mov    %eax,0x4(%esp)
 49e:	8b 45 08             	mov    0x8(%ebp),%eax
 4a1:	89 04 24             	mov    %eax,(%esp)
 4a4:	e8 5a ff ff ff       	call   403 <write>
}
 4a9:	c9                   	leave  
 4aa:	c3                   	ret    

000004ab <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 4ab:	55                   	push   %ebp
 4ac:	89 e5                	mov    %esp,%ebp
 4ae:	56                   	push   %esi
 4af:	53                   	push   %ebx
 4b0:	83 ec 30             	sub    $0x30,%esp
  static char digits[] = "0123456789ABCDEF";
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
 4b3:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  if(sgn && xx < 0){
 4ba:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
 4be:	74 17                	je     4d7 <printint+0x2c>
 4c0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
 4c4:	79 11                	jns    4d7 <printint+0x2c>
    neg = 1;
 4c6:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
    x = -xx;
 4cd:	8b 45 0c             	mov    0xc(%ebp),%eax
 4d0:	f7 d8                	neg    %eax
 4d2:	89 45 ec             	mov    %eax,-0x14(%ebp)
 4d5:	eb 06                	jmp    4dd <printint+0x32>
  } else {
    x = xx;
 4d7:	8b 45 0c             	mov    0xc(%ebp),%eax
 4da:	89 45 ec             	mov    %eax,-0x14(%ebp)
  }

  i = 0;
 4dd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
 4e4:	8b 4d f4             	mov    -0xc(%ebp),%ecx
 4e7:	8d 41 01             	lea    0x1(%ecx),%eax
 4ea:	89 45 f4             	mov    %eax,-0xc(%ebp)
 4ed:	8b 5d 10             	mov    0x10(%ebp),%ebx
 4f0:	8b 45 ec             	mov    -0x14(%ebp),%eax
 4f3:	ba 00 00 00 00       	mov    $0x0,%edx
 4f8:	f7 f3                	div    %ebx
 4fa:	89 d0                	mov    %edx,%eax
 4fc:	0f b6 80 40 0c 00 00 	movzbl 0xc40(%eax),%eax
 503:	88 44 0d dc          	mov    %al,-0x24(%ebp,%ecx,1)
  }while((x /= base) != 0);
 507:	8b 75 10             	mov    0x10(%ebp),%esi
 50a:	8b 45 ec             	mov    -0x14(%ebp),%eax
 50d:	ba 00 00 00 00       	mov    $0x0,%edx
 512:	f7 f6                	div    %esi
 514:	89 45 ec             	mov    %eax,-0x14(%ebp)
 517:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 51b:	75 c7                	jne    4e4 <printint+0x39>
  if(neg)
 51d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 521:	74 10                	je     533 <printint+0x88>
    buf[i++] = '-';
 523:	8b 45 f4             	mov    -0xc(%ebp),%eax
 526:	8d 50 01             	lea    0x1(%eax),%edx
 529:	89 55 f4             	mov    %edx,-0xc(%ebp)
 52c:	c6 44 05 dc 2d       	movb   $0x2d,-0x24(%ebp,%eax,1)

  while(--i >= 0)
 531:	eb 1f                	jmp    552 <printint+0xa7>
 533:	eb 1d                	jmp    552 <printint+0xa7>
    putc(fd, buf[i]);
 535:	8d 55 dc             	lea    -0x24(%ebp),%edx
 538:	8b 45 f4             	mov    -0xc(%ebp),%eax
 53b:	01 d0                	add    %edx,%eax
 53d:	0f b6 00             	movzbl (%eax),%eax
 540:	0f be c0             	movsbl %al,%eax
 543:	89 44 24 04          	mov    %eax,0x4(%esp)
 547:	8b 45 08             	mov    0x8(%ebp),%eax
 54a:	89 04 24             	mov    %eax,(%esp)
 54d:	e8 31 ff ff ff       	call   483 <putc>
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
 552:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
 556:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 55a:	79 d9                	jns    535 <printint+0x8a>
    putc(fd, buf[i]);
}
 55c:	83 c4 30             	add    $0x30,%esp
 55f:	5b                   	pop    %ebx
 560:	5e                   	pop    %esi
 561:	5d                   	pop    %ebp
 562:	c3                   	ret    

00000563 <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
 563:	55                   	push   %ebp
 564:	89 e5                	mov    %esp,%ebp
 566:	83 ec 38             	sub    $0x38,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
 569:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  ap = (uint*)(void*)&fmt + 1;
 570:	8d 45 0c             	lea    0xc(%ebp),%eax
 573:	83 c0 04             	add    $0x4,%eax
 576:	89 45 e8             	mov    %eax,-0x18(%ebp)
  for(i = 0; fmt[i]; i++){
 579:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
 580:	e9 7c 01 00 00       	jmp    701 <printf+0x19e>
    c = fmt[i] & 0xff;
 585:	8b 55 0c             	mov    0xc(%ebp),%edx
 588:	8b 45 f0             	mov    -0x10(%ebp),%eax
 58b:	01 d0                	add    %edx,%eax
 58d:	0f b6 00             	movzbl (%eax),%eax
 590:	0f be c0             	movsbl %al,%eax
 593:	25 ff 00 00 00       	and    $0xff,%eax
 598:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(state == 0){
 59b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 59f:	75 2c                	jne    5cd <printf+0x6a>
      if(c == '%'){
 5a1:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 5a5:	75 0c                	jne    5b3 <printf+0x50>
        state = '%';
 5a7:	c7 45 ec 25 00 00 00 	movl   $0x25,-0x14(%ebp)
 5ae:	e9 4a 01 00 00       	jmp    6fd <printf+0x19a>
      } else {
        putc(fd, c);
 5b3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 5b6:	0f be c0             	movsbl %al,%eax
 5b9:	89 44 24 04          	mov    %eax,0x4(%esp)
 5bd:	8b 45 08             	mov    0x8(%ebp),%eax
 5c0:	89 04 24             	mov    %eax,(%esp)
 5c3:	e8 bb fe ff ff       	call   483 <putc>
 5c8:	e9 30 01 00 00       	jmp    6fd <printf+0x19a>
      }
    } else if(state == '%'){
 5cd:	83 7d ec 25          	cmpl   $0x25,-0x14(%ebp)
 5d1:	0f 85 26 01 00 00    	jne    6fd <printf+0x19a>
      if(c == 'd'){
 5d7:	83 7d e4 64          	cmpl   $0x64,-0x1c(%ebp)
 5db:	75 2d                	jne    60a <printf+0xa7>
        printint(fd, *ap, 10, 1);
 5dd:	8b 45 e8             	mov    -0x18(%ebp),%eax
 5e0:	8b 00                	mov    (%eax),%eax
 5e2:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
 5e9:	00 
 5ea:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
 5f1:	00 
 5f2:	89 44 24 04          	mov    %eax,0x4(%esp)
 5f6:	8b 45 08             	mov    0x8(%ebp),%eax
 5f9:	89 04 24             	mov    %eax,(%esp)
 5fc:	e8 aa fe ff ff       	call   4ab <printint>
        ap++;
 601:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 605:	e9 ec 00 00 00       	jmp    6f6 <printf+0x193>
      } else if(c == 'x' || c == 'p'){
 60a:	83 7d e4 78          	cmpl   $0x78,-0x1c(%ebp)
 60e:	74 06                	je     616 <printf+0xb3>
 610:	83 7d e4 70          	cmpl   $0x70,-0x1c(%ebp)
 614:	75 2d                	jne    643 <printf+0xe0>
        printint(fd, *ap, 16, 0);
 616:	8b 45 e8             	mov    -0x18(%ebp),%eax
 619:	8b 00                	mov    (%eax),%eax
 61b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
 622:	00 
 623:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
 62a:	00 
 62b:	89 44 24 04          	mov    %eax,0x4(%esp)
 62f:	8b 45 08             	mov    0x8(%ebp),%eax
 632:	89 04 24             	mov    %eax,(%esp)
 635:	e8 71 fe ff ff       	call   4ab <printint>
        ap++;
 63a:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 63e:	e9 b3 00 00 00       	jmp    6f6 <printf+0x193>
      } else if(c == 's'){
 643:	83 7d e4 73          	cmpl   $0x73,-0x1c(%ebp)
 647:	75 45                	jne    68e <printf+0x12b>
        s = (char*)*ap;
 649:	8b 45 e8             	mov    -0x18(%ebp),%eax
 64c:	8b 00                	mov    (%eax),%eax
 64e:	89 45 f4             	mov    %eax,-0xc(%ebp)
        ap++;
 651:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
        if(s == 0)
 655:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 659:	75 09                	jne    664 <printf+0x101>
          s = "(null)";
 65b:	c7 45 f4 f5 09 00 00 	movl   $0x9f5,-0xc(%ebp)
        while(*s != 0){
 662:	eb 1e                	jmp    682 <printf+0x11f>
 664:	eb 1c                	jmp    682 <printf+0x11f>
          putc(fd, *s);
 666:	8b 45 f4             	mov    -0xc(%ebp),%eax
 669:	0f b6 00             	movzbl (%eax),%eax
 66c:	0f be c0             	movsbl %al,%eax
 66f:	89 44 24 04          	mov    %eax,0x4(%esp)
 673:	8b 45 08             	mov    0x8(%ebp),%eax
 676:	89 04 24             	mov    %eax,(%esp)
 679:	e8 05 fe ff ff       	call   483 <putc>
          s++;
 67e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      } else if(c == 's'){
        s = (char*)*ap;
        ap++;
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 682:	8b 45 f4             	mov    -0xc(%ebp),%eax
 685:	0f b6 00             	movzbl (%eax),%eax
 688:	84 c0                	test   %al,%al
 68a:	75 da                	jne    666 <printf+0x103>
 68c:	eb 68                	jmp    6f6 <printf+0x193>
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 68e:	83 7d e4 63          	cmpl   $0x63,-0x1c(%ebp)
 692:	75 1d                	jne    6b1 <printf+0x14e>
        putc(fd, *ap);
 694:	8b 45 e8             	mov    -0x18(%ebp),%eax
 697:	8b 00                	mov    (%eax),%eax
 699:	0f be c0             	movsbl %al,%eax
 69c:	89 44 24 04          	mov    %eax,0x4(%esp)
 6a0:	8b 45 08             	mov    0x8(%ebp),%eax
 6a3:	89 04 24             	mov    %eax,(%esp)
 6a6:	e8 d8 fd ff ff       	call   483 <putc>
        ap++;
 6ab:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 6af:	eb 45                	jmp    6f6 <printf+0x193>
      } else if(c == '%'){
 6b1:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 6b5:	75 17                	jne    6ce <printf+0x16b>
        putc(fd, c);
 6b7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 6ba:	0f be c0             	movsbl %al,%eax
 6bd:	89 44 24 04          	mov    %eax,0x4(%esp)
 6c1:	8b 45 08             	mov    0x8(%ebp),%eax
 6c4:	89 04 24             	mov    %eax,(%esp)
 6c7:	e8 b7 fd ff ff       	call   483 <putc>
 6cc:	eb 28                	jmp    6f6 <printf+0x193>
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 6ce:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
 6d5:	00 
 6d6:	8b 45 08             	mov    0x8(%ebp),%eax
 6d9:	89 04 24             	mov    %eax,(%esp)
 6dc:	e8 a2 fd ff ff       	call   483 <putc>
        putc(fd, c);
 6e1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 6e4:	0f be c0             	movsbl %al,%eax
 6e7:	89 44 24 04          	mov    %eax,0x4(%esp)
 6eb:	8b 45 08             	mov    0x8(%ebp),%eax
 6ee:	89 04 24             	mov    %eax,(%esp)
 6f1:	e8 8d fd ff ff       	call   483 <putc>
      }
      state = 0;
 6f6:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
  for(i = 0; fmt[i]; i++){
 6fd:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
 701:	8b 55 0c             	mov    0xc(%ebp),%edx
 704:	8b 45 f0             	mov    -0x10(%ebp),%eax
 707:	01 d0                	add    %edx,%eax
 709:	0f b6 00             	movzbl (%eax),%eax
 70c:	84 c0                	test   %al,%al
 70e:	0f 85 71 fe ff ff    	jne    585 <printf+0x22>
        putc(fd, c);
      }
      state = 0;
    }
  }
}
 714:	c9                   	leave  
 715:	c3                   	ret    

00000716 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 716:	55                   	push   %ebp
 717:	89 e5                	mov    %esp,%ebp
 719:	83 ec 10             	sub    $0x10,%esp
  Header *bp, *p;

  bp = (Header*)ap - 1;
 71c:	8b 45 08             	mov    0x8(%ebp),%eax
 71f:	83 e8 08             	sub    $0x8,%eax
 722:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 725:	a1 5c 0c 00 00       	mov    0xc5c,%eax
 72a:	89 45 fc             	mov    %eax,-0x4(%ebp)
 72d:	eb 24                	jmp    753 <free+0x3d>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 72f:	8b 45 fc             	mov    -0x4(%ebp),%eax
 732:	8b 00                	mov    (%eax),%eax
 734:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 737:	77 12                	ja     74b <free+0x35>
 739:	8b 45 f8             	mov    -0x8(%ebp),%eax
 73c:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 73f:	77 24                	ja     765 <free+0x4f>
 741:	8b 45 fc             	mov    -0x4(%ebp),%eax
 744:	8b 00                	mov    (%eax),%eax
 746:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 749:	77 1a                	ja     765 <free+0x4f>
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 74b:	8b 45 fc             	mov    -0x4(%ebp),%eax
 74e:	8b 00                	mov    (%eax),%eax
 750:	89 45 fc             	mov    %eax,-0x4(%ebp)
 753:	8b 45 f8             	mov    -0x8(%ebp),%eax
 756:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 759:	76 d4                	jbe    72f <free+0x19>
 75b:	8b 45 fc             	mov    -0x4(%ebp),%eax
 75e:	8b 00                	mov    (%eax),%eax
 760:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 763:	76 ca                	jbe    72f <free+0x19>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
 765:	8b 45 f8             	mov    -0x8(%ebp),%eax
 768:	8b 40 04             	mov    0x4(%eax),%eax
 76b:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
 772:	8b 45 f8             	mov    -0x8(%ebp),%eax
 775:	01 c2                	add    %eax,%edx
 777:	8b 45 fc             	mov    -0x4(%ebp),%eax
 77a:	8b 00                	mov    (%eax),%eax
 77c:	39 c2                	cmp    %eax,%edx
 77e:	75 24                	jne    7a4 <free+0x8e>
    bp->s.size += p->s.ptr->s.size;
 780:	8b 45 f8             	mov    -0x8(%ebp),%eax
 783:	8b 50 04             	mov    0x4(%eax),%edx
 786:	8b 45 fc             	mov    -0x4(%ebp),%eax
 789:	8b 00                	mov    (%eax),%eax
 78b:	8b 40 04             	mov    0x4(%eax),%eax
 78e:	01 c2                	add    %eax,%edx
 790:	8b 45 f8             	mov    -0x8(%ebp),%eax
 793:	89 50 04             	mov    %edx,0x4(%eax)
    bp->s.ptr = p->s.ptr->s.ptr;
 796:	8b 45 fc             	mov    -0x4(%ebp),%eax
 799:	8b 00                	mov    (%eax),%eax
 79b:	8b 10                	mov    (%eax),%edx
 79d:	8b 45 f8             	mov    -0x8(%ebp),%eax
 7a0:	89 10                	mov    %edx,(%eax)
 7a2:	eb 0a                	jmp    7ae <free+0x98>
  } else
    bp->s.ptr = p->s.ptr;
 7a4:	8b 45 fc             	mov    -0x4(%ebp),%eax
 7a7:	8b 10                	mov    (%eax),%edx
 7a9:	8b 45 f8             	mov    -0x8(%ebp),%eax
 7ac:	89 10                	mov    %edx,(%eax)
  if(p + p->s.size == bp){
 7ae:	8b 45 fc             	mov    -0x4(%ebp),%eax
 7b1:	8b 40 04             	mov    0x4(%eax),%eax
 7b4:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
 7bb:	8b 45 fc             	mov    -0x4(%ebp),%eax
 7be:	01 d0                	add    %edx,%eax
 7c0:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 7c3:	75 20                	jne    7e5 <free+0xcf>
    p->s.size += bp->s.size;
 7c5:	8b 45 fc             	mov    -0x4(%ebp),%eax
 7c8:	8b 50 04             	mov    0x4(%eax),%edx
 7cb:	8b 45 f8             	mov    -0x8(%ebp),%eax
 7ce:	8b 40 04             	mov    0x4(%eax),%eax
 7d1:	01 c2                	add    %eax,%edx
 7d3:	8b 45 fc             	mov    -0x4(%ebp),%eax
 7d6:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 7d9:	8b 45 f8             	mov    -0x8(%ebp),%eax
 7dc:	8b 10                	mov    (%eax),%edx
 7de:	8b 45 fc             	mov    -0x4(%ebp),%eax
 7e1:	89 10                	mov    %edx,(%eax)
 7e3:	eb 08                	jmp    7ed <free+0xd7>
  } else
    p->s.ptr = bp;
 7e5:	8b 45 fc             	mov    -0x4(%ebp),%eax
 7e8:	8b 55 f8             	mov    -0x8(%ebp),%edx
 7eb:	89 10                	mov    %edx,(%eax)
  freep = p;
 7ed:	8b 45 fc             	mov    -0x4(%ebp),%eax
 7f0:	a3 5c 0c 00 00       	mov    %eax,0xc5c
}
 7f5:	c9                   	leave  
 7f6:	c3                   	ret    

000007f7 <morecore>:

static Header*
morecore(uint nu)
{
 7f7:	55                   	push   %ebp
 7f8:	89 e5                	mov    %esp,%ebp
 7fa:	83 ec 28             	sub    $0x28,%esp
  char *p;
  Header *hp;

  if(nu < 4096)
 7fd:	81 7d 08 ff 0f 00 00 	cmpl   $0xfff,0x8(%ebp)
 804:	77 07                	ja     80d <morecore+0x16>
    nu = 4096;
 806:	c7 45 08 00 10 00 00 	movl   $0x1000,0x8(%ebp)
  p = sbrk(nu * sizeof(Header));
 80d:	8b 45 08             	mov    0x8(%ebp),%eax
 810:	c1 e0 03             	shl    $0x3,%eax
 813:	89 04 24             	mov    %eax,(%esp)
 816:	e8 50 fc ff ff       	call   46b <sbrk>
 81b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(p == (char*)-1)
 81e:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
 822:	75 07                	jne    82b <morecore+0x34>
    return 0;
 824:	b8 00 00 00 00       	mov    $0x0,%eax
 829:	eb 22                	jmp    84d <morecore+0x56>
  hp = (Header*)p;
 82b:	8b 45 f4             	mov    -0xc(%ebp),%eax
 82e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  hp->s.size = nu;
 831:	8b 45 f0             	mov    -0x10(%ebp),%eax
 834:	8b 55 08             	mov    0x8(%ebp),%edx
 837:	89 50 04             	mov    %edx,0x4(%eax)
  free((void*)(hp + 1));
 83a:	8b 45 f0             	mov    -0x10(%ebp),%eax
 83d:	83 c0 08             	add    $0x8,%eax
 840:	89 04 24             	mov    %eax,(%esp)
 843:	e8 ce fe ff ff       	call   716 <free>
  return freep;
 848:	a1 5c 0c 00 00       	mov    0xc5c,%eax
}
 84d:	c9                   	leave  
 84e:	c3                   	ret    

0000084f <malloc>:

void*
malloc(uint nbytes)
{
 84f:	55                   	push   %ebp
 850:	89 e5                	mov    %esp,%ebp
 852:	83 ec 28             	sub    $0x28,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 855:	8b 45 08             	mov    0x8(%ebp),%eax
 858:	83 c0 07             	add    $0x7,%eax
 85b:	c1 e8 03             	shr    $0x3,%eax
 85e:	83 c0 01             	add    $0x1,%eax
 861:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((prevp = freep) == 0){
 864:	a1 5c 0c 00 00       	mov    0xc5c,%eax
 869:	89 45 f0             	mov    %eax,-0x10(%ebp)
 86c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 870:	75 23                	jne    895 <malloc+0x46>
    base.s.ptr = freep = prevp = &base;
 872:	c7 45 f0 54 0c 00 00 	movl   $0xc54,-0x10(%ebp)
 879:	8b 45 f0             	mov    -0x10(%ebp),%eax
 87c:	a3 5c 0c 00 00       	mov    %eax,0xc5c
 881:	a1 5c 0c 00 00       	mov    0xc5c,%eax
 886:	a3 54 0c 00 00       	mov    %eax,0xc54
    base.s.size = 0;
 88b:	c7 05 58 0c 00 00 00 	movl   $0x0,0xc58
 892:	00 00 00 
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 895:	8b 45 f0             	mov    -0x10(%ebp),%eax
 898:	8b 00                	mov    (%eax),%eax
 89a:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(p->s.size >= nunits){
 89d:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8a0:	8b 40 04             	mov    0x4(%eax),%eax
 8a3:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 8a6:	72 4d                	jb     8f5 <malloc+0xa6>
      if(p->s.size == nunits)
 8a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8ab:	8b 40 04             	mov    0x4(%eax),%eax
 8ae:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 8b1:	75 0c                	jne    8bf <malloc+0x70>
        prevp->s.ptr = p->s.ptr;
 8b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8b6:	8b 10                	mov    (%eax),%edx
 8b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
 8bb:	89 10                	mov    %edx,(%eax)
 8bd:	eb 26                	jmp    8e5 <malloc+0x96>
      else {
        p->s.size -= nunits;
 8bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8c2:	8b 40 04             	mov    0x4(%eax),%eax
 8c5:	2b 45 ec             	sub    -0x14(%ebp),%eax
 8c8:	89 c2                	mov    %eax,%edx
 8ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8cd:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 8d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8d3:	8b 40 04             	mov    0x4(%eax),%eax
 8d6:	c1 e0 03             	shl    $0x3,%eax
 8d9:	01 45 f4             	add    %eax,-0xc(%ebp)
        p->s.size = nunits;
 8dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8df:	8b 55 ec             	mov    -0x14(%ebp),%edx
 8e2:	89 50 04             	mov    %edx,0x4(%eax)
      }
      freep = prevp;
 8e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
 8e8:	a3 5c 0c 00 00       	mov    %eax,0xc5c
      return (void*)(p + 1);
 8ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8f0:	83 c0 08             	add    $0x8,%eax
 8f3:	eb 38                	jmp    92d <malloc+0xde>
    }
    if(p == freep)
 8f5:	a1 5c 0c 00 00       	mov    0xc5c,%eax
 8fa:	39 45 f4             	cmp    %eax,-0xc(%ebp)
 8fd:	75 1b                	jne    91a <malloc+0xcb>
      if((p = morecore(nunits)) == 0)
 8ff:	8b 45 ec             	mov    -0x14(%ebp),%eax
 902:	89 04 24             	mov    %eax,(%esp)
 905:	e8 ed fe ff ff       	call   7f7 <morecore>
 90a:	89 45 f4             	mov    %eax,-0xc(%ebp)
 90d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 911:	75 07                	jne    91a <malloc+0xcb>
        return 0;
 913:	b8 00 00 00 00       	mov    $0x0,%eax
 918:	eb 13                	jmp    92d <malloc+0xde>
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 91a:	8b 45 f4             	mov    -0xc(%ebp),%eax
 91d:	89 45 f0             	mov    %eax,-0x10(%ebp)
 920:	8b 45 f4             	mov    -0xc(%ebp),%eax
 923:	8b 00                	mov    (%eax),%eax
 925:	89 45 f4             	mov    %eax,-0xc(%ebp)
      return (void*)(p + 1);
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
 928:	e9 70 ff ff ff       	jmp    89d <malloc+0x4e>
}
 92d:	c9                   	leave  
 92e:	c3                   	ret    
