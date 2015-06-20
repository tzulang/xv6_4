
_t:     file format elf32-i386


Disassembly of section .text:

00000000 <main>:
#include "types.h"
#include "user.h"
#include "fcntl.h"

int main(int argc, char **argv){
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	83 e4 f0             	and    $0xfffffff0,%esp
   6:	83 ec 10             	sub    $0x10,%esp


	printf(1,"\n Endless loop\n\n");
   9:	c7 44 24 04 d3 07 00 	movl   $0x7d3,0x4(%esp)
  10:	00 
  11:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  18:	e8 ea 03 00 00       	call   407 <printf>
	for(;;);
  1d:	eb fe                	jmp    1d <main+0x1d>

0000001f <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
  1f:	55                   	push   %ebp
  20:	89 e5                	mov    %esp,%ebp
  22:	57                   	push   %edi
  23:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
  24:	8b 4d 08             	mov    0x8(%ebp),%ecx
  27:	8b 55 10             	mov    0x10(%ebp),%edx
  2a:	8b 45 0c             	mov    0xc(%ebp),%eax
  2d:	89 cb                	mov    %ecx,%ebx
  2f:	89 df                	mov    %ebx,%edi
  31:	89 d1                	mov    %edx,%ecx
  33:	fc                   	cld    
  34:	f3 aa                	rep stos %al,%es:(%edi)
  36:	89 ca                	mov    %ecx,%edx
  38:	89 fb                	mov    %edi,%ebx
  3a:	89 5d 08             	mov    %ebx,0x8(%ebp)
  3d:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
  40:	5b                   	pop    %ebx
  41:	5f                   	pop    %edi
  42:	5d                   	pop    %ebp
  43:	c3                   	ret    

00000044 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
  44:	55                   	push   %ebp
  45:	89 e5                	mov    %esp,%ebp
  47:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
  4a:	8b 45 08             	mov    0x8(%ebp),%eax
  4d:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while((*s++ = *t++) != 0)
  50:	90                   	nop
  51:	8b 45 08             	mov    0x8(%ebp),%eax
  54:	8d 50 01             	lea    0x1(%eax),%edx
  57:	89 55 08             	mov    %edx,0x8(%ebp)
  5a:	8b 55 0c             	mov    0xc(%ebp),%edx
  5d:	8d 4a 01             	lea    0x1(%edx),%ecx
  60:	89 4d 0c             	mov    %ecx,0xc(%ebp)
  63:	0f b6 12             	movzbl (%edx),%edx
  66:	88 10                	mov    %dl,(%eax)
  68:	0f b6 00             	movzbl (%eax),%eax
  6b:	84 c0                	test   %al,%al
  6d:	75 e2                	jne    51 <strcpy+0xd>
    ;
  return os;
  6f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  72:	c9                   	leave  
  73:	c3                   	ret    

00000074 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  74:	55                   	push   %ebp
  75:	89 e5                	mov    %esp,%ebp
  while(*p && *p == *q)
  77:	eb 08                	jmp    81 <strcmp+0xd>
    p++, q++;
  79:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  7d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
  while(*p && *p == *q)
  81:	8b 45 08             	mov    0x8(%ebp),%eax
  84:	0f b6 00             	movzbl (%eax),%eax
  87:	84 c0                	test   %al,%al
  89:	74 10                	je     9b <strcmp+0x27>
  8b:	8b 45 08             	mov    0x8(%ebp),%eax
  8e:	0f b6 10             	movzbl (%eax),%edx
  91:	8b 45 0c             	mov    0xc(%ebp),%eax
  94:	0f b6 00             	movzbl (%eax),%eax
  97:	38 c2                	cmp    %al,%dl
  99:	74 de                	je     79 <strcmp+0x5>
    p++, q++;
  return (uchar)*p - (uchar)*q;
  9b:	8b 45 08             	mov    0x8(%ebp),%eax
  9e:	0f b6 00             	movzbl (%eax),%eax
  a1:	0f b6 d0             	movzbl %al,%edx
  a4:	8b 45 0c             	mov    0xc(%ebp),%eax
  a7:	0f b6 00             	movzbl (%eax),%eax
  aa:	0f b6 c0             	movzbl %al,%eax
  ad:	29 c2                	sub    %eax,%edx
  af:	89 d0                	mov    %edx,%eax
}
  b1:	5d                   	pop    %ebp
  b2:	c3                   	ret    

000000b3 <strlen>:

uint
strlen(char *s)
{
  b3:	55                   	push   %ebp
  b4:	89 e5                	mov    %esp,%ebp
  b6:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
  b9:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  c0:	eb 04                	jmp    c6 <strlen+0x13>
  c2:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  c6:	8b 55 fc             	mov    -0x4(%ebp),%edx
  c9:	8b 45 08             	mov    0x8(%ebp),%eax
  cc:	01 d0                	add    %edx,%eax
  ce:	0f b6 00             	movzbl (%eax),%eax
  d1:	84 c0                	test   %al,%al
  d3:	75 ed                	jne    c2 <strlen+0xf>
    ;
  return n;
  d5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  d8:	c9                   	leave  
  d9:	c3                   	ret    

000000da <memset>:

void*
memset(void *dst, int c, uint n)
{
  da:	55                   	push   %ebp
  db:	89 e5                	mov    %esp,%ebp
  dd:	83 ec 0c             	sub    $0xc,%esp
  stosb(dst, c, n);
  e0:	8b 45 10             	mov    0x10(%ebp),%eax
  e3:	89 44 24 08          	mov    %eax,0x8(%esp)
  e7:	8b 45 0c             	mov    0xc(%ebp),%eax
  ea:	89 44 24 04          	mov    %eax,0x4(%esp)
  ee:	8b 45 08             	mov    0x8(%ebp),%eax
  f1:	89 04 24             	mov    %eax,(%esp)
  f4:	e8 26 ff ff ff       	call   1f <stosb>
  return dst;
  f9:	8b 45 08             	mov    0x8(%ebp),%eax
}
  fc:	c9                   	leave  
  fd:	c3                   	ret    

000000fe <strchr>:

char*
strchr(const char *s, char c)
{
  fe:	55                   	push   %ebp
  ff:	89 e5                	mov    %esp,%ebp
 101:	83 ec 04             	sub    $0x4,%esp
 104:	8b 45 0c             	mov    0xc(%ebp),%eax
 107:	88 45 fc             	mov    %al,-0x4(%ebp)
  for(; *s; s++)
 10a:	eb 14                	jmp    120 <strchr+0x22>
    if(*s == c)
 10c:	8b 45 08             	mov    0x8(%ebp),%eax
 10f:	0f b6 00             	movzbl (%eax),%eax
 112:	3a 45 fc             	cmp    -0x4(%ebp),%al
 115:	75 05                	jne    11c <strchr+0x1e>
      return (char*)s;
 117:	8b 45 08             	mov    0x8(%ebp),%eax
 11a:	eb 13                	jmp    12f <strchr+0x31>
}

char*
strchr(const char *s, char c)
{
  for(; *s; s++)
 11c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 120:	8b 45 08             	mov    0x8(%ebp),%eax
 123:	0f b6 00             	movzbl (%eax),%eax
 126:	84 c0                	test   %al,%al
 128:	75 e2                	jne    10c <strchr+0xe>
    if(*s == c)
      return (char*)s;
  return 0;
 12a:	b8 00 00 00 00       	mov    $0x0,%eax
}
 12f:	c9                   	leave  
 130:	c3                   	ret    

00000131 <gets>:

char*
gets(char *buf, int max)
{
 131:	55                   	push   %ebp
 132:	89 e5                	mov    %esp,%ebp
 134:	83 ec 28             	sub    $0x28,%esp
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 137:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 13e:	eb 4c                	jmp    18c <gets+0x5b>
    cc = read(0, &c, 1);
 140:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 147:	00 
 148:	8d 45 ef             	lea    -0x11(%ebp),%eax
 14b:	89 44 24 04          	mov    %eax,0x4(%esp)
 14f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
 156:	e8 44 01 00 00       	call   29f <read>
 15b:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(cc < 1)
 15e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 162:	7f 02                	jg     166 <gets+0x35>
      break;
 164:	eb 31                	jmp    197 <gets+0x66>
    buf[i++] = c;
 166:	8b 45 f4             	mov    -0xc(%ebp),%eax
 169:	8d 50 01             	lea    0x1(%eax),%edx
 16c:	89 55 f4             	mov    %edx,-0xc(%ebp)
 16f:	89 c2                	mov    %eax,%edx
 171:	8b 45 08             	mov    0x8(%ebp),%eax
 174:	01 c2                	add    %eax,%edx
 176:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 17a:	88 02                	mov    %al,(%edx)
    if(c == '\n' || c == '\r')
 17c:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 180:	3c 0a                	cmp    $0xa,%al
 182:	74 13                	je     197 <gets+0x66>
 184:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 188:	3c 0d                	cmp    $0xd,%al
 18a:	74 0b                	je     197 <gets+0x66>
gets(char *buf, int max)
{
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 18c:	8b 45 f4             	mov    -0xc(%ebp),%eax
 18f:	83 c0 01             	add    $0x1,%eax
 192:	3b 45 0c             	cmp    0xc(%ebp),%eax
 195:	7c a9                	jl     140 <gets+0xf>
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
      break;
  }
  buf[i] = '\0';
 197:	8b 55 f4             	mov    -0xc(%ebp),%edx
 19a:	8b 45 08             	mov    0x8(%ebp),%eax
 19d:	01 d0                	add    %edx,%eax
 19f:	c6 00 00             	movb   $0x0,(%eax)
  return buf;
 1a2:	8b 45 08             	mov    0x8(%ebp),%eax
}
 1a5:	c9                   	leave  
 1a6:	c3                   	ret    

000001a7 <stat>:

int
stat(char *n, struct stat *st)
{
 1a7:	55                   	push   %ebp
 1a8:	89 e5                	mov    %esp,%ebp
 1aa:	83 ec 28             	sub    $0x28,%esp
  int fd;
  int r;
  
  
  fd = open(n, O_RDONLY);
 1ad:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 1b4:	00 
 1b5:	8b 45 08             	mov    0x8(%ebp),%eax
 1b8:	89 04 24             	mov    %eax,(%esp)
 1bb:	e8 07 01 00 00       	call   2c7 <open>
 1c0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0)
 1c3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 1c7:	79 07                	jns    1d0 <stat+0x29>
    return -1;
 1c9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
 1ce:	eb 23                	jmp    1f3 <stat+0x4c>
  r = fstat(fd, st);
 1d0:	8b 45 0c             	mov    0xc(%ebp),%eax
 1d3:	89 44 24 04          	mov    %eax,0x4(%esp)
 1d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
 1da:	89 04 24             	mov    %eax,(%esp)
 1dd:	e8 fd 00 00 00       	call   2df <fstat>
 1e2:	89 45 f0             	mov    %eax,-0x10(%ebp)
  close(fd);
 1e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
 1e8:	89 04 24             	mov    %eax,(%esp)
 1eb:	e8 bf 00 00 00       	call   2af <close>
  return r;
 1f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
 1f3:	c9                   	leave  
 1f4:	c3                   	ret    

000001f5 <atoi>:

int
atoi(const char *s)
{
 1f5:	55                   	push   %ebp
 1f6:	89 e5                	mov    %esp,%ebp
 1f8:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
 1fb:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
 202:	eb 25                	jmp    229 <atoi+0x34>
    n = n*10 + *s++ - '0';
 204:	8b 55 fc             	mov    -0x4(%ebp),%edx
 207:	89 d0                	mov    %edx,%eax
 209:	c1 e0 02             	shl    $0x2,%eax
 20c:	01 d0                	add    %edx,%eax
 20e:	01 c0                	add    %eax,%eax
 210:	89 c1                	mov    %eax,%ecx
 212:	8b 45 08             	mov    0x8(%ebp),%eax
 215:	8d 50 01             	lea    0x1(%eax),%edx
 218:	89 55 08             	mov    %edx,0x8(%ebp)
 21b:	0f b6 00             	movzbl (%eax),%eax
 21e:	0f be c0             	movsbl %al,%eax
 221:	01 c8                	add    %ecx,%eax
 223:	83 e8 30             	sub    $0x30,%eax
 226:	89 45 fc             	mov    %eax,-0x4(%ebp)
atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 229:	8b 45 08             	mov    0x8(%ebp),%eax
 22c:	0f b6 00             	movzbl (%eax),%eax
 22f:	3c 2f                	cmp    $0x2f,%al
 231:	7e 0a                	jle    23d <atoi+0x48>
 233:	8b 45 08             	mov    0x8(%ebp),%eax
 236:	0f b6 00             	movzbl (%eax),%eax
 239:	3c 39                	cmp    $0x39,%al
 23b:	7e c7                	jle    204 <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
 23d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 240:	c9                   	leave  
 241:	c3                   	ret    

00000242 <memmove>:

void*
memmove(void *vdst, void *vsrc, int n)
{
 242:	55                   	push   %ebp
 243:	89 e5                	mov    %esp,%ebp
 245:	83 ec 10             	sub    $0x10,%esp
  char *dst, *src;
  
  dst = vdst;
 248:	8b 45 08             	mov    0x8(%ebp),%eax
 24b:	89 45 fc             	mov    %eax,-0x4(%ebp)
  src = vsrc;
 24e:	8b 45 0c             	mov    0xc(%ebp),%eax
 251:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0)
 254:	eb 17                	jmp    26d <memmove+0x2b>
    *dst++ = *src++;
 256:	8b 45 fc             	mov    -0x4(%ebp),%eax
 259:	8d 50 01             	lea    0x1(%eax),%edx
 25c:	89 55 fc             	mov    %edx,-0x4(%ebp)
 25f:	8b 55 f8             	mov    -0x8(%ebp),%edx
 262:	8d 4a 01             	lea    0x1(%edx),%ecx
 265:	89 4d f8             	mov    %ecx,-0x8(%ebp)
 268:	0f b6 12             	movzbl (%edx),%edx
 26b:	88 10                	mov    %dl,(%eax)
{
  char *dst, *src;
  
  dst = vdst;
  src = vsrc;
  while(n-- > 0)
 26d:	8b 45 10             	mov    0x10(%ebp),%eax
 270:	8d 50 ff             	lea    -0x1(%eax),%edx
 273:	89 55 10             	mov    %edx,0x10(%ebp)
 276:	85 c0                	test   %eax,%eax
 278:	7f dc                	jg     256 <memmove+0x14>
    *dst++ = *src++;
  return vdst;
 27a:	8b 45 08             	mov    0x8(%ebp),%eax
}
 27d:	c9                   	leave  
 27e:	c3                   	ret    

0000027f <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 27f:	b8 01 00 00 00       	mov    $0x1,%eax
 284:	cd 40                	int    $0x40
 286:	c3                   	ret    

00000287 <exit>:
SYSCALL(exit)
 287:	b8 02 00 00 00       	mov    $0x2,%eax
 28c:	cd 40                	int    $0x40
 28e:	c3                   	ret    

0000028f <wait>:
SYSCALL(wait)
 28f:	b8 03 00 00 00       	mov    $0x3,%eax
 294:	cd 40                	int    $0x40
 296:	c3                   	ret    

00000297 <pipe>:
SYSCALL(pipe)
 297:	b8 04 00 00 00       	mov    $0x4,%eax
 29c:	cd 40                	int    $0x40
 29e:	c3                   	ret    

0000029f <read>:
SYSCALL(read)
 29f:	b8 05 00 00 00       	mov    $0x5,%eax
 2a4:	cd 40                	int    $0x40
 2a6:	c3                   	ret    

000002a7 <write>:
SYSCALL(write)
 2a7:	b8 10 00 00 00       	mov    $0x10,%eax
 2ac:	cd 40                	int    $0x40
 2ae:	c3                   	ret    

000002af <close>:
SYSCALL(close)
 2af:	b8 15 00 00 00       	mov    $0x15,%eax
 2b4:	cd 40                	int    $0x40
 2b6:	c3                   	ret    

000002b7 <kill>:
SYSCALL(kill)
 2b7:	b8 06 00 00 00       	mov    $0x6,%eax
 2bc:	cd 40                	int    $0x40
 2be:	c3                   	ret    

000002bf <exec>:
SYSCALL(exec)
 2bf:	b8 07 00 00 00       	mov    $0x7,%eax
 2c4:	cd 40                	int    $0x40
 2c6:	c3                   	ret    

000002c7 <open>:
SYSCALL(open)
 2c7:	b8 0f 00 00 00       	mov    $0xf,%eax
 2cc:	cd 40                	int    $0x40
 2ce:	c3                   	ret    

000002cf <mknod>:
SYSCALL(mknod)
 2cf:	b8 11 00 00 00       	mov    $0x11,%eax
 2d4:	cd 40                	int    $0x40
 2d6:	c3                   	ret    

000002d7 <unlink>:
SYSCALL(unlink)
 2d7:	b8 12 00 00 00       	mov    $0x12,%eax
 2dc:	cd 40                	int    $0x40
 2de:	c3                   	ret    

000002df <fstat>:
SYSCALL(fstat)
 2df:	b8 08 00 00 00       	mov    $0x8,%eax
 2e4:	cd 40                	int    $0x40
 2e6:	c3                   	ret    

000002e7 <link>:
SYSCALL(link)
 2e7:	b8 13 00 00 00       	mov    $0x13,%eax
 2ec:	cd 40                	int    $0x40
 2ee:	c3                   	ret    

000002ef <mkdir>:
SYSCALL(mkdir)
 2ef:	b8 14 00 00 00       	mov    $0x14,%eax
 2f4:	cd 40                	int    $0x40
 2f6:	c3                   	ret    

000002f7 <chdir>:
SYSCALL(chdir)
 2f7:	b8 09 00 00 00       	mov    $0x9,%eax
 2fc:	cd 40                	int    $0x40
 2fe:	c3                   	ret    

000002ff <dup>:
SYSCALL(dup)
 2ff:	b8 0a 00 00 00       	mov    $0xa,%eax
 304:	cd 40                	int    $0x40
 306:	c3                   	ret    

00000307 <getpid>:
SYSCALL(getpid)
 307:	b8 0b 00 00 00       	mov    $0xb,%eax
 30c:	cd 40                	int    $0x40
 30e:	c3                   	ret    

0000030f <sbrk>:
SYSCALL(sbrk)
 30f:	b8 0c 00 00 00       	mov    $0xc,%eax
 314:	cd 40                	int    $0x40
 316:	c3                   	ret    

00000317 <sleep>:
SYSCALL(sleep)
 317:	b8 0d 00 00 00       	mov    $0xd,%eax
 31c:	cd 40                	int    $0x40
 31e:	c3                   	ret    

0000031f <uptime>:
SYSCALL(uptime)
 31f:	b8 0e 00 00 00       	mov    $0xe,%eax
 324:	cd 40                	int    $0x40
 326:	c3                   	ret    

00000327 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 327:	55                   	push   %ebp
 328:	89 e5                	mov    %esp,%ebp
 32a:	83 ec 18             	sub    $0x18,%esp
 32d:	8b 45 0c             	mov    0xc(%ebp),%eax
 330:	88 45 f4             	mov    %al,-0xc(%ebp)
  write(fd, &c, 1);
 333:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 33a:	00 
 33b:	8d 45 f4             	lea    -0xc(%ebp),%eax
 33e:	89 44 24 04          	mov    %eax,0x4(%esp)
 342:	8b 45 08             	mov    0x8(%ebp),%eax
 345:	89 04 24             	mov    %eax,(%esp)
 348:	e8 5a ff ff ff       	call   2a7 <write>
}
 34d:	c9                   	leave  
 34e:	c3                   	ret    

0000034f <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 34f:	55                   	push   %ebp
 350:	89 e5                	mov    %esp,%ebp
 352:	56                   	push   %esi
 353:	53                   	push   %ebx
 354:	83 ec 30             	sub    $0x30,%esp
  static char digits[] = "0123456789ABCDEF";
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
 357:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  if(sgn && xx < 0){
 35e:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
 362:	74 17                	je     37b <printint+0x2c>
 364:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
 368:	79 11                	jns    37b <printint+0x2c>
    neg = 1;
 36a:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
    x = -xx;
 371:	8b 45 0c             	mov    0xc(%ebp),%eax
 374:	f7 d8                	neg    %eax
 376:	89 45 ec             	mov    %eax,-0x14(%ebp)
 379:	eb 06                	jmp    381 <printint+0x32>
  } else {
    x = xx;
 37b:	8b 45 0c             	mov    0xc(%ebp),%eax
 37e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  }

  i = 0;
 381:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
 388:	8b 4d f4             	mov    -0xc(%ebp),%ecx
 38b:	8d 41 01             	lea    0x1(%ecx),%eax
 38e:	89 45 f4             	mov    %eax,-0xc(%ebp)
 391:	8b 5d 10             	mov    0x10(%ebp),%ebx
 394:	8b 45 ec             	mov    -0x14(%ebp),%eax
 397:	ba 00 00 00 00       	mov    $0x0,%edx
 39c:	f7 f3                	div    %ebx
 39e:	89 d0                	mov    %edx,%eax
 3a0:	0f b6 80 30 0a 00 00 	movzbl 0xa30(%eax),%eax
 3a7:	88 44 0d dc          	mov    %al,-0x24(%ebp,%ecx,1)
  }while((x /= base) != 0);
 3ab:	8b 75 10             	mov    0x10(%ebp),%esi
 3ae:	8b 45 ec             	mov    -0x14(%ebp),%eax
 3b1:	ba 00 00 00 00       	mov    $0x0,%edx
 3b6:	f7 f6                	div    %esi
 3b8:	89 45 ec             	mov    %eax,-0x14(%ebp)
 3bb:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 3bf:	75 c7                	jne    388 <printint+0x39>
  if(neg)
 3c1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 3c5:	74 10                	je     3d7 <printint+0x88>
    buf[i++] = '-';
 3c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
 3ca:	8d 50 01             	lea    0x1(%eax),%edx
 3cd:	89 55 f4             	mov    %edx,-0xc(%ebp)
 3d0:	c6 44 05 dc 2d       	movb   $0x2d,-0x24(%ebp,%eax,1)

  while(--i >= 0)
 3d5:	eb 1f                	jmp    3f6 <printint+0xa7>
 3d7:	eb 1d                	jmp    3f6 <printint+0xa7>
    putc(fd, buf[i]);
 3d9:	8d 55 dc             	lea    -0x24(%ebp),%edx
 3dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
 3df:	01 d0                	add    %edx,%eax
 3e1:	0f b6 00             	movzbl (%eax),%eax
 3e4:	0f be c0             	movsbl %al,%eax
 3e7:	89 44 24 04          	mov    %eax,0x4(%esp)
 3eb:	8b 45 08             	mov    0x8(%ebp),%eax
 3ee:	89 04 24             	mov    %eax,(%esp)
 3f1:	e8 31 ff ff ff       	call   327 <putc>
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
 3f6:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
 3fa:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 3fe:	79 d9                	jns    3d9 <printint+0x8a>
    putc(fd, buf[i]);
}
 400:	83 c4 30             	add    $0x30,%esp
 403:	5b                   	pop    %ebx
 404:	5e                   	pop    %esi
 405:	5d                   	pop    %ebp
 406:	c3                   	ret    

00000407 <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
 407:	55                   	push   %ebp
 408:	89 e5                	mov    %esp,%ebp
 40a:	83 ec 38             	sub    $0x38,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
 40d:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  ap = (uint*)(void*)&fmt + 1;
 414:	8d 45 0c             	lea    0xc(%ebp),%eax
 417:	83 c0 04             	add    $0x4,%eax
 41a:	89 45 e8             	mov    %eax,-0x18(%ebp)
  for(i = 0; fmt[i]; i++){
 41d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
 424:	e9 7c 01 00 00       	jmp    5a5 <printf+0x19e>
    c = fmt[i] & 0xff;
 429:	8b 55 0c             	mov    0xc(%ebp),%edx
 42c:	8b 45 f0             	mov    -0x10(%ebp),%eax
 42f:	01 d0                	add    %edx,%eax
 431:	0f b6 00             	movzbl (%eax),%eax
 434:	0f be c0             	movsbl %al,%eax
 437:	25 ff 00 00 00       	and    $0xff,%eax
 43c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(state == 0){
 43f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 443:	75 2c                	jne    471 <printf+0x6a>
      if(c == '%'){
 445:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 449:	75 0c                	jne    457 <printf+0x50>
        state = '%';
 44b:	c7 45 ec 25 00 00 00 	movl   $0x25,-0x14(%ebp)
 452:	e9 4a 01 00 00       	jmp    5a1 <printf+0x19a>
      } else {
        putc(fd, c);
 457:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 45a:	0f be c0             	movsbl %al,%eax
 45d:	89 44 24 04          	mov    %eax,0x4(%esp)
 461:	8b 45 08             	mov    0x8(%ebp),%eax
 464:	89 04 24             	mov    %eax,(%esp)
 467:	e8 bb fe ff ff       	call   327 <putc>
 46c:	e9 30 01 00 00       	jmp    5a1 <printf+0x19a>
      }
    } else if(state == '%'){
 471:	83 7d ec 25          	cmpl   $0x25,-0x14(%ebp)
 475:	0f 85 26 01 00 00    	jne    5a1 <printf+0x19a>
      if(c == 'd'){
 47b:	83 7d e4 64          	cmpl   $0x64,-0x1c(%ebp)
 47f:	75 2d                	jne    4ae <printf+0xa7>
        printint(fd, *ap, 10, 1);
 481:	8b 45 e8             	mov    -0x18(%ebp),%eax
 484:	8b 00                	mov    (%eax),%eax
 486:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
 48d:	00 
 48e:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
 495:	00 
 496:	89 44 24 04          	mov    %eax,0x4(%esp)
 49a:	8b 45 08             	mov    0x8(%ebp),%eax
 49d:	89 04 24             	mov    %eax,(%esp)
 4a0:	e8 aa fe ff ff       	call   34f <printint>
        ap++;
 4a5:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 4a9:	e9 ec 00 00 00       	jmp    59a <printf+0x193>
      } else if(c == 'x' || c == 'p'){
 4ae:	83 7d e4 78          	cmpl   $0x78,-0x1c(%ebp)
 4b2:	74 06                	je     4ba <printf+0xb3>
 4b4:	83 7d e4 70          	cmpl   $0x70,-0x1c(%ebp)
 4b8:	75 2d                	jne    4e7 <printf+0xe0>
        printint(fd, *ap, 16, 0);
 4ba:	8b 45 e8             	mov    -0x18(%ebp),%eax
 4bd:	8b 00                	mov    (%eax),%eax
 4bf:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
 4c6:	00 
 4c7:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
 4ce:	00 
 4cf:	89 44 24 04          	mov    %eax,0x4(%esp)
 4d3:	8b 45 08             	mov    0x8(%ebp),%eax
 4d6:	89 04 24             	mov    %eax,(%esp)
 4d9:	e8 71 fe ff ff       	call   34f <printint>
        ap++;
 4de:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 4e2:	e9 b3 00 00 00       	jmp    59a <printf+0x193>
      } else if(c == 's'){
 4e7:	83 7d e4 73          	cmpl   $0x73,-0x1c(%ebp)
 4eb:	75 45                	jne    532 <printf+0x12b>
        s = (char*)*ap;
 4ed:	8b 45 e8             	mov    -0x18(%ebp),%eax
 4f0:	8b 00                	mov    (%eax),%eax
 4f2:	89 45 f4             	mov    %eax,-0xc(%ebp)
        ap++;
 4f5:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
        if(s == 0)
 4f9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 4fd:	75 09                	jne    508 <printf+0x101>
          s = "(null)";
 4ff:	c7 45 f4 e4 07 00 00 	movl   $0x7e4,-0xc(%ebp)
        while(*s != 0){
 506:	eb 1e                	jmp    526 <printf+0x11f>
 508:	eb 1c                	jmp    526 <printf+0x11f>
          putc(fd, *s);
 50a:	8b 45 f4             	mov    -0xc(%ebp),%eax
 50d:	0f b6 00             	movzbl (%eax),%eax
 510:	0f be c0             	movsbl %al,%eax
 513:	89 44 24 04          	mov    %eax,0x4(%esp)
 517:	8b 45 08             	mov    0x8(%ebp),%eax
 51a:	89 04 24             	mov    %eax,(%esp)
 51d:	e8 05 fe ff ff       	call   327 <putc>
          s++;
 522:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      } else if(c == 's'){
        s = (char*)*ap;
        ap++;
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 526:	8b 45 f4             	mov    -0xc(%ebp),%eax
 529:	0f b6 00             	movzbl (%eax),%eax
 52c:	84 c0                	test   %al,%al
 52e:	75 da                	jne    50a <printf+0x103>
 530:	eb 68                	jmp    59a <printf+0x193>
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 532:	83 7d e4 63          	cmpl   $0x63,-0x1c(%ebp)
 536:	75 1d                	jne    555 <printf+0x14e>
        putc(fd, *ap);
 538:	8b 45 e8             	mov    -0x18(%ebp),%eax
 53b:	8b 00                	mov    (%eax),%eax
 53d:	0f be c0             	movsbl %al,%eax
 540:	89 44 24 04          	mov    %eax,0x4(%esp)
 544:	8b 45 08             	mov    0x8(%ebp),%eax
 547:	89 04 24             	mov    %eax,(%esp)
 54a:	e8 d8 fd ff ff       	call   327 <putc>
        ap++;
 54f:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 553:	eb 45                	jmp    59a <printf+0x193>
      } else if(c == '%'){
 555:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 559:	75 17                	jne    572 <printf+0x16b>
        putc(fd, c);
 55b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 55e:	0f be c0             	movsbl %al,%eax
 561:	89 44 24 04          	mov    %eax,0x4(%esp)
 565:	8b 45 08             	mov    0x8(%ebp),%eax
 568:	89 04 24             	mov    %eax,(%esp)
 56b:	e8 b7 fd ff ff       	call   327 <putc>
 570:	eb 28                	jmp    59a <printf+0x193>
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 572:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
 579:	00 
 57a:	8b 45 08             	mov    0x8(%ebp),%eax
 57d:	89 04 24             	mov    %eax,(%esp)
 580:	e8 a2 fd ff ff       	call   327 <putc>
        putc(fd, c);
 585:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 588:	0f be c0             	movsbl %al,%eax
 58b:	89 44 24 04          	mov    %eax,0x4(%esp)
 58f:	8b 45 08             	mov    0x8(%ebp),%eax
 592:	89 04 24             	mov    %eax,(%esp)
 595:	e8 8d fd ff ff       	call   327 <putc>
      }
      state = 0;
 59a:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
  for(i = 0; fmt[i]; i++){
 5a1:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
 5a5:	8b 55 0c             	mov    0xc(%ebp),%edx
 5a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
 5ab:	01 d0                	add    %edx,%eax
 5ad:	0f b6 00             	movzbl (%eax),%eax
 5b0:	84 c0                	test   %al,%al
 5b2:	0f 85 71 fe ff ff    	jne    429 <printf+0x22>
        putc(fd, c);
      }
      state = 0;
    }
  }
}
 5b8:	c9                   	leave  
 5b9:	c3                   	ret    

000005ba <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 5ba:	55                   	push   %ebp
 5bb:	89 e5                	mov    %esp,%ebp
 5bd:	83 ec 10             	sub    $0x10,%esp
  Header *bp, *p;

  bp = (Header*)ap - 1;
 5c0:	8b 45 08             	mov    0x8(%ebp),%eax
 5c3:	83 e8 08             	sub    $0x8,%eax
 5c6:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 5c9:	a1 4c 0a 00 00       	mov    0xa4c,%eax
 5ce:	89 45 fc             	mov    %eax,-0x4(%ebp)
 5d1:	eb 24                	jmp    5f7 <free+0x3d>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 5d3:	8b 45 fc             	mov    -0x4(%ebp),%eax
 5d6:	8b 00                	mov    (%eax),%eax
 5d8:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 5db:	77 12                	ja     5ef <free+0x35>
 5dd:	8b 45 f8             	mov    -0x8(%ebp),%eax
 5e0:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 5e3:	77 24                	ja     609 <free+0x4f>
 5e5:	8b 45 fc             	mov    -0x4(%ebp),%eax
 5e8:	8b 00                	mov    (%eax),%eax
 5ea:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 5ed:	77 1a                	ja     609 <free+0x4f>
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 5ef:	8b 45 fc             	mov    -0x4(%ebp),%eax
 5f2:	8b 00                	mov    (%eax),%eax
 5f4:	89 45 fc             	mov    %eax,-0x4(%ebp)
 5f7:	8b 45 f8             	mov    -0x8(%ebp),%eax
 5fa:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 5fd:	76 d4                	jbe    5d3 <free+0x19>
 5ff:	8b 45 fc             	mov    -0x4(%ebp),%eax
 602:	8b 00                	mov    (%eax),%eax
 604:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 607:	76 ca                	jbe    5d3 <free+0x19>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
 609:	8b 45 f8             	mov    -0x8(%ebp),%eax
 60c:	8b 40 04             	mov    0x4(%eax),%eax
 60f:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
 616:	8b 45 f8             	mov    -0x8(%ebp),%eax
 619:	01 c2                	add    %eax,%edx
 61b:	8b 45 fc             	mov    -0x4(%ebp),%eax
 61e:	8b 00                	mov    (%eax),%eax
 620:	39 c2                	cmp    %eax,%edx
 622:	75 24                	jne    648 <free+0x8e>
    bp->s.size += p->s.ptr->s.size;
 624:	8b 45 f8             	mov    -0x8(%ebp),%eax
 627:	8b 50 04             	mov    0x4(%eax),%edx
 62a:	8b 45 fc             	mov    -0x4(%ebp),%eax
 62d:	8b 00                	mov    (%eax),%eax
 62f:	8b 40 04             	mov    0x4(%eax),%eax
 632:	01 c2                	add    %eax,%edx
 634:	8b 45 f8             	mov    -0x8(%ebp),%eax
 637:	89 50 04             	mov    %edx,0x4(%eax)
    bp->s.ptr = p->s.ptr->s.ptr;
 63a:	8b 45 fc             	mov    -0x4(%ebp),%eax
 63d:	8b 00                	mov    (%eax),%eax
 63f:	8b 10                	mov    (%eax),%edx
 641:	8b 45 f8             	mov    -0x8(%ebp),%eax
 644:	89 10                	mov    %edx,(%eax)
 646:	eb 0a                	jmp    652 <free+0x98>
  } else
    bp->s.ptr = p->s.ptr;
 648:	8b 45 fc             	mov    -0x4(%ebp),%eax
 64b:	8b 10                	mov    (%eax),%edx
 64d:	8b 45 f8             	mov    -0x8(%ebp),%eax
 650:	89 10                	mov    %edx,(%eax)
  if(p + p->s.size == bp){
 652:	8b 45 fc             	mov    -0x4(%ebp),%eax
 655:	8b 40 04             	mov    0x4(%eax),%eax
 658:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
 65f:	8b 45 fc             	mov    -0x4(%ebp),%eax
 662:	01 d0                	add    %edx,%eax
 664:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 667:	75 20                	jne    689 <free+0xcf>
    p->s.size += bp->s.size;
 669:	8b 45 fc             	mov    -0x4(%ebp),%eax
 66c:	8b 50 04             	mov    0x4(%eax),%edx
 66f:	8b 45 f8             	mov    -0x8(%ebp),%eax
 672:	8b 40 04             	mov    0x4(%eax),%eax
 675:	01 c2                	add    %eax,%edx
 677:	8b 45 fc             	mov    -0x4(%ebp),%eax
 67a:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 67d:	8b 45 f8             	mov    -0x8(%ebp),%eax
 680:	8b 10                	mov    (%eax),%edx
 682:	8b 45 fc             	mov    -0x4(%ebp),%eax
 685:	89 10                	mov    %edx,(%eax)
 687:	eb 08                	jmp    691 <free+0xd7>
  } else
    p->s.ptr = bp;
 689:	8b 45 fc             	mov    -0x4(%ebp),%eax
 68c:	8b 55 f8             	mov    -0x8(%ebp),%edx
 68f:	89 10                	mov    %edx,(%eax)
  freep = p;
 691:	8b 45 fc             	mov    -0x4(%ebp),%eax
 694:	a3 4c 0a 00 00       	mov    %eax,0xa4c
}
 699:	c9                   	leave  
 69a:	c3                   	ret    

0000069b <morecore>:

static Header*
morecore(uint nu)
{
 69b:	55                   	push   %ebp
 69c:	89 e5                	mov    %esp,%ebp
 69e:	83 ec 28             	sub    $0x28,%esp
  char *p;
  Header *hp;

  if(nu < 4096)
 6a1:	81 7d 08 ff 0f 00 00 	cmpl   $0xfff,0x8(%ebp)
 6a8:	77 07                	ja     6b1 <morecore+0x16>
    nu = 4096;
 6aa:	c7 45 08 00 10 00 00 	movl   $0x1000,0x8(%ebp)
  p = sbrk(nu * sizeof(Header));
 6b1:	8b 45 08             	mov    0x8(%ebp),%eax
 6b4:	c1 e0 03             	shl    $0x3,%eax
 6b7:	89 04 24             	mov    %eax,(%esp)
 6ba:	e8 50 fc ff ff       	call   30f <sbrk>
 6bf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(p == (char*)-1)
 6c2:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
 6c6:	75 07                	jne    6cf <morecore+0x34>
    return 0;
 6c8:	b8 00 00 00 00       	mov    $0x0,%eax
 6cd:	eb 22                	jmp    6f1 <morecore+0x56>
  hp = (Header*)p;
 6cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
 6d2:	89 45 f0             	mov    %eax,-0x10(%ebp)
  hp->s.size = nu;
 6d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
 6d8:	8b 55 08             	mov    0x8(%ebp),%edx
 6db:	89 50 04             	mov    %edx,0x4(%eax)
  free((void*)(hp + 1));
 6de:	8b 45 f0             	mov    -0x10(%ebp),%eax
 6e1:	83 c0 08             	add    $0x8,%eax
 6e4:	89 04 24             	mov    %eax,(%esp)
 6e7:	e8 ce fe ff ff       	call   5ba <free>
  return freep;
 6ec:	a1 4c 0a 00 00       	mov    0xa4c,%eax
}
 6f1:	c9                   	leave  
 6f2:	c3                   	ret    

000006f3 <malloc>:

void*
malloc(uint nbytes)
{
 6f3:	55                   	push   %ebp
 6f4:	89 e5                	mov    %esp,%ebp
 6f6:	83 ec 28             	sub    $0x28,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 6f9:	8b 45 08             	mov    0x8(%ebp),%eax
 6fc:	83 c0 07             	add    $0x7,%eax
 6ff:	c1 e8 03             	shr    $0x3,%eax
 702:	83 c0 01             	add    $0x1,%eax
 705:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((prevp = freep) == 0){
 708:	a1 4c 0a 00 00       	mov    0xa4c,%eax
 70d:	89 45 f0             	mov    %eax,-0x10(%ebp)
 710:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 714:	75 23                	jne    739 <malloc+0x46>
    base.s.ptr = freep = prevp = &base;
 716:	c7 45 f0 44 0a 00 00 	movl   $0xa44,-0x10(%ebp)
 71d:	8b 45 f0             	mov    -0x10(%ebp),%eax
 720:	a3 4c 0a 00 00       	mov    %eax,0xa4c
 725:	a1 4c 0a 00 00       	mov    0xa4c,%eax
 72a:	a3 44 0a 00 00       	mov    %eax,0xa44
    base.s.size = 0;
 72f:	c7 05 48 0a 00 00 00 	movl   $0x0,0xa48
 736:	00 00 00 
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 739:	8b 45 f0             	mov    -0x10(%ebp),%eax
 73c:	8b 00                	mov    (%eax),%eax
 73e:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(p->s.size >= nunits){
 741:	8b 45 f4             	mov    -0xc(%ebp),%eax
 744:	8b 40 04             	mov    0x4(%eax),%eax
 747:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 74a:	72 4d                	jb     799 <malloc+0xa6>
      if(p->s.size == nunits)
 74c:	8b 45 f4             	mov    -0xc(%ebp),%eax
 74f:	8b 40 04             	mov    0x4(%eax),%eax
 752:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 755:	75 0c                	jne    763 <malloc+0x70>
        prevp->s.ptr = p->s.ptr;
 757:	8b 45 f4             	mov    -0xc(%ebp),%eax
 75a:	8b 10                	mov    (%eax),%edx
 75c:	8b 45 f0             	mov    -0x10(%ebp),%eax
 75f:	89 10                	mov    %edx,(%eax)
 761:	eb 26                	jmp    789 <malloc+0x96>
      else {
        p->s.size -= nunits;
 763:	8b 45 f4             	mov    -0xc(%ebp),%eax
 766:	8b 40 04             	mov    0x4(%eax),%eax
 769:	2b 45 ec             	sub    -0x14(%ebp),%eax
 76c:	89 c2                	mov    %eax,%edx
 76e:	8b 45 f4             	mov    -0xc(%ebp),%eax
 771:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 774:	8b 45 f4             	mov    -0xc(%ebp),%eax
 777:	8b 40 04             	mov    0x4(%eax),%eax
 77a:	c1 e0 03             	shl    $0x3,%eax
 77d:	01 45 f4             	add    %eax,-0xc(%ebp)
        p->s.size = nunits;
 780:	8b 45 f4             	mov    -0xc(%ebp),%eax
 783:	8b 55 ec             	mov    -0x14(%ebp),%edx
 786:	89 50 04             	mov    %edx,0x4(%eax)
      }
      freep = prevp;
 789:	8b 45 f0             	mov    -0x10(%ebp),%eax
 78c:	a3 4c 0a 00 00       	mov    %eax,0xa4c
      return (void*)(p + 1);
 791:	8b 45 f4             	mov    -0xc(%ebp),%eax
 794:	83 c0 08             	add    $0x8,%eax
 797:	eb 38                	jmp    7d1 <malloc+0xde>
    }
    if(p == freep)
 799:	a1 4c 0a 00 00       	mov    0xa4c,%eax
 79e:	39 45 f4             	cmp    %eax,-0xc(%ebp)
 7a1:	75 1b                	jne    7be <malloc+0xcb>
      if((p = morecore(nunits)) == 0)
 7a3:	8b 45 ec             	mov    -0x14(%ebp),%eax
 7a6:	89 04 24             	mov    %eax,(%esp)
 7a9:	e8 ed fe ff ff       	call   69b <morecore>
 7ae:	89 45 f4             	mov    %eax,-0xc(%ebp)
 7b1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 7b5:	75 07                	jne    7be <malloc+0xcb>
        return 0;
 7b7:	b8 00 00 00 00       	mov    $0x0,%eax
 7bc:	eb 13                	jmp    7d1 <malloc+0xde>
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7be:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7c1:	89 45 f0             	mov    %eax,-0x10(%ebp)
 7c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7c7:	8b 00                	mov    (%eax),%eax
 7c9:	89 45 f4             	mov    %eax,-0xc(%ebp)
      return (void*)(p + 1);
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
 7cc:	e9 70 ff ff ff       	jmp    741 <malloc+0x4e>
}
 7d1:	c9                   	leave  
 7d2:	c3                   	ret    
