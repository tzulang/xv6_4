
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4 0f                	in     $0xf,%al

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 a0 10 00       	mov    $0x10a000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc 50 c6 10 80       	mov    $0x8010c650,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 32 38 10 80       	mov    $0x80103832,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  initlock(&bcache.lock, "bcache");
8010003a:	c7 44 24 04 6c 87 10 	movl   $0x8010876c,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100049:	e8 cd 50 00 00       	call   8010511b <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 70 05 11 80 64 	movl   $0x80110564,0x80110570
80100055:	05 11 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 74 05 11 80 64 	movl   $0x80110564,0x80110574
8010005f:	05 11 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 94 c6 10 80 	movl   $0x8010c694,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 74 05 11 80    	mov    0x80110574,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c 64 05 11 80 	movl   $0x80110564,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 74 05 11 80       	mov    0x80110574,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 74 05 11 80       	mov    %eax,0x80110574

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 64 05 11 80 	cmpl   $0x80110564,-0xc(%ebp)
801000ac:	72 bd                	jb     8010006b <binit+0x37>
    b->prev = &bcache.head;
    b->dev = -1;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}
801000ae:	c9                   	leave  
801000af:	c3                   	ret    

801000b0 <bget>:
// Look through buffer cache for sector on device dev.
// If not found, allocate a buffer.
// In either case, return B_BUSY buffer.
static struct buf*
bget(uint dev, uint sector)
{
801000b0:	55                   	push   %ebp
801000b1:	89 e5                	mov    %esp,%ebp
801000b3:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  acquire(&bcache.lock);
801000b6:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801000bd:	e8 7a 50 00 00       	call   8010513c <acquire>

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 74 05 11 80       	mov    0x80110574,%eax
801000c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801000ca:	eb 63                	jmp    8010012f <bget+0x7f>
    if(b->dev == dev && b->sector == sector){
801000cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000cf:	8b 40 04             	mov    0x4(%eax),%eax
801000d2:	3b 45 08             	cmp    0x8(%ebp),%eax
801000d5:	75 4f                	jne    80100126 <bget+0x76>
801000d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000da:	8b 40 08             	mov    0x8(%eax),%eax
801000dd:	3b 45 0c             	cmp    0xc(%ebp),%eax
801000e0:	75 44                	jne    80100126 <bget+0x76>
      if(!(b->flags & B_BUSY)){
801000e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000e5:	8b 00                	mov    (%eax),%eax
801000e7:	83 e0 01             	and    $0x1,%eax
801000ea:	85 c0                	test   %eax,%eax
801000ec:	75 23                	jne    80100111 <bget+0x61>
        b->flags |= B_BUSY;
801000ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000f1:	8b 00                	mov    (%eax),%eax
801000f3:	83 c8 01             	or     $0x1,%eax
801000f6:	89 c2                	mov    %eax,%edx
801000f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000fb:	89 10                	mov    %edx,(%eax)
        release(&bcache.lock);
801000fd:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100104:	e8 95 50 00 00       	call   8010519e <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 c6 10 	movl   $0x8010c660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 1c 4b 00 00       	call   80104c40 <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 64 05 11 80 	cmpl   $0x80110564,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
  }

  // Not cached; recycle some non-busy and clean buffer.
  // "clean" because B_DIRTY and !B_BUSY means log.c
  // hasn't yet committed the changes to the buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 70 05 11 80       	mov    0x80110570,%eax
8010013d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100140:	eb 4d                	jmp    8010018f <bget+0xdf>
    if((b->flags & B_BUSY) == 0 && (b->flags & B_DIRTY) == 0){
80100142:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100145:	8b 00                	mov    (%eax),%eax
80100147:	83 e0 01             	and    $0x1,%eax
8010014a:	85 c0                	test   %eax,%eax
8010014c:	75 38                	jne    80100186 <bget+0xd6>
8010014e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100151:	8b 00                	mov    (%eax),%eax
80100153:	83 e0 04             	and    $0x4,%eax
80100156:	85 c0                	test   %eax,%eax
80100158:	75 2c                	jne    80100186 <bget+0xd6>
      b->dev = dev;
8010015a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010015d:	8b 55 08             	mov    0x8(%ebp),%edx
80100160:	89 50 04             	mov    %edx,0x4(%eax)
      b->sector = sector;
80100163:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100166:	8b 55 0c             	mov    0xc(%ebp),%edx
80100169:	89 50 08             	mov    %edx,0x8(%eax)
      b->flags = B_BUSY;
8010016c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010016f:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
      release(&bcache.lock);
80100175:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010017c:	e8 1d 50 00 00       	call   8010519e <release>
      return b;
80100181:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100184:	eb 1e                	jmp    801001a4 <bget+0xf4>
  }

  // Not cached; recycle some non-busy and clean buffer.
  // "clean" because B_DIRTY and !B_BUSY means log.c
  // hasn't yet committed the changes to the buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100186:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100189:	8b 40 0c             	mov    0xc(%eax),%eax
8010018c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010018f:	81 7d f4 64 05 11 80 	cmpl   $0x80110564,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 73 87 10 80 	movl   $0x80108773,(%esp)
8010019f:	e8 96 03 00 00       	call   8010053a <panic>
}
801001a4:	c9                   	leave  
801001a5:	c3                   	ret    

801001a6 <bread>:

// Return a B_BUSY buf with the contents of the indicated disk sector.
struct buf*
bread(uint dev, uint sector)
{
801001a6:	55                   	push   %ebp
801001a7:	89 e5                	mov    %esp,%ebp
801001a9:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  b = bget(dev, sector);
801001ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801001af:	89 44 24 04          	mov    %eax,0x4(%esp)
801001b3:	8b 45 08             	mov    0x8(%ebp),%eax
801001b6:	89 04 24             	mov    %eax,(%esp)
801001b9:	e8 f2 fe ff ff       	call   801000b0 <bget>
801001be:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(!(b->flags & B_VALID))
801001c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001c4:	8b 00                	mov    (%eax),%eax
801001c6:	83 e0 02             	and    $0x2,%eax
801001c9:	85 c0                	test   %eax,%eax
801001cb:	75 0b                	jne    801001d8 <bread+0x32>
    iderw(b);
801001cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001d0:	89 04 24             	mov    %eax,(%esp)
801001d3:	e8 e4 26 00 00       	call   801028bc <iderw>
  return b;
801001d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801001db:	c9                   	leave  
801001dc:	c3                   	ret    

801001dd <bwrite>:

// Write b's contents to disk.  Must be B_BUSY.
void
bwrite(struct buf *b)
{
801001dd:	55                   	push   %ebp
801001de:	89 e5                	mov    %esp,%ebp
801001e0:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
801001e3:	8b 45 08             	mov    0x8(%ebp),%eax
801001e6:	8b 00                	mov    (%eax),%eax
801001e8:	83 e0 01             	and    $0x1,%eax
801001eb:	85 c0                	test   %eax,%eax
801001ed:	75 0c                	jne    801001fb <bwrite+0x1e>
    panic("bwrite");
801001ef:	c7 04 24 84 87 10 80 	movl   $0x80108784,(%esp)
801001f6:	e8 3f 03 00 00       	call   8010053a <panic>
  b->flags |= B_DIRTY;
801001fb:	8b 45 08             	mov    0x8(%ebp),%eax
801001fe:	8b 00                	mov    (%eax),%eax
80100200:	83 c8 04             	or     $0x4,%eax
80100203:	89 c2                	mov    %eax,%edx
80100205:	8b 45 08             	mov    0x8(%ebp),%eax
80100208:	89 10                	mov    %edx,(%eax)
  iderw(b);
8010020a:	8b 45 08             	mov    0x8(%ebp),%eax
8010020d:	89 04 24             	mov    %eax,(%esp)
80100210:	e8 a7 26 00 00       	call   801028bc <iderw>
}
80100215:	c9                   	leave  
80100216:	c3                   	ret    

80100217 <brelse>:

// Release a B_BUSY buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
80100217:	55                   	push   %ebp
80100218:	89 e5                	mov    %esp,%ebp
8010021a:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
8010021d:	8b 45 08             	mov    0x8(%ebp),%eax
80100220:	8b 00                	mov    (%eax),%eax
80100222:	83 e0 01             	and    $0x1,%eax
80100225:	85 c0                	test   %eax,%eax
80100227:	75 0c                	jne    80100235 <brelse+0x1e>
    panic("brelse");
80100229:	c7 04 24 8b 87 10 80 	movl   $0x8010878b,(%esp)
80100230:	e8 05 03 00 00       	call   8010053a <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010023c:	e8 fb 4e 00 00       	call   8010513c <acquire>

  b->next->prev = b->prev;
80100241:	8b 45 08             	mov    0x8(%ebp),%eax
80100244:	8b 40 10             	mov    0x10(%eax),%eax
80100247:	8b 55 08             	mov    0x8(%ebp),%edx
8010024a:	8b 52 0c             	mov    0xc(%edx),%edx
8010024d:	89 50 0c             	mov    %edx,0xc(%eax)
  b->prev->next = b->next;
80100250:	8b 45 08             	mov    0x8(%ebp),%eax
80100253:	8b 40 0c             	mov    0xc(%eax),%eax
80100256:	8b 55 08             	mov    0x8(%ebp),%edx
80100259:	8b 52 10             	mov    0x10(%edx),%edx
8010025c:	89 50 10             	mov    %edx,0x10(%eax)
  b->next = bcache.head.next;
8010025f:	8b 15 74 05 11 80    	mov    0x80110574,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c 64 05 11 80 	movl   $0x80110564,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 74 05 11 80       	mov    0x80110574,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 74 05 11 80       	mov    %eax,0x80110574

  b->flags &= ~B_BUSY;
80100288:	8b 45 08             	mov    0x8(%ebp),%eax
8010028b:	8b 00                	mov    (%eax),%eax
8010028d:	83 e0 fe             	and    $0xfffffffe,%eax
80100290:	89 c2                	mov    %eax,%edx
80100292:	8b 45 08             	mov    0x8(%ebp),%eax
80100295:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80100297:	8b 45 08             	mov    0x8(%ebp),%eax
8010029a:	89 04 24             	mov    %eax,(%esp)
8010029d:	e8 77 4a 00 00       	call   80104d19 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801002a9:	e8 f0 4e 00 00       	call   8010519e <release>
}
801002ae:	c9                   	leave  
801002af:	c3                   	ret    

801002b0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801002b0:	55                   	push   %ebp
801002b1:	89 e5                	mov    %esp,%ebp
801002b3:	83 ec 14             	sub    $0x14,%esp
801002b6:	8b 45 08             	mov    0x8(%ebp),%eax
801002b9:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801002bd:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801002c1:	89 c2                	mov    %eax,%edx
801002c3:	ec                   	in     (%dx),%al
801002c4:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801002c7:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801002cb:	c9                   	leave  
801002cc:	c3                   	ret    

801002cd <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801002cd:	55                   	push   %ebp
801002ce:	89 e5                	mov    %esp,%ebp
801002d0:	83 ec 08             	sub    $0x8,%esp
801002d3:	8b 55 08             	mov    0x8(%ebp),%edx
801002d6:	8b 45 0c             	mov    0xc(%ebp),%eax
801002d9:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801002dd:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801002e0:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801002e4:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801002e8:	ee                   	out    %al,(%dx)
}
801002e9:	c9                   	leave  
801002ea:	c3                   	ret    

801002eb <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801002eb:	55                   	push   %ebp
801002ec:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801002ee:	fa                   	cli    
}
801002ef:	5d                   	pop    %ebp
801002f0:	c3                   	ret    

801002f1 <printint>:
  int locking;
} cons;

static void
printint(int xx, int base, int sign)
{
801002f1:	55                   	push   %ebp
801002f2:	89 e5                	mov    %esp,%ebp
801002f4:	56                   	push   %esi
801002f5:	53                   	push   %ebx
801002f6:	83 ec 30             	sub    $0x30,%esp
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
801002f9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801002fd:	74 1c                	je     8010031b <printint+0x2a>
801002ff:	8b 45 08             	mov    0x8(%ebp),%eax
80100302:	c1 e8 1f             	shr    $0x1f,%eax
80100305:	0f b6 c0             	movzbl %al,%eax
80100308:	89 45 10             	mov    %eax,0x10(%ebp)
8010030b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010030f:	74 0a                	je     8010031b <printint+0x2a>
    x = -xx;
80100311:	8b 45 08             	mov    0x8(%ebp),%eax
80100314:	f7 d8                	neg    %eax
80100316:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100319:	eb 06                	jmp    80100321 <printint+0x30>
  else
    x = xx;
8010031b:	8b 45 08             	mov    0x8(%ebp),%eax
8010031e:	89 45 f0             	mov    %eax,-0x10(%ebp)

  i = 0;
80100321:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
80100328:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010032b:	8d 41 01             	lea    0x1(%ecx),%eax
8010032e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100331:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80100334:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100337:	ba 00 00 00 00       	mov    $0x0,%edx
8010033c:	f7 f3                	div    %ebx
8010033e:	89 d0                	mov    %edx,%eax
80100340:	0f b6 80 04 90 10 80 	movzbl -0x7fef6ffc(%eax),%eax
80100347:	88 44 0d e0          	mov    %al,-0x20(%ebp,%ecx,1)
  }while((x /= base) != 0);
8010034b:	8b 75 0c             	mov    0xc(%ebp),%esi
8010034e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100351:	ba 00 00 00 00       	mov    $0x0,%edx
80100356:	f7 f6                	div    %esi
80100358:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010035b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010035f:	75 c7                	jne    80100328 <printint+0x37>

  if(sign)
80100361:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100365:	74 10                	je     80100377 <printint+0x86>
    buf[i++] = '-';
80100367:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010036a:	8d 50 01             	lea    0x1(%eax),%edx
8010036d:	89 55 f4             	mov    %edx,-0xc(%ebp)
80100370:	c6 44 05 e0 2d       	movb   $0x2d,-0x20(%ebp,%eax,1)

  while(--i >= 0)
80100375:	eb 18                	jmp    8010038f <printint+0x9e>
80100377:	eb 16                	jmp    8010038f <printint+0x9e>
    consputc(buf[i]);
80100379:	8d 55 e0             	lea    -0x20(%ebp),%edx
8010037c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010037f:	01 d0                	add    %edx,%eax
80100381:	0f b6 00             	movzbl (%eax),%eax
80100384:	0f be c0             	movsbl %al,%eax
80100387:	89 04 24             	mov    %eax,(%esp)
8010038a:	e8 c1 03 00 00       	call   80100750 <consputc>
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
8010038f:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100393:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100397:	79 e0                	jns    80100379 <printint+0x88>
    consputc(buf[i]);
}
80100399:	83 c4 30             	add    $0x30,%esp
8010039c:	5b                   	pop    %ebx
8010039d:	5e                   	pop    %esi
8010039e:	5d                   	pop    %ebp
8010039f:	c3                   	ret    

801003a0 <cprintf>:
//PAGEBREAK: 50

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
801003a0:	55                   	push   %ebp
801003a1:	89 e5                	mov    %esp,%ebp
801003a3:	83 ec 38             	sub    $0x38,%esp
  int i, c, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
801003a6:	a1 f4 b5 10 80       	mov    0x8010b5f4,%eax
801003ab:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003ae:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003b2:	74 0c                	je     801003c0 <cprintf+0x20>
    acquire(&cons.lock);
801003b4:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
801003bb:	e8 7c 4d 00 00       	call   8010513c <acquire>

  if (fmt == 0)
801003c0:	8b 45 08             	mov    0x8(%ebp),%eax
801003c3:	85 c0                	test   %eax,%eax
801003c5:	75 0c                	jne    801003d3 <cprintf+0x33>
    panic("null fmt");
801003c7:	c7 04 24 92 87 10 80 	movl   $0x80108792,(%esp)
801003ce:	e8 67 01 00 00       	call   8010053a <panic>

  argp = (uint*)(void*)(&fmt + 1);
801003d3:	8d 45 0c             	lea    0xc(%ebp),%eax
801003d6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
801003d9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801003e0:	e9 21 01 00 00       	jmp    80100506 <cprintf+0x166>
    if(c != '%'){
801003e5:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
801003e9:	74 10                	je     801003fb <cprintf+0x5b>
      consputc(c);
801003eb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801003ee:	89 04 24             	mov    %eax,(%esp)
801003f1:	e8 5a 03 00 00       	call   80100750 <consputc>
      continue;
801003f6:	e9 07 01 00 00       	jmp    80100502 <cprintf+0x162>
    }
    c = fmt[++i] & 0xff;
801003fb:	8b 55 08             	mov    0x8(%ebp),%edx
801003fe:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100402:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100405:	01 d0                	add    %edx,%eax
80100407:	0f b6 00             	movzbl (%eax),%eax
8010040a:	0f be c0             	movsbl %al,%eax
8010040d:	25 ff 00 00 00       	and    $0xff,%eax
80100412:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(c == 0)
80100415:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100419:	75 05                	jne    80100420 <cprintf+0x80>
      break;
8010041b:	e9 06 01 00 00       	jmp    80100526 <cprintf+0x186>
    switch(c){
80100420:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100423:	83 f8 70             	cmp    $0x70,%eax
80100426:	74 4f                	je     80100477 <cprintf+0xd7>
80100428:	83 f8 70             	cmp    $0x70,%eax
8010042b:	7f 13                	jg     80100440 <cprintf+0xa0>
8010042d:	83 f8 25             	cmp    $0x25,%eax
80100430:	0f 84 a6 00 00 00    	je     801004dc <cprintf+0x13c>
80100436:	83 f8 64             	cmp    $0x64,%eax
80100439:	74 14                	je     8010044f <cprintf+0xaf>
8010043b:	e9 aa 00 00 00       	jmp    801004ea <cprintf+0x14a>
80100440:	83 f8 73             	cmp    $0x73,%eax
80100443:	74 57                	je     8010049c <cprintf+0xfc>
80100445:	83 f8 78             	cmp    $0x78,%eax
80100448:	74 2d                	je     80100477 <cprintf+0xd7>
8010044a:	e9 9b 00 00 00       	jmp    801004ea <cprintf+0x14a>
    case 'd':
      printint(*argp++, 10, 1);
8010044f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100452:	8d 50 04             	lea    0x4(%eax),%edx
80100455:	89 55 f0             	mov    %edx,-0x10(%ebp)
80100458:	8b 00                	mov    (%eax),%eax
8010045a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80100461:	00 
80100462:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80100469:	00 
8010046a:	89 04 24             	mov    %eax,(%esp)
8010046d:	e8 7f fe ff ff       	call   801002f1 <printint>
      break;
80100472:	e9 8b 00 00 00       	jmp    80100502 <cprintf+0x162>
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
80100477:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010047a:	8d 50 04             	lea    0x4(%eax),%edx
8010047d:	89 55 f0             	mov    %edx,-0x10(%ebp)
80100480:	8b 00                	mov    (%eax),%eax
80100482:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100489:	00 
8010048a:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80100491:	00 
80100492:	89 04 24             	mov    %eax,(%esp)
80100495:	e8 57 fe ff ff       	call   801002f1 <printint>
      break;
8010049a:	eb 66                	jmp    80100502 <cprintf+0x162>
    case 's':
      if((s = (char*)*argp++) == 0)
8010049c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010049f:	8d 50 04             	lea    0x4(%eax),%edx
801004a2:	89 55 f0             	mov    %edx,-0x10(%ebp)
801004a5:	8b 00                	mov    (%eax),%eax
801004a7:	89 45 ec             	mov    %eax,-0x14(%ebp)
801004aa:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801004ae:	75 09                	jne    801004b9 <cprintf+0x119>
        s = "(null)";
801004b0:	c7 45 ec 9b 87 10 80 	movl   $0x8010879b,-0x14(%ebp)
      for(; *s; s++)
801004b7:	eb 17                	jmp    801004d0 <cprintf+0x130>
801004b9:	eb 15                	jmp    801004d0 <cprintf+0x130>
        consputc(*s);
801004bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004be:	0f b6 00             	movzbl (%eax),%eax
801004c1:	0f be c0             	movsbl %al,%eax
801004c4:	89 04 24             	mov    %eax,(%esp)
801004c7:	e8 84 02 00 00       	call   80100750 <consputc>
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
        s = "(null)";
      for(; *s; s++)
801004cc:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
801004d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004d3:	0f b6 00             	movzbl (%eax),%eax
801004d6:	84 c0                	test   %al,%al
801004d8:	75 e1                	jne    801004bb <cprintf+0x11b>
        consputc(*s);
      break;
801004da:	eb 26                	jmp    80100502 <cprintf+0x162>
    case '%':
      consputc('%');
801004dc:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004e3:	e8 68 02 00 00       	call   80100750 <consputc>
      break;
801004e8:	eb 18                	jmp    80100502 <cprintf+0x162>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
801004ea:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004f1:	e8 5a 02 00 00       	call   80100750 <consputc>
      consputc(c);
801004f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801004f9:	89 04 24             	mov    %eax,(%esp)
801004fc:	e8 4f 02 00 00       	call   80100750 <consputc>
      break;
80100501:	90                   	nop

  if (fmt == 0)
    panic("null fmt");

  argp = (uint*)(void*)(&fmt + 1);
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100502:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100506:	8b 55 08             	mov    0x8(%ebp),%edx
80100509:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010050c:	01 d0                	add    %edx,%eax
8010050e:	0f b6 00             	movzbl (%eax),%eax
80100511:	0f be c0             	movsbl %al,%eax
80100514:	25 ff 00 00 00       	and    $0xff,%eax
80100519:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010051c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100520:	0f 85 bf fe ff ff    	jne    801003e5 <cprintf+0x45>
      consputc(c);
      break;
    }
  }

  if(locking)
80100526:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010052a:	74 0c                	je     80100538 <cprintf+0x198>
    release(&cons.lock);
8010052c:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100533:	e8 66 4c 00 00       	call   8010519e <release>
}
80100538:	c9                   	leave  
80100539:	c3                   	ret    

8010053a <panic>:

void
panic(char *s)
{
8010053a:	55                   	push   %ebp
8010053b:	89 e5                	mov    %esp,%ebp
8010053d:	83 ec 48             	sub    $0x48,%esp
  int i;
  uint pcs[10];
  
  cli();
80100540:	e8 a6 fd ff ff       	call   801002eb <cli>
  cons.locking = 0;
80100545:	c7 05 f4 b5 10 80 00 	movl   $0x0,0x8010b5f4
8010054c:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
8010054f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100555:	0f b6 00             	movzbl (%eax),%eax
80100558:	0f b6 c0             	movzbl %al,%eax
8010055b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010055f:	c7 04 24 a2 87 10 80 	movl   $0x801087a2,(%esp)
80100566:	e8 35 fe ff ff       	call   801003a0 <cprintf>
  cprintf(s);
8010056b:	8b 45 08             	mov    0x8(%ebp),%eax
8010056e:	89 04 24             	mov    %eax,(%esp)
80100571:	e8 2a fe ff ff       	call   801003a0 <cprintf>
  cprintf("\n");
80100576:	c7 04 24 b1 87 10 80 	movl   $0x801087b1,(%esp)
8010057d:	e8 1e fe ff ff       	call   801003a0 <cprintf>
  getcallerpcs(&s, pcs);
80100582:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100585:	89 44 24 04          	mov    %eax,0x4(%esp)
80100589:	8d 45 08             	lea    0x8(%ebp),%eax
8010058c:	89 04 24             	mov    %eax,(%esp)
8010058f:	e8 59 4c 00 00       	call   801051ed <getcallerpcs>
  for(i=0; i<10; i++)
80100594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059b:	eb 1b                	jmp    801005b8 <panic+0x7e>
    cprintf(" %p", pcs[i]);
8010059d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a0:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801005a8:	c7 04 24 b3 87 10 80 	movl   $0x801087b3,(%esp)
801005af:	e8 ec fd ff ff       	call   801003a0 <cprintf>
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
801005b4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801005b8:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801005bc:	7e df                	jle    8010059d <panic+0x63>
    cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
801005be:	c7 05 a0 b5 10 80 01 	movl   $0x1,0x8010b5a0
801005c5:	00 00 00 
  for(;;)
    ;
801005c8:	eb fe                	jmp    801005c8 <panic+0x8e>

801005ca <cgaputc>:
#define CRTPORT 0x3d4
static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory

static void
cgaputc(int c)
{
801005ca:	55                   	push   %ebp
801005cb:	89 e5                	mov    %esp,%ebp
801005cd:	83 ec 28             	sub    $0x28,%esp
  int pos;
  
  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
801005d0:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801005d7:	00 
801005d8:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801005df:	e8 e9 fc ff ff       	call   801002cd <outb>
  pos = inb(CRTPORT+1) << 8;
801005e4:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
801005eb:	e8 c0 fc ff ff       	call   801002b0 <inb>
801005f0:	0f b6 c0             	movzbl %al,%eax
801005f3:	c1 e0 08             	shl    $0x8,%eax
801005f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  outb(CRTPORT, 15);
801005f9:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80100600:	00 
80100601:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100608:	e8 c0 fc ff ff       	call   801002cd <outb>
  pos |= inb(CRTPORT+1);
8010060d:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100614:	e8 97 fc ff ff       	call   801002b0 <inb>
80100619:	0f b6 c0             	movzbl %al,%eax
8010061c:	09 45 f4             	or     %eax,-0xc(%ebp)

  if(c == '\n')
8010061f:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
80100623:	75 30                	jne    80100655 <cgaputc+0x8b>
    pos += 80 - pos%80;
80100625:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80100628:	ba 67 66 66 66       	mov    $0x66666667,%edx
8010062d:	89 c8                	mov    %ecx,%eax
8010062f:	f7 ea                	imul   %edx
80100631:	c1 fa 05             	sar    $0x5,%edx
80100634:	89 c8                	mov    %ecx,%eax
80100636:	c1 f8 1f             	sar    $0x1f,%eax
80100639:	29 c2                	sub    %eax,%edx
8010063b:	89 d0                	mov    %edx,%eax
8010063d:	c1 e0 02             	shl    $0x2,%eax
80100640:	01 d0                	add    %edx,%eax
80100642:	c1 e0 04             	shl    $0x4,%eax
80100645:	29 c1                	sub    %eax,%ecx
80100647:	89 ca                	mov    %ecx,%edx
80100649:	b8 50 00 00 00       	mov    $0x50,%eax
8010064e:	29 d0                	sub    %edx,%eax
80100650:	01 45 f4             	add    %eax,-0xc(%ebp)
80100653:	eb 35                	jmp    8010068a <cgaputc+0xc0>
  else if(c == BACKSPACE){
80100655:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010065c:	75 0c                	jne    8010066a <cgaputc+0xa0>
    if(pos > 0) --pos;
8010065e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100662:	7e 26                	jle    8010068a <cgaputc+0xc0>
80100664:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100668:	eb 20                	jmp    8010068a <cgaputc+0xc0>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010066a:	8b 0d 00 90 10 80    	mov    0x80109000,%ecx
80100670:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100673:	8d 50 01             	lea    0x1(%eax),%edx
80100676:	89 55 f4             	mov    %edx,-0xc(%ebp)
80100679:	01 c0                	add    %eax,%eax
8010067b:	8d 14 01             	lea    (%ecx,%eax,1),%edx
8010067e:	8b 45 08             	mov    0x8(%ebp),%eax
80100681:	0f b6 c0             	movzbl %al,%eax
80100684:	80 cc 07             	or     $0x7,%ah
80100687:	66 89 02             	mov    %ax,(%edx)
  
  if((pos/80) >= 24){  // Scroll up.
8010068a:	81 7d f4 7f 07 00 00 	cmpl   $0x77f,-0xc(%ebp)
80100691:	7e 53                	jle    801006e6 <cgaputc+0x11c>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
80100693:	a1 00 90 10 80       	mov    0x80109000,%eax
80100698:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
8010069e:	a1 00 90 10 80       	mov    0x80109000,%eax
801006a3:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801006aa:	00 
801006ab:	89 54 24 04          	mov    %edx,0x4(%esp)
801006af:	89 04 24             	mov    %eax,(%esp)
801006b2:	e8 a8 4d 00 00       	call   8010545f <memmove>
    pos -= 80;
801006b7:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801006bb:	b8 80 07 00 00       	mov    $0x780,%eax
801006c0:	2b 45 f4             	sub    -0xc(%ebp),%eax
801006c3:	8d 14 00             	lea    (%eax,%eax,1),%edx
801006c6:	a1 00 90 10 80       	mov    0x80109000,%eax
801006cb:	8b 4d f4             	mov    -0xc(%ebp),%ecx
801006ce:	01 c9                	add    %ecx,%ecx
801006d0:	01 c8                	add    %ecx,%eax
801006d2:	89 54 24 08          	mov    %edx,0x8(%esp)
801006d6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801006dd:	00 
801006de:	89 04 24             	mov    %eax,(%esp)
801006e1:	e8 aa 4c 00 00       	call   80105390 <memset>
  }
  
  outb(CRTPORT, 14);
801006e6:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801006ed:	00 
801006ee:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801006f5:	e8 d3 fb ff ff       	call   801002cd <outb>
  outb(CRTPORT+1, pos>>8);
801006fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801006fd:	c1 f8 08             	sar    $0x8,%eax
80100700:	0f b6 c0             	movzbl %al,%eax
80100703:	89 44 24 04          	mov    %eax,0x4(%esp)
80100707:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
8010070e:	e8 ba fb ff ff       	call   801002cd <outb>
  outb(CRTPORT, 15);
80100713:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
8010071a:	00 
8010071b:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100722:	e8 a6 fb ff ff       	call   801002cd <outb>
  outb(CRTPORT+1, pos);
80100727:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010072a:	0f b6 c0             	movzbl %al,%eax
8010072d:	89 44 24 04          	mov    %eax,0x4(%esp)
80100731:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100738:	e8 90 fb ff ff       	call   801002cd <outb>
  crt[pos] = ' ' | 0x0700;
8010073d:	a1 00 90 10 80       	mov    0x80109000,%eax
80100742:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100745:	01 d2                	add    %edx,%edx
80100747:	01 d0                	add    %edx,%eax
80100749:	66 c7 00 20 07       	movw   $0x720,(%eax)
}
8010074e:	c9                   	leave  
8010074f:	c3                   	ret    

80100750 <consputc>:

void
consputc(int c)
{
80100750:	55                   	push   %ebp
80100751:	89 e5                	mov    %esp,%ebp
80100753:	83 ec 18             	sub    $0x18,%esp
  if(panicked){
80100756:	a1 a0 b5 10 80       	mov    0x8010b5a0,%eax
8010075b:	85 c0                	test   %eax,%eax
8010075d:	74 07                	je     80100766 <consputc+0x16>
    cli();
8010075f:	e8 87 fb ff ff       	call   801002eb <cli>
    for(;;)
      ;
80100764:	eb fe                	jmp    80100764 <consputc+0x14>
  }

  if(c == BACKSPACE){
80100766:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010076d:	75 26                	jne    80100795 <consputc+0x45>
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010076f:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100776:	e8 32 66 00 00       	call   80106dad <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 26 66 00 00       	call   80106dad <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 1a 66 00 00       	call   80106dad <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 0d 66 00 00       	call   80106dad <uartputc>
  cgaputc(c);
801007a0:	8b 45 08             	mov    0x8(%ebp),%eax
801007a3:	89 04 24             	mov    %eax,(%esp)
801007a6:	e8 1f fe ff ff       	call   801005ca <cgaputc>
}
801007ab:	c9                   	leave  
801007ac:	c3                   	ret    

801007ad <consoleintr>:

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
801007ad:	55                   	push   %ebp
801007ae:	89 e5                	mov    %esp,%ebp
801007b0:	83 ec 28             	sub    $0x28,%esp
  int c;

  acquire(&input.lock);
801007b3:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
801007ba:	e8 7d 49 00 00       	call   8010513c <acquire>
  while((c = getc()) >= 0){
801007bf:	e9 37 01 00 00       	jmp    801008fb <consoleintr+0x14e>
    switch(c){
801007c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801007c7:	83 f8 10             	cmp    $0x10,%eax
801007ca:	74 1e                	je     801007ea <consoleintr+0x3d>
801007cc:	83 f8 10             	cmp    $0x10,%eax
801007cf:	7f 0a                	jg     801007db <consoleintr+0x2e>
801007d1:	83 f8 08             	cmp    $0x8,%eax
801007d4:	74 64                	je     8010083a <consoleintr+0x8d>
801007d6:	e9 91 00 00 00       	jmp    8010086c <consoleintr+0xbf>
801007db:	83 f8 15             	cmp    $0x15,%eax
801007de:	74 2f                	je     8010080f <consoleintr+0x62>
801007e0:	83 f8 7f             	cmp    $0x7f,%eax
801007e3:	74 55                	je     8010083a <consoleintr+0x8d>
801007e5:	e9 82 00 00 00       	jmp    8010086c <consoleintr+0xbf>
    case C('P'):  // Process listing.
      procdump();
801007ea:	e8 cd 45 00 00       	call   80104dbc <procdump>
      break;
801007ef:	e9 07 01 00 00       	jmp    801008fb <consoleintr+0x14e>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
801007f4:	a1 3c 08 11 80       	mov    0x8011083c,%eax
801007f9:	83 e8 01             	sub    $0x1,%eax
801007fc:	a3 3c 08 11 80       	mov    %eax,0x8011083c
        consputc(BACKSPACE);
80100801:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100808:	e8 43 ff ff ff       	call   80100750 <consputc>
8010080d:	eb 01                	jmp    80100810 <consoleintr+0x63>
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
8010080f:	90                   	nop
80100810:	8b 15 3c 08 11 80    	mov    0x8011083c,%edx
80100816:	a1 38 08 11 80       	mov    0x80110838,%eax
8010081b:	39 c2                	cmp    %eax,%edx
8010081d:	74 16                	je     80100835 <consoleintr+0x88>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
8010081f:	a1 3c 08 11 80       	mov    0x8011083c,%eax
80100824:	83 e8 01             	sub    $0x1,%eax
80100827:	83 e0 7f             	and    $0x7f,%eax
8010082a:	0f b6 80 b4 07 11 80 	movzbl -0x7feef84c(%eax),%eax
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100831:	3c 0a                	cmp    $0xa,%al
80100833:	75 bf                	jne    801007f4 <consoleintr+0x47>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100835:	e9 c1 00 00 00       	jmp    801008fb <consoleintr+0x14e>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
8010083a:	8b 15 3c 08 11 80    	mov    0x8011083c,%edx
80100840:	a1 38 08 11 80       	mov    0x80110838,%eax
80100845:	39 c2                	cmp    %eax,%edx
80100847:	74 1e                	je     80100867 <consoleintr+0xba>
        input.e--;
80100849:	a1 3c 08 11 80       	mov    0x8011083c,%eax
8010084e:	83 e8 01             	sub    $0x1,%eax
80100851:	a3 3c 08 11 80       	mov    %eax,0x8011083c
        consputc(BACKSPACE);
80100856:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
8010085d:	e8 ee fe ff ff       	call   80100750 <consputc>
      }
      break;
80100862:	e9 94 00 00 00       	jmp    801008fb <consoleintr+0x14e>
80100867:	e9 8f 00 00 00       	jmp    801008fb <consoleintr+0x14e>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
8010086c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100870:	0f 84 84 00 00 00    	je     801008fa <consoleintr+0x14d>
80100876:	8b 15 3c 08 11 80    	mov    0x8011083c,%edx
8010087c:	a1 34 08 11 80       	mov    0x80110834,%eax
80100881:	29 c2                	sub    %eax,%edx
80100883:	89 d0                	mov    %edx,%eax
80100885:	83 f8 7f             	cmp    $0x7f,%eax
80100888:	77 70                	ja     801008fa <consoleintr+0x14d>
        c = (c == '\r') ? '\n' : c;
8010088a:	83 7d f4 0d          	cmpl   $0xd,-0xc(%ebp)
8010088e:	74 05                	je     80100895 <consoleintr+0xe8>
80100890:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100893:	eb 05                	jmp    8010089a <consoleintr+0xed>
80100895:	b8 0a 00 00 00       	mov    $0xa,%eax
8010089a:	89 45 f4             	mov    %eax,-0xc(%ebp)
        input.buf[input.e++ % INPUT_BUF] = c;
8010089d:	a1 3c 08 11 80       	mov    0x8011083c,%eax
801008a2:	8d 50 01             	lea    0x1(%eax),%edx
801008a5:	89 15 3c 08 11 80    	mov    %edx,0x8011083c
801008ab:	83 e0 7f             	and    $0x7f,%eax
801008ae:	89 c2                	mov    %eax,%edx
801008b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008b3:	88 82 b4 07 11 80    	mov    %al,-0x7feef84c(%edx)
        consputc(c);
801008b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008bc:	89 04 24             	mov    %eax,(%esp)
801008bf:	e8 8c fe ff ff       	call   80100750 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801008c4:	83 7d f4 0a          	cmpl   $0xa,-0xc(%ebp)
801008c8:	74 18                	je     801008e2 <consoleintr+0x135>
801008ca:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
801008ce:	74 12                	je     801008e2 <consoleintr+0x135>
801008d0:	a1 3c 08 11 80       	mov    0x8011083c,%eax
801008d5:	8b 15 34 08 11 80    	mov    0x80110834,%edx
801008db:	83 ea 80             	sub    $0xffffff80,%edx
801008de:	39 d0                	cmp    %edx,%eax
801008e0:	75 18                	jne    801008fa <consoleintr+0x14d>
          input.w = input.e;
801008e2:	a1 3c 08 11 80       	mov    0x8011083c,%eax
801008e7:	a3 38 08 11 80       	mov    %eax,0x80110838
          wakeup(&input.r);
801008ec:	c7 04 24 34 08 11 80 	movl   $0x80110834,(%esp)
801008f3:	e8 21 44 00 00       	call   80104d19 <wakeup>
        }
      }
      break;
801008f8:	eb 00                	jmp    801008fa <consoleintr+0x14d>
801008fa:	90                   	nop
consoleintr(int (*getc)(void))
{
  int c;

  acquire(&input.lock);
  while((c = getc()) >= 0){
801008fb:	8b 45 08             	mov    0x8(%ebp),%eax
801008fe:	ff d0                	call   *%eax
80100900:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100903:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100907:	0f 89 b7 fe ff ff    	jns    801007c4 <consoleintr+0x17>
        }
      }
      break;
    }
  }
  release(&input.lock);
8010090d:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
80100914:	e8 85 48 00 00       	call   8010519e <release>
}
80100919:	c9                   	leave  
8010091a:	c3                   	ret    

8010091b <consoleread>:

int
consoleread(struct inode *ip, char *dst, int off, int n)
{
8010091b:	55                   	push   %ebp
8010091c:	89 e5                	mov    %esp,%ebp
8010091e:	83 ec 28             	sub    $0x28,%esp
  uint target;
  int c;

  iunlock(ip);
80100921:	8b 45 08             	mov    0x8(%ebp),%eax
80100924:	89 04 24             	mov    %eax,(%esp)
80100927:	e8 7d 10 00 00       	call   801019a9 <iunlock>
  target = n;
8010092c:	8b 45 14             	mov    0x14(%ebp),%eax
8010092f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
80100932:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
80100939:	e8 fe 47 00 00       	call   8010513c <acquire>
  while(n > 0){
8010093e:	e9 aa 00 00 00       	jmp    801009ed <consoleread+0xd2>
    while(input.r == input.w){
80100943:	eb 42                	jmp    80100987 <consoleread+0x6c>
      if(proc->killed){
80100945:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010094b:	8b 40 24             	mov    0x24(%eax),%eax
8010094e:	85 c0                	test   %eax,%eax
80100950:	74 21                	je     80100973 <consoleread+0x58>
        release(&input.lock);
80100952:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
80100959:	e8 40 48 00 00       	call   8010519e <release>
        ilock(ip);
8010095e:	8b 45 08             	mov    0x8(%ebp),%eax
80100961:	89 04 24             	mov    %eax,(%esp)
80100964:	e8 f2 0e 00 00       	call   8010185b <ilock>
        return -1;
80100969:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010096e:	e9 a5 00 00 00       	jmp    80100a18 <consoleread+0xfd>
      }
      sleep(&input.r, &input.lock);
80100973:	c7 44 24 04 80 07 11 	movl   $0x80110780,0x4(%esp)
8010097a:	80 
8010097b:	c7 04 24 34 08 11 80 	movl   $0x80110834,(%esp)
80100982:	e8 b9 42 00 00       	call   80104c40 <sleep>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
80100987:	8b 15 34 08 11 80    	mov    0x80110834,%edx
8010098d:	a1 38 08 11 80       	mov    0x80110838,%eax
80100992:	39 c2                	cmp    %eax,%edx
80100994:	74 af                	je     80100945 <consoleread+0x2a>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
80100996:	a1 34 08 11 80       	mov    0x80110834,%eax
8010099b:	8d 50 01             	lea    0x1(%eax),%edx
8010099e:	89 15 34 08 11 80    	mov    %edx,0x80110834
801009a4:	83 e0 7f             	and    $0x7f,%eax
801009a7:	0f b6 80 b4 07 11 80 	movzbl -0x7feef84c(%eax),%eax
801009ae:	0f be c0             	movsbl %al,%eax
801009b1:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(c == C('D')){  // EOF
801009b4:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
801009b8:	75 19                	jne    801009d3 <consoleread+0xb8>
      if(n < target){
801009ba:	8b 45 14             	mov    0x14(%ebp),%eax
801009bd:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801009c0:	73 0f                	jae    801009d1 <consoleread+0xb6>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
801009c2:	a1 34 08 11 80       	mov    0x80110834,%eax
801009c7:	83 e8 01             	sub    $0x1,%eax
801009ca:	a3 34 08 11 80       	mov    %eax,0x80110834
      }
      break;
801009cf:	eb 26                	jmp    801009f7 <consoleread+0xdc>
801009d1:	eb 24                	jmp    801009f7 <consoleread+0xdc>
    }
    *dst++ = c;
801009d3:	8b 45 0c             	mov    0xc(%ebp),%eax
801009d6:	8d 50 01             	lea    0x1(%eax),%edx
801009d9:	89 55 0c             	mov    %edx,0xc(%ebp)
801009dc:	8b 55 f0             	mov    -0x10(%ebp),%edx
801009df:	88 10                	mov    %dl,(%eax)
    --n;
801009e1:	83 6d 14 01          	subl   $0x1,0x14(%ebp)
    if(c == '\n')
801009e5:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
801009e9:	75 02                	jne    801009ed <consoleread+0xd2>
      break;
801009eb:	eb 0a                	jmp    801009f7 <consoleread+0xdc>
  int c;

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
801009ed:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801009f1:	0f 8f 4c ff ff ff    	jg     80100943 <consoleread+0x28>
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
  }
  release(&input.lock);
801009f7:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
801009fe:	e8 9b 47 00 00       	call   8010519e <release>
  ilock(ip);
80100a03:	8b 45 08             	mov    0x8(%ebp),%eax
80100a06:	89 04 24             	mov    %eax,(%esp)
80100a09:	e8 4d 0e 00 00       	call   8010185b <ilock>

  return target - n;
80100a0e:	8b 45 14             	mov    0x14(%ebp),%eax
80100a11:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a14:	29 c2                	sub    %eax,%edx
80100a16:	89 d0                	mov    %edx,%eax
}
80100a18:	c9                   	leave  
80100a19:	c3                   	ret    

80100a1a <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80100a1a:	55                   	push   %ebp
80100a1b:	89 e5                	mov    %esp,%ebp
80100a1d:	83 ec 28             	sub    $0x28,%esp
  int i;

  iunlock(ip);
80100a20:	8b 45 08             	mov    0x8(%ebp),%eax
80100a23:	89 04 24             	mov    %eax,(%esp)
80100a26:	e8 7e 0f 00 00       	call   801019a9 <iunlock>
  acquire(&cons.lock);
80100a2b:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a32:	e8 05 47 00 00       	call   8010513c <acquire>
  for(i = 0; i < n; i++)
80100a37:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100a3e:	eb 1d                	jmp    80100a5d <consolewrite+0x43>
    consputc(buf[i] & 0xff);
80100a40:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a43:	8b 45 0c             	mov    0xc(%ebp),%eax
80100a46:	01 d0                	add    %edx,%eax
80100a48:	0f b6 00             	movzbl (%eax),%eax
80100a4b:	0f be c0             	movsbl %al,%eax
80100a4e:	0f b6 c0             	movzbl %al,%eax
80100a51:	89 04 24             	mov    %eax,(%esp)
80100a54:	e8 f7 fc ff ff       	call   80100750 <consputc>
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
80100a59:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100a5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a60:	3b 45 10             	cmp    0x10(%ebp),%eax
80100a63:	7c db                	jl     80100a40 <consolewrite+0x26>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
80100a65:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a6c:	e8 2d 47 00 00       	call   8010519e <release>
  ilock(ip);
80100a71:	8b 45 08             	mov    0x8(%ebp),%eax
80100a74:	89 04 24             	mov    %eax,(%esp)
80100a77:	e8 df 0d 00 00       	call   8010185b <ilock>

  return n;
80100a7c:	8b 45 10             	mov    0x10(%ebp),%eax
}
80100a7f:	c9                   	leave  
80100a80:	c3                   	ret    

80100a81 <consoleinit>:

void
consoleinit(void)
{
80100a81:	55                   	push   %ebp
80100a82:	89 e5                	mov    %esp,%ebp
80100a84:	83 ec 18             	sub    $0x18,%esp
  initlock(&cons.lock, "console");
80100a87:	c7 44 24 04 b7 87 10 	movl   $0x801087b7,0x4(%esp)
80100a8e:	80 
80100a8f:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a96:	e8 80 46 00 00       	call   8010511b <initlock>
  initlock(&input.lock, "input");
80100a9b:	c7 44 24 04 bf 87 10 	movl   $0x801087bf,0x4(%esp)
80100aa2:	80 
80100aa3:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
80100aaa:	e8 6c 46 00 00       	call   8010511b <initlock>

  devsw[CONSOLE].write = consolewrite;
80100aaf:	c7 05 fc 11 11 80 1a 	movl   $0x80100a1a,0x801111fc
80100ab6:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ab9:	c7 05 f8 11 11 80 1b 	movl   $0x8010091b,0x801111f8
80100ac0:	09 10 80 
  cons.locking = 1;
80100ac3:	c7 05 f4 b5 10 80 01 	movl   $0x1,0x8010b5f4
80100aca:	00 00 00 

  picenable(IRQ_KBD);
80100acd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ad4:	e8 fb 33 00 00       	call   80103ed4 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ad9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100ae0:	00 
80100ae1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ae8:	e8 8b 1f 00 00       	call   80102a78 <ioapicenable>
}
80100aed:	c9                   	leave  
80100aee:	c3                   	ret    

80100aef <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
80100aef:	55                   	push   %ebp
80100af0:	89 e5                	mov    %esp,%ebp
80100af2:	81 ec 38 01 00 00    	sub    $0x138,%esp
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;

  begin_op();
80100af8:	e8 2e 2a 00 00       	call   8010352b <begin_op>
  if((ip = namei(path)) == 0){
80100afd:	8b 45 08             	mov    0x8(%ebp),%eax
80100b00:	89 04 24             	mov    %eax,(%esp)
80100b03:	e8 19 1a 00 00       	call   80102521 <namei>
80100b08:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b0b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b0f:	75 0f                	jne    80100b20 <exec+0x31>
    end_op();
80100b11:	e8 99 2a 00 00       	call   801035af <end_op>
    return -1;
80100b16:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b1b:	e9 e8 03 00 00       	jmp    80100f08 <exec+0x419>
  }
  ilock(ip);
80100b20:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b23:	89 04 24             	mov    %eax,(%esp)
80100b26:	e8 30 0d 00 00       	call   8010185b <ilock>
  pgdir = 0;
80100b2b:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
80100b32:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
80100b39:	00 
80100b3a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100b41:	00 
80100b42:	8d 85 0c ff ff ff    	lea    -0xf4(%ebp),%eax
80100b48:	89 44 24 04          	mov    %eax,0x4(%esp)
80100b4c:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b4f:	89 04 24             	mov    %eax,(%esp)
80100b52:	e8 11 12 00 00       	call   80101d68 <readi>
80100b57:	83 f8 33             	cmp    $0x33,%eax
80100b5a:	77 05                	ja     80100b61 <exec+0x72>
    goto bad;
80100b5c:	e9 7b 03 00 00       	jmp    80100edc <exec+0x3ed>
  if(elf.magic != ELF_MAGIC)
80100b61:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100b67:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b6c:	74 05                	je     80100b73 <exec+0x84>
    goto bad;
80100b6e:	e9 69 03 00 00       	jmp    80100edc <exec+0x3ed>

  if((pgdir = setupkvm()) == 0)
80100b73:	e8 86 73 00 00       	call   80107efe <setupkvm>
80100b78:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100b7b:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100b7f:	75 05                	jne    80100b86 <exec+0x97>
    goto bad;
80100b81:	e9 56 03 00 00       	jmp    80100edc <exec+0x3ed>

  // Load program into memory.
  sz = 0;
80100b86:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100b8d:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100b94:	8b 85 28 ff ff ff    	mov    -0xd8(%ebp),%eax
80100b9a:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100b9d:	e9 cb 00 00 00       	jmp    80100c6d <exec+0x17e>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100ba2:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100ba5:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80100bac:	00 
80100bad:	89 44 24 08          	mov    %eax,0x8(%esp)
80100bb1:	8d 85 ec fe ff ff    	lea    -0x114(%ebp),%eax
80100bb7:	89 44 24 04          	mov    %eax,0x4(%esp)
80100bbb:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100bbe:	89 04 24             	mov    %eax,(%esp)
80100bc1:	e8 a2 11 00 00       	call   80101d68 <readi>
80100bc6:	83 f8 20             	cmp    $0x20,%eax
80100bc9:	74 05                	je     80100bd0 <exec+0xe1>
      goto bad;
80100bcb:	e9 0c 03 00 00       	jmp    80100edc <exec+0x3ed>
    if(ph.type != ELF_PROG_LOAD)
80100bd0:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100bd6:	83 f8 01             	cmp    $0x1,%eax
80100bd9:	74 05                	je     80100be0 <exec+0xf1>
      continue;
80100bdb:	e9 80 00 00 00       	jmp    80100c60 <exec+0x171>
    if(ph.memsz < ph.filesz)
80100be0:	8b 95 00 ff ff ff    	mov    -0x100(%ebp),%edx
80100be6:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100bec:	39 c2                	cmp    %eax,%edx
80100bee:	73 05                	jae    80100bf5 <exec+0x106>
      goto bad;
80100bf0:	e9 e7 02 00 00       	jmp    80100edc <exec+0x3ed>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100bf5:	8b 95 f4 fe ff ff    	mov    -0x10c(%ebp),%edx
80100bfb:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
80100c01:	01 d0                	add    %edx,%eax
80100c03:	89 44 24 08          	mov    %eax,0x8(%esp)
80100c07:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c0a:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c0e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c11:	89 04 24             	mov    %eax,(%esp)
80100c14:	e8 b3 76 00 00       	call   801082cc <allocuvm>
80100c19:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100c1c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100c20:	75 05                	jne    80100c27 <exec+0x138>
      goto bad;
80100c22:	e9 b5 02 00 00       	jmp    80100edc <exec+0x3ed>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100c27:	8b 8d fc fe ff ff    	mov    -0x104(%ebp),%ecx
80100c2d:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100c33:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
80100c39:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80100c3d:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100c41:	8b 55 d8             	mov    -0x28(%ebp),%edx
80100c44:	89 54 24 08          	mov    %edx,0x8(%esp)
80100c48:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c4c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c4f:	89 04 24             	mov    %eax,(%esp)
80100c52:	e8 8a 75 00 00       	call   801081e1 <loaduvm>
80100c57:	85 c0                	test   %eax,%eax
80100c59:	79 05                	jns    80100c60 <exec+0x171>
      goto bad;
80100c5b:	e9 7c 02 00 00       	jmp    80100edc <exec+0x3ed>
  if((pgdir = setupkvm()) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100c60:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100c64:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100c67:	83 c0 20             	add    $0x20,%eax
80100c6a:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100c6d:	0f b7 85 38 ff ff ff 	movzwl -0xc8(%ebp),%eax
80100c74:	0f b7 c0             	movzwl %ax,%eax
80100c77:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100c7a:	0f 8f 22 ff ff ff    	jg     80100ba2 <exec+0xb3>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
80100c80:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100c83:	89 04 24             	mov    %eax,(%esp)
80100c86:	e8 54 0e 00 00       	call   80101adf <iunlockput>
  end_op();
80100c8b:	e8 1f 29 00 00       	call   801035af <end_op>
  ip = 0;
80100c90:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100c97:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c9a:	05 ff 0f 00 00       	add    $0xfff,%eax
80100c9f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100ca4:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100ca7:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100caa:	05 00 20 00 00       	add    $0x2000,%eax
80100caf:	89 44 24 08          	mov    %eax,0x8(%esp)
80100cb3:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cb6:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cbd:	89 04 24             	mov    %eax,(%esp)
80100cc0:	e8 07 76 00 00       	call   801082cc <allocuvm>
80100cc5:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100cc8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100ccc:	75 05                	jne    80100cd3 <exec+0x1e4>
    goto bad;
80100cce:	e9 09 02 00 00       	jmp    80100edc <exec+0x3ed>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100cd3:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cd6:	2d 00 20 00 00       	sub    $0x2000,%eax
80100cdb:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cdf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100ce2:	89 04 24             	mov    %eax,(%esp)
80100ce5:	e8 12 78 00 00       	call   801084fc <clearpteu>
  sp = sz;
80100cea:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100ced:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100cf0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100cf7:	e9 9a 00 00 00       	jmp    80100d96 <exec+0x2a7>
    if(argc >= MAXARG)
80100cfc:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100d00:	76 05                	jbe    80100d07 <exec+0x218>
      goto bad;
80100d02:	e9 d5 01 00 00       	jmp    80100edc <exec+0x3ed>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100d07:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d0a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100d11:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d14:	01 d0                	add    %edx,%eax
80100d16:	8b 00                	mov    (%eax),%eax
80100d18:	89 04 24             	mov    %eax,(%esp)
80100d1b:	e8 da 48 00 00       	call   801055fa <strlen>
80100d20:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100d23:	29 c2                	sub    %eax,%edx
80100d25:	89 d0                	mov    %edx,%eax
80100d27:	83 e8 01             	sub    $0x1,%eax
80100d2a:	83 e0 fc             	and    $0xfffffffc,%eax
80100d2d:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100d30:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d33:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100d3a:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d3d:	01 d0                	add    %edx,%eax
80100d3f:	8b 00                	mov    (%eax),%eax
80100d41:	89 04 24             	mov    %eax,(%esp)
80100d44:	e8 b1 48 00 00       	call   801055fa <strlen>
80100d49:	83 c0 01             	add    $0x1,%eax
80100d4c:	89 c2                	mov    %eax,%edx
80100d4e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d51:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
80100d58:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d5b:	01 c8                	add    %ecx,%eax
80100d5d:	8b 00                	mov    (%eax),%eax
80100d5f:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100d63:	89 44 24 08          	mov    %eax,0x8(%esp)
80100d67:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d6a:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d6e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d71:	89 04 24             	mov    %eax,(%esp)
80100d74:	e8 48 79 00 00       	call   801086c1 <copyout>
80100d79:	85 c0                	test   %eax,%eax
80100d7b:	79 05                	jns    80100d82 <exec+0x293>
      goto bad;
80100d7d:	e9 5a 01 00 00       	jmp    80100edc <exec+0x3ed>
    ustack[3+argc] = sp;
80100d82:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d85:	8d 50 03             	lea    0x3(%eax),%edx
80100d88:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d8b:	89 84 95 40 ff ff ff 	mov    %eax,-0xc0(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100d92:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100d96:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d99:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100da0:	8b 45 0c             	mov    0xc(%ebp),%eax
80100da3:	01 d0                	add    %edx,%eax
80100da5:	8b 00                	mov    (%eax),%eax
80100da7:	85 c0                	test   %eax,%eax
80100da9:	0f 85 4d ff ff ff    	jne    80100cfc <exec+0x20d>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80100daf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100db2:	83 c0 03             	add    $0x3,%eax
80100db5:	c7 84 85 40 ff ff ff 	movl   $0x0,-0xc0(%ebp,%eax,4)
80100dbc:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100dc0:	c7 85 40 ff ff ff ff 	movl   $0xffffffff,-0xc0(%ebp)
80100dc7:	ff ff ff 
  ustack[1] = argc;
80100dca:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dcd:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100dd3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dd6:	83 c0 01             	add    $0x1,%eax
80100dd9:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100de0:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100de3:	29 d0                	sub    %edx,%eax
80100de5:	89 85 48 ff ff ff    	mov    %eax,-0xb8(%ebp)

  sp -= (3+argc+1) * 4;
80100deb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dee:	83 c0 04             	add    $0x4,%eax
80100df1:	c1 e0 02             	shl    $0x2,%eax
80100df4:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100df7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dfa:	83 c0 04             	add    $0x4,%eax
80100dfd:	c1 e0 02             	shl    $0x2,%eax
80100e00:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100e04:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
80100e0a:	89 44 24 08          	mov    %eax,0x8(%esp)
80100e0e:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e11:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e15:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e18:	89 04 24             	mov    %eax,(%esp)
80100e1b:	e8 a1 78 00 00       	call   801086c1 <copyout>
80100e20:	85 c0                	test   %eax,%eax
80100e22:	79 05                	jns    80100e29 <exec+0x33a>
    goto bad;
80100e24:	e9 b3 00 00 00       	jmp    80100edc <exec+0x3ed>

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e29:	8b 45 08             	mov    0x8(%ebp),%eax
80100e2c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100e2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e32:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100e35:	eb 17                	jmp    80100e4e <exec+0x35f>
    if(*s == '/')
80100e37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e3a:	0f b6 00             	movzbl (%eax),%eax
80100e3d:	3c 2f                	cmp    $0x2f,%al
80100e3f:	75 09                	jne    80100e4a <exec+0x35b>
      last = s+1;
80100e41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e44:	83 c0 01             	add    $0x1,%eax
80100e47:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e4a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100e4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e51:	0f b6 00             	movzbl (%eax),%eax
80100e54:	84 c0                	test   %al,%al
80100e56:	75 df                	jne    80100e37 <exec+0x348>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80100e58:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e5e:	8d 50 6c             	lea    0x6c(%eax),%edx
80100e61:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100e68:	00 
80100e69:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100e6c:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e70:	89 14 24             	mov    %edx,(%esp)
80100e73:	e8 38 47 00 00       	call   801055b0 <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
80100e78:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e7e:	8b 40 04             	mov    0x4(%eax),%eax
80100e81:	89 45 d0             	mov    %eax,-0x30(%ebp)
  proc->pgdir = pgdir;
80100e84:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e8a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100e8d:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80100e90:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e96:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100e99:	89 10                	mov    %edx,(%eax)
  proc->tf->eip = elf.entry;  // main
80100e9b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ea1:	8b 40 18             	mov    0x18(%eax),%eax
80100ea4:	8b 95 24 ff ff ff    	mov    -0xdc(%ebp),%edx
80100eaa:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
80100ead:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100eb3:	8b 40 18             	mov    0x18(%eax),%eax
80100eb6:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100eb9:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
80100ebc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ec2:	89 04 24             	mov    %eax,(%esp)
80100ec5:	e8 25 71 00 00       	call   80107fef <switchuvm>
  freevm(oldpgdir);
80100eca:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ecd:	89 04 24             	mov    %eax,(%esp)
80100ed0:	e8 8d 75 00 00       	call   80108462 <freevm>
  return 0;
80100ed5:	b8 00 00 00 00       	mov    $0x0,%eax
80100eda:	eb 2c                	jmp    80100f08 <exec+0x419>

 bad:
  if(pgdir)
80100edc:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100ee0:	74 0b                	je     80100eed <exec+0x3fe>
    freevm(pgdir);
80100ee2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100ee5:	89 04 24             	mov    %eax,(%esp)
80100ee8:	e8 75 75 00 00       	call   80108462 <freevm>
  if(ip){
80100eed:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100ef1:	74 10                	je     80100f03 <exec+0x414>
    iunlockput(ip);
80100ef3:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100ef6:	89 04 24             	mov    %eax,(%esp)
80100ef9:	e8 e1 0b 00 00       	call   80101adf <iunlockput>
    end_op();
80100efe:	e8 ac 26 00 00       	call   801035af <end_op>
  }
  return -1;
80100f03:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100f08:	c9                   	leave  
80100f09:	c3                   	ret    

80100f0a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100f0a:	55                   	push   %ebp
80100f0b:	89 e5                	mov    %esp,%ebp
80100f0d:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
80100f10:	c7 44 24 04 c5 87 10 	movl   $0x801087c5,0x4(%esp)
80100f17:	80 
80100f18:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100f1f:	e8 f7 41 00 00       	call   8010511b <initlock>
}
80100f24:	c9                   	leave  
80100f25:	c3                   	ret    

80100f26 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100f26:	55                   	push   %ebp
80100f27:	89 e5                	mov    %esp,%ebp
80100f29:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
80100f2c:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100f33:	e8 04 42 00 00       	call   8010513c <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f38:	c7 45 f4 74 08 11 80 	movl   $0x80110874,-0xc(%ebp)
80100f3f:	eb 29                	jmp    80100f6a <filealloc+0x44>
    if(f->ref == 0){
80100f41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f44:	8b 40 04             	mov    0x4(%eax),%eax
80100f47:	85 c0                	test   %eax,%eax
80100f49:	75 1b                	jne    80100f66 <filealloc+0x40>
      f->ref = 1;
80100f4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f4e:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
80100f55:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100f5c:	e8 3d 42 00 00       	call   8010519e <release>
      return f;
80100f61:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f64:	eb 1e                	jmp    80100f84 <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f66:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80100f6a:	81 7d f4 d4 11 11 80 	cmpl   $0x801111d4,-0xc(%ebp)
80100f71:	72 ce                	jb     80100f41 <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80100f73:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100f7a:	e8 1f 42 00 00       	call   8010519e <release>
  return 0;
80100f7f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80100f84:	c9                   	leave  
80100f85:	c3                   	ret    

80100f86 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100f86:	55                   	push   %ebp
80100f87:	89 e5                	mov    %esp,%ebp
80100f89:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
80100f8c:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100f93:	e8 a4 41 00 00       	call   8010513c <acquire>
  if(f->ref < 1)
80100f98:	8b 45 08             	mov    0x8(%ebp),%eax
80100f9b:	8b 40 04             	mov    0x4(%eax),%eax
80100f9e:	85 c0                	test   %eax,%eax
80100fa0:	7f 0c                	jg     80100fae <filedup+0x28>
    panic("filedup");
80100fa2:	c7 04 24 cc 87 10 80 	movl   $0x801087cc,(%esp)
80100fa9:	e8 8c f5 ff ff       	call   8010053a <panic>
  f->ref++;
80100fae:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb1:	8b 40 04             	mov    0x4(%eax),%eax
80100fb4:	8d 50 01             	lea    0x1(%eax),%edx
80100fb7:	8b 45 08             	mov    0x8(%ebp),%eax
80100fba:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fbd:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100fc4:	e8 d5 41 00 00       	call   8010519e <release>
  return f;
80100fc9:	8b 45 08             	mov    0x8(%ebp),%eax
}
80100fcc:	c9                   	leave  
80100fcd:	c3                   	ret    

80100fce <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100fce:	55                   	push   %ebp
80100fcf:	89 e5                	mov    %esp,%ebp
80100fd1:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
80100fd4:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100fdb:	e8 5c 41 00 00       	call   8010513c <acquire>
  if(f->ref < 1)
80100fe0:	8b 45 08             	mov    0x8(%ebp),%eax
80100fe3:	8b 40 04             	mov    0x4(%eax),%eax
80100fe6:	85 c0                	test   %eax,%eax
80100fe8:	7f 0c                	jg     80100ff6 <fileclose+0x28>
    panic("fileclose");
80100fea:	c7 04 24 d4 87 10 80 	movl   $0x801087d4,(%esp)
80100ff1:	e8 44 f5 ff ff       	call   8010053a <panic>
  if(--f->ref > 0){
80100ff6:	8b 45 08             	mov    0x8(%ebp),%eax
80100ff9:	8b 40 04             	mov    0x4(%eax),%eax
80100ffc:	8d 50 ff             	lea    -0x1(%eax),%edx
80100fff:	8b 45 08             	mov    0x8(%ebp),%eax
80101002:	89 50 04             	mov    %edx,0x4(%eax)
80101005:	8b 45 08             	mov    0x8(%ebp),%eax
80101008:	8b 40 04             	mov    0x4(%eax),%eax
8010100b:	85 c0                	test   %eax,%eax
8010100d:	7e 11                	jle    80101020 <fileclose+0x52>
    release(&ftable.lock);
8010100f:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80101016:	e8 83 41 00 00       	call   8010519e <release>
8010101b:	e9 82 00 00 00       	jmp    801010a2 <fileclose+0xd4>
    return;
  }
  ff = *f;
80101020:	8b 45 08             	mov    0x8(%ebp),%eax
80101023:	8b 10                	mov    (%eax),%edx
80101025:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101028:	8b 50 04             	mov    0x4(%eax),%edx
8010102b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
8010102e:	8b 50 08             	mov    0x8(%eax),%edx
80101031:	89 55 e8             	mov    %edx,-0x18(%ebp)
80101034:	8b 50 0c             	mov    0xc(%eax),%edx
80101037:	89 55 ec             	mov    %edx,-0x14(%ebp)
8010103a:	8b 50 10             	mov    0x10(%eax),%edx
8010103d:	89 55 f0             	mov    %edx,-0x10(%ebp)
80101040:	8b 40 14             	mov    0x14(%eax),%eax
80101043:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
80101046:	8b 45 08             	mov    0x8(%ebp),%eax
80101049:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
80101050:	8b 45 08             	mov    0x8(%ebp),%eax
80101053:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
80101059:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80101060:	e8 39 41 00 00       	call   8010519e <release>
  
  if(ff.type == FD_PIPE)
80101065:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101068:	83 f8 01             	cmp    $0x1,%eax
8010106b:	75 18                	jne    80101085 <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
8010106d:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
80101071:	0f be d0             	movsbl %al,%edx
80101074:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101077:	89 54 24 04          	mov    %edx,0x4(%esp)
8010107b:	89 04 24             	mov    %eax,(%esp)
8010107e:	e8 01 31 00 00       	call   80104184 <pipeclose>
80101083:	eb 1d                	jmp    801010a2 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
80101085:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101088:	83 f8 02             	cmp    $0x2,%eax
8010108b:	75 15                	jne    801010a2 <fileclose+0xd4>
    begin_op();
8010108d:	e8 99 24 00 00       	call   8010352b <begin_op>
    iput(ff.ip);
80101092:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101095:	89 04 24             	mov    %eax,(%esp)
80101098:	e8 71 09 00 00       	call   80101a0e <iput>
    end_op();
8010109d:	e8 0d 25 00 00       	call   801035af <end_op>
  }
}
801010a2:	c9                   	leave  
801010a3:	c3                   	ret    

801010a4 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
801010a4:	55                   	push   %ebp
801010a5:	89 e5                	mov    %esp,%ebp
801010a7:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
801010aa:	8b 45 08             	mov    0x8(%ebp),%eax
801010ad:	8b 00                	mov    (%eax),%eax
801010af:	83 f8 02             	cmp    $0x2,%eax
801010b2:	75 38                	jne    801010ec <filestat+0x48>
    ilock(f->ip);
801010b4:	8b 45 08             	mov    0x8(%ebp),%eax
801010b7:	8b 40 10             	mov    0x10(%eax),%eax
801010ba:	89 04 24             	mov    %eax,(%esp)
801010bd:	e8 99 07 00 00       	call   8010185b <ilock>
    stati(f->ip, st);
801010c2:	8b 45 08             	mov    0x8(%ebp),%eax
801010c5:	8b 40 10             	mov    0x10(%eax),%eax
801010c8:	8b 55 0c             	mov    0xc(%ebp),%edx
801010cb:	89 54 24 04          	mov    %edx,0x4(%esp)
801010cf:	89 04 24             	mov    %eax,(%esp)
801010d2:	e8 4c 0c 00 00       	call   80101d23 <stati>
    iunlock(f->ip);
801010d7:	8b 45 08             	mov    0x8(%ebp),%eax
801010da:	8b 40 10             	mov    0x10(%eax),%eax
801010dd:	89 04 24             	mov    %eax,(%esp)
801010e0:	e8 c4 08 00 00       	call   801019a9 <iunlock>
    return 0;
801010e5:	b8 00 00 00 00       	mov    $0x0,%eax
801010ea:	eb 05                	jmp    801010f1 <filestat+0x4d>
  }
  return -1;
801010ec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801010f1:	c9                   	leave  
801010f2:	c3                   	ret    

801010f3 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
801010f3:	55                   	push   %ebp
801010f4:	89 e5                	mov    %esp,%ebp
801010f6:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
801010f9:	8b 45 08             	mov    0x8(%ebp),%eax
801010fc:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101100:	84 c0                	test   %al,%al
80101102:	75 0a                	jne    8010110e <fileread+0x1b>
    return -1;
80101104:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101109:	e9 9f 00 00 00       	jmp    801011ad <fileread+0xba>
  if(f->type == FD_PIPE)
8010110e:	8b 45 08             	mov    0x8(%ebp),%eax
80101111:	8b 00                	mov    (%eax),%eax
80101113:	83 f8 01             	cmp    $0x1,%eax
80101116:	75 1e                	jne    80101136 <fileread+0x43>
    return piperead(f->pipe, addr, n);
80101118:	8b 45 08             	mov    0x8(%ebp),%eax
8010111b:	8b 40 0c             	mov    0xc(%eax),%eax
8010111e:	8b 55 10             	mov    0x10(%ebp),%edx
80101121:	89 54 24 08          	mov    %edx,0x8(%esp)
80101125:	8b 55 0c             	mov    0xc(%ebp),%edx
80101128:	89 54 24 04          	mov    %edx,0x4(%esp)
8010112c:	89 04 24             	mov    %eax,(%esp)
8010112f:	e8 d1 31 00 00       	call   80104305 <piperead>
80101134:	eb 77                	jmp    801011ad <fileread+0xba>
  if(f->type == FD_INODE){
80101136:	8b 45 08             	mov    0x8(%ebp),%eax
80101139:	8b 00                	mov    (%eax),%eax
8010113b:	83 f8 02             	cmp    $0x2,%eax
8010113e:	75 61                	jne    801011a1 <fileread+0xae>
    ilock(f->ip);
80101140:	8b 45 08             	mov    0x8(%ebp),%eax
80101143:	8b 40 10             	mov    0x10(%eax),%eax
80101146:	89 04 24             	mov    %eax,(%esp)
80101149:	e8 0d 07 00 00       	call   8010185b <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
8010114e:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101151:	8b 45 08             	mov    0x8(%ebp),%eax
80101154:	8b 50 14             	mov    0x14(%eax),%edx
80101157:	8b 45 08             	mov    0x8(%ebp),%eax
8010115a:	8b 40 10             	mov    0x10(%eax),%eax
8010115d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101161:	89 54 24 08          	mov    %edx,0x8(%esp)
80101165:	8b 55 0c             	mov    0xc(%ebp),%edx
80101168:	89 54 24 04          	mov    %edx,0x4(%esp)
8010116c:	89 04 24             	mov    %eax,(%esp)
8010116f:	e8 f4 0b 00 00       	call   80101d68 <readi>
80101174:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101177:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010117b:	7e 11                	jle    8010118e <fileread+0x9b>
      f->off += r;
8010117d:	8b 45 08             	mov    0x8(%ebp),%eax
80101180:	8b 50 14             	mov    0x14(%eax),%edx
80101183:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101186:	01 c2                	add    %eax,%edx
80101188:	8b 45 08             	mov    0x8(%ebp),%eax
8010118b:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
8010118e:	8b 45 08             	mov    0x8(%ebp),%eax
80101191:	8b 40 10             	mov    0x10(%eax),%eax
80101194:	89 04 24             	mov    %eax,(%esp)
80101197:	e8 0d 08 00 00       	call   801019a9 <iunlock>
    return r;
8010119c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010119f:	eb 0c                	jmp    801011ad <fileread+0xba>
  }
  panic("fileread");
801011a1:	c7 04 24 de 87 10 80 	movl   $0x801087de,(%esp)
801011a8:	e8 8d f3 ff ff       	call   8010053a <panic>
}
801011ad:	c9                   	leave  
801011ae:	c3                   	ret    

801011af <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
801011af:	55                   	push   %ebp
801011b0:	89 e5                	mov    %esp,%ebp
801011b2:	53                   	push   %ebx
801011b3:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
801011b6:	8b 45 08             	mov    0x8(%ebp),%eax
801011b9:	0f b6 40 09          	movzbl 0x9(%eax),%eax
801011bd:	84 c0                	test   %al,%al
801011bf:	75 0a                	jne    801011cb <filewrite+0x1c>
    return -1;
801011c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801011c6:	e9 20 01 00 00       	jmp    801012eb <filewrite+0x13c>
  if(f->type == FD_PIPE)
801011cb:	8b 45 08             	mov    0x8(%ebp),%eax
801011ce:	8b 00                	mov    (%eax),%eax
801011d0:	83 f8 01             	cmp    $0x1,%eax
801011d3:	75 21                	jne    801011f6 <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
801011d5:	8b 45 08             	mov    0x8(%ebp),%eax
801011d8:	8b 40 0c             	mov    0xc(%eax),%eax
801011db:	8b 55 10             	mov    0x10(%ebp),%edx
801011de:	89 54 24 08          	mov    %edx,0x8(%esp)
801011e2:	8b 55 0c             	mov    0xc(%ebp),%edx
801011e5:	89 54 24 04          	mov    %edx,0x4(%esp)
801011e9:	89 04 24             	mov    %eax,(%esp)
801011ec:	e8 25 30 00 00       	call   80104216 <pipewrite>
801011f1:	e9 f5 00 00 00       	jmp    801012eb <filewrite+0x13c>
  if(f->type == FD_INODE){
801011f6:	8b 45 08             	mov    0x8(%ebp),%eax
801011f9:	8b 00                	mov    (%eax),%eax
801011fb:	83 f8 02             	cmp    $0x2,%eax
801011fe:	0f 85 db 00 00 00    	jne    801012df <filewrite+0x130>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
80101204:	c7 45 ec 00 1a 00 00 	movl   $0x1a00,-0x14(%ebp)
    int i = 0;
8010120b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
80101212:	e9 a8 00 00 00       	jmp    801012bf <filewrite+0x110>
      int n1 = n - i;
80101217:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010121a:	8b 55 10             	mov    0x10(%ebp),%edx
8010121d:	29 c2                	sub    %eax,%edx
8010121f:	89 d0                	mov    %edx,%eax
80101221:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
80101224:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101227:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010122a:	7e 06                	jle    80101232 <filewrite+0x83>
        n1 = max;
8010122c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010122f:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_op();
80101232:	e8 f4 22 00 00       	call   8010352b <begin_op>
      ilock(f->ip);
80101237:	8b 45 08             	mov    0x8(%ebp),%eax
8010123a:	8b 40 10             	mov    0x10(%eax),%eax
8010123d:	89 04 24             	mov    %eax,(%esp)
80101240:	e8 16 06 00 00       	call   8010185b <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80101245:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80101248:	8b 45 08             	mov    0x8(%ebp),%eax
8010124b:	8b 50 14             	mov    0x14(%eax),%edx
8010124e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
80101251:	8b 45 0c             	mov    0xc(%ebp),%eax
80101254:	01 c3                	add    %eax,%ebx
80101256:	8b 45 08             	mov    0x8(%ebp),%eax
80101259:	8b 40 10             	mov    0x10(%eax),%eax
8010125c:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101260:	89 54 24 08          	mov    %edx,0x8(%esp)
80101264:	89 5c 24 04          	mov    %ebx,0x4(%esp)
80101268:	89 04 24             	mov    %eax,(%esp)
8010126b:	e8 69 0c 00 00       	call   80101ed9 <writei>
80101270:	89 45 e8             	mov    %eax,-0x18(%ebp)
80101273:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101277:	7e 11                	jle    8010128a <filewrite+0xdb>
        f->off += r;
80101279:	8b 45 08             	mov    0x8(%ebp),%eax
8010127c:	8b 50 14             	mov    0x14(%eax),%edx
8010127f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101282:	01 c2                	add    %eax,%edx
80101284:	8b 45 08             	mov    0x8(%ebp),%eax
80101287:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
8010128a:	8b 45 08             	mov    0x8(%ebp),%eax
8010128d:	8b 40 10             	mov    0x10(%eax),%eax
80101290:	89 04 24             	mov    %eax,(%esp)
80101293:	e8 11 07 00 00       	call   801019a9 <iunlock>
      end_op();
80101298:	e8 12 23 00 00       	call   801035af <end_op>

      if(r < 0)
8010129d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801012a1:	79 02                	jns    801012a5 <filewrite+0xf6>
        break;
801012a3:	eb 26                	jmp    801012cb <filewrite+0x11c>
      if(r != n1)
801012a5:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012a8:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012ab:	74 0c                	je     801012b9 <filewrite+0x10a>
        panic("short filewrite");
801012ad:	c7 04 24 e7 87 10 80 	movl   $0x801087e7,(%esp)
801012b4:	e8 81 f2 ff ff       	call   8010053a <panic>
      i += r;
801012b9:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012bc:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
801012bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012c2:	3b 45 10             	cmp    0x10(%ebp),%eax
801012c5:	0f 8c 4c ff ff ff    	jl     80101217 <filewrite+0x68>
        break;
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
801012cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012ce:	3b 45 10             	cmp    0x10(%ebp),%eax
801012d1:	75 05                	jne    801012d8 <filewrite+0x129>
801012d3:	8b 45 10             	mov    0x10(%ebp),%eax
801012d6:	eb 05                	jmp    801012dd <filewrite+0x12e>
801012d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801012dd:	eb 0c                	jmp    801012eb <filewrite+0x13c>
  }
  panic("filewrite");
801012df:	c7 04 24 f7 87 10 80 	movl   $0x801087f7,(%esp)
801012e6:	e8 4f f2 ff ff       	call   8010053a <panic>
}
801012eb:	83 c4 24             	add    $0x24,%esp
801012ee:	5b                   	pop    %ebx
801012ef:	5d                   	pop    %ebp
801012f0:	c3                   	ret    

801012f1 <readsb>:
static void itrunc(struct inode*);

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
801012f1:	55                   	push   %ebp
801012f2:	89 e5                	mov    %esp,%ebp
801012f4:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
801012f7:	8b 45 08             	mov    0x8(%ebp),%eax
801012fa:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80101301:	00 
80101302:	89 04 24             	mov    %eax,(%esp)
80101305:	e8 9c ee ff ff       	call   801001a6 <bread>
8010130a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
8010130d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101310:	83 c0 18             	add    $0x18,%eax
80101313:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010131a:	00 
8010131b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010131f:	8b 45 0c             	mov    0xc(%ebp),%eax
80101322:	89 04 24             	mov    %eax,(%esp)
80101325:	e8 35 41 00 00       	call   8010545f <memmove>
  brelse(bp);
8010132a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010132d:	89 04 24             	mov    %eax,(%esp)
80101330:	e8 e2 ee ff ff       	call   80100217 <brelse>
}
80101335:	c9                   	leave  
80101336:	c3                   	ret    

80101337 <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80101337:	55                   	push   %ebp
80101338:	89 e5                	mov    %esp,%ebp
8010133a:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
8010133d:	8b 55 0c             	mov    0xc(%ebp),%edx
80101340:	8b 45 08             	mov    0x8(%ebp),%eax
80101343:	89 54 24 04          	mov    %edx,0x4(%esp)
80101347:	89 04 24             	mov    %eax,(%esp)
8010134a:	e8 57 ee ff ff       	call   801001a6 <bread>
8010134f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
80101352:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101355:	83 c0 18             	add    $0x18,%eax
80101358:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010135f:	00 
80101360:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101367:	00 
80101368:	89 04 24             	mov    %eax,(%esp)
8010136b:	e8 20 40 00 00       	call   80105390 <memset>
  log_write(bp);
80101370:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101373:	89 04 24             	mov    %eax,(%esp)
80101376:	e8 bb 23 00 00       	call   80103736 <log_write>
  brelse(bp);
8010137b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010137e:	89 04 24             	mov    %eax,(%esp)
80101381:	e8 91 ee ff ff       	call   80100217 <brelse>
}
80101386:	c9                   	leave  
80101387:	c3                   	ret    

80101388 <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
80101388:	55                   	push   %ebp
80101389:	89 e5                	mov    %esp,%ebp
8010138b:	83 ec 38             	sub    $0x38,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
8010138e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
80101395:	8b 45 08             	mov    0x8(%ebp),%eax
80101398:	8d 55 d8             	lea    -0x28(%ebp),%edx
8010139b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010139f:	89 04 24             	mov    %eax,(%esp)
801013a2:	e8 4a ff ff ff       	call   801012f1 <readsb>
  for(b = 0; b < sb.size; b += BPB){
801013a7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801013ae:	e9 07 01 00 00       	jmp    801014ba <balloc+0x132>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
801013b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013b6:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
801013bc:	85 c0                	test   %eax,%eax
801013be:	0f 48 c2             	cmovs  %edx,%eax
801013c1:	c1 f8 0c             	sar    $0xc,%eax
801013c4:	8b 55 e0             	mov    -0x20(%ebp),%edx
801013c7:	c1 ea 03             	shr    $0x3,%edx
801013ca:	01 d0                	add    %edx,%eax
801013cc:	83 c0 03             	add    $0x3,%eax
801013cf:	89 44 24 04          	mov    %eax,0x4(%esp)
801013d3:	8b 45 08             	mov    0x8(%ebp),%eax
801013d6:	89 04 24             	mov    %eax,(%esp)
801013d9:	e8 c8 ed ff ff       	call   801001a6 <bread>
801013de:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801013e1:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801013e8:	e9 9d 00 00 00       	jmp    8010148a <balloc+0x102>
      m = 1 << (bi % 8);
801013ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
801013f0:	99                   	cltd   
801013f1:	c1 ea 1d             	shr    $0x1d,%edx
801013f4:	01 d0                	add    %edx,%eax
801013f6:	83 e0 07             	and    $0x7,%eax
801013f9:	29 d0                	sub    %edx,%eax
801013fb:	ba 01 00 00 00       	mov    $0x1,%edx
80101400:	89 c1                	mov    %eax,%ecx
80101402:	d3 e2                	shl    %cl,%edx
80101404:	89 d0                	mov    %edx,%eax
80101406:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
80101409:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010140c:	8d 50 07             	lea    0x7(%eax),%edx
8010140f:	85 c0                	test   %eax,%eax
80101411:	0f 48 c2             	cmovs  %edx,%eax
80101414:	c1 f8 03             	sar    $0x3,%eax
80101417:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010141a:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
8010141f:	0f b6 c0             	movzbl %al,%eax
80101422:	23 45 e8             	and    -0x18(%ebp),%eax
80101425:	85 c0                	test   %eax,%eax
80101427:	75 5d                	jne    80101486 <balloc+0xfe>
        bp->data[bi/8] |= m;  // Mark block in use.
80101429:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010142c:	8d 50 07             	lea    0x7(%eax),%edx
8010142f:	85 c0                	test   %eax,%eax
80101431:	0f 48 c2             	cmovs  %edx,%eax
80101434:	c1 f8 03             	sar    $0x3,%eax
80101437:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010143a:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
8010143f:	89 d1                	mov    %edx,%ecx
80101441:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101444:	09 ca                	or     %ecx,%edx
80101446:	89 d1                	mov    %edx,%ecx
80101448:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010144b:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
8010144f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101452:	89 04 24             	mov    %eax,(%esp)
80101455:	e8 dc 22 00 00       	call   80103736 <log_write>
        brelse(bp);
8010145a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010145d:	89 04 24             	mov    %eax,(%esp)
80101460:	e8 b2 ed ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
80101465:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101468:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010146b:	01 c2                	add    %eax,%edx
8010146d:	8b 45 08             	mov    0x8(%ebp),%eax
80101470:	89 54 24 04          	mov    %edx,0x4(%esp)
80101474:	89 04 24             	mov    %eax,(%esp)
80101477:	e8 bb fe ff ff       	call   80101337 <bzero>
        return b + bi;
8010147c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010147f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101482:	01 d0                	add    %edx,%eax
80101484:	eb 4e                	jmp    801014d4 <balloc+0x14c>

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101486:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010148a:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
80101491:	7f 15                	jg     801014a8 <balloc+0x120>
80101493:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101496:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101499:	01 d0                	add    %edx,%eax
8010149b:	89 c2                	mov    %eax,%edx
8010149d:	8b 45 d8             	mov    -0x28(%ebp),%eax
801014a0:	39 c2                	cmp    %eax,%edx
801014a2:	0f 82 45 ff ff ff    	jb     801013ed <balloc+0x65>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
801014a8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801014ab:	89 04 24             	mov    %eax,(%esp)
801014ae:	e8 64 ed ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
801014b3:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801014ba:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014bd:	8b 45 d8             	mov    -0x28(%ebp),%eax
801014c0:	39 c2                	cmp    %eax,%edx
801014c2:	0f 82 eb fe ff ff    	jb     801013b3 <balloc+0x2b>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
801014c8:	c7 04 24 01 88 10 80 	movl   $0x80108801,(%esp)
801014cf:	e8 66 f0 ff ff       	call   8010053a <panic>
}
801014d4:	c9                   	leave  
801014d5:	c3                   	ret    

801014d6 <bfree>:

// Free a disk block.
static void
bfree(int dev, uint b)
{
801014d6:	55                   	push   %ebp
801014d7:	89 e5                	mov    %esp,%ebp
801014d9:	83 ec 38             	sub    $0x38,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
801014dc:	8d 45 dc             	lea    -0x24(%ebp),%eax
801014df:	89 44 24 04          	mov    %eax,0x4(%esp)
801014e3:	8b 45 08             	mov    0x8(%ebp),%eax
801014e6:	89 04 24             	mov    %eax,(%esp)
801014e9:	e8 03 fe ff ff       	call   801012f1 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
801014ee:	8b 45 0c             	mov    0xc(%ebp),%eax
801014f1:	c1 e8 0c             	shr    $0xc,%eax
801014f4:	89 c2                	mov    %eax,%edx
801014f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801014f9:	c1 e8 03             	shr    $0x3,%eax
801014fc:	01 d0                	add    %edx,%eax
801014fe:	8d 50 03             	lea    0x3(%eax),%edx
80101501:	8b 45 08             	mov    0x8(%ebp),%eax
80101504:	89 54 24 04          	mov    %edx,0x4(%esp)
80101508:	89 04 24             	mov    %eax,(%esp)
8010150b:	e8 96 ec ff ff       	call   801001a6 <bread>
80101510:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80101513:	8b 45 0c             	mov    0xc(%ebp),%eax
80101516:	25 ff 0f 00 00       	and    $0xfff,%eax
8010151b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
8010151e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101521:	99                   	cltd   
80101522:	c1 ea 1d             	shr    $0x1d,%edx
80101525:	01 d0                	add    %edx,%eax
80101527:	83 e0 07             	and    $0x7,%eax
8010152a:	29 d0                	sub    %edx,%eax
8010152c:	ba 01 00 00 00       	mov    $0x1,%edx
80101531:	89 c1                	mov    %eax,%ecx
80101533:	d3 e2                	shl    %cl,%edx
80101535:	89 d0                	mov    %edx,%eax
80101537:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
8010153a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010153d:	8d 50 07             	lea    0x7(%eax),%edx
80101540:	85 c0                	test   %eax,%eax
80101542:	0f 48 c2             	cmovs  %edx,%eax
80101545:	c1 f8 03             	sar    $0x3,%eax
80101548:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010154b:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101550:	0f b6 c0             	movzbl %al,%eax
80101553:	23 45 ec             	and    -0x14(%ebp),%eax
80101556:	85 c0                	test   %eax,%eax
80101558:	75 0c                	jne    80101566 <bfree+0x90>
    panic("freeing free block");
8010155a:	c7 04 24 17 88 10 80 	movl   $0x80108817,(%esp)
80101561:	e8 d4 ef ff ff       	call   8010053a <panic>
  bp->data[bi/8] &= ~m;
80101566:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101569:	8d 50 07             	lea    0x7(%eax),%edx
8010156c:	85 c0                	test   %eax,%eax
8010156e:	0f 48 c2             	cmovs  %edx,%eax
80101571:	c1 f8 03             	sar    $0x3,%eax
80101574:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101577:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
8010157c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
8010157f:	f7 d1                	not    %ecx
80101581:	21 ca                	and    %ecx,%edx
80101583:	89 d1                	mov    %edx,%ecx
80101585:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101588:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
8010158c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010158f:	89 04 24             	mov    %eax,(%esp)
80101592:	e8 9f 21 00 00       	call   80103736 <log_write>
  brelse(bp);
80101597:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010159a:	89 04 24             	mov    %eax,(%esp)
8010159d:	e8 75 ec ff ff       	call   80100217 <brelse>
}
801015a2:	c9                   	leave  
801015a3:	c3                   	ret    

801015a4 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
801015a4:	55                   	push   %ebp
801015a5:	89 e5                	mov    %esp,%ebp
801015a7:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
801015aa:	c7 44 24 04 2a 88 10 	movl   $0x8010882a,0x4(%esp)
801015b1:	80 
801015b2:	c7 04 24 80 12 11 80 	movl   $0x80111280,(%esp)
801015b9:	e8 5d 3b 00 00       	call   8010511b <initlock>
}
801015be:	c9                   	leave  
801015bf:	c3                   	ret    

801015c0 <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
801015c0:	55                   	push   %ebp
801015c1:	89 e5                	mov    %esp,%ebp
801015c3:	83 ec 38             	sub    $0x38,%esp
801015c6:	8b 45 0c             	mov    0xc(%ebp),%eax
801015c9:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
801015cd:	8b 45 08             	mov    0x8(%ebp),%eax
801015d0:	8d 55 dc             	lea    -0x24(%ebp),%edx
801015d3:	89 54 24 04          	mov    %edx,0x4(%esp)
801015d7:	89 04 24             	mov    %eax,(%esp)
801015da:	e8 12 fd ff ff       	call   801012f1 <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
801015df:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
801015e6:	e9 98 00 00 00       	jmp    80101683 <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
801015eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015ee:	c1 e8 03             	shr    $0x3,%eax
801015f1:	83 c0 02             	add    $0x2,%eax
801015f4:	89 44 24 04          	mov    %eax,0x4(%esp)
801015f8:	8b 45 08             	mov    0x8(%ebp),%eax
801015fb:	89 04 24             	mov    %eax,(%esp)
801015fe:	e8 a3 eb ff ff       	call   801001a6 <bread>
80101603:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80101606:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101609:	8d 50 18             	lea    0x18(%eax),%edx
8010160c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010160f:	83 e0 07             	and    $0x7,%eax
80101612:	c1 e0 06             	shl    $0x6,%eax
80101615:	01 d0                	add    %edx,%eax
80101617:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
8010161a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010161d:	0f b7 00             	movzwl (%eax),%eax
80101620:	66 85 c0             	test   %ax,%ax
80101623:	75 4f                	jne    80101674 <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
80101625:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
8010162c:	00 
8010162d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101634:	00 
80101635:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101638:	89 04 24             	mov    %eax,(%esp)
8010163b:	e8 50 3d 00 00       	call   80105390 <memset>
      dip->type = type;
80101640:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101643:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
80101647:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
8010164a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010164d:	89 04 24             	mov    %eax,(%esp)
80101650:	e8 e1 20 00 00       	call   80103736 <log_write>
      brelse(bp);
80101655:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101658:	89 04 24             	mov    %eax,(%esp)
8010165b:	e8 b7 eb ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
80101660:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101663:	89 44 24 04          	mov    %eax,0x4(%esp)
80101667:	8b 45 08             	mov    0x8(%ebp),%eax
8010166a:	89 04 24             	mov    %eax,(%esp)
8010166d:	e8 e5 00 00 00       	call   80101757 <iget>
80101672:	eb 29                	jmp    8010169d <ialloc+0xdd>
    }
    brelse(bp);
80101674:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101677:	89 04 24             	mov    %eax,(%esp)
8010167a:	e8 98 eb ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
8010167f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101683:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101686:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101689:	39 c2                	cmp    %eax,%edx
8010168b:	0f 82 5a ff ff ff    	jb     801015eb <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
80101691:	c7 04 24 31 88 10 80 	movl   $0x80108831,(%esp)
80101698:	e8 9d ee ff ff       	call   8010053a <panic>
}
8010169d:	c9                   	leave  
8010169e:	c3                   	ret    

8010169f <iupdate>:

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
8010169f:	55                   	push   %ebp
801016a0:	89 e5                	mov    %esp,%ebp
801016a2:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
801016a5:	8b 45 08             	mov    0x8(%ebp),%eax
801016a8:	8b 40 04             	mov    0x4(%eax),%eax
801016ab:	c1 e8 03             	shr    $0x3,%eax
801016ae:	8d 50 02             	lea    0x2(%eax),%edx
801016b1:	8b 45 08             	mov    0x8(%ebp),%eax
801016b4:	8b 00                	mov    (%eax),%eax
801016b6:	89 54 24 04          	mov    %edx,0x4(%esp)
801016ba:	89 04 24             	mov    %eax,(%esp)
801016bd:	e8 e4 ea ff ff       	call   801001a6 <bread>
801016c2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
801016c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016c8:	8d 50 18             	lea    0x18(%eax),%edx
801016cb:	8b 45 08             	mov    0x8(%ebp),%eax
801016ce:	8b 40 04             	mov    0x4(%eax),%eax
801016d1:	83 e0 07             	and    $0x7,%eax
801016d4:	c1 e0 06             	shl    $0x6,%eax
801016d7:	01 d0                	add    %edx,%eax
801016d9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
801016dc:	8b 45 08             	mov    0x8(%ebp),%eax
801016df:	0f b7 50 10          	movzwl 0x10(%eax),%edx
801016e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016e6:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
801016e9:	8b 45 08             	mov    0x8(%ebp),%eax
801016ec:	0f b7 50 12          	movzwl 0x12(%eax),%edx
801016f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016f3:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
801016f7:	8b 45 08             	mov    0x8(%ebp),%eax
801016fa:	0f b7 50 14          	movzwl 0x14(%eax),%edx
801016fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101701:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101705:	8b 45 08             	mov    0x8(%ebp),%eax
80101708:	0f b7 50 16          	movzwl 0x16(%eax),%edx
8010170c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010170f:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
80101713:	8b 45 08             	mov    0x8(%ebp),%eax
80101716:	8b 50 18             	mov    0x18(%eax),%edx
80101719:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010171c:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
8010171f:	8b 45 08             	mov    0x8(%ebp),%eax
80101722:	8d 50 1c             	lea    0x1c(%eax),%edx
80101725:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101728:	83 c0 0c             	add    $0xc,%eax
8010172b:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101732:	00 
80101733:	89 54 24 04          	mov    %edx,0x4(%esp)
80101737:	89 04 24             	mov    %eax,(%esp)
8010173a:	e8 20 3d 00 00       	call   8010545f <memmove>
  log_write(bp);
8010173f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101742:	89 04 24             	mov    %eax,(%esp)
80101745:	e8 ec 1f 00 00       	call   80103736 <log_write>
  brelse(bp);
8010174a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010174d:	89 04 24             	mov    %eax,(%esp)
80101750:	e8 c2 ea ff ff       	call   80100217 <brelse>
}
80101755:	c9                   	leave  
80101756:	c3                   	ret    

80101757 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
80101757:	55                   	push   %ebp
80101758:	89 e5                	mov    %esp,%ebp
8010175a:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
8010175d:	c7 04 24 80 12 11 80 	movl   $0x80111280,(%esp)
80101764:	e8 d3 39 00 00       	call   8010513c <acquire>

  // Is the inode already cached?
  empty = 0;
80101769:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101770:	c7 45 f4 b4 12 11 80 	movl   $0x801112b4,-0xc(%ebp)
80101777:	eb 59                	jmp    801017d2 <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
80101779:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010177c:	8b 40 08             	mov    0x8(%eax),%eax
8010177f:	85 c0                	test   %eax,%eax
80101781:	7e 35                	jle    801017b8 <iget+0x61>
80101783:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101786:	8b 00                	mov    (%eax),%eax
80101788:	3b 45 08             	cmp    0x8(%ebp),%eax
8010178b:	75 2b                	jne    801017b8 <iget+0x61>
8010178d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101790:	8b 40 04             	mov    0x4(%eax),%eax
80101793:	3b 45 0c             	cmp    0xc(%ebp),%eax
80101796:	75 20                	jne    801017b8 <iget+0x61>
      ip->ref++;
80101798:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010179b:	8b 40 08             	mov    0x8(%eax),%eax
8010179e:	8d 50 01             	lea    0x1(%eax),%edx
801017a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017a4:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
801017a7:	c7 04 24 80 12 11 80 	movl   $0x80111280,(%esp)
801017ae:	e8 eb 39 00 00       	call   8010519e <release>
      return ip;
801017b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017b6:	eb 6f                	jmp    80101827 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801017b8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801017bc:	75 10                	jne    801017ce <iget+0x77>
801017be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017c1:	8b 40 08             	mov    0x8(%eax),%eax
801017c4:	85 c0                	test   %eax,%eax
801017c6:	75 06                	jne    801017ce <iget+0x77>
      empty = ip;
801017c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017cb:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801017ce:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
801017d2:	81 7d f4 54 22 11 80 	cmpl   $0x80112254,-0xc(%ebp)
801017d9:	72 9e                	jb     80101779 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
801017db:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801017df:	75 0c                	jne    801017ed <iget+0x96>
    panic("iget: no inodes");
801017e1:	c7 04 24 43 88 10 80 	movl   $0x80108843,(%esp)
801017e8:	e8 4d ed ff ff       	call   8010053a <panic>

  ip = empty;
801017ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017f0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
801017f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017f6:	8b 55 08             	mov    0x8(%ebp),%edx
801017f9:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
801017fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017fe:	8b 55 0c             	mov    0xc(%ebp),%edx
80101801:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80101804:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101807:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
8010180e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101811:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
80101818:	c7 04 24 80 12 11 80 	movl   $0x80111280,(%esp)
8010181f:	e8 7a 39 00 00       	call   8010519e <release>

  return ip;
80101824:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80101827:	c9                   	leave  
80101828:	c3                   	ret    

80101829 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
80101829:	55                   	push   %ebp
8010182a:	89 e5                	mov    %esp,%ebp
8010182c:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
8010182f:	c7 04 24 80 12 11 80 	movl   $0x80111280,(%esp)
80101836:	e8 01 39 00 00       	call   8010513c <acquire>
  ip->ref++;
8010183b:	8b 45 08             	mov    0x8(%ebp),%eax
8010183e:	8b 40 08             	mov    0x8(%eax),%eax
80101841:	8d 50 01             	lea    0x1(%eax),%edx
80101844:	8b 45 08             	mov    0x8(%ebp),%eax
80101847:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
8010184a:	c7 04 24 80 12 11 80 	movl   $0x80111280,(%esp)
80101851:	e8 48 39 00 00       	call   8010519e <release>
  return ip;
80101856:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101859:	c9                   	leave  
8010185a:	c3                   	ret    

8010185b <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
8010185b:	55                   	push   %ebp
8010185c:	89 e5                	mov    %esp,%ebp
8010185e:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
80101861:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101865:	74 0a                	je     80101871 <ilock+0x16>
80101867:	8b 45 08             	mov    0x8(%ebp),%eax
8010186a:	8b 40 08             	mov    0x8(%eax),%eax
8010186d:	85 c0                	test   %eax,%eax
8010186f:	7f 0c                	jg     8010187d <ilock+0x22>
    panic("ilock");
80101871:	c7 04 24 53 88 10 80 	movl   $0x80108853,(%esp)
80101878:	e8 bd ec ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
8010187d:	c7 04 24 80 12 11 80 	movl   $0x80111280,(%esp)
80101884:	e8 b3 38 00 00       	call   8010513c <acquire>
  while(ip->flags & I_BUSY)
80101889:	eb 13                	jmp    8010189e <ilock+0x43>
    sleep(ip, &icache.lock);
8010188b:	c7 44 24 04 80 12 11 	movl   $0x80111280,0x4(%esp)
80101892:	80 
80101893:	8b 45 08             	mov    0x8(%ebp),%eax
80101896:	89 04 24             	mov    %eax,(%esp)
80101899:	e8 a2 33 00 00       	call   80104c40 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
8010189e:	8b 45 08             	mov    0x8(%ebp),%eax
801018a1:	8b 40 0c             	mov    0xc(%eax),%eax
801018a4:	83 e0 01             	and    $0x1,%eax
801018a7:	85 c0                	test   %eax,%eax
801018a9:	75 e0                	jne    8010188b <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
801018ab:	8b 45 08             	mov    0x8(%ebp),%eax
801018ae:	8b 40 0c             	mov    0xc(%eax),%eax
801018b1:	83 c8 01             	or     $0x1,%eax
801018b4:	89 c2                	mov    %eax,%edx
801018b6:	8b 45 08             	mov    0x8(%ebp),%eax
801018b9:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
801018bc:	c7 04 24 80 12 11 80 	movl   $0x80111280,(%esp)
801018c3:	e8 d6 38 00 00       	call   8010519e <release>

  if(!(ip->flags & I_VALID)){
801018c8:	8b 45 08             	mov    0x8(%ebp),%eax
801018cb:	8b 40 0c             	mov    0xc(%eax),%eax
801018ce:	83 e0 02             	and    $0x2,%eax
801018d1:	85 c0                	test   %eax,%eax
801018d3:	0f 85 ce 00 00 00    	jne    801019a7 <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
801018d9:	8b 45 08             	mov    0x8(%ebp),%eax
801018dc:	8b 40 04             	mov    0x4(%eax),%eax
801018df:	c1 e8 03             	shr    $0x3,%eax
801018e2:	8d 50 02             	lea    0x2(%eax),%edx
801018e5:	8b 45 08             	mov    0x8(%ebp),%eax
801018e8:	8b 00                	mov    (%eax),%eax
801018ea:	89 54 24 04          	mov    %edx,0x4(%esp)
801018ee:	89 04 24             	mov    %eax,(%esp)
801018f1:	e8 b0 e8 ff ff       	call   801001a6 <bread>
801018f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
801018f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018fc:	8d 50 18             	lea    0x18(%eax),%edx
801018ff:	8b 45 08             	mov    0x8(%ebp),%eax
80101902:	8b 40 04             	mov    0x4(%eax),%eax
80101905:	83 e0 07             	and    $0x7,%eax
80101908:	c1 e0 06             	shl    $0x6,%eax
8010190b:	01 d0                	add    %edx,%eax
8010190d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80101910:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101913:	0f b7 10             	movzwl (%eax),%edx
80101916:	8b 45 08             	mov    0x8(%ebp),%eax
80101919:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
8010191d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101920:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101924:	8b 45 08             	mov    0x8(%ebp),%eax
80101927:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
8010192b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010192e:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101932:	8b 45 08             	mov    0x8(%ebp),%eax
80101935:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
80101939:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010193c:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101940:	8b 45 08             	mov    0x8(%ebp),%eax
80101943:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
80101947:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010194a:	8b 50 08             	mov    0x8(%eax),%edx
8010194d:	8b 45 08             	mov    0x8(%ebp),%eax
80101950:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101953:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101956:	8d 50 0c             	lea    0xc(%eax),%edx
80101959:	8b 45 08             	mov    0x8(%ebp),%eax
8010195c:	83 c0 1c             	add    $0x1c,%eax
8010195f:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101966:	00 
80101967:	89 54 24 04          	mov    %edx,0x4(%esp)
8010196b:	89 04 24             	mov    %eax,(%esp)
8010196e:	e8 ec 3a 00 00       	call   8010545f <memmove>
    brelse(bp);
80101973:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101976:	89 04 24             	mov    %eax,(%esp)
80101979:	e8 99 e8 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
8010197e:	8b 45 08             	mov    0x8(%ebp),%eax
80101981:	8b 40 0c             	mov    0xc(%eax),%eax
80101984:	83 c8 02             	or     $0x2,%eax
80101987:	89 c2                	mov    %eax,%edx
80101989:	8b 45 08             	mov    0x8(%ebp),%eax
8010198c:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
8010198f:	8b 45 08             	mov    0x8(%ebp),%eax
80101992:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101996:	66 85 c0             	test   %ax,%ax
80101999:	75 0c                	jne    801019a7 <ilock+0x14c>
      panic("ilock: no type");
8010199b:	c7 04 24 59 88 10 80 	movl   $0x80108859,(%esp)
801019a2:	e8 93 eb ff ff       	call   8010053a <panic>
  }
}
801019a7:	c9                   	leave  
801019a8:	c3                   	ret    

801019a9 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
801019a9:	55                   	push   %ebp
801019aa:	89 e5                	mov    %esp,%ebp
801019ac:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
801019af:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801019b3:	74 17                	je     801019cc <iunlock+0x23>
801019b5:	8b 45 08             	mov    0x8(%ebp),%eax
801019b8:	8b 40 0c             	mov    0xc(%eax),%eax
801019bb:	83 e0 01             	and    $0x1,%eax
801019be:	85 c0                	test   %eax,%eax
801019c0:	74 0a                	je     801019cc <iunlock+0x23>
801019c2:	8b 45 08             	mov    0x8(%ebp),%eax
801019c5:	8b 40 08             	mov    0x8(%eax),%eax
801019c8:	85 c0                	test   %eax,%eax
801019ca:	7f 0c                	jg     801019d8 <iunlock+0x2f>
    panic("iunlock");
801019cc:	c7 04 24 68 88 10 80 	movl   $0x80108868,(%esp)
801019d3:	e8 62 eb ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
801019d8:	c7 04 24 80 12 11 80 	movl   $0x80111280,(%esp)
801019df:	e8 58 37 00 00       	call   8010513c <acquire>
  ip->flags &= ~I_BUSY;
801019e4:	8b 45 08             	mov    0x8(%ebp),%eax
801019e7:	8b 40 0c             	mov    0xc(%eax),%eax
801019ea:	83 e0 fe             	and    $0xfffffffe,%eax
801019ed:	89 c2                	mov    %eax,%edx
801019ef:	8b 45 08             	mov    0x8(%ebp),%eax
801019f2:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
801019f5:	8b 45 08             	mov    0x8(%ebp),%eax
801019f8:	89 04 24             	mov    %eax,(%esp)
801019fb:	e8 19 33 00 00       	call   80104d19 <wakeup>
  release(&icache.lock);
80101a00:	c7 04 24 80 12 11 80 	movl   $0x80111280,(%esp)
80101a07:	e8 92 37 00 00       	call   8010519e <release>
}
80101a0c:	c9                   	leave  
80101a0d:	c3                   	ret    

80101a0e <iput>:
// to it, free the inode (and its content) on disk.
// All calls to iput() must be inside a transaction in
// case it has to free the inode.
void
iput(struct inode *ip)
{
80101a0e:	55                   	push   %ebp
80101a0f:	89 e5                	mov    %esp,%ebp
80101a11:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101a14:	c7 04 24 80 12 11 80 	movl   $0x80111280,(%esp)
80101a1b:	e8 1c 37 00 00       	call   8010513c <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101a20:	8b 45 08             	mov    0x8(%ebp),%eax
80101a23:	8b 40 08             	mov    0x8(%eax),%eax
80101a26:	83 f8 01             	cmp    $0x1,%eax
80101a29:	0f 85 93 00 00 00    	jne    80101ac2 <iput+0xb4>
80101a2f:	8b 45 08             	mov    0x8(%ebp),%eax
80101a32:	8b 40 0c             	mov    0xc(%eax),%eax
80101a35:	83 e0 02             	and    $0x2,%eax
80101a38:	85 c0                	test   %eax,%eax
80101a3a:	0f 84 82 00 00 00    	je     80101ac2 <iput+0xb4>
80101a40:	8b 45 08             	mov    0x8(%ebp),%eax
80101a43:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101a47:	66 85 c0             	test   %ax,%ax
80101a4a:	75 76                	jne    80101ac2 <iput+0xb4>
    // inode has no links and no other references: truncate and free.
    if(ip->flags & I_BUSY)
80101a4c:	8b 45 08             	mov    0x8(%ebp),%eax
80101a4f:	8b 40 0c             	mov    0xc(%eax),%eax
80101a52:	83 e0 01             	and    $0x1,%eax
80101a55:	85 c0                	test   %eax,%eax
80101a57:	74 0c                	je     80101a65 <iput+0x57>
      panic("iput busy");
80101a59:	c7 04 24 70 88 10 80 	movl   $0x80108870,(%esp)
80101a60:	e8 d5 ea ff ff       	call   8010053a <panic>
    ip->flags |= I_BUSY;
80101a65:	8b 45 08             	mov    0x8(%ebp),%eax
80101a68:	8b 40 0c             	mov    0xc(%eax),%eax
80101a6b:	83 c8 01             	or     $0x1,%eax
80101a6e:	89 c2                	mov    %eax,%edx
80101a70:	8b 45 08             	mov    0x8(%ebp),%eax
80101a73:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101a76:	c7 04 24 80 12 11 80 	movl   $0x80111280,(%esp)
80101a7d:	e8 1c 37 00 00       	call   8010519e <release>
    itrunc(ip);
80101a82:	8b 45 08             	mov    0x8(%ebp),%eax
80101a85:	89 04 24             	mov    %eax,(%esp)
80101a88:	e8 7d 01 00 00       	call   80101c0a <itrunc>
    ip->type = 0;
80101a8d:	8b 45 08             	mov    0x8(%ebp),%eax
80101a90:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101a96:	8b 45 08             	mov    0x8(%ebp),%eax
80101a99:	89 04 24             	mov    %eax,(%esp)
80101a9c:	e8 fe fb ff ff       	call   8010169f <iupdate>
    acquire(&icache.lock);
80101aa1:	c7 04 24 80 12 11 80 	movl   $0x80111280,(%esp)
80101aa8:	e8 8f 36 00 00       	call   8010513c <acquire>
    ip->flags = 0;
80101aad:	8b 45 08             	mov    0x8(%ebp),%eax
80101ab0:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101ab7:	8b 45 08             	mov    0x8(%ebp),%eax
80101aba:	89 04 24             	mov    %eax,(%esp)
80101abd:	e8 57 32 00 00       	call   80104d19 <wakeup>
  }
  ip->ref--;
80101ac2:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac5:	8b 40 08             	mov    0x8(%eax),%eax
80101ac8:	8d 50 ff             	lea    -0x1(%eax),%edx
80101acb:	8b 45 08             	mov    0x8(%ebp),%eax
80101ace:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101ad1:	c7 04 24 80 12 11 80 	movl   $0x80111280,(%esp)
80101ad8:	e8 c1 36 00 00       	call   8010519e <release>
}
80101add:	c9                   	leave  
80101ade:	c3                   	ret    

80101adf <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101adf:	55                   	push   %ebp
80101ae0:	89 e5                	mov    %esp,%ebp
80101ae2:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101ae5:	8b 45 08             	mov    0x8(%ebp),%eax
80101ae8:	89 04 24             	mov    %eax,(%esp)
80101aeb:	e8 b9 fe ff ff       	call   801019a9 <iunlock>
  iput(ip);
80101af0:	8b 45 08             	mov    0x8(%ebp),%eax
80101af3:	89 04 24             	mov    %eax,(%esp)
80101af6:	e8 13 ff ff ff       	call   80101a0e <iput>
}
80101afb:	c9                   	leave  
80101afc:	c3                   	ret    

80101afd <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101afd:	55                   	push   %ebp
80101afe:	89 e5                	mov    %esp,%ebp
80101b00:	53                   	push   %ebx
80101b01:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101b04:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101b08:	77 3e                	ja     80101b48 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101b0a:	8b 45 08             	mov    0x8(%ebp),%eax
80101b0d:	8b 55 0c             	mov    0xc(%ebp),%edx
80101b10:	83 c2 04             	add    $0x4,%edx
80101b13:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101b17:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b1a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101b1e:	75 20                	jne    80101b40 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101b20:	8b 45 08             	mov    0x8(%ebp),%eax
80101b23:	8b 00                	mov    (%eax),%eax
80101b25:	89 04 24             	mov    %eax,(%esp)
80101b28:	e8 5b f8 ff ff       	call   80101388 <balloc>
80101b2d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b30:	8b 45 08             	mov    0x8(%ebp),%eax
80101b33:	8b 55 0c             	mov    0xc(%ebp),%edx
80101b36:	8d 4a 04             	lea    0x4(%edx),%ecx
80101b39:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b3c:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101b40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b43:	e9 bc 00 00 00       	jmp    80101c04 <bmap+0x107>
  }
  bn -= NDIRECT;
80101b48:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101b4c:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101b50:	0f 87 a2 00 00 00    	ja     80101bf8 <bmap+0xfb>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101b56:	8b 45 08             	mov    0x8(%ebp),%eax
80101b59:	8b 40 4c             	mov    0x4c(%eax),%eax
80101b5c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b5f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101b63:	75 19                	jne    80101b7e <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101b65:	8b 45 08             	mov    0x8(%ebp),%eax
80101b68:	8b 00                	mov    (%eax),%eax
80101b6a:	89 04 24             	mov    %eax,(%esp)
80101b6d:	e8 16 f8 ff ff       	call   80101388 <balloc>
80101b72:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b75:	8b 45 08             	mov    0x8(%ebp),%eax
80101b78:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b7b:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80101b7e:	8b 45 08             	mov    0x8(%ebp),%eax
80101b81:	8b 00                	mov    (%eax),%eax
80101b83:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b86:	89 54 24 04          	mov    %edx,0x4(%esp)
80101b8a:	89 04 24             	mov    %eax,(%esp)
80101b8d:	e8 14 e6 ff ff       	call   801001a6 <bread>
80101b92:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101b95:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b98:	83 c0 18             	add    $0x18,%eax
80101b9b:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101b9e:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ba1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101ba8:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101bab:	01 d0                	add    %edx,%eax
80101bad:	8b 00                	mov    (%eax),%eax
80101baf:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bb2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101bb6:	75 30                	jne    80101be8 <bmap+0xeb>
      a[bn] = addr = balloc(ip->dev);
80101bb8:	8b 45 0c             	mov    0xc(%ebp),%eax
80101bbb:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101bc2:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101bc5:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80101bc8:	8b 45 08             	mov    0x8(%ebp),%eax
80101bcb:	8b 00                	mov    (%eax),%eax
80101bcd:	89 04 24             	mov    %eax,(%esp)
80101bd0:	e8 b3 f7 ff ff       	call   80101388 <balloc>
80101bd5:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bd8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101bdb:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101bdd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101be0:	89 04 24             	mov    %eax,(%esp)
80101be3:	e8 4e 1b 00 00       	call   80103736 <log_write>
    }
    brelse(bp);
80101be8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101beb:	89 04 24             	mov    %eax,(%esp)
80101bee:	e8 24 e6 ff ff       	call   80100217 <brelse>
    return addr;
80101bf3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101bf6:	eb 0c                	jmp    80101c04 <bmap+0x107>
  }

  panic("bmap: out of range");
80101bf8:	c7 04 24 7a 88 10 80 	movl   $0x8010887a,(%esp)
80101bff:	e8 36 e9 ff ff       	call   8010053a <panic>
}
80101c04:	83 c4 24             	add    $0x24,%esp
80101c07:	5b                   	pop    %ebx
80101c08:	5d                   	pop    %ebp
80101c09:	c3                   	ret    

80101c0a <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101c0a:	55                   	push   %ebp
80101c0b:	89 e5                	mov    %esp,%ebp
80101c0d:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101c10:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101c17:	eb 44                	jmp    80101c5d <itrunc+0x53>
    if(ip->addrs[i]){
80101c19:	8b 45 08             	mov    0x8(%ebp),%eax
80101c1c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c1f:	83 c2 04             	add    $0x4,%edx
80101c22:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101c26:	85 c0                	test   %eax,%eax
80101c28:	74 2f                	je     80101c59 <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101c2a:	8b 45 08             	mov    0x8(%ebp),%eax
80101c2d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c30:	83 c2 04             	add    $0x4,%edx
80101c33:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101c37:	8b 45 08             	mov    0x8(%ebp),%eax
80101c3a:	8b 00                	mov    (%eax),%eax
80101c3c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c40:	89 04 24             	mov    %eax,(%esp)
80101c43:	e8 8e f8 ff ff       	call   801014d6 <bfree>
      ip->addrs[i] = 0;
80101c48:	8b 45 08             	mov    0x8(%ebp),%eax
80101c4b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c4e:	83 c2 04             	add    $0x4,%edx
80101c51:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101c58:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101c59:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101c5d:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101c61:	7e b6                	jle    80101c19 <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80101c63:	8b 45 08             	mov    0x8(%ebp),%eax
80101c66:	8b 40 4c             	mov    0x4c(%eax),%eax
80101c69:	85 c0                	test   %eax,%eax
80101c6b:	0f 84 9b 00 00 00    	je     80101d0c <itrunc+0x102>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101c71:	8b 45 08             	mov    0x8(%ebp),%eax
80101c74:	8b 50 4c             	mov    0x4c(%eax),%edx
80101c77:	8b 45 08             	mov    0x8(%ebp),%eax
80101c7a:	8b 00                	mov    (%eax),%eax
80101c7c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c80:	89 04 24             	mov    %eax,(%esp)
80101c83:	e8 1e e5 ff ff       	call   801001a6 <bread>
80101c88:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101c8b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101c8e:	83 c0 18             	add    $0x18,%eax
80101c91:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101c94:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101c9b:	eb 3b                	jmp    80101cd8 <itrunc+0xce>
      if(a[j])
80101c9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ca0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101ca7:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101caa:	01 d0                	add    %edx,%eax
80101cac:	8b 00                	mov    (%eax),%eax
80101cae:	85 c0                	test   %eax,%eax
80101cb0:	74 22                	je     80101cd4 <itrunc+0xca>
        bfree(ip->dev, a[j]);
80101cb2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cb5:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101cbc:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101cbf:	01 d0                	add    %edx,%eax
80101cc1:	8b 10                	mov    (%eax),%edx
80101cc3:	8b 45 08             	mov    0x8(%ebp),%eax
80101cc6:	8b 00                	mov    (%eax),%eax
80101cc8:	89 54 24 04          	mov    %edx,0x4(%esp)
80101ccc:	89 04 24             	mov    %eax,(%esp)
80101ccf:	e8 02 f8 ff ff       	call   801014d6 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101cd4:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101cd8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cdb:	83 f8 7f             	cmp    $0x7f,%eax
80101cde:	76 bd                	jbe    80101c9d <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101ce0:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ce3:	89 04 24             	mov    %eax,(%esp)
80101ce6:	e8 2c e5 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101ceb:	8b 45 08             	mov    0x8(%ebp),%eax
80101cee:	8b 50 4c             	mov    0x4c(%eax),%edx
80101cf1:	8b 45 08             	mov    0x8(%ebp),%eax
80101cf4:	8b 00                	mov    (%eax),%eax
80101cf6:	89 54 24 04          	mov    %edx,0x4(%esp)
80101cfa:	89 04 24             	mov    %eax,(%esp)
80101cfd:	e8 d4 f7 ff ff       	call   801014d6 <bfree>
    ip->addrs[NDIRECT] = 0;
80101d02:	8b 45 08             	mov    0x8(%ebp),%eax
80101d05:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80101d0c:	8b 45 08             	mov    0x8(%ebp),%eax
80101d0f:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80101d16:	8b 45 08             	mov    0x8(%ebp),%eax
80101d19:	89 04 24             	mov    %eax,(%esp)
80101d1c:	e8 7e f9 ff ff       	call   8010169f <iupdate>
}
80101d21:	c9                   	leave  
80101d22:	c3                   	ret    

80101d23 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80101d23:	55                   	push   %ebp
80101d24:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101d26:	8b 45 08             	mov    0x8(%ebp),%eax
80101d29:	8b 00                	mov    (%eax),%eax
80101d2b:	89 c2                	mov    %eax,%edx
80101d2d:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d30:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101d33:	8b 45 08             	mov    0x8(%ebp),%eax
80101d36:	8b 50 04             	mov    0x4(%eax),%edx
80101d39:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d3c:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101d3f:	8b 45 08             	mov    0x8(%ebp),%eax
80101d42:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101d46:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d49:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101d4c:	8b 45 08             	mov    0x8(%ebp),%eax
80101d4f:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101d53:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d56:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101d5a:	8b 45 08             	mov    0x8(%ebp),%eax
80101d5d:	8b 50 18             	mov    0x18(%eax),%edx
80101d60:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d63:	89 50 10             	mov    %edx,0x10(%eax)
}
80101d66:	5d                   	pop    %ebp
80101d67:	c3                   	ret    

80101d68 <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101d68:	55                   	push   %ebp
80101d69:	89 e5                	mov    %esp,%ebp
80101d6b:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101d6e:	8b 45 08             	mov    0x8(%ebp),%eax
80101d71:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101d75:	66 83 f8 03          	cmp    $0x3,%ax
80101d79:	75 6d                	jne    80101de8 <readi+0x80>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101d7b:	8b 45 08             	mov    0x8(%ebp),%eax
80101d7e:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101d82:	66 85 c0             	test   %ax,%ax
80101d85:	78 23                	js     80101daa <readi+0x42>
80101d87:	8b 45 08             	mov    0x8(%ebp),%eax
80101d8a:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101d8e:	66 83 f8 09          	cmp    $0x9,%ax
80101d92:	7f 16                	jg     80101daa <readi+0x42>
80101d94:	8b 45 08             	mov    0x8(%ebp),%eax
80101d97:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101d9b:	98                   	cwtl   
80101d9c:	c1 e0 04             	shl    $0x4,%eax
80101d9f:	05 e8 11 11 80       	add    $0x801111e8,%eax
80101da4:	8b 00                	mov    (%eax),%eax
80101da6:	85 c0                	test   %eax,%eax
80101da8:	75 0a                	jne    80101db4 <readi+0x4c>
      return -1;
80101daa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101daf:	e9 23 01 00 00       	jmp    80101ed7 <readi+0x16f>
    return devsw[ip->major].read(ip, dst, off, n);
80101db4:	8b 45 08             	mov    0x8(%ebp),%eax
80101db7:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101dbb:	98                   	cwtl   
80101dbc:	c1 e0 04             	shl    $0x4,%eax
80101dbf:	05 e8 11 11 80       	add    $0x801111e8,%eax
80101dc4:	8b 00                	mov    (%eax),%eax
80101dc6:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101dc9:	8b 55 10             	mov    0x10(%ebp),%edx
80101dcc:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101dd0:	89 54 24 08          	mov    %edx,0x8(%esp)
80101dd4:	8b 55 0c             	mov    0xc(%ebp),%edx
80101dd7:	89 54 24 04          	mov    %edx,0x4(%esp)
80101ddb:	8b 55 08             	mov    0x8(%ebp),%edx
80101dde:	89 14 24             	mov    %edx,(%esp)
80101de1:	ff d0                	call   *%eax
80101de3:	e9 ef 00 00 00       	jmp    80101ed7 <readi+0x16f>
  }

  if(off > ip->size || off + n < off)
80101de8:	8b 45 08             	mov    0x8(%ebp),%eax
80101deb:	8b 40 18             	mov    0x18(%eax),%eax
80101dee:	3b 45 10             	cmp    0x10(%ebp),%eax
80101df1:	72 0d                	jb     80101e00 <readi+0x98>
80101df3:	8b 45 14             	mov    0x14(%ebp),%eax
80101df6:	8b 55 10             	mov    0x10(%ebp),%edx
80101df9:	01 d0                	add    %edx,%eax
80101dfb:	3b 45 10             	cmp    0x10(%ebp),%eax
80101dfe:	73 0a                	jae    80101e0a <readi+0xa2>
    return -1;
80101e00:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101e05:	e9 cd 00 00 00       	jmp    80101ed7 <readi+0x16f>
  if(off + n > ip->size)
80101e0a:	8b 45 14             	mov    0x14(%ebp),%eax
80101e0d:	8b 55 10             	mov    0x10(%ebp),%edx
80101e10:	01 c2                	add    %eax,%edx
80101e12:	8b 45 08             	mov    0x8(%ebp),%eax
80101e15:	8b 40 18             	mov    0x18(%eax),%eax
80101e18:	39 c2                	cmp    %eax,%edx
80101e1a:	76 0c                	jbe    80101e28 <readi+0xc0>
    n = ip->size - off;
80101e1c:	8b 45 08             	mov    0x8(%ebp),%eax
80101e1f:	8b 40 18             	mov    0x18(%eax),%eax
80101e22:	2b 45 10             	sub    0x10(%ebp),%eax
80101e25:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101e28:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101e2f:	e9 94 00 00 00       	jmp    80101ec8 <readi+0x160>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101e34:	8b 45 10             	mov    0x10(%ebp),%eax
80101e37:	c1 e8 09             	shr    $0x9,%eax
80101e3a:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e3e:	8b 45 08             	mov    0x8(%ebp),%eax
80101e41:	89 04 24             	mov    %eax,(%esp)
80101e44:	e8 b4 fc ff ff       	call   80101afd <bmap>
80101e49:	8b 55 08             	mov    0x8(%ebp),%edx
80101e4c:	8b 12                	mov    (%edx),%edx
80101e4e:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e52:	89 14 24             	mov    %edx,(%esp)
80101e55:	e8 4c e3 ff ff       	call   801001a6 <bread>
80101e5a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101e5d:	8b 45 10             	mov    0x10(%ebp),%eax
80101e60:	25 ff 01 00 00       	and    $0x1ff,%eax
80101e65:	89 c2                	mov    %eax,%edx
80101e67:	b8 00 02 00 00       	mov    $0x200,%eax
80101e6c:	29 d0                	sub    %edx,%eax
80101e6e:	89 c2                	mov    %eax,%edx
80101e70:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e73:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101e76:	29 c1                	sub    %eax,%ecx
80101e78:	89 c8                	mov    %ecx,%eax
80101e7a:	39 c2                	cmp    %eax,%edx
80101e7c:	0f 46 c2             	cmovbe %edx,%eax
80101e7f:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80101e82:	8b 45 10             	mov    0x10(%ebp),%eax
80101e85:	25 ff 01 00 00       	and    $0x1ff,%eax
80101e8a:	8d 50 10             	lea    0x10(%eax),%edx
80101e8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e90:	01 d0                	add    %edx,%eax
80101e92:	8d 50 08             	lea    0x8(%eax),%edx
80101e95:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101e98:	89 44 24 08          	mov    %eax,0x8(%esp)
80101e9c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101ea0:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ea3:	89 04 24             	mov    %eax,(%esp)
80101ea6:	e8 b4 35 00 00       	call   8010545f <memmove>
    brelse(bp);
80101eab:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101eae:	89 04 24             	mov    %eax,(%esp)
80101eb1:	e8 61 e3 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101eb6:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101eb9:	01 45 f4             	add    %eax,-0xc(%ebp)
80101ebc:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ebf:	01 45 10             	add    %eax,0x10(%ebp)
80101ec2:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ec5:	01 45 0c             	add    %eax,0xc(%ebp)
80101ec8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ecb:	3b 45 14             	cmp    0x14(%ebp),%eax
80101ece:	0f 82 60 ff ff ff    	jb     80101e34 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80101ed4:	8b 45 14             	mov    0x14(%ebp),%eax
}
80101ed7:	c9                   	leave  
80101ed8:	c3                   	ret    

80101ed9 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80101ed9:	55                   	push   %ebp
80101eda:	89 e5                	mov    %esp,%ebp
80101edc:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101edf:	8b 45 08             	mov    0x8(%ebp),%eax
80101ee2:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101ee6:	66 83 f8 03          	cmp    $0x3,%ax
80101eea:	75 66                	jne    80101f52 <writei+0x79>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80101eec:	8b 45 08             	mov    0x8(%ebp),%eax
80101eef:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101ef3:	66 85 c0             	test   %ax,%ax
80101ef6:	78 23                	js     80101f1b <writei+0x42>
80101ef8:	8b 45 08             	mov    0x8(%ebp),%eax
80101efb:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101eff:	66 83 f8 09          	cmp    $0x9,%ax
80101f03:	7f 16                	jg     80101f1b <writei+0x42>
80101f05:	8b 45 08             	mov    0x8(%ebp),%eax
80101f08:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f0c:	98                   	cwtl   
80101f0d:	c1 e0 04             	shl    $0x4,%eax
80101f10:	05 ec 11 11 80       	add    $0x801111ec,%eax
80101f15:	8b 00                	mov    (%eax),%eax
80101f17:	85 c0                	test   %eax,%eax
80101f19:	75 0a                	jne    80101f25 <writei+0x4c>
      return -1;
80101f1b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f20:	e9 47 01 00 00       	jmp    8010206c <writei+0x193>
    return devsw[ip->major].write(ip, src, n);
80101f25:	8b 45 08             	mov    0x8(%ebp),%eax
80101f28:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f2c:	98                   	cwtl   
80101f2d:	c1 e0 04             	shl    $0x4,%eax
80101f30:	05 ec 11 11 80       	add    $0x801111ec,%eax
80101f35:	8b 00                	mov    (%eax),%eax
80101f37:	8b 55 14             	mov    0x14(%ebp),%edx
80101f3a:	89 54 24 08          	mov    %edx,0x8(%esp)
80101f3e:	8b 55 0c             	mov    0xc(%ebp),%edx
80101f41:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f45:	8b 55 08             	mov    0x8(%ebp),%edx
80101f48:	89 14 24             	mov    %edx,(%esp)
80101f4b:	ff d0                	call   *%eax
80101f4d:	e9 1a 01 00 00       	jmp    8010206c <writei+0x193>
  }

  if(off > ip->size || off + n < off)
80101f52:	8b 45 08             	mov    0x8(%ebp),%eax
80101f55:	8b 40 18             	mov    0x18(%eax),%eax
80101f58:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f5b:	72 0d                	jb     80101f6a <writei+0x91>
80101f5d:	8b 45 14             	mov    0x14(%ebp),%eax
80101f60:	8b 55 10             	mov    0x10(%ebp),%edx
80101f63:	01 d0                	add    %edx,%eax
80101f65:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f68:	73 0a                	jae    80101f74 <writei+0x9b>
    return -1;
80101f6a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f6f:	e9 f8 00 00 00       	jmp    8010206c <writei+0x193>
  if(off + n > MAXFILE*BSIZE)
80101f74:	8b 45 14             	mov    0x14(%ebp),%eax
80101f77:	8b 55 10             	mov    0x10(%ebp),%edx
80101f7a:	01 d0                	add    %edx,%eax
80101f7c:	3d 00 18 01 00       	cmp    $0x11800,%eax
80101f81:	76 0a                	jbe    80101f8d <writei+0xb4>
    return -1;
80101f83:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f88:	e9 df 00 00 00       	jmp    8010206c <writei+0x193>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80101f8d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101f94:	e9 9f 00 00 00       	jmp    80102038 <writei+0x15f>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101f99:	8b 45 10             	mov    0x10(%ebp),%eax
80101f9c:	c1 e8 09             	shr    $0x9,%eax
80101f9f:	89 44 24 04          	mov    %eax,0x4(%esp)
80101fa3:	8b 45 08             	mov    0x8(%ebp),%eax
80101fa6:	89 04 24             	mov    %eax,(%esp)
80101fa9:	e8 4f fb ff ff       	call   80101afd <bmap>
80101fae:	8b 55 08             	mov    0x8(%ebp),%edx
80101fb1:	8b 12                	mov    (%edx),%edx
80101fb3:	89 44 24 04          	mov    %eax,0x4(%esp)
80101fb7:	89 14 24             	mov    %edx,(%esp)
80101fba:	e8 e7 e1 ff ff       	call   801001a6 <bread>
80101fbf:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101fc2:	8b 45 10             	mov    0x10(%ebp),%eax
80101fc5:	25 ff 01 00 00       	and    $0x1ff,%eax
80101fca:	89 c2                	mov    %eax,%edx
80101fcc:	b8 00 02 00 00       	mov    $0x200,%eax
80101fd1:	29 d0                	sub    %edx,%eax
80101fd3:	89 c2                	mov    %eax,%edx
80101fd5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101fd8:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101fdb:	29 c1                	sub    %eax,%ecx
80101fdd:	89 c8                	mov    %ecx,%eax
80101fdf:	39 c2                	cmp    %eax,%edx
80101fe1:	0f 46 c2             	cmovbe %edx,%eax
80101fe4:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80101fe7:	8b 45 10             	mov    0x10(%ebp),%eax
80101fea:	25 ff 01 00 00       	and    $0x1ff,%eax
80101fef:	8d 50 10             	lea    0x10(%eax),%edx
80101ff2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ff5:	01 d0                	add    %edx,%eax
80101ff7:	8d 50 08             	lea    0x8(%eax),%edx
80101ffa:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ffd:	89 44 24 08          	mov    %eax,0x8(%esp)
80102001:	8b 45 0c             	mov    0xc(%ebp),%eax
80102004:	89 44 24 04          	mov    %eax,0x4(%esp)
80102008:	89 14 24             	mov    %edx,(%esp)
8010200b:	e8 4f 34 00 00       	call   8010545f <memmove>
    log_write(bp);
80102010:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102013:	89 04 24             	mov    %eax,(%esp)
80102016:	e8 1b 17 00 00       	call   80103736 <log_write>
    brelse(bp);
8010201b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010201e:	89 04 24             	mov    %eax,(%esp)
80102021:	e8 f1 e1 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102026:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102029:	01 45 f4             	add    %eax,-0xc(%ebp)
8010202c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010202f:	01 45 10             	add    %eax,0x10(%ebp)
80102032:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102035:	01 45 0c             	add    %eax,0xc(%ebp)
80102038:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010203b:	3b 45 14             	cmp    0x14(%ebp),%eax
8010203e:	0f 82 55 ff ff ff    	jb     80101f99 <writei+0xc0>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
80102044:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80102048:	74 1f                	je     80102069 <writei+0x190>
8010204a:	8b 45 08             	mov    0x8(%ebp),%eax
8010204d:	8b 40 18             	mov    0x18(%eax),%eax
80102050:	3b 45 10             	cmp    0x10(%ebp),%eax
80102053:	73 14                	jae    80102069 <writei+0x190>
    ip->size = off;
80102055:	8b 45 08             	mov    0x8(%ebp),%eax
80102058:	8b 55 10             	mov    0x10(%ebp),%edx
8010205b:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
8010205e:	8b 45 08             	mov    0x8(%ebp),%eax
80102061:	89 04 24             	mov    %eax,(%esp)
80102064:	e8 36 f6 ff ff       	call   8010169f <iupdate>
  }
  return n;
80102069:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010206c:	c9                   	leave  
8010206d:	c3                   	ret    

8010206e <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
8010206e:	55                   	push   %ebp
8010206f:	89 e5                	mov    %esp,%ebp
80102071:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
80102074:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
8010207b:	00 
8010207c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010207f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102083:	8b 45 08             	mov    0x8(%ebp),%eax
80102086:	89 04 24             	mov    %eax,(%esp)
80102089:	e8 74 34 00 00       	call   80105502 <strncmp>
}
8010208e:	c9                   	leave  
8010208f:	c3                   	ret    

80102090 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
80102090:	55                   	push   %ebp
80102091:	89 e5                	mov    %esp,%ebp
80102093:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;
  struct inode *ip;

  if(dp->type != T_DIR && !IS_DEV_DIR(dp))
80102096:	8b 45 08             	mov    0x8(%ebp),%eax
80102099:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010209d:	66 83 f8 01          	cmp    $0x1,%ax
801020a1:	74 4d                	je     801020f0 <dirlookup+0x60>
801020a3:	8b 45 08             	mov    0x8(%ebp),%eax
801020a6:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801020aa:	66 83 f8 03          	cmp    $0x3,%ax
801020ae:	75 34                	jne    801020e4 <dirlookup+0x54>
801020b0:	8b 45 08             	mov    0x8(%ebp),%eax
801020b3:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801020b7:	98                   	cwtl   
801020b8:	c1 e0 04             	shl    $0x4,%eax
801020bb:	05 e0 11 11 80       	add    $0x801111e0,%eax
801020c0:	8b 00                	mov    (%eax),%eax
801020c2:	85 c0                	test   %eax,%eax
801020c4:	74 1e                	je     801020e4 <dirlookup+0x54>
801020c6:	8b 45 08             	mov    0x8(%ebp),%eax
801020c9:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801020cd:	98                   	cwtl   
801020ce:	c1 e0 04             	shl    $0x4,%eax
801020d1:	05 e0 11 11 80       	add    $0x801111e0,%eax
801020d6:	8b 00                	mov    (%eax),%eax
801020d8:	8b 55 08             	mov    0x8(%ebp),%edx
801020db:	89 14 24             	mov    %edx,(%esp)
801020de:	ff d0                	call   *%eax
801020e0:	85 c0                	test   %eax,%eax
801020e2:	75 0c                	jne    801020f0 <dirlookup+0x60>
    panic("dirlookup not DIR");
801020e4:	c7 04 24 8d 88 10 80 	movl   $0x8010888d,(%esp)
801020eb:	e8 4a e4 ff ff       	call   8010053a <panic>

  for(off = 0; off < dp->size || dp->type == T_DEV; off += sizeof(de)){
801020f0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801020f7:	e9 fd 00 00 00       	jmp    801021f9 <dirlookup+0x169>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de)) {
801020fc:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102103:	00 
80102104:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102107:	89 44 24 08          	mov    %eax,0x8(%esp)
8010210b:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010210e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102112:	8b 45 08             	mov    0x8(%ebp),%eax
80102115:	89 04 24             	mov    %eax,(%esp)
80102118:	e8 4b fc ff ff       	call   80101d68 <readi>
8010211d:	83 f8 10             	cmp    $0x10,%eax
80102120:	74 23                	je     80102145 <dirlookup+0xb5>
      if (dp->type == T_DEV)
80102122:	8b 45 08             	mov    0x8(%ebp),%eax
80102125:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102129:	66 83 f8 03          	cmp    $0x3,%ax
8010212d:	75 0a                	jne    80102139 <dirlookup+0xa9>
        return 0;
8010212f:	b8 00 00 00 00       	mov    $0x0,%eax
80102134:	e9 e5 00 00 00       	jmp    8010221e <dirlookup+0x18e>
      else
        panic("dirlink read");
80102139:	c7 04 24 9f 88 10 80 	movl   $0x8010889f,(%esp)
80102140:	e8 f5 e3 ff ff       	call   8010053a <panic>
    }
    if(de.inum == 0)
80102145:	0f b7 45 dc          	movzwl -0x24(%ebp),%eax
80102149:	66 85 c0             	test   %ax,%ax
8010214c:	75 05                	jne    80102153 <dirlookup+0xc3>
      continue;
8010214e:	e9 a2 00 00 00       	jmp    801021f5 <dirlookup+0x165>
    if(namecmp(name, de.name) == 0){
80102153:	8d 45 dc             	lea    -0x24(%ebp),%eax
80102156:	83 c0 02             	add    $0x2,%eax
80102159:	89 44 24 04          	mov    %eax,0x4(%esp)
8010215d:	8b 45 0c             	mov    0xc(%ebp),%eax
80102160:	89 04 24             	mov    %eax,(%esp)
80102163:	e8 06 ff ff ff       	call   8010206e <namecmp>
80102168:	85 c0                	test   %eax,%eax
8010216a:	0f 85 85 00 00 00    	jne    801021f5 <dirlookup+0x165>
      // entry matches path element
      if(poff)
80102170:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80102174:	74 08                	je     8010217e <dirlookup+0xee>
        *poff = off;
80102176:	8b 45 10             	mov    0x10(%ebp),%eax
80102179:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010217c:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
8010217e:	0f b7 45 dc          	movzwl -0x24(%ebp),%eax
80102182:	0f b7 c0             	movzwl %ax,%eax
80102185:	89 45 f0             	mov    %eax,-0x10(%ebp)
      ip = iget(dp->dev, inum);
80102188:	8b 45 08             	mov    0x8(%ebp),%eax
8010218b:	8b 00                	mov    (%eax),%eax
8010218d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102190:	89 54 24 04          	mov    %edx,0x4(%esp)
80102194:	89 04 24             	mov    %eax,(%esp)
80102197:	e8 bb f5 ff ff       	call   80101757 <iget>
8010219c:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if (!(ip->flags & I_VALID) && dp->type == T_DEV && devsw[dp->major].iread) {
8010219f:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021a2:	8b 40 0c             	mov    0xc(%eax),%eax
801021a5:	83 e0 02             	and    $0x2,%eax
801021a8:	85 c0                	test   %eax,%eax
801021aa:	75 44                	jne    801021f0 <dirlookup+0x160>
801021ac:	8b 45 08             	mov    0x8(%ebp),%eax
801021af:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801021b3:	66 83 f8 03          	cmp    $0x3,%ax
801021b7:	75 37                	jne    801021f0 <dirlookup+0x160>
801021b9:	8b 45 08             	mov    0x8(%ebp),%eax
801021bc:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801021c0:	98                   	cwtl   
801021c1:	c1 e0 04             	shl    $0x4,%eax
801021c4:	05 e4 11 11 80       	add    $0x801111e4,%eax
801021c9:	8b 00                	mov    (%eax),%eax
801021cb:	85 c0                	test   %eax,%eax
801021cd:	74 21                	je     801021f0 <dirlookup+0x160>
        devsw[dp->major].iread(dp, ip);
801021cf:	8b 45 08             	mov    0x8(%ebp),%eax
801021d2:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801021d6:	98                   	cwtl   
801021d7:	c1 e0 04             	shl    $0x4,%eax
801021da:	05 e4 11 11 80       	add    $0x801111e4,%eax
801021df:	8b 00                	mov    (%eax),%eax
801021e1:	8b 55 ec             	mov    -0x14(%ebp),%edx
801021e4:	89 54 24 04          	mov    %edx,0x4(%esp)
801021e8:	8b 55 08             	mov    0x8(%ebp),%edx
801021eb:	89 14 24             	mov    %edx,(%esp)
801021ee:	ff d0                	call   *%eax
      }
      return ip;
801021f0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021f3:	eb 29                	jmp    8010221e <dirlookup+0x18e>
  struct inode *ip;

  if(dp->type != T_DIR && !IS_DEV_DIR(dp))
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size || dp->type == T_DEV; off += sizeof(de)){
801021f5:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801021f9:	8b 45 08             	mov    0x8(%ebp),%eax
801021fc:	8b 40 18             	mov    0x18(%eax),%eax
801021ff:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80102202:	0f 87 f4 fe ff ff    	ja     801020fc <dirlookup+0x6c>
80102208:	8b 45 08             	mov    0x8(%ebp),%eax
8010220b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010220f:	66 83 f8 03          	cmp    $0x3,%ax
80102213:	0f 84 e3 fe ff ff    	je     801020fc <dirlookup+0x6c>
      }
      return ip;
    }
  }

  return 0;
80102219:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010221e:	c9                   	leave  
8010221f:	c3                   	ret    

80102220 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
80102220:	55                   	push   %ebp
80102221:	89 e5                	mov    %esp,%ebp
80102223:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
80102226:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010222d:	00 
8010222e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102231:	89 44 24 04          	mov    %eax,0x4(%esp)
80102235:	8b 45 08             	mov    0x8(%ebp),%eax
80102238:	89 04 24             	mov    %eax,(%esp)
8010223b:	e8 50 fe ff ff       	call   80102090 <dirlookup>
80102240:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102243:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102247:	74 15                	je     8010225e <dirlink+0x3e>
    iput(ip);
80102249:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010224c:	89 04 24             	mov    %eax,(%esp)
8010224f:	e8 ba f7 ff ff       	call   80101a0e <iput>
    return -1;
80102254:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102259:	e9 b7 00 00 00       	jmp    80102315 <dirlink+0xf5>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
8010225e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102265:	eb 46                	jmp    801022ad <dirlink+0x8d>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102267:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010226a:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102271:	00 
80102272:	89 44 24 08          	mov    %eax,0x8(%esp)
80102276:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102279:	89 44 24 04          	mov    %eax,0x4(%esp)
8010227d:	8b 45 08             	mov    0x8(%ebp),%eax
80102280:	89 04 24             	mov    %eax,(%esp)
80102283:	e8 e0 fa ff ff       	call   80101d68 <readi>
80102288:	83 f8 10             	cmp    $0x10,%eax
8010228b:	74 0c                	je     80102299 <dirlink+0x79>
      panic("dirlink read");
8010228d:	c7 04 24 9f 88 10 80 	movl   $0x8010889f,(%esp)
80102294:	e8 a1 e2 ff ff       	call   8010053a <panic>
    if(de.inum == 0)
80102299:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010229d:	66 85 c0             	test   %ax,%ax
801022a0:	75 02                	jne    801022a4 <dirlink+0x84>
      break;
801022a2:	eb 16                	jmp    801022ba <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801022a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022a7:	83 c0 10             	add    $0x10,%eax
801022aa:	89 45 f4             	mov    %eax,-0xc(%ebp)
801022ad:	8b 55 f4             	mov    -0xc(%ebp),%edx
801022b0:	8b 45 08             	mov    0x8(%ebp),%eax
801022b3:	8b 40 18             	mov    0x18(%eax),%eax
801022b6:	39 c2                	cmp    %eax,%edx
801022b8:	72 ad                	jb     80102267 <dirlink+0x47>
      panic("dirlink read");
    if(de.inum == 0)
      break;
  }

  strncpy(de.name, name, DIRSIZ);
801022ba:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801022c1:	00 
801022c2:	8b 45 0c             	mov    0xc(%ebp),%eax
801022c5:	89 44 24 04          	mov    %eax,0x4(%esp)
801022c9:	8d 45 e0             	lea    -0x20(%ebp),%eax
801022cc:	83 c0 02             	add    $0x2,%eax
801022cf:	89 04 24             	mov    %eax,(%esp)
801022d2:	e8 81 32 00 00       	call   80105558 <strncpy>
  de.inum = inum;
801022d7:	8b 45 10             	mov    0x10(%ebp),%eax
801022da:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801022de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022e1:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801022e8:	00 
801022e9:	89 44 24 08          	mov    %eax,0x8(%esp)
801022ed:	8d 45 e0             	lea    -0x20(%ebp),%eax
801022f0:	89 44 24 04          	mov    %eax,0x4(%esp)
801022f4:	8b 45 08             	mov    0x8(%ebp),%eax
801022f7:	89 04 24             	mov    %eax,(%esp)
801022fa:	e8 da fb ff ff       	call   80101ed9 <writei>
801022ff:	83 f8 10             	cmp    $0x10,%eax
80102302:	74 0c                	je     80102310 <dirlink+0xf0>
    panic("dirlink");
80102304:	c7 04 24 ac 88 10 80 	movl   $0x801088ac,(%esp)
8010230b:	e8 2a e2 ff ff       	call   8010053a <panic>
  
  return 0;
80102310:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102315:	c9                   	leave  
80102316:	c3                   	ret    

80102317 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80102317:	55                   	push   %ebp
80102318:	89 e5                	mov    %esp,%ebp
8010231a:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
8010231d:	eb 04                	jmp    80102323 <skipelem+0xc>
    path++;
8010231f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
80102323:	8b 45 08             	mov    0x8(%ebp),%eax
80102326:	0f b6 00             	movzbl (%eax),%eax
80102329:	3c 2f                	cmp    $0x2f,%al
8010232b:	74 f2                	je     8010231f <skipelem+0x8>
    path++;
  if(*path == 0)
8010232d:	8b 45 08             	mov    0x8(%ebp),%eax
80102330:	0f b6 00             	movzbl (%eax),%eax
80102333:	84 c0                	test   %al,%al
80102335:	75 0a                	jne    80102341 <skipelem+0x2a>
    return 0;
80102337:	b8 00 00 00 00       	mov    $0x0,%eax
8010233c:	e9 86 00 00 00       	jmp    801023c7 <skipelem+0xb0>
  s = path;
80102341:	8b 45 08             	mov    0x8(%ebp),%eax
80102344:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
80102347:	eb 04                	jmp    8010234d <skipelem+0x36>
    path++;
80102349:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
8010234d:	8b 45 08             	mov    0x8(%ebp),%eax
80102350:	0f b6 00             	movzbl (%eax),%eax
80102353:	3c 2f                	cmp    $0x2f,%al
80102355:	74 0a                	je     80102361 <skipelem+0x4a>
80102357:	8b 45 08             	mov    0x8(%ebp),%eax
8010235a:	0f b6 00             	movzbl (%eax),%eax
8010235d:	84 c0                	test   %al,%al
8010235f:	75 e8                	jne    80102349 <skipelem+0x32>
    path++;
  len = path - s;
80102361:	8b 55 08             	mov    0x8(%ebp),%edx
80102364:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102367:	29 c2                	sub    %eax,%edx
80102369:	89 d0                	mov    %edx,%eax
8010236b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
8010236e:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
80102372:	7e 1c                	jle    80102390 <skipelem+0x79>
    memmove(name, s, DIRSIZ);
80102374:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
8010237b:	00 
8010237c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010237f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102383:	8b 45 0c             	mov    0xc(%ebp),%eax
80102386:	89 04 24             	mov    %eax,(%esp)
80102389:	e8 d1 30 00 00       	call   8010545f <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
8010238e:	eb 2a                	jmp    801023ba <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
80102390:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102393:	89 44 24 08          	mov    %eax,0x8(%esp)
80102397:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010239a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010239e:	8b 45 0c             	mov    0xc(%ebp),%eax
801023a1:	89 04 24             	mov    %eax,(%esp)
801023a4:	e8 b6 30 00 00       	call   8010545f <memmove>
    name[len] = 0;
801023a9:	8b 55 f0             	mov    -0x10(%ebp),%edx
801023ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801023af:	01 d0                	add    %edx,%eax
801023b1:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
801023b4:	eb 04                	jmp    801023ba <skipelem+0xa3>
    path++;
801023b6:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801023ba:	8b 45 08             	mov    0x8(%ebp),%eax
801023bd:	0f b6 00             	movzbl (%eax),%eax
801023c0:	3c 2f                	cmp    $0x2f,%al
801023c2:	74 f2                	je     801023b6 <skipelem+0x9f>
    path++;
  return path;
801023c4:	8b 45 08             	mov    0x8(%ebp),%eax
}
801023c7:	c9                   	leave  
801023c8:	c3                   	ret    

801023c9 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
801023c9:	55                   	push   %ebp
801023ca:	89 e5                	mov    %esp,%ebp
801023cc:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
801023cf:	8b 45 08             	mov    0x8(%ebp),%eax
801023d2:	0f b6 00             	movzbl (%eax),%eax
801023d5:	3c 2f                	cmp    $0x2f,%al
801023d7:	75 1c                	jne    801023f5 <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
801023d9:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801023e0:	00 
801023e1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801023e8:	e8 6a f3 ff ff       	call   80101757 <iget>
801023ed:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801023f0:	e9 f0 00 00 00       	jmp    801024e5 <namex+0x11c>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
801023f5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801023fb:	8b 40 68             	mov    0x68(%eax),%eax
801023fe:	89 04 24             	mov    %eax,(%esp)
80102401:	e8 23 f4 ff ff       	call   80101829 <idup>
80102406:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
80102409:	e9 d7 00 00 00       	jmp    801024e5 <namex+0x11c>
    ilock(ip);
8010240e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102411:	89 04 24             	mov    %eax,(%esp)
80102414:	e8 42 f4 ff ff       	call   8010185b <ilock>
    if(ip->type != T_DIR && !IS_DEV_DIR(ip)){
80102419:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010241c:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102420:	66 83 f8 01          	cmp    $0x1,%ax
80102424:	74 56                	je     8010247c <namex+0xb3>
80102426:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102429:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010242d:	66 83 f8 03          	cmp    $0x3,%ax
80102431:	75 34                	jne    80102467 <namex+0x9e>
80102433:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102436:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010243a:	98                   	cwtl   
8010243b:	c1 e0 04             	shl    $0x4,%eax
8010243e:	05 e0 11 11 80       	add    $0x801111e0,%eax
80102443:	8b 00                	mov    (%eax),%eax
80102445:	85 c0                	test   %eax,%eax
80102447:	74 1e                	je     80102467 <namex+0x9e>
80102449:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010244c:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102450:	98                   	cwtl   
80102451:	c1 e0 04             	shl    $0x4,%eax
80102454:	05 e0 11 11 80       	add    $0x801111e0,%eax
80102459:	8b 00                	mov    (%eax),%eax
8010245b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010245e:	89 14 24             	mov    %edx,(%esp)
80102461:	ff d0                	call   *%eax
80102463:	85 c0                	test   %eax,%eax
80102465:	75 15                	jne    8010247c <namex+0xb3>
      iunlockput(ip);
80102467:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010246a:	89 04 24             	mov    %eax,(%esp)
8010246d:	e8 6d f6 ff ff       	call   80101adf <iunlockput>
      return 0;
80102472:	b8 00 00 00 00       	mov    $0x0,%eax
80102477:	e9 a3 00 00 00       	jmp    8010251f <namex+0x156>
    }
    if(nameiparent && *path == '\0'){
8010247c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102480:	74 1d                	je     8010249f <namex+0xd6>
80102482:	8b 45 08             	mov    0x8(%ebp),%eax
80102485:	0f b6 00             	movzbl (%eax),%eax
80102488:	84 c0                	test   %al,%al
8010248a:	75 13                	jne    8010249f <namex+0xd6>
      // Stop one level early.
      iunlock(ip);
8010248c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010248f:	89 04 24             	mov    %eax,(%esp)
80102492:	e8 12 f5 ff ff       	call   801019a9 <iunlock>
      return ip;
80102497:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010249a:	e9 80 00 00 00       	jmp    8010251f <namex+0x156>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
8010249f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801024a6:	00 
801024a7:	8b 45 10             	mov    0x10(%ebp),%eax
801024aa:	89 44 24 04          	mov    %eax,0x4(%esp)
801024ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024b1:	89 04 24             	mov    %eax,(%esp)
801024b4:	e8 d7 fb ff ff       	call   80102090 <dirlookup>
801024b9:	89 45 f0             	mov    %eax,-0x10(%ebp)
801024bc:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801024c0:	75 12                	jne    801024d4 <namex+0x10b>
      iunlockput(ip);
801024c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024c5:	89 04 24             	mov    %eax,(%esp)
801024c8:	e8 12 f6 ff ff       	call   80101adf <iunlockput>
      return 0;
801024cd:	b8 00 00 00 00       	mov    $0x0,%eax
801024d2:	eb 4b                	jmp    8010251f <namex+0x156>
    }
    iunlockput(ip);
801024d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024d7:	89 04 24             	mov    %eax,(%esp)
801024da:	e8 00 f6 ff ff       	call   80101adf <iunlockput>
    ip = next;
801024df:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024e2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801024e5:	8b 45 10             	mov    0x10(%ebp),%eax
801024e8:	89 44 24 04          	mov    %eax,0x4(%esp)
801024ec:	8b 45 08             	mov    0x8(%ebp),%eax
801024ef:	89 04 24             	mov    %eax,(%esp)
801024f2:	e8 20 fe ff ff       	call   80102317 <skipelem>
801024f7:	89 45 08             	mov    %eax,0x8(%ebp)
801024fa:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801024fe:	0f 85 0a ff ff ff    	jne    8010240e <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
80102504:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102508:	74 12                	je     8010251c <namex+0x153>
    iput(ip);
8010250a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010250d:	89 04 24             	mov    %eax,(%esp)
80102510:	e8 f9 f4 ff ff       	call   80101a0e <iput>
    return 0;
80102515:	b8 00 00 00 00       	mov    $0x0,%eax
8010251a:	eb 03                	jmp    8010251f <namex+0x156>
  }
  return ip;
8010251c:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010251f:	c9                   	leave  
80102520:	c3                   	ret    

80102521 <namei>:

struct inode*
namei(char *path)
{
80102521:	55                   	push   %ebp
80102522:	89 e5                	mov    %esp,%ebp
80102524:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80102527:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010252a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010252e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102535:	00 
80102536:	8b 45 08             	mov    0x8(%ebp),%eax
80102539:	89 04 24             	mov    %eax,(%esp)
8010253c:	e8 88 fe ff ff       	call   801023c9 <namex>
}
80102541:	c9                   	leave  
80102542:	c3                   	ret    

80102543 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80102543:	55                   	push   %ebp
80102544:	89 e5                	mov    %esp,%ebp
80102546:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
80102549:	8b 45 0c             	mov    0xc(%ebp),%eax
8010254c:	89 44 24 08          	mov    %eax,0x8(%esp)
80102550:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102557:	00 
80102558:	8b 45 08             	mov    0x8(%ebp),%eax
8010255b:	89 04 24             	mov    %eax,(%esp)
8010255e:	e8 66 fe ff ff       	call   801023c9 <namex>
}
80102563:	c9                   	leave  
80102564:	c3                   	ret    

80102565 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102565:	55                   	push   %ebp
80102566:	89 e5                	mov    %esp,%ebp
80102568:	83 ec 14             	sub    $0x14,%esp
8010256b:	8b 45 08             	mov    0x8(%ebp),%eax
8010256e:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102572:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102576:	89 c2                	mov    %eax,%edx
80102578:	ec                   	in     (%dx),%al
80102579:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
8010257c:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102580:	c9                   	leave  
80102581:	c3                   	ret    

80102582 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
80102582:	55                   	push   %ebp
80102583:	89 e5                	mov    %esp,%ebp
80102585:	57                   	push   %edi
80102586:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
80102587:	8b 55 08             	mov    0x8(%ebp),%edx
8010258a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010258d:	8b 45 10             	mov    0x10(%ebp),%eax
80102590:	89 cb                	mov    %ecx,%ebx
80102592:	89 df                	mov    %ebx,%edi
80102594:	89 c1                	mov    %eax,%ecx
80102596:	fc                   	cld    
80102597:	f3 6d                	rep insl (%dx),%es:(%edi)
80102599:	89 c8                	mov    %ecx,%eax
8010259b:	89 fb                	mov    %edi,%ebx
8010259d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801025a0:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
801025a3:	5b                   	pop    %ebx
801025a4:	5f                   	pop    %edi
801025a5:	5d                   	pop    %ebp
801025a6:	c3                   	ret    

801025a7 <outb>:

static inline void
outb(ushort port, uchar data)
{
801025a7:	55                   	push   %ebp
801025a8:	89 e5                	mov    %esp,%ebp
801025aa:	83 ec 08             	sub    $0x8,%esp
801025ad:	8b 55 08             	mov    0x8(%ebp),%edx
801025b0:	8b 45 0c             	mov    0xc(%ebp),%eax
801025b3:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801025b7:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801025ba:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801025be:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801025c2:	ee                   	out    %al,(%dx)
}
801025c3:	c9                   	leave  
801025c4:	c3                   	ret    

801025c5 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
801025c5:	55                   	push   %ebp
801025c6:	89 e5                	mov    %esp,%ebp
801025c8:	56                   	push   %esi
801025c9:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
801025ca:	8b 55 08             	mov    0x8(%ebp),%edx
801025cd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801025d0:	8b 45 10             	mov    0x10(%ebp),%eax
801025d3:	89 cb                	mov    %ecx,%ebx
801025d5:	89 de                	mov    %ebx,%esi
801025d7:	89 c1                	mov    %eax,%ecx
801025d9:	fc                   	cld    
801025da:	f3 6f                	rep outsl %ds:(%esi),(%dx)
801025dc:	89 c8                	mov    %ecx,%eax
801025de:	89 f3                	mov    %esi,%ebx
801025e0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801025e3:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
801025e6:	5b                   	pop    %ebx
801025e7:	5e                   	pop    %esi
801025e8:	5d                   	pop    %ebp
801025e9:	c3                   	ret    

801025ea <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
801025ea:	55                   	push   %ebp
801025eb:	89 e5                	mov    %esp,%ebp
801025ed:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
801025f0:	90                   	nop
801025f1:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801025f8:	e8 68 ff ff ff       	call   80102565 <inb>
801025fd:	0f b6 c0             	movzbl %al,%eax
80102600:	89 45 fc             	mov    %eax,-0x4(%ebp)
80102603:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102606:	25 c0 00 00 00       	and    $0xc0,%eax
8010260b:	83 f8 40             	cmp    $0x40,%eax
8010260e:	75 e1                	jne    801025f1 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102610:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102614:	74 11                	je     80102627 <idewait+0x3d>
80102616:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102619:	83 e0 21             	and    $0x21,%eax
8010261c:	85 c0                	test   %eax,%eax
8010261e:	74 07                	je     80102627 <idewait+0x3d>
    return -1;
80102620:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102625:	eb 05                	jmp    8010262c <idewait+0x42>
  return 0;
80102627:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010262c:	c9                   	leave  
8010262d:	c3                   	ret    

8010262e <ideinit>:

void
ideinit(void)
{
8010262e:	55                   	push   %ebp
8010262f:	89 e5                	mov    %esp,%ebp
80102631:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
80102634:	c7 44 24 04 b4 88 10 	movl   $0x801088b4,0x4(%esp)
8010263b:	80 
8010263c:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102643:	e8 d3 2a 00 00       	call   8010511b <initlock>
  picenable(IRQ_IDE);
80102648:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
8010264f:	e8 80 18 00 00       	call   80103ed4 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102654:	a1 80 29 11 80       	mov    0x80112980,%eax
80102659:	83 e8 01             	sub    $0x1,%eax
8010265c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102660:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102667:	e8 0c 04 00 00       	call   80102a78 <ioapicenable>
  idewait(0);
8010266c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102673:	e8 72 ff ff ff       	call   801025ea <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80102678:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
8010267f:	00 
80102680:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102687:	e8 1b ff ff ff       	call   801025a7 <outb>
  for(i=0; i<1000; i++){
8010268c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102693:	eb 20                	jmp    801026b5 <ideinit+0x87>
    if(inb(0x1f7) != 0){
80102695:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010269c:	e8 c4 fe ff ff       	call   80102565 <inb>
801026a1:	84 c0                	test   %al,%al
801026a3:	74 0c                	je     801026b1 <ideinit+0x83>
      havedisk1 = 1;
801026a5:	c7 05 38 b6 10 80 01 	movl   $0x1,0x8010b638
801026ac:	00 00 00 
      break;
801026af:	eb 0d                	jmp    801026be <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
801026b1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801026b5:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
801026bc:	7e d7                	jle    80102695 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
801026be:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
801026c5:	00 
801026c6:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801026cd:	e8 d5 fe ff ff       	call   801025a7 <outb>
}
801026d2:	c9                   	leave  
801026d3:	c3                   	ret    

801026d4 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
801026d4:	55                   	push   %ebp
801026d5:	89 e5                	mov    %esp,%ebp
801026d7:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
801026da:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801026de:	75 0c                	jne    801026ec <idestart+0x18>
    panic("idestart");
801026e0:	c7 04 24 b8 88 10 80 	movl   $0x801088b8,(%esp)
801026e7:	e8 4e de ff ff       	call   8010053a <panic>

  idewait(0);
801026ec:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801026f3:	e8 f2 fe ff ff       	call   801025ea <idewait>
  outb(0x3f6, 0);  // generate interrupt
801026f8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801026ff:	00 
80102700:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
80102707:	e8 9b fe ff ff       	call   801025a7 <outb>
  outb(0x1f2, 1);  // number of sectors
8010270c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102713:	00 
80102714:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
8010271b:	e8 87 fe ff ff       	call   801025a7 <outb>
  outb(0x1f3, b->sector & 0xff);
80102720:	8b 45 08             	mov    0x8(%ebp),%eax
80102723:	8b 40 08             	mov    0x8(%eax),%eax
80102726:	0f b6 c0             	movzbl %al,%eax
80102729:	89 44 24 04          	mov    %eax,0x4(%esp)
8010272d:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80102734:	e8 6e fe ff ff       	call   801025a7 <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
80102739:	8b 45 08             	mov    0x8(%ebp),%eax
8010273c:	8b 40 08             	mov    0x8(%eax),%eax
8010273f:	c1 e8 08             	shr    $0x8,%eax
80102742:	0f b6 c0             	movzbl %al,%eax
80102745:	89 44 24 04          	mov    %eax,0x4(%esp)
80102749:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102750:	e8 52 fe ff ff       	call   801025a7 <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
80102755:	8b 45 08             	mov    0x8(%ebp),%eax
80102758:	8b 40 08             	mov    0x8(%eax),%eax
8010275b:	c1 e8 10             	shr    $0x10,%eax
8010275e:	0f b6 c0             	movzbl %al,%eax
80102761:	89 44 24 04          	mov    %eax,0x4(%esp)
80102765:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
8010276c:	e8 36 fe ff ff       	call   801025a7 <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
80102771:	8b 45 08             	mov    0x8(%ebp),%eax
80102774:	8b 40 04             	mov    0x4(%eax),%eax
80102777:	83 e0 01             	and    $0x1,%eax
8010277a:	c1 e0 04             	shl    $0x4,%eax
8010277d:	89 c2                	mov    %eax,%edx
8010277f:	8b 45 08             	mov    0x8(%ebp),%eax
80102782:	8b 40 08             	mov    0x8(%eax),%eax
80102785:	c1 e8 18             	shr    $0x18,%eax
80102788:	83 e0 0f             	and    $0xf,%eax
8010278b:	09 d0                	or     %edx,%eax
8010278d:	83 c8 e0             	or     $0xffffffe0,%eax
80102790:	0f b6 c0             	movzbl %al,%eax
80102793:	89 44 24 04          	mov    %eax,0x4(%esp)
80102797:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010279e:	e8 04 fe ff ff       	call   801025a7 <outb>
  if(b->flags & B_DIRTY){
801027a3:	8b 45 08             	mov    0x8(%ebp),%eax
801027a6:	8b 00                	mov    (%eax),%eax
801027a8:	83 e0 04             	and    $0x4,%eax
801027ab:	85 c0                	test   %eax,%eax
801027ad:	74 34                	je     801027e3 <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
801027af:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
801027b6:	00 
801027b7:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801027be:	e8 e4 fd ff ff       	call   801025a7 <outb>
    outsl(0x1f0, b->data, 512/4);
801027c3:	8b 45 08             	mov    0x8(%ebp),%eax
801027c6:	83 c0 18             	add    $0x18,%eax
801027c9:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801027d0:	00 
801027d1:	89 44 24 04          	mov    %eax,0x4(%esp)
801027d5:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
801027dc:	e8 e4 fd ff ff       	call   801025c5 <outsl>
801027e1:	eb 14                	jmp    801027f7 <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
801027e3:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801027ea:	00 
801027eb:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801027f2:	e8 b0 fd ff ff       	call   801025a7 <outb>
  }
}
801027f7:	c9                   	leave  
801027f8:	c3                   	ret    

801027f9 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
801027f9:	55                   	push   %ebp
801027fa:	89 e5                	mov    %esp,%ebp
801027fc:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
801027ff:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102806:	e8 31 29 00 00       	call   8010513c <acquire>
  if((b = idequeue) == 0){
8010280b:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102810:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102813:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102817:	75 11                	jne    8010282a <ideintr+0x31>
    release(&idelock);
80102819:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102820:	e8 79 29 00 00       	call   8010519e <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80102825:	e9 90 00 00 00       	jmp    801028ba <ideintr+0xc1>
  }
  idequeue = b->qnext;
8010282a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010282d:	8b 40 14             	mov    0x14(%eax),%eax
80102830:	a3 34 b6 10 80       	mov    %eax,0x8010b634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80102835:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102838:	8b 00                	mov    (%eax),%eax
8010283a:	83 e0 04             	and    $0x4,%eax
8010283d:	85 c0                	test   %eax,%eax
8010283f:	75 2e                	jne    8010286f <ideintr+0x76>
80102841:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102848:	e8 9d fd ff ff       	call   801025ea <idewait>
8010284d:	85 c0                	test   %eax,%eax
8010284f:	78 1e                	js     8010286f <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
80102851:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102854:	83 c0 18             	add    $0x18,%eax
80102857:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010285e:	00 
8010285f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102863:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
8010286a:	e8 13 fd ff ff       	call   80102582 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
8010286f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102872:	8b 00                	mov    (%eax),%eax
80102874:	83 c8 02             	or     $0x2,%eax
80102877:	89 c2                	mov    %eax,%edx
80102879:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010287c:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
8010287e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102881:	8b 00                	mov    (%eax),%eax
80102883:	83 e0 fb             	and    $0xfffffffb,%eax
80102886:	89 c2                	mov    %eax,%edx
80102888:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010288b:	89 10                	mov    %edx,(%eax)
  wakeup(b);
8010288d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102890:	89 04 24             	mov    %eax,(%esp)
80102893:	e8 81 24 00 00       	call   80104d19 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80102898:	a1 34 b6 10 80       	mov    0x8010b634,%eax
8010289d:	85 c0                	test   %eax,%eax
8010289f:	74 0d                	je     801028ae <ideintr+0xb5>
    idestart(idequeue);
801028a1:	a1 34 b6 10 80       	mov    0x8010b634,%eax
801028a6:	89 04 24             	mov    %eax,(%esp)
801028a9:	e8 26 fe ff ff       	call   801026d4 <idestart>

  release(&idelock);
801028ae:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801028b5:	e8 e4 28 00 00       	call   8010519e <release>
}
801028ba:	c9                   	leave  
801028bb:	c3                   	ret    

801028bc <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
801028bc:	55                   	push   %ebp
801028bd:	89 e5                	mov    %esp,%ebp
801028bf:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
801028c2:	8b 45 08             	mov    0x8(%ebp),%eax
801028c5:	8b 00                	mov    (%eax),%eax
801028c7:	83 e0 01             	and    $0x1,%eax
801028ca:	85 c0                	test   %eax,%eax
801028cc:	75 0c                	jne    801028da <iderw+0x1e>
    panic("iderw: buf not busy");
801028ce:	c7 04 24 c1 88 10 80 	movl   $0x801088c1,(%esp)
801028d5:	e8 60 dc ff ff       	call   8010053a <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
801028da:	8b 45 08             	mov    0x8(%ebp),%eax
801028dd:	8b 00                	mov    (%eax),%eax
801028df:	83 e0 06             	and    $0x6,%eax
801028e2:	83 f8 02             	cmp    $0x2,%eax
801028e5:	75 0c                	jne    801028f3 <iderw+0x37>
    panic("iderw: nothing to do");
801028e7:	c7 04 24 d5 88 10 80 	movl   $0x801088d5,(%esp)
801028ee:	e8 47 dc ff ff       	call   8010053a <panic>
  if(b->dev != 0 && !havedisk1)
801028f3:	8b 45 08             	mov    0x8(%ebp),%eax
801028f6:	8b 40 04             	mov    0x4(%eax),%eax
801028f9:	85 c0                	test   %eax,%eax
801028fb:	74 15                	je     80102912 <iderw+0x56>
801028fd:	a1 38 b6 10 80       	mov    0x8010b638,%eax
80102902:	85 c0                	test   %eax,%eax
80102904:	75 0c                	jne    80102912 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
80102906:	c7 04 24 ea 88 10 80 	movl   $0x801088ea,(%esp)
8010290d:	e8 28 dc ff ff       	call   8010053a <panic>

  acquire(&idelock);  //DOC:acquire-lock
80102912:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102919:	e8 1e 28 00 00       	call   8010513c <acquire>

  // Append b to idequeue.
  b->qnext = 0;
8010291e:	8b 45 08             	mov    0x8(%ebp),%eax
80102921:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80102928:	c7 45 f4 34 b6 10 80 	movl   $0x8010b634,-0xc(%ebp)
8010292f:	eb 0b                	jmp    8010293c <iderw+0x80>
80102931:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102934:	8b 00                	mov    (%eax),%eax
80102936:	83 c0 14             	add    $0x14,%eax
80102939:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010293c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010293f:	8b 00                	mov    (%eax),%eax
80102941:	85 c0                	test   %eax,%eax
80102943:	75 ec                	jne    80102931 <iderw+0x75>
    ;
  *pp = b;
80102945:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102948:	8b 55 08             	mov    0x8(%ebp),%edx
8010294b:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
8010294d:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102952:	3b 45 08             	cmp    0x8(%ebp),%eax
80102955:	75 0d                	jne    80102964 <iderw+0xa8>
    idestart(b);
80102957:	8b 45 08             	mov    0x8(%ebp),%eax
8010295a:	89 04 24             	mov    %eax,(%esp)
8010295d:	e8 72 fd ff ff       	call   801026d4 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102962:	eb 15                	jmp    80102979 <iderw+0xbd>
80102964:	eb 13                	jmp    80102979 <iderw+0xbd>
    sleep(b, &idelock);
80102966:	c7 44 24 04 00 b6 10 	movl   $0x8010b600,0x4(%esp)
8010296d:	80 
8010296e:	8b 45 08             	mov    0x8(%ebp),%eax
80102971:	89 04 24             	mov    %eax,(%esp)
80102974:	e8 c7 22 00 00       	call   80104c40 <sleep>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102979:	8b 45 08             	mov    0x8(%ebp),%eax
8010297c:	8b 00                	mov    (%eax),%eax
8010297e:	83 e0 06             	and    $0x6,%eax
80102981:	83 f8 02             	cmp    $0x2,%eax
80102984:	75 e0                	jne    80102966 <iderw+0xaa>
    sleep(b, &idelock);
  }

  release(&idelock);
80102986:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
8010298d:	e8 0c 28 00 00       	call   8010519e <release>
}
80102992:	c9                   	leave  
80102993:	c3                   	ret    

80102994 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102994:	55                   	push   %ebp
80102995:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102997:	a1 54 22 11 80       	mov    0x80112254,%eax
8010299c:	8b 55 08             	mov    0x8(%ebp),%edx
8010299f:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
801029a1:	a1 54 22 11 80       	mov    0x80112254,%eax
801029a6:	8b 40 10             	mov    0x10(%eax),%eax
}
801029a9:	5d                   	pop    %ebp
801029aa:	c3                   	ret    

801029ab <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
801029ab:	55                   	push   %ebp
801029ac:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
801029ae:	a1 54 22 11 80       	mov    0x80112254,%eax
801029b3:	8b 55 08             	mov    0x8(%ebp),%edx
801029b6:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
801029b8:	a1 54 22 11 80       	mov    0x80112254,%eax
801029bd:	8b 55 0c             	mov    0xc(%ebp),%edx
801029c0:	89 50 10             	mov    %edx,0x10(%eax)
}
801029c3:	5d                   	pop    %ebp
801029c4:	c3                   	ret    

801029c5 <ioapicinit>:

void
ioapicinit(void)
{
801029c5:	55                   	push   %ebp
801029c6:	89 e5                	mov    %esp,%ebp
801029c8:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
801029cb:	a1 84 23 11 80       	mov    0x80112384,%eax
801029d0:	85 c0                	test   %eax,%eax
801029d2:	75 05                	jne    801029d9 <ioapicinit+0x14>
    return;
801029d4:	e9 9d 00 00 00       	jmp    80102a76 <ioapicinit+0xb1>

  ioapic = (volatile struct ioapic*)IOAPIC;
801029d9:	c7 05 54 22 11 80 00 	movl   $0xfec00000,0x80112254
801029e0:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
801029e3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801029ea:	e8 a5 ff ff ff       	call   80102994 <ioapicread>
801029ef:	c1 e8 10             	shr    $0x10,%eax
801029f2:	25 ff 00 00 00       	and    $0xff,%eax
801029f7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
801029fa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102a01:	e8 8e ff ff ff       	call   80102994 <ioapicread>
80102a06:	c1 e8 18             	shr    $0x18,%eax
80102a09:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80102a0c:	0f b6 05 80 23 11 80 	movzbl 0x80112380,%eax
80102a13:	0f b6 c0             	movzbl %al,%eax
80102a16:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102a19:	74 0c                	je     80102a27 <ioapicinit+0x62>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102a1b:	c7 04 24 08 89 10 80 	movl   $0x80108908,(%esp)
80102a22:	e8 79 d9 ff ff       	call   801003a0 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102a27:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102a2e:	eb 3e                	jmp    80102a6e <ioapicinit+0xa9>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80102a30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a33:	83 c0 20             	add    $0x20,%eax
80102a36:	0d 00 00 01 00       	or     $0x10000,%eax
80102a3b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102a3e:	83 c2 08             	add    $0x8,%edx
80102a41:	01 d2                	add    %edx,%edx
80102a43:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a47:	89 14 24             	mov    %edx,(%esp)
80102a4a:	e8 5c ff ff ff       	call   801029ab <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102a4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a52:	83 c0 08             	add    $0x8,%eax
80102a55:	01 c0                	add    %eax,%eax
80102a57:	83 c0 01             	add    $0x1,%eax
80102a5a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102a61:	00 
80102a62:	89 04 24             	mov    %eax,(%esp)
80102a65:	e8 41 ff ff ff       	call   801029ab <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102a6a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102a6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a71:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80102a74:	7e ba                	jle    80102a30 <ioapicinit+0x6b>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80102a76:	c9                   	leave  
80102a77:	c3                   	ret    

80102a78 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102a78:	55                   	push   %ebp
80102a79:	89 e5                	mov    %esp,%ebp
80102a7b:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80102a7e:	a1 84 23 11 80       	mov    0x80112384,%eax
80102a83:	85 c0                	test   %eax,%eax
80102a85:	75 02                	jne    80102a89 <ioapicenable+0x11>
    return;
80102a87:	eb 37                	jmp    80102ac0 <ioapicenable+0x48>

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80102a89:	8b 45 08             	mov    0x8(%ebp),%eax
80102a8c:	83 c0 20             	add    $0x20,%eax
80102a8f:	8b 55 08             	mov    0x8(%ebp),%edx
80102a92:	83 c2 08             	add    $0x8,%edx
80102a95:	01 d2                	add    %edx,%edx
80102a97:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a9b:	89 14 24             	mov    %edx,(%esp)
80102a9e:	e8 08 ff ff ff       	call   801029ab <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80102aa3:	8b 45 0c             	mov    0xc(%ebp),%eax
80102aa6:	c1 e0 18             	shl    $0x18,%eax
80102aa9:	8b 55 08             	mov    0x8(%ebp),%edx
80102aac:	83 c2 08             	add    $0x8,%edx
80102aaf:	01 d2                	add    %edx,%edx
80102ab1:	83 c2 01             	add    $0x1,%edx
80102ab4:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ab8:	89 14 24             	mov    %edx,(%esp)
80102abb:	e8 eb fe ff ff       	call   801029ab <ioapicwrite>
}
80102ac0:	c9                   	leave  
80102ac1:	c3                   	ret    

80102ac2 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80102ac2:	55                   	push   %ebp
80102ac3:	89 e5                	mov    %esp,%ebp
80102ac5:	8b 45 08             	mov    0x8(%ebp),%eax
80102ac8:	05 00 00 00 80       	add    $0x80000000,%eax
80102acd:	5d                   	pop    %ebp
80102ace:	c3                   	ret    

80102acf <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80102acf:	55                   	push   %ebp
80102ad0:	89 e5                	mov    %esp,%ebp
80102ad2:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80102ad5:	c7 44 24 04 3a 89 10 	movl   $0x8010893a,0x4(%esp)
80102adc:	80 
80102add:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80102ae4:	e8 32 26 00 00       	call   8010511b <initlock>
  kmem.use_lock = 0;
80102ae9:	c7 05 94 22 11 80 00 	movl   $0x0,0x80112294
80102af0:	00 00 00 
  freerange(vstart, vend);
80102af3:	8b 45 0c             	mov    0xc(%ebp),%eax
80102af6:	89 44 24 04          	mov    %eax,0x4(%esp)
80102afa:	8b 45 08             	mov    0x8(%ebp),%eax
80102afd:	89 04 24             	mov    %eax,(%esp)
80102b00:	e8 26 00 00 00       	call   80102b2b <freerange>
}
80102b05:	c9                   	leave  
80102b06:	c3                   	ret    

80102b07 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102b07:	55                   	push   %ebp
80102b08:	89 e5                	mov    %esp,%ebp
80102b0a:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80102b0d:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b10:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b14:	8b 45 08             	mov    0x8(%ebp),%eax
80102b17:	89 04 24             	mov    %eax,(%esp)
80102b1a:	e8 0c 00 00 00       	call   80102b2b <freerange>
  kmem.use_lock = 1;
80102b1f:	c7 05 94 22 11 80 01 	movl   $0x1,0x80112294
80102b26:	00 00 00 
}
80102b29:	c9                   	leave  
80102b2a:	c3                   	ret    

80102b2b <freerange>:

void
freerange(void *vstart, void *vend)
{
80102b2b:	55                   	push   %ebp
80102b2c:	89 e5                	mov    %esp,%ebp
80102b2e:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102b31:	8b 45 08             	mov    0x8(%ebp),%eax
80102b34:	05 ff 0f 00 00       	add    $0xfff,%eax
80102b39:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102b3e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102b41:	eb 12                	jmp    80102b55 <freerange+0x2a>
    kfree(p);
80102b43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b46:	89 04 24             	mov    %eax,(%esp)
80102b49:	e8 16 00 00 00       	call   80102b64 <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102b4e:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102b55:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b58:	05 00 10 00 00       	add    $0x1000,%eax
80102b5d:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102b60:	76 e1                	jbe    80102b43 <freerange+0x18>
    kfree(p);
}
80102b62:	c9                   	leave  
80102b63:	c3                   	ret    

80102b64 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102b64:	55                   	push   %ebp
80102b65:	89 e5                	mov    %esp,%ebp
80102b67:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80102b6a:	8b 45 08             	mov    0x8(%ebp),%eax
80102b6d:	25 ff 0f 00 00       	and    $0xfff,%eax
80102b72:	85 c0                	test   %eax,%eax
80102b74:	75 1b                	jne    80102b91 <kfree+0x2d>
80102b76:	81 7d 08 7c 51 11 80 	cmpl   $0x8011517c,0x8(%ebp)
80102b7d:	72 12                	jb     80102b91 <kfree+0x2d>
80102b7f:	8b 45 08             	mov    0x8(%ebp),%eax
80102b82:	89 04 24             	mov    %eax,(%esp)
80102b85:	e8 38 ff ff ff       	call   80102ac2 <v2p>
80102b8a:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102b8f:	76 0c                	jbe    80102b9d <kfree+0x39>
    panic("kfree");
80102b91:	c7 04 24 3f 89 10 80 	movl   $0x8010893f,(%esp)
80102b98:	e8 9d d9 ff ff       	call   8010053a <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102b9d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102ba4:	00 
80102ba5:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102bac:	00 
80102bad:	8b 45 08             	mov    0x8(%ebp),%eax
80102bb0:	89 04 24             	mov    %eax,(%esp)
80102bb3:	e8 d8 27 00 00       	call   80105390 <memset>

  if(kmem.use_lock)
80102bb8:	a1 94 22 11 80       	mov    0x80112294,%eax
80102bbd:	85 c0                	test   %eax,%eax
80102bbf:	74 0c                	je     80102bcd <kfree+0x69>
    acquire(&kmem.lock);
80102bc1:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80102bc8:	e8 6f 25 00 00       	call   8010513c <acquire>
  r = (struct run*)v;
80102bcd:	8b 45 08             	mov    0x8(%ebp),%eax
80102bd0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102bd3:	8b 15 98 22 11 80    	mov    0x80112298,%edx
80102bd9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102bdc:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102bde:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102be1:	a3 98 22 11 80       	mov    %eax,0x80112298
  if(kmem.use_lock)
80102be6:	a1 94 22 11 80       	mov    0x80112294,%eax
80102beb:	85 c0                	test   %eax,%eax
80102bed:	74 0c                	je     80102bfb <kfree+0x97>
    release(&kmem.lock);
80102bef:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80102bf6:	e8 a3 25 00 00       	call   8010519e <release>
}
80102bfb:	c9                   	leave  
80102bfc:	c3                   	ret    

80102bfd <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102bfd:	55                   	push   %ebp
80102bfe:	89 e5                	mov    %esp,%ebp
80102c00:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80102c03:	a1 94 22 11 80       	mov    0x80112294,%eax
80102c08:	85 c0                	test   %eax,%eax
80102c0a:	74 0c                	je     80102c18 <kalloc+0x1b>
    acquire(&kmem.lock);
80102c0c:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80102c13:	e8 24 25 00 00       	call   8010513c <acquire>
  r = kmem.freelist;
80102c18:	a1 98 22 11 80       	mov    0x80112298,%eax
80102c1d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102c20:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102c24:	74 0a                	je     80102c30 <kalloc+0x33>
    kmem.freelist = r->next;
80102c26:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c29:	8b 00                	mov    (%eax),%eax
80102c2b:	a3 98 22 11 80       	mov    %eax,0x80112298
  if(kmem.use_lock)
80102c30:	a1 94 22 11 80       	mov    0x80112294,%eax
80102c35:	85 c0                	test   %eax,%eax
80102c37:	74 0c                	je     80102c45 <kalloc+0x48>
    release(&kmem.lock);
80102c39:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80102c40:	e8 59 25 00 00       	call   8010519e <release>
  return (char*)r;
80102c45:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102c48:	c9                   	leave  
80102c49:	c3                   	ret    

80102c4a <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102c4a:	55                   	push   %ebp
80102c4b:	89 e5                	mov    %esp,%ebp
80102c4d:	83 ec 14             	sub    $0x14,%esp
80102c50:	8b 45 08             	mov    0x8(%ebp),%eax
80102c53:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102c57:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102c5b:	89 c2                	mov    %eax,%edx
80102c5d:	ec                   	in     (%dx),%al
80102c5e:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102c61:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102c65:	c9                   	leave  
80102c66:	c3                   	ret    

80102c67 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102c67:	55                   	push   %ebp
80102c68:	89 e5                	mov    %esp,%ebp
80102c6a:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102c6d:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102c74:	e8 d1 ff ff ff       	call   80102c4a <inb>
80102c79:	0f b6 c0             	movzbl %al,%eax
80102c7c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102c7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c82:	83 e0 01             	and    $0x1,%eax
80102c85:	85 c0                	test   %eax,%eax
80102c87:	75 0a                	jne    80102c93 <kbdgetc+0x2c>
    return -1;
80102c89:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102c8e:	e9 25 01 00 00       	jmp    80102db8 <kbdgetc+0x151>
  data = inb(KBDATAP);
80102c93:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80102c9a:	e8 ab ff ff ff       	call   80102c4a <inb>
80102c9f:	0f b6 c0             	movzbl %al,%eax
80102ca2:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102ca5:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102cac:	75 17                	jne    80102cc5 <kbdgetc+0x5e>
    shift |= E0ESC;
80102cae:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102cb3:	83 c8 40             	or     $0x40,%eax
80102cb6:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102cbb:	b8 00 00 00 00       	mov    $0x0,%eax
80102cc0:	e9 f3 00 00 00       	jmp    80102db8 <kbdgetc+0x151>
  } else if(data & 0x80){
80102cc5:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102cc8:	25 80 00 00 00       	and    $0x80,%eax
80102ccd:	85 c0                	test   %eax,%eax
80102ccf:	74 45                	je     80102d16 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102cd1:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102cd6:	83 e0 40             	and    $0x40,%eax
80102cd9:	85 c0                	test   %eax,%eax
80102cdb:	75 08                	jne    80102ce5 <kbdgetc+0x7e>
80102cdd:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102ce0:	83 e0 7f             	and    $0x7f,%eax
80102ce3:	eb 03                	jmp    80102ce8 <kbdgetc+0x81>
80102ce5:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102ce8:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102ceb:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102cee:	05 20 90 10 80       	add    $0x80109020,%eax
80102cf3:	0f b6 00             	movzbl (%eax),%eax
80102cf6:	83 c8 40             	or     $0x40,%eax
80102cf9:	0f b6 c0             	movzbl %al,%eax
80102cfc:	f7 d0                	not    %eax
80102cfe:	89 c2                	mov    %eax,%edx
80102d00:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d05:	21 d0                	and    %edx,%eax
80102d07:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102d0c:	b8 00 00 00 00       	mov    $0x0,%eax
80102d11:	e9 a2 00 00 00       	jmp    80102db8 <kbdgetc+0x151>
  } else if(shift & E0ESC){
80102d16:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d1b:	83 e0 40             	and    $0x40,%eax
80102d1e:	85 c0                	test   %eax,%eax
80102d20:	74 14                	je     80102d36 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102d22:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102d29:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d2e:	83 e0 bf             	and    $0xffffffbf,%eax
80102d31:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  }

  shift |= shiftcode[data];
80102d36:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d39:	05 20 90 10 80       	add    $0x80109020,%eax
80102d3e:	0f b6 00             	movzbl (%eax),%eax
80102d41:	0f b6 d0             	movzbl %al,%edx
80102d44:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d49:	09 d0                	or     %edx,%eax
80102d4b:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  shift ^= togglecode[data];
80102d50:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d53:	05 20 91 10 80       	add    $0x80109120,%eax
80102d58:	0f b6 00             	movzbl (%eax),%eax
80102d5b:	0f b6 d0             	movzbl %al,%edx
80102d5e:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d63:	31 d0                	xor    %edx,%eax
80102d65:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  c = charcode[shift & (CTL | SHIFT)][data];
80102d6a:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d6f:	83 e0 03             	and    $0x3,%eax
80102d72:	8b 14 85 20 95 10 80 	mov    -0x7fef6ae0(,%eax,4),%edx
80102d79:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d7c:	01 d0                	add    %edx,%eax
80102d7e:	0f b6 00             	movzbl (%eax),%eax
80102d81:	0f b6 c0             	movzbl %al,%eax
80102d84:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102d87:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d8c:	83 e0 08             	and    $0x8,%eax
80102d8f:	85 c0                	test   %eax,%eax
80102d91:	74 22                	je     80102db5 <kbdgetc+0x14e>
    if('a' <= c && c <= 'z')
80102d93:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102d97:	76 0c                	jbe    80102da5 <kbdgetc+0x13e>
80102d99:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102d9d:	77 06                	ja     80102da5 <kbdgetc+0x13e>
      c += 'A' - 'a';
80102d9f:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102da3:	eb 10                	jmp    80102db5 <kbdgetc+0x14e>
    else if('A' <= c && c <= 'Z')
80102da5:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102da9:	76 0a                	jbe    80102db5 <kbdgetc+0x14e>
80102dab:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102daf:	77 04                	ja     80102db5 <kbdgetc+0x14e>
      c += 'a' - 'A';
80102db1:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102db5:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102db8:	c9                   	leave  
80102db9:	c3                   	ret    

80102dba <kbdintr>:

void
kbdintr(void)
{
80102dba:	55                   	push   %ebp
80102dbb:	89 e5                	mov    %esp,%ebp
80102dbd:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80102dc0:	c7 04 24 67 2c 10 80 	movl   $0x80102c67,(%esp)
80102dc7:	e8 e1 d9 ff ff       	call   801007ad <consoleintr>
}
80102dcc:	c9                   	leave  
80102dcd:	c3                   	ret    

80102dce <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102dce:	55                   	push   %ebp
80102dcf:	89 e5                	mov    %esp,%ebp
80102dd1:	83 ec 14             	sub    $0x14,%esp
80102dd4:	8b 45 08             	mov    0x8(%ebp),%eax
80102dd7:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102ddb:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102ddf:	89 c2                	mov    %eax,%edx
80102de1:	ec                   	in     (%dx),%al
80102de2:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102de5:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102de9:	c9                   	leave  
80102dea:	c3                   	ret    

80102deb <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80102deb:	55                   	push   %ebp
80102dec:	89 e5                	mov    %esp,%ebp
80102dee:	83 ec 08             	sub    $0x8,%esp
80102df1:	8b 55 08             	mov    0x8(%ebp),%edx
80102df4:	8b 45 0c             	mov    0xc(%ebp),%eax
80102df7:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102dfb:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102dfe:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102e02:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102e06:	ee                   	out    %al,(%dx)
}
80102e07:	c9                   	leave  
80102e08:	c3                   	ret    

80102e09 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80102e09:	55                   	push   %ebp
80102e0a:	89 e5                	mov    %esp,%ebp
80102e0c:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80102e0f:	9c                   	pushf  
80102e10:	58                   	pop    %eax
80102e11:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80102e14:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80102e17:	c9                   	leave  
80102e18:	c3                   	ret    

80102e19 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102e19:	55                   	push   %ebp
80102e1a:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102e1c:	a1 9c 22 11 80       	mov    0x8011229c,%eax
80102e21:	8b 55 08             	mov    0x8(%ebp),%edx
80102e24:	c1 e2 02             	shl    $0x2,%edx
80102e27:	01 c2                	add    %eax,%edx
80102e29:	8b 45 0c             	mov    0xc(%ebp),%eax
80102e2c:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102e2e:	a1 9c 22 11 80       	mov    0x8011229c,%eax
80102e33:	83 c0 20             	add    $0x20,%eax
80102e36:	8b 00                	mov    (%eax),%eax
}
80102e38:	5d                   	pop    %ebp
80102e39:	c3                   	ret    

80102e3a <lapicinit>:
//PAGEBREAK!

void
lapicinit(void)
{
80102e3a:	55                   	push   %ebp
80102e3b:	89 e5                	mov    %esp,%ebp
80102e3d:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80102e40:	a1 9c 22 11 80       	mov    0x8011229c,%eax
80102e45:	85 c0                	test   %eax,%eax
80102e47:	75 05                	jne    80102e4e <lapicinit+0x14>
    return;
80102e49:	e9 43 01 00 00       	jmp    80102f91 <lapicinit+0x157>

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102e4e:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80102e55:	00 
80102e56:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80102e5d:	e8 b7 ff ff ff       	call   80102e19 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102e62:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80102e69:	00 
80102e6a:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80102e71:	e8 a3 ff ff ff       	call   80102e19 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102e76:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80102e7d:	00 
80102e7e:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102e85:	e8 8f ff ff ff       	call   80102e19 <lapicw>
  lapicw(TICR, 10000000); 
80102e8a:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80102e91:	00 
80102e92:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80102e99:	e8 7b ff ff ff       	call   80102e19 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102e9e:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102ea5:	00 
80102ea6:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80102ead:	e8 67 ff ff ff       	call   80102e19 <lapicw>
  lapicw(LINT1, MASKED);
80102eb2:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102eb9:	00 
80102eba:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80102ec1:	e8 53 ff ff ff       	call   80102e19 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102ec6:	a1 9c 22 11 80       	mov    0x8011229c,%eax
80102ecb:	83 c0 30             	add    $0x30,%eax
80102ece:	8b 00                	mov    (%eax),%eax
80102ed0:	c1 e8 10             	shr    $0x10,%eax
80102ed3:	0f b6 c0             	movzbl %al,%eax
80102ed6:	83 f8 03             	cmp    $0x3,%eax
80102ed9:	76 14                	jbe    80102eef <lapicinit+0xb5>
    lapicw(PCINT, MASKED);
80102edb:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102ee2:	00 
80102ee3:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80102eea:	e8 2a ff ff ff       	call   80102e19 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102eef:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80102ef6:	00 
80102ef7:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80102efe:	e8 16 ff ff ff       	call   80102e19 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80102f03:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f0a:	00 
80102f0b:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102f12:	e8 02 ff ff ff       	call   80102e19 <lapicw>
  lapicw(ESR, 0);
80102f17:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f1e:	00 
80102f1f:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102f26:	e8 ee fe ff ff       	call   80102e19 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80102f2b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f32:	00 
80102f33:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102f3a:	e8 da fe ff ff       	call   80102e19 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80102f3f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f46:	00 
80102f47:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102f4e:	e8 c6 fe ff ff       	call   80102e19 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102f53:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80102f5a:	00 
80102f5b:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102f62:	e8 b2 fe ff ff       	call   80102e19 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102f67:	90                   	nop
80102f68:	a1 9c 22 11 80       	mov    0x8011229c,%eax
80102f6d:	05 00 03 00 00       	add    $0x300,%eax
80102f72:	8b 00                	mov    (%eax),%eax
80102f74:	25 00 10 00 00       	and    $0x1000,%eax
80102f79:	85 c0                	test   %eax,%eax
80102f7b:	75 eb                	jne    80102f68 <lapicinit+0x12e>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80102f7d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f84:	00 
80102f85:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80102f8c:	e8 88 fe ff ff       	call   80102e19 <lapicw>
}
80102f91:	c9                   	leave  
80102f92:	c3                   	ret    

80102f93 <cpunum>:

int
cpunum(void)
{
80102f93:	55                   	push   %ebp
80102f94:	89 e5                	mov    %esp,%ebp
80102f96:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80102f99:	e8 6b fe ff ff       	call   80102e09 <readeflags>
80102f9e:	25 00 02 00 00       	and    $0x200,%eax
80102fa3:	85 c0                	test   %eax,%eax
80102fa5:	74 25                	je     80102fcc <cpunum+0x39>
    static int n;
    if(n++ == 0)
80102fa7:	a1 40 b6 10 80       	mov    0x8010b640,%eax
80102fac:	8d 50 01             	lea    0x1(%eax),%edx
80102faf:	89 15 40 b6 10 80    	mov    %edx,0x8010b640
80102fb5:	85 c0                	test   %eax,%eax
80102fb7:	75 13                	jne    80102fcc <cpunum+0x39>
      cprintf("cpu called from %x with interrupts enabled\n",
80102fb9:	8b 45 04             	mov    0x4(%ebp),%eax
80102fbc:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fc0:	c7 04 24 48 89 10 80 	movl   $0x80108948,(%esp)
80102fc7:	e8 d4 d3 ff ff       	call   801003a0 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80102fcc:	a1 9c 22 11 80       	mov    0x8011229c,%eax
80102fd1:	85 c0                	test   %eax,%eax
80102fd3:	74 0f                	je     80102fe4 <cpunum+0x51>
    return lapic[ID]>>24;
80102fd5:	a1 9c 22 11 80       	mov    0x8011229c,%eax
80102fda:	83 c0 20             	add    $0x20,%eax
80102fdd:	8b 00                	mov    (%eax),%eax
80102fdf:	c1 e8 18             	shr    $0x18,%eax
80102fe2:	eb 05                	jmp    80102fe9 <cpunum+0x56>
  return 0;
80102fe4:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102fe9:	c9                   	leave  
80102fea:	c3                   	ret    

80102feb <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80102feb:	55                   	push   %ebp
80102fec:	89 e5                	mov    %esp,%ebp
80102fee:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80102ff1:	a1 9c 22 11 80       	mov    0x8011229c,%eax
80102ff6:	85 c0                	test   %eax,%eax
80102ff8:	74 14                	je     8010300e <lapiceoi+0x23>
    lapicw(EOI, 0);
80102ffa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103001:	00 
80103002:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103009:	e8 0b fe ff ff       	call   80102e19 <lapicw>
}
8010300e:	c9                   	leave  
8010300f:	c3                   	ret    

80103010 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80103010:	55                   	push   %ebp
80103011:	89 e5                	mov    %esp,%ebp
}
80103013:	5d                   	pop    %ebp
80103014:	c3                   	ret    

80103015 <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
80103015:	55                   	push   %ebp
80103016:	89 e5                	mov    %esp,%ebp
80103018:	83 ec 1c             	sub    $0x1c,%esp
8010301b:	8b 45 08             	mov    0x8(%ebp),%eax
8010301e:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
80103021:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80103028:	00 
80103029:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80103030:	e8 b6 fd ff ff       	call   80102deb <outb>
  outb(CMOS_PORT+1, 0x0A);
80103035:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
8010303c:	00 
8010303d:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80103044:	e8 a2 fd ff ff       	call   80102deb <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80103049:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80103050:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103053:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80103058:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010305b:	8d 50 02             	lea    0x2(%eax),%edx
8010305e:	8b 45 0c             	mov    0xc(%ebp),%eax
80103061:	c1 e8 04             	shr    $0x4,%eax
80103064:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80103067:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
8010306b:	c1 e0 18             	shl    $0x18,%eax
8010306e:	89 44 24 04          	mov    %eax,0x4(%esp)
80103072:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103079:	e8 9b fd ff ff       	call   80102e19 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
8010307e:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80103085:	00 
80103086:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010308d:	e8 87 fd ff ff       	call   80102e19 <lapicw>
  microdelay(200);
80103092:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103099:	e8 72 ff ff ff       	call   80103010 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
8010309e:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
801030a5:	00 
801030a6:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801030ad:	e8 67 fd ff ff       	call   80102e19 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
801030b2:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
801030b9:	e8 52 ff ff ff       	call   80103010 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801030be:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801030c5:	eb 40                	jmp    80103107 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
801030c7:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801030cb:	c1 e0 18             	shl    $0x18,%eax
801030ce:	89 44 24 04          	mov    %eax,0x4(%esp)
801030d2:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801030d9:	e8 3b fd ff ff       	call   80102e19 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
801030de:	8b 45 0c             	mov    0xc(%ebp),%eax
801030e1:	c1 e8 0c             	shr    $0xc,%eax
801030e4:	80 cc 06             	or     $0x6,%ah
801030e7:	89 44 24 04          	mov    %eax,0x4(%esp)
801030eb:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801030f2:	e8 22 fd ff ff       	call   80102e19 <lapicw>
    microdelay(200);
801030f7:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801030fe:	e8 0d ff ff ff       	call   80103010 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103103:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103107:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
8010310b:	7e ba                	jle    801030c7 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
8010310d:	c9                   	leave  
8010310e:	c3                   	ret    

8010310f <cmos_read>:
#define DAY     0x07
#define MONTH   0x08
#define YEAR    0x09

static uint cmos_read(uint reg)
{
8010310f:	55                   	push   %ebp
80103110:	89 e5                	mov    %esp,%ebp
80103112:	83 ec 08             	sub    $0x8,%esp
  outb(CMOS_PORT,  reg);
80103115:	8b 45 08             	mov    0x8(%ebp),%eax
80103118:	0f b6 c0             	movzbl %al,%eax
8010311b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010311f:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80103126:	e8 c0 fc ff ff       	call   80102deb <outb>
  microdelay(200);
8010312b:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103132:	e8 d9 fe ff ff       	call   80103010 <microdelay>

  return inb(CMOS_RETURN);
80103137:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
8010313e:	e8 8b fc ff ff       	call   80102dce <inb>
80103143:	0f b6 c0             	movzbl %al,%eax
}
80103146:	c9                   	leave  
80103147:	c3                   	ret    

80103148 <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
80103148:	55                   	push   %ebp
80103149:	89 e5                	mov    %esp,%ebp
8010314b:	83 ec 04             	sub    $0x4,%esp
  r->second = cmos_read(SECS);
8010314e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80103155:	e8 b5 ff ff ff       	call   8010310f <cmos_read>
8010315a:	8b 55 08             	mov    0x8(%ebp),%edx
8010315d:	89 02                	mov    %eax,(%edx)
  r->minute = cmos_read(MINS);
8010315f:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80103166:	e8 a4 ff ff ff       	call   8010310f <cmos_read>
8010316b:	8b 55 08             	mov    0x8(%ebp),%edx
8010316e:	89 42 04             	mov    %eax,0x4(%edx)
  r->hour   = cmos_read(HOURS);
80103171:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80103178:	e8 92 ff ff ff       	call   8010310f <cmos_read>
8010317d:	8b 55 08             	mov    0x8(%ebp),%edx
80103180:	89 42 08             	mov    %eax,0x8(%edx)
  r->day    = cmos_read(DAY);
80103183:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
8010318a:	e8 80 ff ff ff       	call   8010310f <cmos_read>
8010318f:	8b 55 08             	mov    0x8(%ebp),%edx
80103192:	89 42 0c             	mov    %eax,0xc(%edx)
  r->month  = cmos_read(MONTH);
80103195:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010319c:	e8 6e ff ff ff       	call   8010310f <cmos_read>
801031a1:	8b 55 08             	mov    0x8(%ebp),%edx
801031a4:	89 42 10             	mov    %eax,0x10(%edx)
  r->year   = cmos_read(YEAR);
801031a7:	c7 04 24 09 00 00 00 	movl   $0x9,(%esp)
801031ae:	e8 5c ff ff ff       	call   8010310f <cmos_read>
801031b3:	8b 55 08             	mov    0x8(%ebp),%edx
801031b6:	89 42 14             	mov    %eax,0x14(%edx)
}
801031b9:	c9                   	leave  
801031ba:	c3                   	ret    

801031bb <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
801031bb:	55                   	push   %ebp
801031bc:	89 e5                	mov    %esp,%ebp
801031be:	83 ec 58             	sub    $0x58,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
801031c1:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
801031c8:	e8 42 ff ff ff       	call   8010310f <cmos_read>
801031cd:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
801031d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031d3:	83 e0 04             	and    $0x4,%eax
801031d6:	85 c0                	test   %eax,%eax
801031d8:	0f 94 c0             	sete   %al
801031db:	0f b6 c0             	movzbl %al,%eax
801031de:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
801031e1:	8d 45 d8             	lea    -0x28(%ebp),%eax
801031e4:	89 04 24             	mov    %eax,(%esp)
801031e7:	e8 5c ff ff ff       	call   80103148 <fill_rtcdate>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
801031ec:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
801031f3:	e8 17 ff ff ff       	call   8010310f <cmos_read>
801031f8:	25 80 00 00 00       	and    $0x80,%eax
801031fd:	85 c0                	test   %eax,%eax
801031ff:	74 02                	je     80103203 <cmostime+0x48>
        continue;
80103201:	eb 36                	jmp    80103239 <cmostime+0x7e>
    fill_rtcdate(&t2);
80103203:	8d 45 c0             	lea    -0x40(%ebp),%eax
80103206:	89 04 24             	mov    %eax,(%esp)
80103209:	e8 3a ff ff ff       	call   80103148 <fill_rtcdate>
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
8010320e:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
80103215:	00 
80103216:	8d 45 c0             	lea    -0x40(%ebp),%eax
80103219:	89 44 24 04          	mov    %eax,0x4(%esp)
8010321d:	8d 45 d8             	lea    -0x28(%ebp),%eax
80103220:	89 04 24             	mov    %eax,(%esp)
80103223:	e8 df 21 00 00       	call   80105407 <memcmp>
80103228:	85 c0                	test   %eax,%eax
8010322a:	75 0d                	jne    80103239 <cmostime+0x7e>
      break;
8010322c:	90                   	nop
  }

  // convert
  if (bcd) {
8010322d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103231:	0f 84 ac 00 00 00    	je     801032e3 <cmostime+0x128>
80103237:	eb 02                	jmp    8010323b <cmostime+0x80>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
80103239:	eb a6                	jmp    801031e1 <cmostime+0x26>

  // convert
  if (bcd) {
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
8010323b:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010323e:	c1 e8 04             	shr    $0x4,%eax
80103241:	89 c2                	mov    %eax,%edx
80103243:	89 d0                	mov    %edx,%eax
80103245:	c1 e0 02             	shl    $0x2,%eax
80103248:	01 d0                	add    %edx,%eax
8010324a:	01 c0                	add    %eax,%eax
8010324c:	8b 55 d8             	mov    -0x28(%ebp),%edx
8010324f:	83 e2 0f             	and    $0xf,%edx
80103252:	01 d0                	add    %edx,%eax
80103254:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
80103257:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010325a:	c1 e8 04             	shr    $0x4,%eax
8010325d:	89 c2                	mov    %eax,%edx
8010325f:	89 d0                	mov    %edx,%eax
80103261:	c1 e0 02             	shl    $0x2,%eax
80103264:	01 d0                	add    %edx,%eax
80103266:	01 c0                	add    %eax,%eax
80103268:	8b 55 dc             	mov    -0x24(%ebp),%edx
8010326b:	83 e2 0f             	and    $0xf,%edx
8010326e:	01 d0                	add    %edx,%eax
80103270:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
80103273:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103276:	c1 e8 04             	shr    $0x4,%eax
80103279:	89 c2                	mov    %eax,%edx
8010327b:	89 d0                	mov    %edx,%eax
8010327d:	c1 e0 02             	shl    $0x2,%eax
80103280:	01 d0                	add    %edx,%eax
80103282:	01 c0                	add    %eax,%eax
80103284:	8b 55 e0             	mov    -0x20(%ebp),%edx
80103287:	83 e2 0f             	and    $0xf,%edx
8010328a:	01 d0                	add    %edx,%eax
8010328c:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
8010328f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103292:	c1 e8 04             	shr    $0x4,%eax
80103295:	89 c2                	mov    %eax,%edx
80103297:	89 d0                	mov    %edx,%eax
80103299:	c1 e0 02             	shl    $0x2,%eax
8010329c:	01 d0                	add    %edx,%eax
8010329e:	01 c0                	add    %eax,%eax
801032a0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801032a3:	83 e2 0f             	and    $0xf,%edx
801032a6:	01 d0                	add    %edx,%eax
801032a8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
801032ab:	8b 45 e8             	mov    -0x18(%ebp),%eax
801032ae:	c1 e8 04             	shr    $0x4,%eax
801032b1:	89 c2                	mov    %eax,%edx
801032b3:	89 d0                	mov    %edx,%eax
801032b5:	c1 e0 02             	shl    $0x2,%eax
801032b8:	01 d0                	add    %edx,%eax
801032ba:	01 c0                	add    %eax,%eax
801032bc:	8b 55 e8             	mov    -0x18(%ebp),%edx
801032bf:	83 e2 0f             	and    $0xf,%edx
801032c2:	01 d0                	add    %edx,%eax
801032c4:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
801032c7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801032ca:	c1 e8 04             	shr    $0x4,%eax
801032cd:	89 c2                	mov    %eax,%edx
801032cf:	89 d0                	mov    %edx,%eax
801032d1:	c1 e0 02             	shl    $0x2,%eax
801032d4:	01 d0                	add    %edx,%eax
801032d6:	01 c0                	add    %eax,%eax
801032d8:	8b 55 ec             	mov    -0x14(%ebp),%edx
801032db:	83 e2 0f             	and    $0xf,%edx
801032de:	01 d0                	add    %edx,%eax
801032e0:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
801032e3:	8b 45 08             	mov    0x8(%ebp),%eax
801032e6:	8b 55 d8             	mov    -0x28(%ebp),%edx
801032e9:	89 10                	mov    %edx,(%eax)
801032eb:	8b 55 dc             	mov    -0x24(%ebp),%edx
801032ee:	89 50 04             	mov    %edx,0x4(%eax)
801032f1:	8b 55 e0             	mov    -0x20(%ebp),%edx
801032f4:	89 50 08             	mov    %edx,0x8(%eax)
801032f7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801032fa:	89 50 0c             	mov    %edx,0xc(%eax)
801032fd:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103300:	89 50 10             	mov    %edx,0x10(%eax)
80103303:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103306:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
80103309:	8b 45 08             	mov    0x8(%ebp),%eax
8010330c:	8b 40 14             	mov    0x14(%eax),%eax
8010330f:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
80103315:	8b 45 08             	mov    0x8(%ebp),%eax
80103318:	89 50 14             	mov    %edx,0x14(%eax)
}
8010331b:	c9                   	leave  
8010331c:	c3                   	ret    

8010331d <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(void)
{
8010331d:	55                   	push   %ebp
8010331e:	89 e5                	mov    %esp,%ebp
80103320:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
80103323:	c7 44 24 04 74 89 10 	movl   $0x80108974,0x4(%esp)
8010332a:	80 
8010332b:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
80103332:	e8 e4 1d 00 00       	call   8010511b <initlock>
  readsb(ROOTDEV, &sb);
80103337:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010333a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010333e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103345:	e8 a7 df ff ff       	call   801012f1 <readsb>
  log.start = sb.size - sb.nlog;
8010334a:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010334d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103350:	29 c2                	sub    %eax,%edx
80103352:	89 d0                	mov    %edx,%eax
80103354:	a3 d4 22 11 80       	mov    %eax,0x801122d4
  log.size = sb.nlog;
80103359:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010335c:	a3 d8 22 11 80       	mov    %eax,0x801122d8
  log.dev = ROOTDEV;
80103361:	c7 05 e4 22 11 80 01 	movl   $0x1,0x801122e4
80103368:	00 00 00 
  recover_from_log();
8010336b:	e8 9a 01 00 00       	call   8010350a <recover_from_log>
}
80103370:	c9                   	leave  
80103371:	c3                   	ret    

80103372 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
80103372:	55                   	push   %ebp
80103373:	89 e5                	mov    %esp,%ebp
80103375:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103378:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010337f:	e9 8c 00 00 00       	jmp    80103410 <install_trans+0x9e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80103384:	8b 15 d4 22 11 80    	mov    0x801122d4,%edx
8010338a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010338d:	01 d0                	add    %edx,%eax
8010338f:	83 c0 01             	add    $0x1,%eax
80103392:	89 c2                	mov    %eax,%edx
80103394:	a1 e4 22 11 80       	mov    0x801122e4,%eax
80103399:	89 54 24 04          	mov    %edx,0x4(%esp)
8010339d:	89 04 24             	mov    %eax,(%esp)
801033a0:	e8 01 ce ff ff       	call   801001a6 <bread>
801033a5:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
801033a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033ab:	83 c0 10             	add    $0x10,%eax
801033ae:	8b 04 85 ac 22 11 80 	mov    -0x7feedd54(,%eax,4),%eax
801033b5:	89 c2                	mov    %eax,%edx
801033b7:	a1 e4 22 11 80       	mov    0x801122e4,%eax
801033bc:	89 54 24 04          	mov    %edx,0x4(%esp)
801033c0:	89 04 24             	mov    %eax,(%esp)
801033c3:	e8 de cd ff ff       	call   801001a6 <bread>
801033c8:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801033cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033ce:	8d 50 18             	lea    0x18(%eax),%edx
801033d1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033d4:	83 c0 18             	add    $0x18,%eax
801033d7:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801033de:	00 
801033df:	89 54 24 04          	mov    %edx,0x4(%esp)
801033e3:	89 04 24             	mov    %eax,(%esp)
801033e6:	e8 74 20 00 00       	call   8010545f <memmove>
    bwrite(dbuf);  // write dst to disk
801033eb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033ee:	89 04 24             	mov    %eax,(%esp)
801033f1:	e8 e7 cd ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
801033f6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033f9:	89 04 24             	mov    %eax,(%esp)
801033fc:	e8 16 ce ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80103401:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103404:	89 04 24             	mov    %eax,(%esp)
80103407:	e8 0b ce ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010340c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103410:	a1 e8 22 11 80       	mov    0x801122e8,%eax
80103415:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103418:	0f 8f 66 ff ff ff    	jg     80103384 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
8010341e:	c9                   	leave  
8010341f:	c3                   	ret    

80103420 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103420:	55                   	push   %ebp
80103421:	89 e5                	mov    %esp,%ebp
80103423:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103426:	a1 d4 22 11 80       	mov    0x801122d4,%eax
8010342b:	89 c2                	mov    %eax,%edx
8010342d:	a1 e4 22 11 80       	mov    0x801122e4,%eax
80103432:	89 54 24 04          	mov    %edx,0x4(%esp)
80103436:	89 04 24             	mov    %eax,(%esp)
80103439:	e8 68 cd ff ff       	call   801001a6 <bread>
8010343e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103441:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103444:	83 c0 18             	add    $0x18,%eax
80103447:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
8010344a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010344d:	8b 00                	mov    (%eax),%eax
8010344f:	a3 e8 22 11 80       	mov    %eax,0x801122e8
  for (i = 0; i < log.lh.n; i++) {
80103454:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010345b:	eb 1b                	jmp    80103478 <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
8010345d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103460:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103463:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103467:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010346a:	83 c2 10             	add    $0x10,%edx
8010346d:	89 04 95 ac 22 11 80 	mov    %eax,-0x7feedd54(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80103474:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103478:	a1 e8 22 11 80       	mov    0x801122e8,%eax
8010347d:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103480:	7f db                	jg     8010345d <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
80103482:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103485:	89 04 24             	mov    %eax,(%esp)
80103488:	e8 8a cd ff ff       	call   80100217 <brelse>
}
8010348d:	c9                   	leave  
8010348e:	c3                   	ret    

8010348f <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
8010348f:	55                   	push   %ebp
80103490:	89 e5                	mov    %esp,%ebp
80103492:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103495:	a1 d4 22 11 80       	mov    0x801122d4,%eax
8010349a:	89 c2                	mov    %eax,%edx
8010349c:	a1 e4 22 11 80       	mov    0x801122e4,%eax
801034a1:	89 54 24 04          	mov    %edx,0x4(%esp)
801034a5:	89 04 24             	mov    %eax,(%esp)
801034a8:	e8 f9 cc ff ff       	call   801001a6 <bread>
801034ad:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
801034b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801034b3:	83 c0 18             	add    $0x18,%eax
801034b6:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
801034b9:	8b 15 e8 22 11 80    	mov    0x801122e8,%edx
801034bf:	8b 45 ec             	mov    -0x14(%ebp),%eax
801034c2:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
801034c4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801034cb:	eb 1b                	jmp    801034e8 <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
801034cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801034d0:	83 c0 10             	add    $0x10,%eax
801034d3:	8b 0c 85 ac 22 11 80 	mov    -0x7feedd54(,%eax,4),%ecx
801034da:	8b 45 ec             	mov    -0x14(%ebp),%eax
801034dd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801034e0:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
801034e4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801034e8:	a1 e8 22 11 80       	mov    0x801122e8,%eax
801034ed:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801034f0:	7f db                	jg     801034cd <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
801034f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801034f5:	89 04 24             	mov    %eax,(%esp)
801034f8:	e8 e0 cc ff ff       	call   801001dd <bwrite>
  brelse(buf);
801034fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103500:	89 04 24             	mov    %eax,(%esp)
80103503:	e8 0f cd ff ff       	call   80100217 <brelse>
}
80103508:	c9                   	leave  
80103509:	c3                   	ret    

8010350a <recover_from_log>:

static void
recover_from_log(void)
{
8010350a:	55                   	push   %ebp
8010350b:	89 e5                	mov    %esp,%ebp
8010350d:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103510:	e8 0b ff ff ff       	call   80103420 <read_head>
  install_trans(); // if committed, copy from log to disk
80103515:	e8 58 fe ff ff       	call   80103372 <install_trans>
  log.lh.n = 0;
8010351a:	c7 05 e8 22 11 80 00 	movl   $0x0,0x801122e8
80103521:	00 00 00 
  write_head(); // clear the log
80103524:	e8 66 ff ff ff       	call   8010348f <write_head>
}
80103529:	c9                   	leave  
8010352a:	c3                   	ret    

8010352b <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
8010352b:	55                   	push   %ebp
8010352c:	89 e5                	mov    %esp,%ebp
8010352e:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103531:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
80103538:	e8 ff 1b 00 00       	call   8010513c <acquire>
  while(1){
    if(log.committing){
8010353d:	a1 e0 22 11 80       	mov    0x801122e0,%eax
80103542:	85 c0                	test   %eax,%eax
80103544:	74 16                	je     8010355c <begin_op+0x31>
      sleep(&log, &log.lock);
80103546:	c7 44 24 04 a0 22 11 	movl   $0x801122a0,0x4(%esp)
8010354d:	80 
8010354e:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
80103555:	e8 e6 16 00 00       	call   80104c40 <sleep>
8010355a:	eb 4f                	jmp    801035ab <begin_op+0x80>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
8010355c:	8b 0d e8 22 11 80    	mov    0x801122e8,%ecx
80103562:	a1 dc 22 11 80       	mov    0x801122dc,%eax
80103567:	8d 50 01             	lea    0x1(%eax),%edx
8010356a:	89 d0                	mov    %edx,%eax
8010356c:	c1 e0 02             	shl    $0x2,%eax
8010356f:	01 d0                	add    %edx,%eax
80103571:	01 c0                	add    %eax,%eax
80103573:	01 c8                	add    %ecx,%eax
80103575:	83 f8 1e             	cmp    $0x1e,%eax
80103578:	7e 16                	jle    80103590 <begin_op+0x65>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
8010357a:	c7 44 24 04 a0 22 11 	movl   $0x801122a0,0x4(%esp)
80103581:	80 
80103582:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
80103589:	e8 b2 16 00 00       	call   80104c40 <sleep>
8010358e:	eb 1b                	jmp    801035ab <begin_op+0x80>
    } else {
      log.outstanding += 1;
80103590:	a1 dc 22 11 80       	mov    0x801122dc,%eax
80103595:	83 c0 01             	add    $0x1,%eax
80103598:	a3 dc 22 11 80       	mov    %eax,0x801122dc
      release(&log.lock);
8010359d:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
801035a4:	e8 f5 1b 00 00       	call   8010519e <release>
      break;
801035a9:	eb 02                	jmp    801035ad <begin_op+0x82>
    }
  }
801035ab:	eb 90                	jmp    8010353d <begin_op+0x12>
}
801035ad:	c9                   	leave  
801035ae:	c3                   	ret    

801035af <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
801035af:	55                   	push   %ebp
801035b0:	89 e5                	mov    %esp,%ebp
801035b2:	83 ec 28             	sub    $0x28,%esp
  int do_commit = 0;
801035b5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
801035bc:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
801035c3:	e8 74 1b 00 00       	call   8010513c <acquire>
  log.outstanding -= 1;
801035c8:	a1 dc 22 11 80       	mov    0x801122dc,%eax
801035cd:	83 e8 01             	sub    $0x1,%eax
801035d0:	a3 dc 22 11 80       	mov    %eax,0x801122dc
  if(log.committing)
801035d5:	a1 e0 22 11 80       	mov    0x801122e0,%eax
801035da:	85 c0                	test   %eax,%eax
801035dc:	74 0c                	je     801035ea <end_op+0x3b>
    panic("log.committing");
801035de:	c7 04 24 78 89 10 80 	movl   $0x80108978,(%esp)
801035e5:	e8 50 cf ff ff       	call   8010053a <panic>
  if(log.outstanding == 0){
801035ea:	a1 dc 22 11 80       	mov    0x801122dc,%eax
801035ef:	85 c0                	test   %eax,%eax
801035f1:	75 13                	jne    80103606 <end_op+0x57>
    do_commit = 1;
801035f3:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
801035fa:	c7 05 e0 22 11 80 01 	movl   $0x1,0x801122e0
80103601:	00 00 00 
80103604:	eb 0c                	jmp    80103612 <end_op+0x63>
  } else {
    // begin_op() may be waiting for log space.
    wakeup(&log);
80103606:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
8010360d:	e8 07 17 00 00       	call   80104d19 <wakeup>
  }
  release(&log.lock);
80103612:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
80103619:	e8 80 1b 00 00       	call   8010519e <release>

  if(do_commit){
8010361e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103622:	74 33                	je     80103657 <end_op+0xa8>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
80103624:	e8 de 00 00 00       	call   80103707 <commit>
    acquire(&log.lock);
80103629:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
80103630:	e8 07 1b 00 00       	call   8010513c <acquire>
    log.committing = 0;
80103635:	c7 05 e0 22 11 80 00 	movl   $0x0,0x801122e0
8010363c:	00 00 00 
    wakeup(&log);
8010363f:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
80103646:	e8 ce 16 00 00       	call   80104d19 <wakeup>
    release(&log.lock);
8010364b:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
80103652:	e8 47 1b 00 00       	call   8010519e <release>
  }
}
80103657:	c9                   	leave  
80103658:	c3                   	ret    

80103659 <write_log>:

// Copy modified blocks from cache to log.
static void 
write_log(void)
{
80103659:	55                   	push   %ebp
8010365a:	89 e5                	mov    %esp,%ebp
8010365c:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010365f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103666:	e9 8c 00 00 00       	jmp    801036f7 <write_log+0x9e>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
8010366b:	8b 15 d4 22 11 80    	mov    0x801122d4,%edx
80103671:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103674:	01 d0                	add    %edx,%eax
80103676:	83 c0 01             	add    $0x1,%eax
80103679:	89 c2                	mov    %eax,%edx
8010367b:	a1 e4 22 11 80       	mov    0x801122e4,%eax
80103680:	89 54 24 04          	mov    %edx,0x4(%esp)
80103684:	89 04 24             	mov    %eax,(%esp)
80103687:	e8 1a cb ff ff       	call   801001a6 <bread>
8010368c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.sector[tail]); // cache block
8010368f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103692:	83 c0 10             	add    $0x10,%eax
80103695:	8b 04 85 ac 22 11 80 	mov    -0x7feedd54(,%eax,4),%eax
8010369c:	89 c2                	mov    %eax,%edx
8010369e:	a1 e4 22 11 80       	mov    0x801122e4,%eax
801036a3:	89 54 24 04          	mov    %edx,0x4(%esp)
801036a7:	89 04 24             	mov    %eax,(%esp)
801036aa:	e8 f7 ca ff ff       	call   801001a6 <bread>
801036af:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
801036b2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801036b5:	8d 50 18             	lea    0x18(%eax),%edx
801036b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801036bb:	83 c0 18             	add    $0x18,%eax
801036be:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801036c5:	00 
801036c6:	89 54 24 04          	mov    %edx,0x4(%esp)
801036ca:	89 04 24             	mov    %eax,(%esp)
801036cd:	e8 8d 1d 00 00       	call   8010545f <memmove>
    bwrite(to);  // write the log
801036d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801036d5:	89 04 24             	mov    %eax,(%esp)
801036d8:	e8 00 cb ff ff       	call   801001dd <bwrite>
    brelse(from); 
801036dd:	8b 45 ec             	mov    -0x14(%ebp),%eax
801036e0:	89 04 24             	mov    %eax,(%esp)
801036e3:	e8 2f cb ff ff       	call   80100217 <brelse>
    brelse(to);
801036e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801036eb:	89 04 24             	mov    %eax,(%esp)
801036ee:	e8 24 cb ff ff       	call   80100217 <brelse>
static void 
write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801036f3:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801036f7:	a1 e8 22 11 80       	mov    0x801122e8,%eax
801036fc:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801036ff:	0f 8f 66 ff ff ff    	jg     8010366b <write_log+0x12>
    memmove(to->data, from->data, BSIZE);
    bwrite(to);  // write the log
    brelse(from); 
    brelse(to);
  }
}
80103705:	c9                   	leave  
80103706:	c3                   	ret    

80103707 <commit>:

static void
commit()
{
80103707:	55                   	push   %ebp
80103708:	89 e5                	mov    %esp,%ebp
8010370a:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
8010370d:	a1 e8 22 11 80       	mov    0x801122e8,%eax
80103712:	85 c0                	test   %eax,%eax
80103714:	7e 1e                	jle    80103734 <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
80103716:	e8 3e ff ff ff       	call   80103659 <write_log>
    write_head();    // Write header to disk -- the real commit
8010371b:	e8 6f fd ff ff       	call   8010348f <write_head>
    install_trans(); // Now install writes to home locations
80103720:	e8 4d fc ff ff       	call   80103372 <install_trans>
    log.lh.n = 0; 
80103725:	c7 05 e8 22 11 80 00 	movl   $0x0,0x801122e8
8010372c:	00 00 00 
    write_head();    // Erase the transaction from the log
8010372f:	e8 5b fd ff ff       	call   8010348f <write_head>
  }
}
80103734:	c9                   	leave  
80103735:	c3                   	ret    

80103736 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103736:	55                   	push   %ebp
80103737:	89 e5                	mov    %esp,%ebp
80103739:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
8010373c:	a1 e8 22 11 80       	mov    0x801122e8,%eax
80103741:	83 f8 1d             	cmp    $0x1d,%eax
80103744:	7f 12                	jg     80103758 <log_write+0x22>
80103746:	a1 e8 22 11 80       	mov    0x801122e8,%eax
8010374b:	8b 15 d8 22 11 80    	mov    0x801122d8,%edx
80103751:	83 ea 01             	sub    $0x1,%edx
80103754:	39 d0                	cmp    %edx,%eax
80103756:	7c 0c                	jl     80103764 <log_write+0x2e>
    panic("too big a transaction");
80103758:	c7 04 24 87 89 10 80 	movl   $0x80108987,(%esp)
8010375f:	e8 d6 cd ff ff       	call   8010053a <panic>
  if (log.outstanding < 1)
80103764:	a1 dc 22 11 80       	mov    0x801122dc,%eax
80103769:	85 c0                	test   %eax,%eax
8010376b:	7f 0c                	jg     80103779 <log_write+0x43>
    panic("log_write outside of trans");
8010376d:	c7 04 24 9d 89 10 80 	movl   $0x8010899d,(%esp)
80103774:	e8 c1 cd ff ff       	call   8010053a <panic>

  acquire(&log.lock);
80103779:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
80103780:	e8 b7 19 00 00       	call   8010513c <acquire>
  for (i = 0; i < log.lh.n; i++) {
80103785:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010378c:	eb 1f                	jmp    801037ad <log_write+0x77>
    if (log.lh.sector[i] == b->sector)   // log absorbtion
8010378e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103791:	83 c0 10             	add    $0x10,%eax
80103794:	8b 04 85 ac 22 11 80 	mov    -0x7feedd54(,%eax,4),%eax
8010379b:	89 c2                	mov    %eax,%edx
8010379d:	8b 45 08             	mov    0x8(%ebp),%eax
801037a0:	8b 40 08             	mov    0x8(%eax),%eax
801037a3:	39 c2                	cmp    %eax,%edx
801037a5:	75 02                	jne    801037a9 <log_write+0x73>
      break;
801037a7:	eb 0e                	jmp    801037b7 <log_write+0x81>
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
801037a9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801037ad:	a1 e8 22 11 80       	mov    0x801122e8,%eax
801037b2:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801037b5:	7f d7                	jg     8010378e <log_write+0x58>
    if (log.lh.sector[i] == b->sector)   // log absorbtion
      break;
  }
  log.lh.sector[i] = b->sector;
801037b7:	8b 45 08             	mov    0x8(%ebp),%eax
801037ba:	8b 40 08             	mov    0x8(%eax),%eax
801037bd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801037c0:	83 c2 10             	add    $0x10,%edx
801037c3:	89 04 95 ac 22 11 80 	mov    %eax,-0x7feedd54(,%edx,4)
  if (i == log.lh.n)
801037ca:	a1 e8 22 11 80       	mov    0x801122e8,%eax
801037cf:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801037d2:	75 0d                	jne    801037e1 <log_write+0xab>
    log.lh.n++;
801037d4:	a1 e8 22 11 80       	mov    0x801122e8,%eax
801037d9:	83 c0 01             	add    $0x1,%eax
801037dc:	a3 e8 22 11 80       	mov    %eax,0x801122e8
  b->flags |= B_DIRTY; // prevent eviction
801037e1:	8b 45 08             	mov    0x8(%ebp),%eax
801037e4:	8b 00                	mov    (%eax),%eax
801037e6:	83 c8 04             	or     $0x4,%eax
801037e9:	89 c2                	mov    %eax,%edx
801037eb:	8b 45 08             	mov    0x8(%ebp),%eax
801037ee:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
801037f0:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
801037f7:	e8 a2 19 00 00       	call   8010519e <release>
}
801037fc:	c9                   	leave  
801037fd:	c3                   	ret    

801037fe <v2p>:
801037fe:	55                   	push   %ebp
801037ff:	89 e5                	mov    %esp,%ebp
80103801:	8b 45 08             	mov    0x8(%ebp),%eax
80103804:	05 00 00 00 80       	add    $0x80000000,%eax
80103809:	5d                   	pop    %ebp
8010380a:	c3                   	ret    

8010380b <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
8010380b:	55                   	push   %ebp
8010380c:	89 e5                	mov    %esp,%ebp
8010380e:	8b 45 08             	mov    0x8(%ebp),%eax
80103811:	05 00 00 00 80       	add    $0x80000000,%eax
80103816:	5d                   	pop    %ebp
80103817:	c3                   	ret    

80103818 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103818:	55                   	push   %ebp
80103819:	89 e5                	mov    %esp,%ebp
8010381b:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
8010381e:	8b 55 08             	mov    0x8(%ebp),%edx
80103821:	8b 45 0c             	mov    0xc(%ebp),%eax
80103824:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103827:	f0 87 02             	lock xchg %eax,(%edx)
8010382a:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
8010382d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80103830:	c9                   	leave  
80103831:	c3                   	ret    

80103832 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103832:	55                   	push   %ebp
80103833:	89 e5                	mov    %esp,%ebp
80103835:	83 e4 f0             	and    $0xfffffff0,%esp
80103838:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
8010383b:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103842:	80 
80103843:	c7 04 24 7c 51 11 80 	movl   $0x8011517c,(%esp)
8010384a:	e8 80 f2 ff ff       	call   80102acf <kinit1>
  kvmalloc();      // kernel page table
8010384f:	e8 67 47 00 00       	call   80107fbb <kvmalloc>
  mpinit();        // collect info about this machine
80103854:	e8 4b 04 00 00       	call   80103ca4 <mpinit>
  lapicinit();
80103859:	e8 dc f5 ff ff       	call   80102e3a <lapicinit>
  seginit();       // set up segments
8010385e:	e8 eb 40 00 00       	call   8010794e <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103863:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103869:	0f b6 00             	movzbl (%eax),%eax
8010386c:	0f b6 c0             	movzbl %al,%eax
8010386f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103873:	c7 04 24 b8 89 10 80 	movl   $0x801089b8,(%esp)
8010387a:	e8 21 cb ff ff       	call   801003a0 <cprintf>
  picinit();       // interrupt controller
8010387f:	e8 7e 06 00 00       	call   80103f02 <picinit>
  ioapicinit();    // another interrupt controller
80103884:	e8 3c f1 ff ff       	call   801029c5 <ioapicinit>
  procfsinit();
80103889:	e8 2a 18 00 00       	call   801050b8 <procfsinit>
  consoleinit();   // I/O devices & their interrupts
8010388e:	e8 ee d1 ff ff       	call   80100a81 <consoleinit>
  uartinit();      // serial port
80103893:	e8 05 34 00 00       	call   80106c9d <uartinit>
  pinit();         // process table
80103898:	e8 6f 0b 00 00       	call   8010440c <pinit>
  tvinit();        // trap vectors
8010389d:	e8 ad 2f 00 00       	call   8010684f <tvinit>
  binit();         // buffer cache
801038a2:	e8 8d c7 ff ff       	call   80100034 <binit>
  fileinit();      // file table
801038a7:	e8 5e d6 ff ff       	call   80100f0a <fileinit>
  iinit();         // inode cache
801038ac:	e8 f3 dc ff ff       	call   801015a4 <iinit>
  ideinit();       // disk
801038b1:	e8 78 ed ff ff       	call   8010262e <ideinit>
  if(!ismp)
801038b6:	a1 84 23 11 80       	mov    0x80112384,%eax
801038bb:	85 c0                	test   %eax,%eax
801038bd:	75 05                	jne    801038c4 <main+0x92>
    timerinit();   // uniprocessor timer
801038bf:	e8 d6 2e 00 00       	call   8010679a <timerinit>
  startothers();   // start other processors
801038c4:	e8 7f 00 00 00       	call   80103948 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
801038c9:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
801038d0:	8e 
801038d1:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
801038d8:	e8 2a f2 ff ff       	call   80102b07 <kinit2>
  userinit();      // first user process
801038dd:	e8 45 0c 00 00       	call   80104527 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
801038e2:	e8 1a 00 00 00       	call   80103901 <mpmain>

801038e7 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
801038e7:	55                   	push   %ebp
801038e8:	89 e5                	mov    %esp,%ebp
801038ea:	83 ec 08             	sub    $0x8,%esp
  switchkvm(); 
801038ed:	e8 e0 46 00 00       	call   80107fd2 <switchkvm>
  seginit();
801038f2:	e8 57 40 00 00       	call   8010794e <seginit>
  lapicinit();
801038f7:	e8 3e f5 ff ff       	call   80102e3a <lapicinit>
  mpmain();
801038fc:	e8 00 00 00 00       	call   80103901 <mpmain>

80103901 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103901:	55                   	push   %ebp
80103902:	89 e5                	mov    %esp,%ebp
80103904:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
80103907:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010390d:	0f b6 00             	movzbl (%eax),%eax
80103910:	0f b6 c0             	movzbl %al,%eax
80103913:	89 44 24 04          	mov    %eax,0x4(%esp)
80103917:	c7 04 24 cf 89 10 80 	movl   $0x801089cf,(%esp)
8010391e:	e8 7d ca ff ff       	call   801003a0 <cprintf>
  idtinit();       // load idt register
80103923:	e8 9b 30 00 00       	call   801069c3 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103928:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010392e:	05 a8 00 00 00       	add    $0xa8,%eax
80103933:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010393a:	00 
8010393b:	89 04 24             	mov    %eax,(%esp)
8010393e:	e8 d5 fe ff ff       	call   80103818 <xchg>
  scheduler();     // start running processes
80103943:	e8 50 11 00 00       	call   80104a98 <scheduler>

80103948 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103948:	55                   	push   %ebp
80103949:	89 e5                	mov    %esp,%ebp
8010394b:	53                   	push   %ebx
8010394c:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
8010394f:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103956:	e8 b0 fe ff ff       	call   8010380b <p2v>
8010395b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
8010395e:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103963:	89 44 24 08          	mov    %eax,0x8(%esp)
80103967:	c7 44 24 04 0c b5 10 	movl   $0x8010b50c,0x4(%esp)
8010396e:	80 
8010396f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103972:	89 04 24             	mov    %eax,(%esp)
80103975:	e8 e5 1a 00 00       	call   8010545f <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
8010397a:	c7 45 f4 a0 23 11 80 	movl   $0x801123a0,-0xc(%ebp)
80103981:	e9 85 00 00 00       	jmp    80103a0b <startothers+0xc3>
    if(c == cpus+cpunum())  // We've started already.
80103986:	e8 08 f6 ff ff       	call   80102f93 <cpunum>
8010398b:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103991:	05 a0 23 11 80       	add    $0x801123a0,%eax
80103996:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103999:	75 02                	jne    8010399d <startothers+0x55>
      continue;
8010399b:	eb 67                	jmp    80103a04 <startothers+0xbc>

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
8010399d:	e8 5b f2 ff ff       	call   80102bfd <kalloc>
801039a2:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
801039a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039a8:	83 e8 04             	sub    $0x4,%eax
801039ab:	8b 55 ec             	mov    -0x14(%ebp),%edx
801039ae:	81 c2 00 10 00 00    	add    $0x1000,%edx
801039b4:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
801039b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039b9:	83 e8 08             	sub    $0x8,%eax
801039bc:	c7 00 e7 38 10 80    	movl   $0x801038e7,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
801039c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039c5:	8d 58 f4             	lea    -0xc(%eax),%ebx
801039c8:	c7 04 24 00 a0 10 80 	movl   $0x8010a000,(%esp)
801039cf:	e8 2a fe ff ff       	call   801037fe <v2p>
801039d4:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
801039d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039d9:	89 04 24             	mov    %eax,(%esp)
801039dc:	e8 1d fe ff ff       	call   801037fe <v2p>
801039e1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801039e4:	0f b6 12             	movzbl (%edx),%edx
801039e7:	0f b6 d2             	movzbl %dl,%edx
801039ea:	89 44 24 04          	mov    %eax,0x4(%esp)
801039ee:	89 14 24             	mov    %edx,(%esp)
801039f1:	e8 1f f6 ff ff       	call   80103015 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
801039f6:	90                   	nop
801039f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039fa:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80103a00:	85 c0                	test   %eax,%eax
80103a02:	74 f3                	je     801039f7 <startothers+0xaf>
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80103a04:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80103a0b:	a1 80 29 11 80       	mov    0x80112980,%eax
80103a10:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103a16:	05 a0 23 11 80       	add    $0x801123a0,%eax
80103a1b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103a1e:	0f 87 62 ff ff ff    	ja     80103986 <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103a24:	83 c4 24             	add    $0x24,%esp
80103a27:	5b                   	pop    %ebx
80103a28:	5d                   	pop    %ebp
80103a29:	c3                   	ret    

80103a2a <p2v>:
80103a2a:	55                   	push   %ebp
80103a2b:	89 e5                	mov    %esp,%ebp
80103a2d:	8b 45 08             	mov    0x8(%ebp),%eax
80103a30:	05 00 00 00 80       	add    $0x80000000,%eax
80103a35:	5d                   	pop    %ebp
80103a36:	c3                   	ret    

80103a37 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103a37:	55                   	push   %ebp
80103a38:	89 e5                	mov    %esp,%ebp
80103a3a:	83 ec 14             	sub    $0x14,%esp
80103a3d:	8b 45 08             	mov    0x8(%ebp),%eax
80103a40:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103a44:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80103a48:	89 c2                	mov    %eax,%edx
80103a4a:	ec                   	in     (%dx),%al
80103a4b:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80103a4e:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80103a52:	c9                   	leave  
80103a53:	c3                   	ret    

80103a54 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103a54:	55                   	push   %ebp
80103a55:	89 e5                	mov    %esp,%ebp
80103a57:	83 ec 08             	sub    $0x8,%esp
80103a5a:	8b 55 08             	mov    0x8(%ebp),%edx
80103a5d:	8b 45 0c             	mov    0xc(%ebp),%eax
80103a60:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103a64:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103a67:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103a6b:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103a6f:	ee                   	out    %al,(%dx)
}
80103a70:	c9                   	leave  
80103a71:	c3                   	ret    

80103a72 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80103a72:	55                   	push   %ebp
80103a73:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
80103a75:	a1 44 b6 10 80       	mov    0x8010b644,%eax
80103a7a:	89 c2                	mov    %eax,%edx
80103a7c:	b8 a0 23 11 80       	mov    $0x801123a0,%eax
80103a81:	29 c2                	sub    %eax,%edx
80103a83:	89 d0                	mov    %edx,%eax
80103a85:	c1 f8 02             	sar    $0x2,%eax
80103a88:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80103a8e:	5d                   	pop    %ebp
80103a8f:	c3                   	ret    

80103a90 <sum>:

static uchar
sum(uchar *addr, int len)
{
80103a90:	55                   	push   %ebp
80103a91:	89 e5                	mov    %esp,%ebp
80103a93:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
80103a96:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80103a9d:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103aa4:	eb 15                	jmp    80103abb <sum+0x2b>
    sum += addr[i];
80103aa6:	8b 55 fc             	mov    -0x4(%ebp),%edx
80103aa9:	8b 45 08             	mov    0x8(%ebp),%eax
80103aac:	01 d0                	add    %edx,%eax
80103aae:	0f b6 00             	movzbl (%eax),%eax
80103ab1:	0f b6 c0             	movzbl %al,%eax
80103ab4:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
80103ab7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103abb:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103abe:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103ac1:	7c e3                	jl     80103aa6 <sum+0x16>
    sum += addr[i];
  return sum;
80103ac3:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103ac6:	c9                   	leave  
80103ac7:	c3                   	ret    

80103ac8 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80103ac8:	55                   	push   %ebp
80103ac9:	89 e5                	mov    %esp,%ebp
80103acb:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80103ace:	8b 45 08             	mov    0x8(%ebp),%eax
80103ad1:	89 04 24             	mov    %eax,(%esp)
80103ad4:	e8 51 ff ff ff       	call   80103a2a <p2v>
80103ad9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80103adc:	8b 55 0c             	mov    0xc(%ebp),%edx
80103adf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ae2:	01 d0                	add    %edx,%eax
80103ae4:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80103ae7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103aea:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103aed:	eb 3f                	jmp    80103b2e <mpsearch1+0x66>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103aef:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103af6:	00 
80103af7:	c7 44 24 04 e0 89 10 	movl   $0x801089e0,0x4(%esp)
80103afe:	80 
80103aff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b02:	89 04 24             	mov    %eax,(%esp)
80103b05:	e8 fd 18 00 00       	call   80105407 <memcmp>
80103b0a:	85 c0                	test   %eax,%eax
80103b0c:	75 1c                	jne    80103b2a <mpsearch1+0x62>
80103b0e:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80103b15:	00 
80103b16:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b19:	89 04 24             	mov    %eax,(%esp)
80103b1c:	e8 6f ff ff ff       	call   80103a90 <sum>
80103b21:	84 c0                	test   %al,%al
80103b23:	75 05                	jne    80103b2a <mpsearch1+0x62>
      return (struct mp*)p;
80103b25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b28:	eb 11                	jmp    80103b3b <mpsearch1+0x73>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80103b2a:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103b2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b31:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103b34:	72 b9                	jb     80103aef <mpsearch1+0x27>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
80103b36:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103b3b:	c9                   	leave  
80103b3c:	c3                   	ret    

80103b3d <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103b3d:	55                   	push   %ebp
80103b3e:	89 e5                	mov    %esp,%ebp
80103b40:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103b43:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80103b4a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b4d:	83 c0 0f             	add    $0xf,%eax
80103b50:	0f b6 00             	movzbl (%eax),%eax
80103b53:	0f b6 c0             	movzbl %al,%eax
80103b56:	c1 e0 08             	shl    $0x8,%eax
80103b59:	89 c2                	mov    %eax,%edx
80103b5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b5e:	83 c0 0e             	add    $0xe,%eax
80103b61:	0f b6 00             	movzbl (%eax),%eax
80103b64:	0f b6 c0             	movzbl %al,%eax
80103b67:	09 d0                	or     %edx,%eax
80103b69:	c1 e0 04             	shl    $0x4,%eax
80103b6c:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103b6f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103b73:	74 21                	je     80103b96 <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80103b75:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103b7c:	00 
80103b7d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b80:	89 04 24             	mov    %eax,(%esp)
80103b83:	e8 40 ff ff ff       	call   80103ac8 <mpsearch1>
80103b88:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103b8b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103b8f:	74 50                	je     80103be1 <mpsearch+0xa4>
      return mp;
80103b91:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b94:	eb 5f                	jmp    80103bf5 <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80103b96:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b99:	83 c0 14             	add    $0x14,%eax
80103b9c:	0f b6 00             	movzbl (%eax),%eax
80103b9f:	0f b6 c0             	movzbl %al,%eax
80103ba2:	c1 e0 08             	shl    $0x8,%eax
80103ba5:	89 c2                	mov    %eax,%edx
80103ba7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103baa:	83 c0 13             	add    $0x13,%eax
80103bad:	0f b6 00             	movzbl (%eax),%eax
80103bb0:	0f b6 c0             	movzbl %al,%eax
80103bb3:	09 d0                	or     %edx,%eax
80103bb5:	c1 e0 0a             	shl    $0xa,%eax
80103bb8:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103bbb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bbe:	2d 00 04 00 00       	sub    $0x400,%eax
80103bc3:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103bca:	00 
80103bcb:	89 04 24             	mov    %eax,(%esp)
80103bce:	e8 f5 fe ff ff       	call   80103ac8 <mpsearch1>
80103bd3:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103bd6:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103bda:	74 05                	je     80103be1 <mpsearch+0xa4>
      return mp;
80103bdc:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103bdf:	eb 14                	jmp    80103bf5 <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80103be1:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103be8:	00 
80103be9:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80103bf0:	e8 d3 fe ff ff       	call   80103ac8 <mpsearch1>
}
80103bf5:	c9                   	leave  
80103bf6:	c3                   	ret    

80103bf7 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80103bf7:	55                   	push   %ebp
80103bf8:	89 e5                	mov    %esp,%ebp
80103bfa:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80103bfd:	e8 3b ff ff ff       	call   80103b3d <mpsearch>
80103c02:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103c05:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103c09:	74 0a                	je     80103c15 <mpconfig+0x1e>
80103c0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c0e:	8b 40 04             	mov    0x4(%eax),%eax
80103c11:	85 c0                	test   %eax,%eax
80103c13:	75 0a                	jne    80103c1f <mpconfig+0x28>
    return 0;
80103c15:	b8 00 00 00 00       	mov    $0x0,%eax
80103c1a:	e9 83 00 00 00       	jmp    80103ca2 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80103c1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c22:	8b 40 04             	mov    0x4(%eax),%eax
80103c25:	89 04 24             	mov    %eax,(%esp)
80103c28:	e8 fd fd ff ff       	call   80103a2a <p2v>
80103c2d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103c30:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103c37:	00 
80103c38:	c7 44 24 04 e5 89 10 	movl   $0x801089e5,0x4(%esp)
80103c3f:	80 
80103c40:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c43:	89 04 24             	mov    %eax,(%esp)
80103c46:	e8 bc 17 00 00       	call   80105407 <memcmp>
80103c4b:	85 c0                	test   %eax,%eax
80103c4d:	74 07                	je     80103c56 <mpconfig+0x5f>
    return 0;
80103c4f:	b8 00 00 00 00       	mov    $0x0,%eax
80103c54:	eb 4c                	jmp    80103ca2 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
80103c56:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c59:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103c5d:	3c 01                	cmp    $0x1,%al
80103c5f:	74 12                	je     80103c73 <mpconfig+0x7c>
80103c61:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c64:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103c68:	3c 04                	cmp    $0x4,%al
80103c6a:	74 07                	je     80103c73 <mpconfig+0x7c>
    return 0;
80103c6c:	b8 00 00 00 00       	mov    $0x0,%eax
80103c71:	eb 2f                	jmp    80103ca2 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80103c73:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c76:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103c7a:	0f b7 c0             	movzwl %ax,%eax
80103c7d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103c81:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c84:	89 04 24             	mov    %eax,(%esp)
80103c87:	e8 04 fe ff ff       	call   80103a90 <sum>
80103c8c:	84 c0                	test   %al,%al
80103c8e:	74 07                	je     80103c97 <mpconfig+0xa0>
    return 0;
80103c90:	b8 00 00 00 00       	mov    $0x0,%eax
80103c95:	eb 0b                	jmp    80103ca2 <mpconfig+0xab>
  *pmp = mp;
80103c97:	8b 45 08             	mov    0x8(%ebp),%eax
80103c9a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103c9d:	89 10                	mov    %edx,(%eax)
  return conf;
80103c9f:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80103ca2:	c9                   	leave  
80103ca3:	c3                   	ret    

80103ca4 <mpinit>:

void
mpinit(void)
{
80103ca4:	55                   	push   %ebp
80103ca5:	89 e5                	mov    %esp,%ebp
80103ca7:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80103caa:	c7 05 44 b6 10 80 a0 	movl   $0x801123a0,0x8010b644
80103cb1:	23 11 80 
  if((conf = mpconfig(&mp)) == 0)
80103cb4:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103cb7:	89 04 24             	mov    %eax,(%esp)
80103cba:	e8 38 ff ff ff       	call   80103bf7 <mpconfig>
80103cbf:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103cc2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103cc6:	75 05                	jne    80103ccd <mpinit+0x29>
    return;
80103cc8:	e9 9c 01 00 00       	jmp    80103e69 <mpinit+0x1c5>
  ismp = 1;
80103ccd:	c7 05 84 23 11 80 01 	movl   $0x1,0x80112384
80103cd4:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80103cd7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103cda:	8b 40 24             	mov    0x24(%eax),%eax
80103cdd:	a3 9c 22 11 80       	mov    %eax,0x8011229c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103ce2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ce5:	83 c0 2c             	add    $0x2c,%eax
80103ce8:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103ceb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103cee:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103cf2:	0f b7 d0             	movzwl %ax,%edx
80103cf5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103cf8:	01 d0                	add    %edx,%eax
80103cfa:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103cfd:	e9 f4 00 00 00       	jmp    80103df6 <mpinit+0x152>
    switch(*p){
80103d02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d05:	0f b6 00             	movzbl (%eax),%eax
80103d08:	0f b6 c0             	movzbl %al,%eax
80103d0b:	83 f8 04             	cmp    $0x4,%eax
80103d0e:	0f 87 bf 00 00 00    	ja     80103dd3 <mpinit+0x12f>
80103d14:	8b 04 85 28 8a 10 80 	mov    -0x7fef75d8(,%eax,4),%eax
80103d1b:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103d1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d20:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80103d23:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103d26:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103d2a:	0f b6 d0             	movzbl %al,%edx
80103d2d:	a1 80 29 11 80       	mov    0x80112980,%eax
80103d32:	39 c2                	cmp    %eax,%edx
80103d34:	74 2d                	je     80103d63 <mpinit+0xbf>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80103d36:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103d39:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103d3d:	0f b6 d0             	movzbl %al,%edx
80103d40:	a1 80 29 11 80       	mov    0x80112980,%eax
80103d45:	89 54 24 08          	mov    %edx,0x8(%esp)
80103d49:	89 44 24 04          	mov    %eax,0x4(%esp)
80103d4d:	c7 04 24 ea 89 10 80 	movl   $0x801089ea,(%esp)
80103d54:	e8 47 c6 ff ff       	call   801003a0 <cprintf>
        ismp = 0;
80103d59:	c7 05 84 23 11 80 00 	movl   $0x0,0x80112384
80103d60:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80103d63:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103d66:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80103d6a:	0f b6 c0             	movzbl %al,%eax
80103d6d:	83 e0 02             	and    $0x2,%eax
80103d70:	85 c0                	test   %eax,%eax
80103d72:	74 15                	je     80103d89 <mpinit+0xe5>
        bcpu = &cpus[ncpu];
80103d74:	a1 80 29 11 80       	mov    0x80112980,%eax
80103d79:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103d7f:	05 a0 23 11 80       	add    $0x801123a0,%eax
80103d84:	a3 44 b6 10 80       	mov    %eax,0x8010b644
      cpus[ncpu].id = ncpu;
80103d89:	8b 15 80 29 11 80    	mov    0x80112980,%edx
80103d8f:	a1 80 29 11 80       	mov    0x80112980,%eax
80103d94:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80103d9a:	81 c2 a0 23 11 80    	add    $0x801123a0,%edx
80103da0:	88 02                	mov    %al,(%edx)
      ncpu++;
80103da2:	a1 80 29 11 80       	mov    0x80112980,%eax
80103da7:	83 c0 01             	add    $0x1,%eax
80103daa:	a3 80 29 11 80       	mov    %eax,0x80112980
      p += sizeof(struct mpproc);
80103daf:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80103db3:	eb 41                	jmp    80103df6 <mpinit+0x152>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80103db5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103db8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80103dbb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103dbe:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103dc2:	a2 80 23 11 80       	mov    %al,0x80112380
      p += sizeof(struct mpioapic);
80103dc7:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103dcb:	eb 29                	jmp    80103df6 <mpinit+0x152>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103dcd:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103dd1:	eb 23                	jmp    80103df6 <mpinit+0x152>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80103dd3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103dd6:	0f b6 00             	movzbl (%eax),%eax
80103dd9:	0f b6 c0             	movzbl %al,%eax
80103ddc:	89 44 24 04          	mov    %eax,0x4(%esp)
80103de0:	c7 04 24 08 8a 10 80 	movl   $0x80108a08,(%esp)
80103de7:	e8 b4 c5 ff ff       	call   801003a0 <cprintf>
      ismp = 0;
80103dec:	c7 05 84 23 11 80 00 	movl   $0x0,0x80112384
80103df3:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103df6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103df9:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103dfc:	0f 82 00 ff ff ff    	jb     80103d02 <mpinit+0x5e>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80103e02:	a1 84 23 11 80       	mov    0x80112384,%eax
80103e07:	85 c0                	test   %eax,%eax
80103e09:	75 1d                	jne    80103e28 <mpinit+0x184>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80103e0b:	c7 05 80 29 11 80 01 	movl   $0x1,0x80112980
80103e12:	00 00 00 
    lapic = 0;
80103e15:	c7 05 9c 22 11 80 00 	movl   $0x0,0x8011229c
80103e1c:	00 00 00 
    ioapicid = 0;
80103e1f:	c6 05 80 23 11 80 00 	movb   $0x0,0x80112380
    return;
80103e26:	eb 41                	jmp    80103e69 <mpinit+0x1c5>
  }

  if(mp->imcrp){
80103e28:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103e2b:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103e2f:	84 c0                	test   %al,%al
80103e31:	74 36                	je     80103e69 <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103e33:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80103e3a:	00 
80103e3b:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80103e42:	e8 0d fc ff ff       	call   80103a54 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103e47:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103e4e:	e8 e4 fb ff ff       	call   80103a37 <inb>
80103e53:	83 c8 01             	or     $0x1,%eax
80103e56:	0f b6 c0             	movzbl %al,%eax
80103e59:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e5d:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103e64:	e8 eb fb ff ff       	call   80103a54 <outb>
  }
}
80103e69:	c9                   	leave  
80103e6a:	c3                   	ret    

80103e6b <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103e6b:	55                   	push   %ebp
80103e6c:	89 e5                	mov    %esp,%ebp
80103e6e:	83 ec 08             	sub    $0x8,%esp
80103e71:	8b 55 08             	mov    0x8(%ebp),%edx
80103e74:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e77:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103e7b:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103e7e:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103e82:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103e86:	ee                   	out    %al,(%dx)
}
80103e87:	c9                   	leave  
80103e88:	c3                   	ret    

80103e89 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80103e89:	55                   	push   %ebp
80103e8a:	89 e5                	mov    %esp,%ebp
80103e8c:	83 ec 0c             	sub    $0xc,%esp
80103e8f:	8b 45 08             	mov    0x8(%ebp),%eax
80103e92:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80103e96:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103e9a:	66 a3 00 b0 10 80    	mov    %ax,0x8010b000
  outb(IO_PIC1+1, mask);
80103ea0:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103ea4:	0f b6 c0             	movzbl %al,%eax
80103ea7:	89 44 24 04          	mov    %eax,0x4(%esp)
80103eab:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103eb2:	e8 b4 ff ff ff       	call   80103e6b <outb>
  outb(IO_PIC2+1, mask >> 8);
80103eb7:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103ebb:	66 c1 e8 08          	shr    $0x8,%ax
80103ebf:	0f b6 c0             	movzbl %al,%eax
80103ec2:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ec6:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103ecd:	e8 99 ff ff ff       	call   80103e6b <outb>
}
80103ed2:	c9                   	leave  
80103ed3:	c3                   	ret    

80103ed4 <picenable>:

void
picenable(int irq)
{
80103ed4:	55                   	push   %ebp
80103ed5:	89 e5                	mov    %esp,%ebp
80103ed7:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80103eda:	8b 45 08             	mov    0x8(%ebp),%eax
80103edd:	ba 01 00 00 00       	mov    $0x1,%edx
80103ee2:	89 c1                	mov    %eax,%ecx
80103ee4:	d3 e2                	shl    %cl,%edx
80103ee6:	89 d0                	mov    %edx,%eax
80103ee8:	f7 d0                	not    %eax
80103eea:	89 c2                	mov    %eax,%edx
80103eec:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103ef3:	21 d0                	and    %edx,%eax
80103ef5:	0f b7 c0             	movzwl %ax,%eax
80103ef8:	89 04 24             	mov    %eax,(%esp)
80103efb:	e8 89 ff ff ff       	call   80103e89 <picsetmask>
}
80103f00:	c9                   	leave  
80103f01:	c3                   	ret    

80103f02 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80103f02:	55                   	push   %ebp
80103f03:	89 e5                	mov    %esp,%ebp
80103f05:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103f08:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103f0f:	00 
80103f10:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103f17:	e8 4f ff ff ff       	call   80103e6b <outb>
  outb(IO_PIC2+1, 0xFF);
80103f1c:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103f23:	00 
80103f24:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103f2b:	e8 3b ff ff ff       	call   80103e6b <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80103f30:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103f37:	00 
80103f38:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103f3f:	e8 27 ff ff ff       	call   80103e6b <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80103f44:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80103f4b:	00 
80103f4c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103f53:	e8 13 ff ff ff       	call   80103e6b <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80103f58:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80103f5f:	00 
80103f60:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103f67:	e8 ff fe ff ff       	call   80103e6b <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80103f6c:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103f73:	00 
80103f74:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103f7b:	e8 eb fe ff ff       	call   80103e6b <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80103f80:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103f87:	00 
80103f88:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103f8f:	e8 d7 fe ff ff       	call   80103e6b <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80103f94:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80103f9b:	00 
80103f9c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103fa3:	e8 c3 fe ff ff       	call   80103e6b <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80103fa8:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80103faf:	00 
80103fb0:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103fb7:	e8 af fe ff ff       	call   80103e6b <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80103fbc:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103fc3:	00 
80103fc4:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103fcb:	e8 9b fe ff ff       	call   80103e6b <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80103fd0:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103fd7:	00 
80103fd8:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103fdf:	e8 87 fe ff ff       	call   80103e6b <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80103fe4:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103feb:	00 
80103fec:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103ff3:	e8 73 fe ff ff       	call   80103e6b <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80103ff8:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103fff:	00 
80104000:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104007:	e8 5f fe ff ff       	call   80103e6b <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
8010400c:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104013:	00 
80104014:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010401b:	e8 4b fe ff ff       	call   80103e6b <outb>

  if(irqmask != 0xFFFF)
80104020:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80104027:	66 83 f8 ff          	cmp    $0xffff,%ax
8010402b:	74 12                	je     8010403f <picinit+0x13d>
    picsetmask(irqmask);
8010402d:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80104034:	0f b7 c0             	movzwl %ax,%eax
80104037:	89 04 24             	mov    %eax,(%esp)
8010403a:	e8 4a fe ff ff       	call   80103e89 <picsetmask>
}
8010403f:	c9                   	leave  
80104040:	c3                   	ret    

80104041 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80104041:	55                   	push   %ebp
80104042:	89 e5                	mov    %esp,%ebp
80104044:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80104047:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
8010404e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104051:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80104057:	8b 45 0c             	mov    0xc(%ebp),%eax
8010405a:	8b 10                	mov    (%eax),%edx
8010405c:	8b 45 08             	mov    0x8(%ebp),%eax
8010405f:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80104061:	e8 c0 ce ff ff       	call   80100f26 <filealloc>
80104066:	8b 55 08             	mov    0x8(%ebp),%edx
80104069:	89 02                	mov    %eax,(%edx)
8010406b:	8b 45 08             	mov    0x8(%ebp),%eax
8010406e:	8b 00                	mov    (%eax),%eax
80104070:	85 c0                	test   %eax,%eax
80104072:	0f 84 c8 00 00 00    	je     80104140 <pipealloc+0xff>
80104078:	e8 a9 ce ff ff       	call   80100f26 <filealloc>
8010407d:	8b 55 0c             	mov    0xc(%ebp),%edx
80104080:	89 02                	mov    %eax,(%edx)
80104082:	8b 45 0c             	mov    0xc(%ebp),%eax
80104085:	8b 00                	mov    (%eax),%eax
80104087:	85 c0                	test   %eax,%eax
80104089:	0f 84 b1 00 00 00    	je     80104140 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
8010408f:	e8 69 eb ff ff       	call   80102bfd <kalloc>
80104094:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104097:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010409b:	75 05                	jne    801040a2 <pipealloc+0x61>
    goto bad;
8010409d:	e9 9e 00 00 00       	jmp    80104140 <pipealloc+0xff>
  p->readopen = 1;
801040a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040a5:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
801040ac:	00 00 00 
  p->writeopen = 1;
801040af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040b2:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
801040b9:	00 00 00 
  p->nwrite = 0;
801040bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040bf:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
801040c6:	00 00 00 
  p->nread = 0;
801040c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040cc:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
801040d3:	00 00 00 
  initlock(&p->lock, "pipe");
801040d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040d9:	c7 44 24 04 3c 8a 10 	movl   $0x80108a3c,0x4(%esp)
801040e0:	80 
801040e1:	89 04 24             	mov    %eax,(%esp)
801040e4:	e8 32 10 00 00       	call   8010511b <initlock>
  (*f0)->type = FD_PIPE;
801040e9:	8b 45 08             	mov    0x8(%ebp),%eax
801040ec:	8b 00                	mov    (%eax),%eax
801040ee:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
801040f4:	8b 45 08             	mov    0x8(%ebp),%eax
801040f7:	8b 00                	mov    (%eax),%eax
801040f9:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
801040fd:	8b 45 08             	mov    0x8(%ebp),%eax
80104100:	8b 00                	mov    (%eax),%eax
80104102:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80104106:	8b 45 08             	mov    0x8(%ebp),%eax
80104109:	8b 00                	mov    (%eax),%eax
8010410b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010410e:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80104111:	8b 45 0c             	mov    0xc(%ebp),%eax
80104114:	8b 00                	mov    (%eax),%eax
80104116:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
8010411c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010411f:	8b 00                	mov    (%eax),%eax
80104121:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80104125:	8b 45 0c             	mov    0xc(%ebp),%eax
80104128:	8b 00                	mov    (%eax),%eax
8010412a:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
8010412e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104131:	8b 00                	mov    (%eax),%eax
80104133:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104136:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80104139:	b8 00 00 00 00       	mov    $0x0,%eax
8010413e:	eb 42                	jmp    80104182 <pipealloc+0x141>

//PAGEBREAK: 20
 bad:
  if(p)
80104140:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104144:	74 0b                	je     80104151 <pipealloc+0x110>
    kfree((char*)p);
80104146:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104149:	89 04 24             	mov    %eax,(%esp)
8010414c:	e8 13 ea ff ff       	call   80102b64 <kfree>
  if(*f0)
80104151:	8b 45 08             	mov    0x8(%ebp),%eax
80104154:	8b 00                	mov    (%eax),%eax
80104156:	85 c0                	test   %eax,%eax
80104158:	74 0d                	je     80104167 <pipealloc+0x126>
    fileclose(*f0);
8010415a:	8b 45 08             	mov    0x8(%ebp),%eax
8010415d:	8b 00                	mov    (%eax),%eax
8010415f:	89 04 24             	mov    %eax,(%esp)
80104162:	e8 67 ce ff ff       	call   80100fce <fileclose>
  if(*f1)
80104167:	8b 45 0c             	mov    0xc(%ebp),%eax
8010416a:	8b 00                	mov    (%eax),%eax
8010416c:	85 c0                	test   %eax,%eax
8010416e:	74 0d                	je     8010417d <pipealloc+0x13c>
    fileclose(*f1);
80104170:	8b 45 0c             	mov    0xc(%ebp),%eax
80104173:	8b 00                	mov    (%eax),%eax
80104175:	89 04 24             	mov    %eax,(%esp)
80104178:	e8 51 ce ff ff       	call   80100fce <fileclose>
  return -1;
8010417d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104182:	c9                   	leave  
80104183:	c3                   	ret    

80104184 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80104184:	55                   	push   %ebp
80104185:	89 e5                	mov    %esp,%ebp
80104187:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
8010418a:	8b 45 08             	mov    0x8(%ebp),%eax
8010418d:	89 04 24             	mov    %eax,(%esp)
80104190:	e8 a7 0f 00 00       	call   8010513c <acquire>
  if(writable){
80104195:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104199:	74 1f                	je     801041ba <pipeclose+0x36>
    p->writeopen = 0;
8010419b:	8b 45 08             	mov    0x8(%ebp),%eax
8010419e:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
801041a5:	00 00 00 
    wakeup(&p->nread);
801041a8:	8b 45 08             	mov    0x8(%ebp),%eax
801041ab:	05 34 02 00 00       	add    $0x234,%eax
801041b0:	89 04 24             	mov    %eax,(%esp)
801041b3:	e8 61 0b 00 00       	call   80104d19 <wakeup>
801041b8:	eb 1d                	jmp    801041d7 <pipeclose+0x53>
  } else {
    p->readopen = 0;
801041ba:	8b 45 08             	mov    0x8(%ebp),%eax
801041bd:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
801041c4:	00 00 00 
    wakeup(&p->nwrite);
801041c7:	8b 45 08             	mov    0x8(%ebp),%eax
801041ca:	05 38 02 00 00       	add    $0x238,%eax
801041cf:	89 04 24             	mov    %eax,(%esp)
801041d2:	e8 42 0b 00 00       	call   80104d19 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
801041d7:	8b 45 08             	mov    0x8(%ebp),%eax
801041da:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801041e0:	85 c0                	test   %eax,%eax
801041e2:	75 25                	jne    80104209 <pipeclose+0x85>
801041e4:	8b 45 08             	mov    0x8(%ebp),%eax
801041e7:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801041ed:	85 c0                	test   %eax,%eax
801041ef:	75 18                	jne    80104209 <pipeclose+0x85>
    release(&p->lock);
801041f1:	8b 45 08             	mov    0x8(%ebp),%eax
801041f4:	89 04 24             	mov    %eax,(%esp)
801041f7:	e8 a2 0f 00 00       	call   8010519e <release>
    kfree((char*)p);
801041fc:	8b 45 08             	mov    0x8(%ebp),%eax
801041ff:	89 04 24             	mov    %eax,(%esp)
80104202:	e8 5d e9 ff ff       	call   80102b64 <kfree>
80104207:	eb 0b                	jmp    80104214 <pipeclose+0x90>
  } else
    release(&p->lock);
80104209:	8b 45 08             	mov    0x8(%ebp),%eax
8010420c:	89 04 24             	mov    %eax,(%esp)
8010420f:	e8 8a 0f 00 00       	call   8010519e <release>
}
80104214:	c9                   	leave  
80104215:	c3                   	ret    

80104216 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80104216:	55                   	push   %ebp
80104217:	89 e5                	mov    %esp,%ebp
80104219:	83 ec 28             	sub    $0x28,%esp
  int i;

  acquire(&p->lock);
8010421c:	8b 45 08             	mov    0x8(%ebp),%eax
8010421f:	89 04 24             	mov    %eax,(%esp)
80104222:	e8 15 0f 00 00       	call   8010513c <acquire>
  for(i = 0; i < n; i++){
80104227:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010422e:	e9 a6 00 00 00       	jmp    801042d9 <pipewrite+0xc3>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104233:	eb 57                	jmp    8010428c <pipewrite+0x76>
      if(p->readopen == 0 || proc->killed){
80104235:	8b 45 08             	mov    0x8(%ebp),%eax
80104238:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
8010423e:	85 c0                	test   %eax,%eax
80104240:	74 0d                	je     8010424f <pipewrite+0x39>
80104242:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104248:	8b 40 24             	mov    0x24(%eax),%eax
8010424b:	85 c0                	test   %eax,%eax
8010424d:	74 15                	je     80104264 <pipewrite+0x4e>
        release(&p->lock);
8010424f:	8b 45 08             	mov    0x8(%ebp),%eax
80104252:	89 04 24             	mov    %eax,(%esp)
80104255:	e8 44 0f 00 00       	call   8010519e <release>
        return -1;
8010425a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010425f:	e9 9f 00 00 00       	jmp    80104303 <pipewrite+0xed>
      }
      wakeup(&p->nread);
80104264:	8b 45 08             	mov    0x8(%ebp),%eax
80104267:	05 34 02 00 00       	add    $0x234,%eax
8010426c:	89 04 24             	mov    %eax,(%esp)
8010426f:	e8 a5 0a 00 00       	call   80104d19 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80104274:	8b 45 08             	mov    0x8(%ebp),%eax
80104277:	8b 55 08             	mov    0x8(%ebp),%edx
8010427a:	81 c2 38 02 00 00    	add    $0x238,%edx
80104280:	89 44 24 04          	mov    %eax,0x4(%esp)
80104284:	89 14 24             	mov    %edx,(%esp)
80104287:	e8 b4 09 00 00       	call   80104c40 <sleep>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
8010428c:	8b 45 08             	mov    0x8(%ebp),%eax
8010428f:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80104295:	8b 45 08             	mov    0x8(%ebp),%eax
80104298:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
8010429e:	05 00 02 00 00       	add    $0x200,%eax
801042a3:	39 c2                	cmp    %eax,%edx
801042a5:	74 8e                	je     80104235 <pipewrite+0x1f>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
801042a7:	8b 45 08             	mov    0x8(%ebp),%eax
801042aa:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801042b0:	8d 48 01             	lea    0x1(%eax),%ecx
801042b3:	8b 55 08             	mov    0x8(%ebp),%edx
801042b6:	89 8a 38 02 00 00    	mov    %ecx,0x238(%edx)
801042bc:	25 ff 01 00 00       	and    $0x1ff,%eax
801042c1:	89 c1                	mov    %eax,%ecx
801042c3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042c6:	8b 45 0c             	mov    0xc(%ebp),%eax
801042c9:	01 d0                	add    %edx,%eax
801042cb:	0f b6 10             	movzbl (%eax),%edx
801042ce:	8b 45 08             	mov    0x8(%ebp),%eax
801042d1:	88 54 08 34          	mov    %dl,0x34(%eax,%ecx,1)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
801042d5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801042d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042dc:	3b 45 10             	cmp    0x10(%ebp),%eax
801042df:	0f 8c 4e ff ff ff    	jl     80104233 <pipewrite+0x1d>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
801042e5:	8b 45 08             	mov    0x8(%ebp),%eax
801042e8:	05 34 02 00 00       	add    $0x234,%eax
801042ed:	89 04 24             	mov    %eax,(%esp)
801042f0:	e8 24 0a 00 00       	call   80104d19 <wakeup>
  release(&p->lock);
801042f5:	8b 45 08             	mov    0x8(%ebp),%eax
801042f8:	89 04 24             	mov    %eax,(%esp)
801042fb:	e8 9e 0e 00 00       	call   8010519e <release>
  return n;
80104300:	8b 45 10             	mov    0x10(%ebp),%eax
}
80104303:	c9                   	leave  
80104304:	c3                   	ret    

80104305 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80104305:	55                   	push   %ebp
80104306:	89 e5                	mov    %esp,%ebp
80104308:	53                   	push   %ebx
80104309:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
8010430c:	8b 45 08             	mov    0x8(%ebp),%eax
8010430f:	89 04 24             	mov    %eax,(%esp)
80104312:	e8 25 0e 00 00       	call   8010513c <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104317:	eb 3a                	jmp    80104353 <piperead+0x4e>
    if(proc->killed){
80104319:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010431f:	8b 40 24             	mov    0x24(%eax),%eax
80104322:	85 c0                	test   %eax,%eax
80104324:	74 15                	je     8010433b <piperead+0x36>
      release(&p->lock);
80104326:	8b 45 08             	mov    0x8(%ebp),%eax
80104329:	89 04 24             	mov    %eax,(%esp)
8010432c:	e8 6d 0e 00 00       	call   8010519e <release>
      return -1;
80104331:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104336:	e9 b5 00 00 00       	jmp    801043f0 <piperead+0xeb>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
8010433b:	8b 45 08             	mov    0x8(%ebp),%eax
8010433e:	8b 55 08             	mov    0x8(%ebp),%edx
80104341:	81 c2 34 02 00 00    	add    $0x234,%edx
80104347:	89 44 24 04          	mov    %eax,0x4(%esp)
8010434b:	89 14 24             	mov    %edx,(%esp)
8010434e:	e8 ed 08 00 00       	call   80104c40 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104353:	8b 45 08             	mov    0x8(%ebp),%eax
80104356:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
8010435c:	8b 45 08             	mov    0x8(%ebp),%eax
8010435f:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104365:	39 c2                	cmp    %eax,%edx
80104367:	75 0d                	jne    80104376 <piperead+0x71>
80104369:	8b 45 08             	mov    0x8(%ebp),%eax
8010436c:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104372:	85 c0                	test   %eax,%eax
80104374:	75 a3                	jne    80104319 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104376:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010437d:	eb 4b                	jmp    801043ca <piperead+0xc5>
    if(p->nread == p->nwrite)
8010437f:	8b 45 08             	mov    0x8(%ebp),%eax
80104382:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104388:	8b 45 08             	mov    0x8(%ebp),%eax
8010438b:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104391:	39 c2                	cmp    %eax,%edx
80104393:	75 02                	jne    80104397 <piperead+0x92>
      break;
80104395:	eb 3b                	jmp    801043d2 <piperead+0xcd>
    addr[i] = p->data[p->nread++ % PIPESIZE];
80104397:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010439a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010439d:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
801043a0:	8b 45 08             	mov    0x8(%ebp),%eax
801043a3:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801043a9:	8d 48 01             	lea    0x1(%eax),%ecx
801043ac:	8b 55 08             	mov    0x8(%ebp),%edx
801043af:	89 8a 34 02 00 00    	mov    %ecx,0x234(%edx)
801043b5:	25 ff 01 00 00       	and    $0x1ff,%eax
801043ba:	89 c2                	mov    %eax,%edx
801043bc:	8b 45 08             	mov    0x8(%ebp),%eax
801043bf:	0f b6 44 10 34       	movzbl 0x34(%eax,%edx,1),%eax
801043c4:	88 03                	mov    %al,(%ebx)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801043c6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801043ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043cd:	3b 45 10             	cmp    0x10(%ebp),%eax
801043d0:	7c ad                	jl     8010437f <piperead+0x7a>
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
801043d2:	8b 45 08             	mov    0x8(%ebp),%eax
801043d5:	05 38 02 00 00       	add    $0x238,%eax
801043da:	89 04 24             	mov    %eax,(%esp)
801043dd:	e8 37 09 00 00       	call   80104d19 <wakeup>
  release(&p->lock);
801043e2:	8b 45 08             	mov    0x8(%ebp),%eax
801043e5:	89 04 24             	mov    %eax,(%esp)
801043e8:	e8 b1 0d 00 00       	call   8010519e <release>
  return i;
801043ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801043f0:	83 c4 24             	add    $0x24,%esp
801043f3:	5b                   	pop    %ebx
801043f4:	5d                   	pop    %ebp
801043f5:	c3                   	ret    

801043f6 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801043f6:	55                   	push   %ebp
801043f7:	89 e5                	mov    %esp,%ebp
801043f9:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801043fc:	9c                   	pushf  
801043fd:	58                   	pop    %eax
801043fe:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80104401:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104404:	c9                   	leave  
80104405:	c3                   	ret    

80104406 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104406:	55                   	push   %ebp
80104407:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104409:	fb                   	sti    
}
8010440a:	5d                   	pop    %ebp
8010440b:	c3                   	ret    

8010440c <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
8010440c:	55                   	push   %ebp
8010440d:	89 e5                	mov    %esp,%ebp
8010440f:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104412:	c7 44 24 04 41 8a 10 	movl   $0x80108a41,0x4(%esp)
80104419:	80 
8010441a:	c7 04 24 a0 29 11 80 	movl   $0x801129a0,(%esp)
80104421:	e8 f5 0c 00 00       	call   8010511b <initlock>
}
80104426:	c9                   	leave  
80104427:	c3                   	ret    

80104428 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104428:	55                   	push   %ebp
80104429:	89 e5                	mov    %esp,%ebp
8010442b:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
8010442e:	c7 04 24 a0 29 11 80 	movl   $0x801129a0,(%esp)
80104435:	e8 02 0d 00 00       	call   8010513c <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010443a:	c7 45 f4 d4 29 11 80 	movl   $0x801129d4,-0xc(%ebp)
80104441:	eb 50                	jmp    80104493 <allocproc+0x6b>
    if(p->state == UNUSED)
80104443:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104446:	8b 40 0c             	mov    0xc(%eax),%eax
80104449:	85 c0                	test   %eax,%eax
8010444b:	75 42                	jne    8010448f <allocproc+0x67>
      goto found;
8010444d:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
8010444e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104451:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
80104458:	a1 04 b0 10 80       	mov    0x8010b004,%eax
8010445d:	8d 50 01             	lea    0x1(%eax),%edx
80104460:	89 15 04 b0 10 80    	mov    %edx,0x8010b004
80104466:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104469:	89 42 10             	mov    %eax,0x10(%edx)
  release(&ptable.lock);
8010446c:	c7 04 24 a0 29 11 80 	movl   $0x801129a0,(%esp)
80104473:	e8 26 0d 00 00       	call   8010519e <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
80104478:	e8 80 e7 ff ff       	call   80102bfd <kalloc>
8010447d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104480:	89 42 08             	mov    %eax,0x8(%edx)
80104483:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104486:	8b 40 08             	mov    0x8(%eax),%eax
80104489:	85 c0                	test   %eax,%eax
8010448b:	75 33                	jne    801044c0 <allocproc+0x98>
8010448d:	eb 20                	jmp    801044af <allocproc+0x87>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010448f:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104493:	81 7d f4 d4 48 11 80 	cmpl   $0x801148d4,-0xc(%ebp)
8010449a:	72 a7                	jb     80104443 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
8010449c:	c7 04 24 a0 29 11 80 	movl   $0x801129a0,(%esp)
801044a3:	e8 f6 0c 00 00       	call   8010519e <release>
  return 0;
801044a8:	b8 00 00 00 00       	mov    $0x0,%eax
801044ad:	eb 76                	jmp    80104525 <allocproc+0xfd>
  p->pid = nextpid++;
  release(&ptable.lock);

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
    p->state = UNUSED;
801044af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044b2:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
801044b9:	b8 00 00 00 00       	mov    $0x0,%eax
801044be:	eb 65                	jmp    80104525 <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
801044c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044c3:	8b 40 08             	mov    0x8(%eax),%eax
801044c6:	05 00 10 00 00       	add    $0x1000,%eax
801044cb:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
801044ce:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
801044d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044d5:	8b 55 f0             	mov    -0x10(%ebp),%edx
801044d8:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
801044db:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
801044df:	ba 0a 68 10 80       	mov    $0x8010680a,%edx
801044e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801044e7:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
801044e9:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
801044ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044f0:	8b 55 f0             	mov    -0x10(%ebp),%edx
801044f3:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
801044f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044f9:	8b 40 1c             	mov    0x1c(%eax),%eax
801044fc:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104503:	00 
80104504:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010450b:	00 
8010450c:	89 04 24             	mov    %eax,(%esp)
8010450f:	e8 7c 0e 00 00       	call   80105390 <memset>
  p->context->eip = (uint)forkret;
80104514:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104517:	8b 40 1c             	mov    0x1c(%eax),%eax
8010451a:	ba 14 4c 10 80       	mov    $0x80104c14,%edx
8010451f:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
80104522:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104525:	c9                   	leave  
80104526:	c3                   	ret    

80104527 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
80104527:	55                   	push   %ebp
80104528:	89 e5                	mov    %esp,%ebp
8010452a:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
8010452d:	e8 f6 fe ff ff       	call   80104428 <allocproc>
80104532:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80104535:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104538:	a3 48 b6 10 80       	mov    %eax,0x8010b648
  if((p->pgdir = setupkvm()) == 0)
8010453d:	e8 bc 39 00 00       	call   80107efe <setupkvm>
80104542:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104545:	89 42 04             	mov    %eax,0x4(%edx)
80104548:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010454b:	8b 40 04             	mov    0x4(%eax),%eax
8010454e:	85 c0                	test   %eax,%eax
80104550:	75 0c                	jne    8010455e <userinit+0x37>
    panic("userinit: out of memory?");
80104552:	c7 04 24 48 8a 10 80 	movl   $0x80108a48,(%esp)
80104559:	e8 dc bf ff ff       	call   8010053a <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
8010455e:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104563:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104566:	8b 40 04             	mov    0x4(%eax),%eax
80104569:	89 54 24 08          	mov    %edx,0x8(%esp)
8010456d:	c7 44 24 04 e0 b4 10 	movl   $0x8010b4e0,0x4(%esp)
80104574:	80 
80104575:	89 04 24             	mov    %eax,(%esp)
80104578:	e8 d9 3b 00 00       	call   80108156 <inituvm>
  p->sz = PGSIZE;
8010457d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104580:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80104586:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104589:	8b 40 18             	mov    0x18(%eax),%eax
8010458c:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104593:	00 
80104594:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010459b:	00 
8010459c:	89 04 24             	mov    %eax,(%esp)
8010459f:	e8 ec 0d 00 00       	call   80105390 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801045a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045a7:	8b 40 18             	mov    0x18(%eax),%eax
801045aa:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801045b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045b3:	8b 40 18             	mov    0x18(%eax),%eax
801045b6:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
801045bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045bf:	8b 40 18             	mov    0x18(%eax),%eax
801045c2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801045c5:	8b 52 18             	mov    0x18(%edx),%edx
801045c8:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801045cc:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801045d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045d3:	8b 40 18             	mov    0x18(%eax),%eax
801045d6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801045d9:	8b 52 18             	mov    0x18(%edx),%edx
801045dc:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801045e0:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801045e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045e7:	8b 40 18             	mov    0x18(%eax),%eax
801045ea:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801045f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045f4:	8b 40 18             	mov    0x18(%eax),%eax
801045f7:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801045fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104601:	8b 40 18             	mov    0x18(%eax),%eax
80104604:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
8010460b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010460e:	83 c0 6c             	add    $0x6c,%eax
80104611:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104618:	00 
80104619:	c7 44 24 04 61 8a 10 	movl   $0x80108a61,0x4(%esp)
80104620:	80 
80104621:	89 04 24             	mov    %eax,(%esp)
80104624:	e8 87 0f 00 00       	call   801055b0 <safestrcpy>
  p->cwd = namei("/");
80104629:	c7 04 24 6a 8a 10 80 	movl   $0x80108a6a,(%esp)
80104630:	e8 ec de ff ff       	call   80102521 <namei>
80104635:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104638:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
8010463b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010463e:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
80104645:	c9                   	leave  
80104646:	c3                   	ret    

80104647 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104647:	55                   	push   %ebp
80104648:	89 e5                	mov    %esp,%ebp
8010464a:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
8010464d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104653:	8b 00                	mov    (%eax),%eax
80104655:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104658:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010465c:	7e 34                	jle    80104692 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
8010465e:	8b 55 08             	mov    0x8(%ebp),%edx
80104661:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104664:	01 c2                	add    %eax,%edx
80104666:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010466c:	8b 40 04             	mov    0x4(%eax),%eax
8010466f:	89 54 24 08          	mov    %edx,0x8(%esp)
80104673:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104676:	89 54 24 04          	mov    %edx,0x4(%esp)
8010467a:	89 04 24             	mov    %eax,(%esp)
8010467d:	e8 4a 3c 00 00       	call   801082cc <allocuvm>
80104682:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104685:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104689:	75 41                	jne    801046cc <growproc+0x85>
      return -1;
8010468b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104690:	eb 58                	jmp    801046ea <growproc+0xa3>
  } else if(n < 0){
80104692:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104696:	79 34                	jns    801046cc <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
80104698:	8b 55 08             	mov    0x8(%ebp),%edx
8010469b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010469e:	01 c2                	add    %eax,%edx
801046a0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046a6:	8b 40 04             	mov    0x4(%eax),%eax
801046a9:	89 54 24 08          	mov    %edx,0x8(%esp)
801046ad:	8b 55 f4             	mov    -0xc(%ebp),%edx
801046b0:	89 54 24 04          	mov    %edx,0x4(%esp)
801046b4:	89 04 24             	mov    %eax,(%esp)
801046b7:	e8 ea 3c 00 00       	call   801083a6 <deallocuvm>
801046bc:	89 45 f4             	mov    %eax,-0xc(%ebp)
801046bf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801046c3:	75 07                	jne    801046cc <growproc+0x85>
      return -1;
801046c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046ca:	eb 1e                	jmp    801046ea <growproc+0xa3>
  }
  proc->sz = sz;
801046cc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046d2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801046d5:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
801046d7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046dd:	89 04 24             	mov    %eax,(%esp)
801046e0:	e8 0a 39 00 00       	call   80107fef <switchuvm>
  return 0;
801046e5:	b8 00 00 00 00       	mov    $0x0,%eax
}
801046ea:	c9                   	leave  
801046eb:	c3                   	ret    

801046ec <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
801046ec:	55                   	push   %ebp
801046ed:	89 e5                	mov    %esp,%ebp
801046ef:	57                   	push   %edi
801046f0:	56                   	push   %esi
801046f1:	53                   	push   %ebx
801046f2:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
801046f5:	e8 2e fd ff ff       	call   80104428 <allocproc>
801046fa:	89 45 e0             	mov    %eax,-0x20(%ebp)
801046fd:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104701:	75 0a                	jne    8010470d <fork+0x21>
    return -1;
80104703:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104708:	e9 52 01 00 00       	jmp    8010485f <fork+0x173>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
8010470d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104713:	8b 10                	mov    (%eax),%edx
80104715:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010471b:	8b 40 04             	mov    0x4(%eax),%eax
8010471e:	89 54 24 04          	mov    %edx,0x4(%esp)
80104722:	89 04 24             	mov    %eax,(%esp)
80104725:	e8 18 3e 00 00       	call   80108542 <copyuvm>
8010472a:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010472d:	89 42 04             	mov    %eax,0x4(%edx)
80104730:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104733:	8b 40 04             	mov    0x4(%eax),%eax
80104736:	85 c0                	test   %eax,%eax
80104738:	75 2c                	jne    80104766 <fork+0x7a>
    kfree(np->kstack);
8010473a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010473d:	8b 40 08             	mov    0x8(%eax),%eax
80104740:	89 04 24             	mov    %eax,(%esp)
80104743:	e8 1c e4 ff ff       	call   80102b64 <kfree>
    np->kstack = 0;
80104748:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010474b:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104752:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104755:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
8010475c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104761:	e9 f9 00 00 00       	jmp    8010485f <fork+0x173>
  }
  np->sz = proc->sz;
80104766:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010476c:	8b 10                	mov    (%eax),%edx
8010476e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104771:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80104773:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010477a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010477d:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
80104780:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104783:	8b 50 18             	mov    0x18(%eax),%edx
80104786:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010478c:	8b 40 18             	mov    0x18(%eax),%eax
8010478f:	89 c3                	mov    %eax,%ebx
80104791:	b8 13 00 00 00       	mov    $0x13,%eax
80104796:	89 d7                	mov    %edx,%edi
80104798:	89 de                	mov    %ebx,%esi
8010479a:	89 c1                	mov    %eax,%ecx
8010479c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
8010479e:	8b 45 e0             	mov    -0x20(%ebp),%eax
801047a1:	8b 40 18             	mov    0x18(%eax),%eax
801047a4:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
801047ab:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801047b2:	eb 3d                	jmp    801047f1 <fork+0x105>
    if(proc->ofile[i])
801047b4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047ba:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801047bd:	83 c2 08             	add    $0x8,%edx
801047c0:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801047c4:	85 c0                	test   %eax,%eax
801047c6:	74 25                	je     801047ed <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
801047c8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047ce:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801047d1:	83 c2 08             	add    $0x8,%edx
801047d4:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801047d8:	89 04 24             	mov    %eax,(%esp)
801047db:	e8 a6 c7 ff ff       	call   80100f86 <filedup>
801047e0:	8b 55 e0             	mov    -0x20(%ebp),%edx
801047e3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801047e6:	83 c1 08             	add    $0x8,%ecx
801047e9:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
801047ed:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
801047f1:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
801047f5:	7e bd                	jle    801047b4 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
801047f7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047fd:	8b 40 68             	mov    0x68(%eax),%eax
80104800:	89 04 24             	mov    %eax,(%esp)
80104803:	e8 21 d0 ff ff       	call   80101829 <idup>
80104808:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010480b:	89 42 68             	mov    %eax,0x68(%edx)

  safestrcpy(np->name, proc->name, sizeof(proc->name));
8010480e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104814:	8d 50 6c             	lea    0x6c(%eax),%edx
80104817:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010481a:	83 c0 6c             	add    $0x6c,%eax
8010481d:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104824:	00 
80104825:	89 54 24 04          	mov    %edx,0x4(%esp)
80104829:	89 04 24             	mov    %eax,(%esp)
8010482c:	e8 7f 0d 00 00       	call   801055b0 <safestrcpy>
 
  pid = np->pid;
80104831:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104834:	8b 40 10             	mov    0x10(%eax),%eax
80104837:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // lock to force the compiler to emit the np->state write last.
  acquire(&ptable.lock);
8010483a:	c7 04 24 a0 29 11 80 	movl   $0x801129a0,(%esp)
80104841:	e8 f6 08 00 00       	call   8010513c <acquire>
  np->state = RUNNABLE;
80104846:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104849:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  release(&ptable.lock);
80104850:	c7 04 24 a0 29 11 80 	movl   $0x801129a0,(%esp)
80104857:	e8 42 09 00 00       	call   8010519e <release>
  
  return pid;
8010485c:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
8010485f:	83 c4 2c             	add    $0x2c,%esp
80104862:	5b                   	pop    %ebx
80104863:	5e                   	pop    %esi
80104864:	5f                   	pop    %edi
80104865:	5d                   	pop    %ebp
80104866:	c3                   	ret    

80104867 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80104867:	55                   	push   %ebp
80104868:	89 e5                	mov    %esp,%ebp
8010486a:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
8010486d:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104874:	a1 48 b6 10 80       	mov    0x8010b648,%eax
80104879:	39 c2                	cmp    %eax,%edx
8010487b:	75 0c                	jne    80104889 <exit+0x22>
    panic("init exiting");
8010487d:	c7 04 24 6c 8a 10 80 	movl   $0x80108a6c,(%esp)
80104884:	e8 b1 bc ff ff       	call   8010053a <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104889:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104890:	eb 44                	jmp    801048d6 <exit+0x6f>
    if(proc->ofile[fd]){
80104892:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104898:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010489b:	83 c2 08             	add    $0x8,%edx
8010489e:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801048a2:	85 c0                	test   %eax,%eax
801048a4:	74 2c                	je     801048d2 <exit+0x6b>
      fileclose(proc->ofile[fd]);
801048a6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048ac:	8b 55 f0             	mov    -0x10(%ebp),%edx
801048af:	83 c2 08             	add    $0x8,%edx
801048b2:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801048b6:	89 04 24             	mov    %eax,(%esp)
801048b9:	e8 10 c7 ff ff       	call   80100fce <fileclose>
      proc->ofile[fd] = 0;
801048be:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048c4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801048c7:	83 c2 08             	add    $0x8,%edx
801048ca:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801048d1:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801048d2:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801048d6:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
801048da:	7e b6                	jle    80104892 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  begin_op();
801048dc:	e8 4a ec ff ff       	call   8010352b <begin_op>
  iput(proc->cwd);
801048e1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048e7:	8b 40 68             	mov    0x68(%eax),%eax
801048ea:	89 04 24             	mov    %eax,(%esp)
801048ed:	e8 1c d1 ff ff       	call   80101a0e <iput>
  end_op();
801048f2:	e8 b8 ec ff ff       	call   801035af <end_op>
  proc->cwd = 0;
801048f7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048fd:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
80104904:	c7 04 24 a0 29 11 80 	movl   $0x801129a0,(%esp)
8010490b:	e8 2c 08 00 00       	call   8010513c <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
80104910:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104916:	8b 40 14             	mov    0x14(%eax),%eax
80104919:	89 04 24             	mov    %eax,(%esp)
8010491c:	e8 ba 03 00 00       	call   80104cdb <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104921:	c7 45 f4 d4 29 11 80 	movl   $0x801129d4,-0xc(%ebp)
80104928:	eb 38                	jmp    80104962 <exit+0xfb>
    if(p->parent == proc){
8010492a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010492d:	8b 50 14             	mov    0x14(%eax),%edx
80104930:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104936:	39 c2                	cmp    %eax,%edx
80104938:	75 24                	jne    8010495e <exit+0xf7>
      p->parent = initproc;
8010493a:	8b 15 48 b6 10 80    	mov    0x8010b648,%edx
80104940:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104943:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
80104946:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104949:	8b 40 0c             	mov    0xc(%eax),%eax
8010494c:	83 f8 05             	cmp    $0x5,%eax
8010494f:	75 0d                	jne    8010495e <exit+0xf7>
        wakeup1(initproc);
80104951:	a1 48 b6 10 80       	mov    0x8010b648,%eax
80104956:	89 04 24             	mov    %eax,(%esp)
80104959:	e8 7d 03 00 00       	call   80104cdb <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010495e:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104962:	81 7d f4 d4 48 11 80 	cmpl   $0x801148d4,-0xc(%ebp)
80104969:	72 bf                	jb     8010492a <exit+0xc3>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
8010496b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104971:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80104978:	e8 b3 01 00 00       	call   80104b30 <sched>
  panic("zombie exit");
8010497d:	c7 04 24 79 8a 10 80 	movl   $0x80108a79,(%esp)
80104984:	e8 b1 bb ff ff       	call   8010053a <panic>

80104989 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
80104989:	55                   	push   %ebp
8010498a:	89 e5                	mov    %esp,%ebp
8010498c:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
8010498f:	c7 04 24 a0 29 11 80 	movl   $0x801129a0,(%esp)
80104996:	e8 a1 07 00 00       	call   8010513c <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
8010499b:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801049a2:	c7 45 f4 d4 29 11 80 	movl   $0x801129d4,-0xc(%ebp)
801049a9:	e9 9a 00 00 00       	jmp    80104a48 <wait+0xbf>
      if(p->parent != proc)
801049ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049b1:	8b 50 14             	mov    0x14(%eax),%edx
801049b4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049ba:	39 c2                	cmp    %eax,%edx
801049bc:	74 05                	je     801049c3 <wait+0x3a>
        continue;
801049be:	e9 81 00 00 00       	jmp    80104a44 <wait+0xbb>
      havekids = 1;
801049c3:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
801049ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049cd:	8b 40 0c             	mov    0xc(%eax),%eax
801049d0:	83 f8 05             	cmp    $0x5,%eax
801049d3:	75 6f                	jne    80104a44 <wait+0xbb>
        // Found one.
        pid = p->pid;
801049d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049d8:	8b 40 10             	mov    0x10(%eax),%eax
801049db:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
801049de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049e1:	8b 40 08             	mov    0x8(%eax),%eax
801049e4:	89 04 24             	mov    %eax,(%esp)
801049e7:	e8 78 e1 ff ff       	call   80102b64 <kfree>
        p->kstack = 0;
801049ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049ef:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
801049f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049f9:	8b 40 04             	mov    0x4(%eax),%eax
801049fc:	89 04 24             	mov    %eax,(%esp)
801049ff:	e8 5e 3a 00 00       	call   80108462 <freevm>
        p->state = UNUSED;
80104a04:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a07:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80104a0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a11:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80104a18:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a1b:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80104a22:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a25:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80104a29:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a2c:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
80104a33:	c7 04 24 a0 29 11 80 	movl   $0x801129a0,(%esp)
80104a3a:	e8 5f 07 00 00       	call   8010519e <release>
        return pid;
80104a3f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104a42:	eb 52                	jmp    80104a96 <wait+0x10d>

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104a44:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104a48:	81 7d f4 d4 48 11 80 	cmpl   $0x801148d4,-0xc(%ebp)
80104a4f:	0f 82 59 ff ff ff    	jb     801049ae <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80104a55:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104a59:	74 0d                	je     80104a68 <wait+0xdf>
80104a5b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a61:	8b 40 24             	mov    0x24(%eax),%eax
80104a64:	85 c0                	test   %eax,%eax
80104a66:	74 13                	je     80104a7b <wait+0xf2>
      release(&ptable.lock);
80104a68:	c7 04 24 a0 29 11 80 	movl   $0x801129a0,(%esp)
80104a6f:	e8 2a 07 00 00       	call   8010519e <release>
      return -1;
80104a74:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a79:	eb 1b                	jmp    80104a96 <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80104a7b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a81:	c7 44 24 04 a0 29 11 	movl   $0x801129a0,0x4(%esp)
80104a88:	80 
80104a89:	89 04 24             	mov    %eax,(%esp)
80104a8c:	e8 af 01 00 00       	call   80104c40 <sleep>
  }
80104a91:	e9 05 ff ff ff       	jmp    8010499b <wait+0x12>
}
80104a96:	c9                   	leave  
80104a97:	c3                   	ret    

80104a98 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80104a98:	55                   	push   %ebp
80104a99:	89 e5                	mov    %esp,%ebp
80104a9b:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
80104a9e:	e8 63 f9 ff ff       	call   80104406 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80104aa3:	c7 04 24 a0 29 11 80 	movl   $0x801129a0,(%esp)
80104aaa:	e8 8d 06 00 00       	call   8010513c <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104aaf:	c7 45 f4 d4 29 11 80 	movl   $0x801129d4,-0xc(%ebp)
80104ab6:	eb 5e                	jmp    80104b16 <scheduler+0x7e>
      if(p->state != RUNNABLE)
80104ab8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104abb:	8b 40 0c             	mov    0xc(%eax),%eax
80104abe:	83 f8 03             	cmp    $0x3,%eax
80104ac1:	74 02                	je     80104ac5 <scheduler+0x2d>
        continue;
80104ac3:	eb 4d                	jmp    80104b12 <scheduler+0x7a>

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
80104ac5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ac8:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80104ace:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ad1:	89 04 24             	mov    %eax,(%esp)
80104ad4:	e8 16 35 00 00       	call   80107fef <switchuvm>
      p->state = RUNNING;
80104ad9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104adc:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80104ae3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ae9:	8b 40 1c             	mov    0x1c(%eax),%eax
80104aec:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104af3:	83 c2 04             	add    $0x4,%edx
80104af6:	89 44 24 04          	mov    %eax,0x4(%esp)
80104afa:	89 14 24             	mov    %edx,(%esp)
80104afd:	e8 1f 0b 00 00       	call   80105621 <swtch>
      switchkvm();
80104b02:	e8 cb 34 00 00       	call   80107fd2 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80104b07:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80104b0e:	00 00 00 00 
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b12:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104b16:	81 7d f4 d4 48 11 80 	cmpl   $0x801148d4,-0xc(%ebp)
80104b1d:	72 99                	jb     80104ab8 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80104b1f:	c7 04 24 a0 29 11 80 	movl   $0x801129a0,(%esp)
80104b26:	e8 73 06 00 00       	call   8010519e <release>

  }
80104b2b:	e9 6e ff ff ff       	jmp    80104a9e <scheduler+0x6>

80104b30 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80104b30:	55                   	push   %ebp
80104b31:	89 e5                	mov    %esp,%ebp
80104b33:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80104b36:	c7 04 24 a0 29 11 80 	movl   $0x801129a0,(%esp)
80104b3d:	e8 24 07 00 00       	call   80105266 <holding>
80104b42:	85 c0                	test   %eax,%eax
80104b44:	75 0c                	jne    80104b52 <sched+0x22>
    panic("sched ptable.lock");
80104b46:	c7 04 24 85 8a 10 80 	movl   $0x80108a85,(%esp)
80104b4d:	e8 e8 b9 ff ff       	call   8010053a <panic>
  if(cpu->ncli != 1)
80104b52:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104b58:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104b5e:	83 f8 01             	cmp    $0x1,%eax
80104b61:	74 0c                	je     80104b6f <sched+0x3f>
    panic("sched locks");
80104b63:	c7 04 24 97 8a 10 80 	movl   $0x80108a97,(%esp)
80104b6a:	e8 cb b9 ff ff       	call   8010053a <panic>
  if(proc->state == RUNNING)
80104b6f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b75:	8b 40 0c             	mov    0xc(%eax),%eax
80104b78:	83 f8 04             	cmp    $0x4,%eax
80104b7b:	75 0c                	jne    80104b89 <sched+0x59>
    panic("sched running");
80104b7d:	c7 04 24 a3 8a 10 80 	movl   $0x80108aa3,(%esp)
80104b84:	e8 b1 b9 ff ff       	call   8010053a <panic>
  if(readeflags()&FL_IF)
80104b89:	e8 68 f8 ff ff       	call   801043f6 <readeflags>
80104b8e:	25 00 02 00 00       	and    $0x200,%eax
80104b93:	85 c0                	test   %eax,%eax
80104b95:	74 0c                	je     80104ba3 <sched+0x73>
    panic("sched interruptible");
80104b97:	c7 04 24 b1 8a 10 80 	movl   $0x80108ab1,(%esp)
80104b9e:	e8 97 b9 ff ff       	call   8010053a <panic>
  intena = cpu->intena;
80104ba3:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104ba9:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104baf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80104bb2:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104bb8:	8b 40 04             	mov    0x4(%eax),%eax
80104bbb:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104bc2:	83 c2 1c             	add    $0x1c,%edx
80104bc5:	89 44 24 04          	mov    %eax,0x4(%esp)
80104bc9:	89 14 24             	mov    %edx,(%esp)
80104bcc:	e8 50 0a 00 00       	call   80105621 <swtch>
  cpu->intena = intena;
80104bd1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104bd7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104bda:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104be0:	c9                   	leave  
80104be1:	c3                   	ret    

80104be2 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80104be2:	55                   	push   %ebp
80104be3:	89 e5                	mov    %esp,%ebp
80104be5:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80104be8:	c7 04 24 a0 29 11 80 	movl   $0x801129a0,(%esp)
80104bef:	e8 48 05 00 00       	call   8010513c <acquire>
  proc->state = RUNNABLE;
80104bf4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104bfa:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80104c01:	e8 2a ff ff ff       	call   80104b30 <sched>
  release(&ptable.lock);
80104c06:	c7 04 24 a0 29 11 80 	movl   $0x801129a0,(%esp)
80104c0d:	e8 8c 05 00 00       	call   8010519e <release>
}
80104c12:	c9                   	leave  
80104c13:	c3                   	ret    

80104c14 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80104c14:	55                   	push   %ebp
80104c15:	89 e5                	mov    %esp,%ebp
80104c17:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80104c1a:	c7 04 24 a0 29 11 80 	movl   $0x801129a0,(%esp)
80104c21:	e8 78 05 00 00       	call   8010519e <release>

  if (first) {
80104c26:	a1 08 b0 10 80       	mov    0x8010b008,%eax
80104c2b:	85 c0                	test   %eax,%eax
80104c2d:	74 0f                	je     80104c3e <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80104c2f:	c7 05 08 b0 10 80 00 	movl   $0x0,0x8010b008
80104c36:	00 00 00 
    initlog();
80104c39:	e8 df e6 ff ff       	call   8010331d <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80104c3e:	c9                   	leave  
80104c3f:	c3                   	ret    

80104c40 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80104c40:	55                   	push   %ebp
80104c41:	89 e5                	mov    %esp,%ebp
80104c43:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80104c46:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c4c:	85 c0                	test   %eax,%eax
80104c4e:	75 0c                	jne    80104c5c <sleep+0x1c>
    panic("sleep");
80104c50:	c7 04 24 c5 8a 10 80 	movl   $0x80108ac5,(%esp)
80104c57:	e8 de b8 ff ff       	call   8010053a <panic>

  if(lk == 0)
80104c5c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104c60:	75 0c                	jne    80104c6e <sleep+0x2e>
    panic("sleep without lk");
80104c62:	c7 04 24 cb 8a 10 80 	movl   $0x80108acb,(%esp)
80104c69:	e8 cc b8 ff ff       	call   8010053a <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104c6e:	81 7d 0c a0 29 11 80 	cmpl   $0x801129a0,0xc(%ebp)
80104c75:	74 17                	je     80104c8e <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80104c77:	c7 04 24 a0 29 11 80 	movl   $0x801129a0,(%esp)
80104c7e:	e8 b9 04 00 00       	call   8010513c <acquire>
    release(lk);
80104c83:	8b 45 0c             	mov    0xc(%ebp),%eax
80104c86:	89 04 24             	mov    %eax,(%esp)
80104c89:	e8 10 05 00 00       	call   8010519e <release>
  }

  // Go to sleep.
  proc->chan = chan;
80104c8e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c94:	8b 55 08             	mov    0x8(%ebp),%edx
80104c97:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80104c9a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ca0:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
80104ca7:	e8 84 fe ff ff       	call   80104b30 <sched>

  // Tidy up.
  proc->chan = 0;
80104cac:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cb2:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80104cb9:	81 7d 0c a0 29 11 80 	cmpl   $0x801129a0,0xc(%ebp)
80104cc0:	74 17                	je     80104cd9 <sleep+0x99>
    release(&ptable.lock);
80104cc2:	c7 04 24 a0 29 11 80 	movl   $0x801129a0,(%esp)
80104cc9:	e8 d0 04 00 00       	call   8010519e <release>
    acquire(lk);
80104cce:	8b 45 0c             	mov    0xc(%ebp),%eax
80104cd1:	89 04 24             	mov    %eax,(%esp)
80104cd4:	e8 63 04 00 00       	call   8010513c <acquire>
  }
}
80104cd9:	c9                   	leave  
80104cda:	c3                   	ret    

80104cdb <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104cdb:	55                   	push   %ebp
80104cdc:	89 e5                	mov    %esp,%ebp
80104cde:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104ce1:	c7 45 fc d4 29 11 80 	movl   $0x801129d4,-0x4(%ebp)
80104ce8:	eb 24                	jmp    80104d0e <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
80104cea:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104ced:	8b 40 0c             	mov    0xc(%eax),%eax
80104cf0:	83 f8 02             	cmp    $0x2,%eax
80104cf3:	75 15                	jne    80104d0a <wakeup1+0x2f>
80104cf5:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104cf8:	8b 40 20             	mov    0x20(%eax),%eax
80104cfb:	3b 45 08             	cmp    0x8(%ebp),%eax
80104cfe:	75 0a                	jne    80104d0a <wakeup1+0x2f>
      p->state = RUNNABLE;
80104d00:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104d03:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104d0a:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
80104d0e:	81 7d fc d4 48 11 80 	cmpl   $0x801148d4,-0x4(%ebp)
80104d15:	72 d3                	jb     80104cea <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80104d17:	c9                   	leave  
80104d18:	c3                   	ret    

80104d19 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104d19:	55                   	push   %ebp
80104d1a:	89 e5                	mov    %esp,%ebp
80104d1c:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80104d1f:	c7 04 24 a0 29 11 80 	movl   $0x801129a0,(%esp)
80104d26:	e8 11 04 00 00       	call   8010513c <acquire>
  wakeup1(chan);
80104d2b:	8b 45 08             	mov    0x8(%ebp),%eax
80104d2e:	89 04 24             	mov    %eax,(%esp)
80104d31:	e8 a5 ff ff ff       	call   80104cdb <wakeup1>
  release(&ptable.lock);
80104d36:	c7 04 24 a0 29 11 80 	movl   $0x801129a0,(%esp)
80104d3d:	e8 5c 04 00 00       	call   8010519e <release>
}
80104d42:	c9                   	leave  
80104d43:	c3                   	ret    

80104d44 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104d44:	55                   	push   %ebp
80104d45:	89 e5                	mov    %esp,%ebp
80104d47:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104d4a:	c7 04 24 a0 29 11 80 	movl   $0x801129a0,(%esp)
80104d51:	e8 e6 03 00 00       	call   8010513c <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104d56:	c7 45 f4 d4 29 11 80 	movl   $0x801129d4,-0xc(%ebp)
80104d5d:	eb 41                	jmp    80104da0 <kill+0x5c>
    if(p->pid == pid){
80104d5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d62:	8b 40 10             	mov    0x10(%eax),%eax
80104d65:	3b 45 08             	cmp    0x8(%ebp),%eax
80104d68:	75 32                	jne    80104d9c <kill+0x58>
      p->killed = 1;
80104d6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d6d:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104d74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d77:	8b 40 0c             	mov    0xc(%eax),%eax
80104d7a:	83 f8 02             	cmp    $0x2,%eax
80104d7d:	75 0a                	jne    80104d89 <kill+0x45>
        p->state = RUNNABLE;
80104d7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d82:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104d89:	c7 04 24 a0 29 11 80 	movl   $0x801129a0,(%esp)
80104d90:	e8 09 04 00 00       	call   8010519e <release>
      return 0;
80104d95:	b8 00 00 00 00       	mov    $0x0,%eax
80104d9a:	eb 1e                	jmp    80104dba <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104d9c:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104da0:	81 7d f4 d4 48 11 80 	cmpl   $0x801148d4,-0xc(%ebp)
80104da7:	72 b6                	jb     80104d5f <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80104da9:	c7 04 24 a0 29 11 80 	movl   $0x801129a0,(%esp)
80104db0:	e8 e9 03 00 00       	call   8010519e <release>
  return -1;
80104db5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104dba:	c9                   	leave  
80104dbb:	c3                   	ret    

80104dbc <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104dbc:	55                   	push   %ebp
80104dbd:	89 e5                	mov    %esp,%ebp
80104dbf:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104dc2:	c7 45 f0 d4 29 11 80 	movl   $0x801129d4,-0x10(%ebp)
80104dc9:	e9 d6 00 00 00       	jmp    80104ea4 <procdump+0xe8>
    if(p->state == UNUSED)
80104dce:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104dd1:	8b 40 0c             	mov    0xc(%eax),%eax
80104dd4:	85 c0                	test   %eax,%eax
80104dd6:	75 05                	jne    80104ddd <procdump+0x21>
      continue;
80104dd8:	e9 c3 00 00 00       	jmp    80104ea0 <procdump+0xe4>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104ddd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104de0:	8b 40 0c             	mov    0xc(%eax),%eax
80104de3:	83 f8 05             	cmp    $0x5,%eax
80104de6:	77 23                	ja     80104e0b <procdump+0x4f>
80104de8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104deb:	8b 40 0c             	mov    0xc(%eax),%eax
80104dee:	8b 04 85 0c b0 10 80 	mov    -0x7fef4ff4(,%eax,4),%eax
80104df5:	85 c0                	test   %eax,%eax
80104df7:	74 12                	je     80104e0b <procdump+0x4f>
      state = states[p->state];
80104df9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104dfc:	8b 40 0c             	mov    0xc(%eax),%eax
80104dff:	8b 04 85 0c b0 10 80 	mov    -0x7fef4ff4(,%eax,4),%eax
80104e06:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104e09:	eb 07                	jmp    80104e12 <procdump+0x56>
    else
      state = "???";
80104e0b:	c7 45 ec dc 8a 10 80 	movl   $0x80108adc,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80104e12:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e15:	8d 50 6c             	lea    0x6c(%eax),%edx
80104e18:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e1b:	8b 40 10             	mov    0x10(%eax),%eax
80104e1e:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104e22:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104e25:	89 54 24 08          	mov    %edx,0x8(%esp)
80104e29:	89 44 24 04          	mov    %eax,0x4(%esp)
80104e2d:	c7 04 24 e0 8a 10 80 	movl   $0x80108ae0,(%esp)
80104e34:	e8 67 b5 ff ff       	call   801003a0 <cprintf>
    if(p->state == SLEEPING){
80104e39:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e3c:	8b 40 0c             	mov    0xc(%eax),%eax
80104e3f:	83 f8 02             	cmp    $0x2,%eax
80104e42:	75 50                	jne    80104e94 <procdump+0xd8>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80104e44:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e47:	8b 40 1c             	mov    0x1c(%eax),%eax
80104e4a:	8b 40 0c             	mov    0xc(%eax),%eax
80104e4d:	83 c0 08             	add    $0x8,%eax
80104e50:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80104e53:	89 54 24 04          	mov    %edx,0x4(%esp)
80104e57:	89 04 24             	mov    %eax,(%esp)
80104e5a:	e8 8e 03 00 00       	call   801051ed <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80104e5f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104e66:	eb 1b                	jmp    80104e83 <procdump+0xc7>
        cprintf(" %p", pc[i]);
80104e68:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e6b:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104e6f:	89 44 24 04          	mov    %eax,0x4(%esp)
80104e73:	c7 04 24 e9 8a 10 80 	movl   $0x80108ae9,(%esp)
80104e7a:	e8 21 b5 ff ff       	call   801003a0 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80104e7f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104e83:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80104e87:	7f 0b                	jg     80104e94 <procdump+0xd8>
80104e89:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e8c:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104e90:	85 c0                	test   %eax,%eax
80104e92:	75 d4                	jne    80104e68 <procdump+0xac>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80104e94:	c7 04 24 ed 8a 10 80 	movl   $0x80108aed,(%esp)
80104e9b:	e8 00 b5 ff ff       	call   801003a0 <cprintf>
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104ea0:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
80104ea4:	81 7d f0 d4 48 11 80 	cmpl   $0x801148d4,-0x10(%ebp)
80104eab:	0f 82 1d ff ff ff    	jb     80104dce <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80104eb1:	c9                   	leave  
80104eb2:	c3                   	ret    

80104eb3 <procfsisdir>:
#include "x86.h"

static int procinum = -1;

int 
procfsisdir(struct inode *ip) {
80104eb3:	55                   	push   %ebp
80104eb4:	89 e5                	mov    %esp,%ebp
  if (procinum == -1)
80104eb6:	a1 24 b0 10 80       	mov    0x8010b024,%eax
80104ebb:	83 f8 ff             	cmp    $0xffffffff,%eax
80104ebe:	75 0b                	jne    80104ecb <procfsisdir+0x18>
    procinum = ip->inum;
80104ec0:	8b 45 08             	mov    0x8(%ebp),%eax
80104ec3:	8b 40 04             	mov    0x4(%eax),%eax
80104ec6:	a3 24 b0 10 80       	mov    %eax,0x8010b024

  return (ip->inum == procinum);
80104ecb:	8b 45 08             	mov    0x8(%ebp),%eax
80104ece:	8b 50 04             	mov    0x4(%eax),%edx
80104ed1:	a1 24 b0 10 80       	mov    0x8010b024,%eax
80104ed6:	39 c2                	cmp    %eax,%edx
80104ed8:	0f 94 c0             	sete   %al
80104edb:	0f b6 c0             	movzbl %al,%eax
}
80104ede:	5d                   	pop    %ebp
80104edf:	c3                   	ret    

80104ee0 <procfsiread>:

void 
procfsiread(struct inode* dp, struct inode *ip) 
{
80104ee0:	55                   	push   %ebp
80104ee1:	89 e5                	mov    %esp,%ebp
	// ip->flags = i_valid;
	// ip->major = 2;
  if (ip->inum == 1234) {
80104ee3:	8b 45 0c             	mov    0xc(%ebp),%eax
80104ee6:	8b 40 04             	mov    0x4(%eax),%eax
80104ee9:	3d d2 04 00 00       	cmp    $0x4d2,%eax
80104eee:	75 2d                	jne    80104f1d <procfsiread+0x3d>
    ip->type = T_DEV;
80104ef0:	8b 45 0c             	mov    0xc(%ebp),%eax
80104ef3:	66 c7 40 10 03 00    	movw   $0x3,0x10(%eax)
    ip->major = PROCFS;
80104ef9:	8b 45 0c             	mov    0xc(%ebp),%eax
80104efc:	66 c7 40 12 02 00    	movw   $0x2,0x12(%eax)
    ip->size = 0;
80104f02:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f05:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
    ip->flags |= I_VALID;
80104f0c:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f0f:	8b 40 0c             	mov    0xc(%eax),%eax
80104f12:	83 c8 02             	or     $0x2,%eax
80104f15:	89 c2                	mov    %eax,%edx
80104f17:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f1a:	89 50 0c             	mov    %edx,0xc(%eax)
  }
}
80104f1d:	5d                   	pop    %ebp
80104f1e:	c3                   	ret    

80104f1f <createprocentries>:

int createprocentries(char *buf) {
80104f1f:	55                   	push   %ebp
80104f20:	89 e5                	mov    %esp,%ebp
80104f22:	83 ec 28             	sub    $0x28,%esp
  struct dirent de;

  de.inum = ROOTINO;
80104f25:	66 c7 45 e8 01 00    	movw   $0x1,-0x18(%ebp)
  memmove(de.name, "..", 3);
80104f2b:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
80104f32:	00 
80104f33:	c7 44 24 04 19 8b 10 	movl   $0x80108b19,0x4(%esp)
80104f3a:	80 
80104f3b:	8d 45 e8             	lea    -0x18(%ebp),%eax
80104f3e:	83 c0 02             	add    $0x2,%eax
80104f41:	89 04 24             	mov    %eax,(%esp)
80104f44:	e8 16 05 00 00       	call   8010545f <memmove>
  memmove(buf + sizeof(de), (char*)&de, sizeof(de));
80104f49:	8b 45 08             	mov    0x8(%ebp),%eax
80104f4c:	8d 50 10             	lea    0x10(%eax),%edx
80104f4f:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104f56:	00 
80104f57:	8d 45 e8             	lea    -0x18(%ebp),%eax
80104f5a:	89 44 24 04          	mov    %eax,0x4(%esp)
80104f5e:	89 14 24             	mov    %edx,(%esp)
80104f61:	e8 f9 04 00 00       	call   8010545f <memmove>
  
  de.inum = procinum;
80104f66:	a1 24 b0 10 80       	mov    0x8010b024,%eax
80104f6b:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  memmove(de.name, ".", 2);
80104f6f:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
80104f76:	00 
80104f77:	c7 44 24 04 1c 8b 10 	movl   $0x80108b1c,0x4(%esp)
80104f7e:	80 
80104f7f:	8d 45 e8             	lea    -0x18(%ebp),%eax
80104f82:	83 c0 02             	add    $0x2,%eax
80104f85:	89 04 24             	mov    %eax,(%esp)
80104f88:	e8 d2 04 00 00       	call   8010545f <memmove>
  memmove(buf, (char*)&de, sizeof(de));
80104f8d:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104f94:	00 
80104f95:	8d 45 e8             	lea    -0x18(%ebp),%eax
80104f98:	89 44 24 04          	mov    %eax,0x4(%esp)
80104f9c:	8b 45 08             	mov    0x8(%ebp),%eax
80104f9f:	89 04 24             	mov    %eax,(%esp)
80104fa2:	e8 b8 04 00 00       	call   8010545f <memmove>


  de.inum = 1234;
80104fa7:	66 c7 45 e8 d2 04    	movw   $0x4d2,-0x18(%ebp)
  memmove(de.name, "test", 5);
80104fad:	c7 44 24 08 05 00 00 	movl   $0x5,0x8(%esp)
80104fb4:	00 
80104fb5:	c7 44 24 04 1e 8b 10 	movl   $0x80108b1e,0x4(%esp)
80104fbc:	80 
80104fbd:	8d 45 e8             	lea    -0x18(%ebp),%eax
80104fc0:	83 c0 02             	add    $0x2,%eax
80104fc3:	89 04 24             	mov    %eax,(%esp)
80104fc6:	e8 94 04 00 00       	call   8010545f <memmove>
  memmove(buf + 2 * sizeof(de), (char*)&de, sizeof(de));
80104fcb:	8b 45 08             	mov    0x8(%ebp),%eax
80104fce:	8d 50 20             	lea    0x20(%eax),%edx
80104fd1:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104fd8:	00 
80104fd9:	8d 45 e8             	lea    -0x18(%ebp),%eax
80104fdc:	89 44 24 04          	mov    %eax,0x4(%esp)
80104fe0:	89 14 24             	mov    %edx,(%esp)
80104fe3:	e8 77 04 00 00       	call   8010545f <memmove>

  //TODO: add dirents for each alive process

  return 3 * sizeof(de);
80104fe8:	b8 30 00 00 00       	mov    $0x30,%eax
}
80104fed:	c9                   	leave  
80104fee:	c3                   	ret    

80104fef <procfsread>:

int
procfsread(struct inode *ip, char *dst, int off, int n) {
80104fef:	55                   	push   %ebp
80104ff0:	89 e5                	mov    %esp,%ebp
80104ff2:	81 ec 28 02 00 00    	sub    $0x228,%esp
  char buf[512];
  int size;

  if (procinum == -1)
80104ff8:	a1 24 b0 10 80       	mov    0x8010b024,%eax
80104ffd:	83 f8 ff             	cmp    $0xffffffff,%eax
80105000:	75 0b                	jne    8010500d <procfsread+0x1e>
    procinum = ip->inum;
80105002:	8b 45 08             	mov    0x8(%ebp),%eax
80105005:	8b 40 04             	mov    0x4(%eax),%eax
80105008:	a3 24 b0 10 80       	mov    %eax,0x8010b024

  if (ip->inum == procinum) {
8010500d:	8b 45 08             	mov    0x8(%ebp),%eax
80105010:	8b 50 04             	mov    0x4(%eax),%edx
80105013:	a1 24 b0 10 80       	mov    0x8010b024,%eax
80105018:	39 c2                	cmp    %eax,%edx
8010501a:	75 11                	jne    8010502d <procfsread+0x3e>
    size = createprocentries(buf);
8010501c:	8d 85 f0 fd ff ff    	lea    -0x210(%ebp),%eax
80105022:	89 04 24             	mov    %eax,(%esp)
80105025:	e8 f5 fe ff ff       	call   80104f1f <createprocentries>
8010502a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  }
  if (ip->inum == 1234) {
8010502d:	8b 45 08             	mov    0x8(%ebp),%eax
80105030:	8b 40 04             	mov    0x4(%eax),%eax
80105033:	3d d2 04 00 00       	cmp    $0x4d2,%eax
80105038:	75 25                	jne    8010505f <procfsread+0x70>
    memmove(buf, "Hello world\n", 13);
8010503a:	c7 44 24 08 0d 00 00 	movl   $0xd,0x8(%esp)
80105041:	00 
80105042:	c7 44 24 04 23 8b 10 	movl   $0x80108b23,0x4(%esp)
80105049:	80 
8010504a:	8d 85 f0 fd ff ff    	lea    -0x210(%ebp),%eax
80105050:	89 04 24             	mov    %eax,(%esp)
80105053:	e8 07 04 00 00       	call   8010545f <memmove>
    size = 13;
80105058:	c7 45 f4 0d 00 00 00 	movl   $0xd,-0xc(%ebp)
  }

  if (off < size) {
8010505f:	8b 45 10             	mov    0x10(%ebp),%eax
80105062:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80105065:	7d 40                	jge    801050a7 <procfsread+0xb8>
    int rr = size - off;
80105067:	8b 45 10             	mov    0x10(%ebp),%eax
8010506a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010506d:	29 c2                	sub    %eax,%edx
8010506f:	89 d0                	mov    %edx,%eax
80105071:	89 45 f0             	mov    %eax,-0x10(%ebp)
    rr = rr < n ? rr : n;
80105074:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105077:	39 45 14             	cmp    %eax,0x14(%ebp)
8010507a:	0f 4e 45 14          	cmovle 0x14(%ebp),%eax
8010507e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(dst, buf + off, rr);
80105081:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105084:	8b 55 10             	mov    0x10(%ebp),%edx
80105087:	8d 8d f0 fd ff ff    	lea    -0x210(%ebp),%ecx
8010508d:	01 ca                	add    %ecx,%edx
8010508f:	89 44 24 08          	mov    %eax,0x8(%esp)
80105093:	89 54 24 04          	mov    %edx,0x4(%esp)
80105097:	8b 45 0c             	mov    0xc(%ebp),%eax
8010509a:	89 04 24             	mov    %eax,(%esp)
8010509d:	e8 bd 03 00 00       	call   8010545f <memmove>
    return rr;
801050a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801050a5:	eb 05                	jmp    801050ac <procfsread+0xbd>
  }

  return 0;
801050a7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801050ac:	c9                   	leave  
801050ad:	c3                   	ret    

801050ae <procfswrite>:

int
procfswrite(struct inode *ip, char *buf, int n)
{
801050ae:	55                   	push   %ebp
801050af:	89 e5                	mov    %esp,%ebp
  return 0;
801050b1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801050b6:	5d                   	pop    %ebp
801050b7:	c3                   	ret    

801050b8 <procfsinit>:

void
procfsinit(void)
{
801050b8:	55                   	push   %ebp
801050b9:	89 e5                	mov    %esp,%ebp
  devsw[PROCFS].isdir = procfsisdir;
801050bb:	c7 05 00 12 11 80 b3 	movl   $0x80104eb3,0x80111200
801050c2:	4e 10 80 
  devsw[PROCFS].iread = procfsiread;
801050c5:	c7 05 04 12 11 80 e0 	movl   $0x80104ee0,0x80111204
801050cc:	4e 10 80 
  devsw[PROCFS].write = procfswrite;
801050cf:	c7 05 0c 12 11 80 ae 	movl   $0x801050ae,0x8011120c
801050d6:	50 10 80 
  devsw[PROCFS].read = procfsread;
801050d9:	c7 05 08 12 11 80 ef 	movl   $0x80104fef,0x80111208
801050e0:	4f 10 80 
}
801050e3:	5d                   	pop    %ebp
801050e4:	c3                   	ret    

801050e5 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801050e5:	55                   	push   %ebp
801050e6:	89 e5                	mov    %esp,%ebp
801050e8:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801050eb:	9c                   	pushf  
801050ec:	58                   	pop    %eax
801050ed:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
801050f0:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801050f3:	c9                   	leave  
801050f4:	c3                   	ret    

801050f5 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801050f5:	55                   	push   %ebp
801050f6:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801050f8:	fa                   	cli    
}
801050f9:	5d                   	pop    %ebp
801050fa:	c3                   	ret    

801050fb <sti>:

static inline void
sti(void)
{
801050fb:	55                   	push   %ebp
801050fc:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
801050fe:	fb                   	sti    
}
801050ff:	5d                   	pop    %ebp
80105100:	c3                   	ret    

80105101 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105101:	55                   	push   %ebp
80105102:	89 e5                	mov    %esp,%ebp
80105104:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105107:	8b 55 08             	mov    0x8(%ebp),%edx
8010510a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010510d:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105110:	f0 87 02             	lock xchg %eax,(%edx)
80105113:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80105116:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105119:	c9                   	leave  
8010511a:	c3                   	ret    

8010511b <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
8010511b:	55                   	push   %ebp
8010511c:	89 e5                	mov    %esp,%ebp
  lk->name = name;
8010511e:	8b 45 08             	mov    0x8(%ebp),%eax
80105121:	8b 55 0c             	mov    0xc(%ebp),%edx
80105124:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80105127:	8b 45 08             	mov    0x8(%ebp),%eax
8010512a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105130:	8b 45 08             	mov    0x8(%ebp),%eax
80105133:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
8010513a:	5d                   	pop    %ebp
8010513b:	c3                   	ret    

8010513c <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
8010513c:	55                   	push   %ebp
8010513d:	89 e5                	mov    %esp,%ebp
8010513f:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80105142:	e8 49 01 00 00       	call   80105290 <pushcli>
  if(holding(lk))
80105147:	8b 45 08             	mov    0x8(%ebp),%eax
8010514a:	89 04 24             	mov    %eax,(%esp)
8010514d:	e8 14 01 00 00       	call   80105266 <holding>
80105152:	85 c0                	test   %eax,%eax
80105154:	74 0c                	je     80105162 <acquire+0x26>
    panic("acquire");
80105156:	c7 04 24 30 8b 10 80 	movl   $0x80108b30,(%esp)
8010515d:	e8 d8 b3 ff ff       	call   8010053a <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105162:	90                   	nop
80105163:	8b 45 08             	mov    0x8(%ebp),%eax
80105166:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010516d:	00 
8010516e:	89 04 24             	mov    %eax,(%esp)
80105171:	e8 8b ff ff ff       	call   80105101 <xchg>
80105176:	85 c0                	test   %eax,%eax
80105178:	75 e9                	jne    80105163 <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
8010517a:	8b 45 08             	mov    0x8(%ebp),%eax
8010517d:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105184:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105187:	8b 45 08             	mov    0x8(%ebp),%eax
8010518a:	83 c0 0c             	add    $0xc,%eax
8010518d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105191:	8d 45 08             	lea    0x8(%ebp),%eax
80105194:	89 04 24             	mov    %eax,(%esp)
80105197:	e8 51 00 00 00       	call   801051ed <getcallerpcs>
}
8010519c:	c9                   	leave  
8010519d:	c3                   	ret    

8010519e <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
8010519e:	55                   	push   %ebp
8010519f:	89 e5                	mov    %esp,%ebp
801051a1:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
801051a4:	8b 45 08             	mov    0x8(%ebp),%eax
801051a7:	89 04 24             	mov    %eax,(%esp)
801051aa:	e8 b7 00 00 00       	call   80105266 <holding>
801051af:	85 c0                	test   %eax,%eax
801051b1:	75 0c                	jne    801051bf <release+0x21>
    panic("release");
801051b3:	c7 04 24 38 8b 10 80 	movl   $0x80108b38,(%esp)
801051ba:	e8 7b b3 ff ff       	call   8010053a <panic>

  lk->pcs[0] = 0;
801051bf:	8b 45 08             	mov    0x8(%ebp),%eax
801051c2:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
801051c9:	8b 45 08             	mov    0x8(%ebp),%eax
801051cc:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
801051d3:	8b 45 08             	mov    0x8(%ebp),%eax
801051d6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801051dd:	00 
801051de:	89 04 24             	mov    %eax,(%esp)
801051e1:	e8 1b ff ff ff       	call   80105101 <xchg>

  popcli();
801051e6:	e8 e9 00 00 00       	call   801052d4 <popcli>
}
801051eb:	c9                   	leave  
801051ec:	c3                   	ret    

801051ed <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
801051ed:	55                   	push   %ebp
801051ee:	89 e5                	mov    %esp,%ebp
801051f0:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
801051f3:	8b 45 08             	mov    0x8(%ebp),%eax
801051f6:	83 e8 08             	sub    $0x8,%eax
801051f9:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
801051fc:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105203:	eb 38                	jmp    8010523d <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105205:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105209:	74 38                	je     80105243 <getcallerpcs+0x56>
8010520b:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105212:	76 2f                	jbe    80105243 <getcallerpcs+0x56>
80105214:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105218:	74 29                	je     80105243 <getcallerpcs+0x56>
      break;
    pcs[i] = ebp[1];     // saved %eip
8010521a:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010521d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105224:	8b 45 0c             	mov    0xc(%ebp),%eax
80105227:	01 c2                	add    %eax,%edx
80105229:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010522c:	8b 40 04             	mov    0x4(%eax),%eax
8010522f:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
80105231:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105234:	8b 00                	mov    (%eax),%eax
80105236:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105239:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
8010523d:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105241:	7e c2                	jle    80105205 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105243:	eb 19                	jmp    8010525e <getcallerpcs+0x71>
    pcs[i] = 0;
80105245:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105248:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010524f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105252:	01 d0                	add    %edx,%eax
80105254:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
8010525a:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
8010525e:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105262:	7e e1                	jle    80105245 <getcallerpcs+0x58>
    pcs[i] = 0;
}
80105264:	c9                   	leave  
80105265:	c3                   	ret    

80105266 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105266:	55                   	push   %ebp
80105267:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105269:	8b 45 08             	mov    0x8(%ebp),%eax
8010526c:	8b 00                	mov    (%eax),%eax
8010526e:	85 c0                	test   %eax,%eax
80105270:	74 17                	je     80105289 <holding+0x23>
80105272:	8b 45 08             	mov    0x8(%ebp),%eax
80105275:	8b 50 08             	mov    0x8(%eax),%edx
80105278:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010527e:	39 c2                	cmp    %eax,%edx
80105280:	75 07                	jne    80105289 <holding+0x23>
80105282:	b8 01 00 00 00       	mov    $0x1,%eax
80105287:	eb 05                	jmp    8010528e <holding+0x28>
80105289:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010528e:	5d                   	pop    %ebp
8010528f:	c3                   	ret    

80105290 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105290:	55                   	push   %ebp
80105291:	89 e5                	mov    %esp,%ebp
80105293:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80105296:	e8 4a fe ff ff       	call   801050e5 <readeflags>
8010529b:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
8010529e:	e8 52 fe ff ff       	call   801050f5 <cli>
  if(cpu->ncli++ == 0)
801052a3:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801052aa:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
801052b0:	8d 48 01             	lea    0x1(%eax),%ecx
801052b3:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
801052b9:	85 c0                	test   %eax,%eax
801052bb:	75 15                	jne    801052d2 <pushcli+0x42>
    cpu->intena = eflags & FL_IF;
801052bd:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801052c3:	8b 55 fc             	mov    -0x4(%ebp),%edx
801052c6:	81 e2 00 02 00 00    	and    $0x200,%edx
801052cc:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801052d2:	c9                   	leave  
801052d3:	c3                   	ret    

801052d4 <popcli>:

void
popcli(void)
{
801052d4:	55                   	push   %ebp
801052d5:	89 e5                	mov    %esp,%ebp
801052d7:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
801052da:	e8 06 fe ff ff       	call   801050e5 <readeflags>
801052df:	25 00 02 00 00       	and    $0x200,%eax
801052e4:	85 c0                	test   %eax,%eax
801052e6:	74 0c                	je     801052f4 <popcli+0x20>
    panic("popcli - interruptible");
801052e8:	c7 04 24 40 8b 10 80 	movl   $0x80108b40,(%esp)
801052ef:	e8 46 b2 ff ff       	call   8010053a <panic>
  if(--cpu->ncli < 0)
801052f4:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801052fa:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105300:	83 ea 01             	sub    $0x1,%edx
80105303:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105309:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
8010530f:	85 c0                	test   %eax,%eax
80105311:	79 0c                	jns    8010531f <popcli+0x4b>
    panic("popcli");
80105313:	c7 04 24 57 8b 10 80 	movl   $0x80108b57,(%esp)
8010531a:	e8 1b b2 ff ff       	call   8010053a <panic>
  if(cpu->ncli == 0 && cpu->intena)
8010531f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105325:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
8010532b:	85 c0                	test   %eax,%eax
8010532d:	75 15                	jne    80105344 <popcli+0x70>
8010532f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105335:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
8010533b:	85 c0                	test   %eax,%eax
8010533d:	74 05                	je     80105344 <popcli+0x70>
    sti();
8010533f:	e8 b7 fd ff ff       	call   801050fb <sti>
}
80105344:	c9                   	leave  
80105345:	c3                   	ret    

80105346 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80105346:	55                   	push   %ebp
80105347:	89 e5                	mov    %esp,%ebp
80105349:	57                   	push   %edi
8010534a:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
8010534b:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010534e:	8b 55 10             	mov    0x10(%ebp),%edx
80105351:	8b 45 0c             	mov    0xc(%ebp),%eax
80105354:	89 cb                	mov    %ecx,%ebx
80105356:	89 df                	mov    %ebx,%edi
80105358:	89 d1                	mov    %edx,%ecx
8010535a:	fc                   	cld    
8010535b:	f3 aa                	rep stos %al,%es:(%edi)
8010535d:	89 ca                	mov    %ecx,%edx
8010535f:	89 fb                	mov    %edi,%ebx
80105361:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105364:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105367:	5b                   	pop    %ebx
80105368:	5f                   	pop    %edi
80105369:	5d                   	pop    %ebp
8010536a:	c3                   	ret    

8010536b <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
8010536b:	55                   	push   %ebp
8010536c:	89 e5                	mov    %esp,%ebp
8010536e:	57                   	push   %edi
8010536f:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80105370:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105373:	8b 55 10             	mov    0x10(%ebp),%edx
80105376:	8b 45 0c             	mov    0xc(%ebp),%eax
80105379:	89 cb                	mov    %ecx,%ebx
8010537b:	89 df                	mov    %ebx,%edi
8010537d:	89 d1                	mov    %edx,%ecx
8010537f:	fc                   	cld    
80105380:	f3 ab                	rep stos %eax,%es:(%edi)
80105382:	89 ca                	mov    %ecx,%edx
80105384:	89 fb                	mov    %edi,%ebx
80105386:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105389:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
8010538c:	5b                   	pop    %ebx
8010538d:	5f                   	pop    %edi
8010538e:	5d                   	pop    %ebp
8010538f:	c3                   	ret    

80105390 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105390:	55                   	push   %ebp
80105391:	89 e5                	mov    %esp,%ebp
80105393:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105396:	8b 45 08             	mov    0x8(%ebp),%eax
80105399:	83 e0 03             	and    $0x3,%eax
8010539c:	85 c0                	test   %eax,%eax
8010539e:	75 49                	jne    801053e9 <memset+0x59>
801053a0:	8b 45 10             	mov    0x10(%ebp),%eax
801053a3:	83 e0 03             	and    $0x3,%eax
801053a6:	85 c0                	test   %eax,%eax
801053a8:	75 3f                	jne    801053e9 <memset+0x59>
    c &= 0xFF;
801053aa:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
801053b1:	8b 45 10             	mov    0x10(%ebp),%eax
801053b4:	c1 e8 02             	shr    $0x2,%eax
801053b7:	89 c2                	mov    %eax,%edx
801053b9:	8b 45 0c             	mov    0xc(%ebp),%eax
801053bc:	c1 e0 18             	shl    $0x18,%eax
801053bf:	89 c1                	mov    %eax,%ecx
801053c1:	8b 45 0c             	mov    0xc(%ebp),%eax
801053c4:	c1 e0 10             	shl    $0x10,%eax
801053c7:	09 c1                	or     %eax,%ecx
801053c9:	8b 45 0c             	mov    0xc(%ebp),%eax
801053cc:	c1 e0 08             	shl    $0x8,%eax
801053cf:	09 c8                	or     %ecx,%eax
801053d1:	0b 45 0c             	or     0xc(%ebp),%eax
801053d4:	89 54 24 08          	mov    %edx,0x8(%esp)
801053d8:	89 44 24 04          	mov    %eax,0x4(%esp)
801053dc:	8b 45 08             	mov    0x8(%ebp),%eax
801053df:	89 04 24             	mov    %eax,(%esp)
801053e2:	e8 84 ff ff ff       	call   8010536b <stosl>
801053e7:	eb 19                	jmp    80105402 <memset+0x72>
  } else
    stosb(dst, c, n);
801053e9:	8b 45 10             	mov    0x10(%ebp),%eax
801053ec:	89 44 24 08          	mov    %eax,0x8(%esp)
801053f0:	8b 45 0c             	mov    0xc(%ebp),%eax
801053f3:	89 44 24 04          	mov    %eax,0x4(%esp)
801053f7:	8b 45 08             	mov    0x8(%ebp),%eax
801053fa:	89 04 24             	mov    %eax,(%esp)
801053fd:	e8 44 ff ff ff       	call   80105346 <stosb>
  return dst;
80105402:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105405:	c9                   	leave  
80105406:	c3                   	ret    

80105407 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105407:	55                   	push   %ebp
80105408:	89 e5                	mov    %esp,%ebp
8010540a:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
8010540d:	8b 45 08             	mov    0x8(%ebp),%eax
80105410:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105413:	8b 45 0c             	mov    0xc(%ebp),%eax
80105416:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105419:	eb 30                	jmp    8010544b <memcmp+0x44>
    if(*s1 != *s2)
8010541b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010541e:	0f b6 10             	movzbl (%eax),%edx
80105421:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105424:	0f b6 00             	movzbl (%eax),%eax
80105427:	38 c2                	cmp    %al,%dl
80105429:	74 18                	je     80105443 <memcmp+0x3c>
      return *s1 - *s2;
8010542b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010542e:	0f b6 00             	movzbl (%eax),%eax
80105431:	0f b6 d0             	movzbl %al,%edx
80105434:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105437:	0f b6 00             	movzbl (%eax),%eax
8010543a:	0f b6 c0             	movzbl %al,%eax
8010543d:	29 c2                	sub    %eax,%edx
8010543f:	89 d0                	mov    %edx,%eax
80105441:	eb 1a                	jmp    8010545d <memcmp+0x56>
    s1++, s2++;
80105443:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105447:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
8010544b:	8b 45 10             	mov    0x10(%ebp),%eax
8010544e:	8d 50 ff             	lea    -0x1(%eax),%edx
80105451:	89 55 10             	mov    %edx,0x10(%ebp)
80105454:	85 c0                	test   %eax,%eax
80105456:	75 c3                	jne    8010541b <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105458:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010545d:	c9                   	leave  
8010545e:	c3                   	ret    

8010545f <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
8010545f:	55                   	push   %ebp
80105460:	89 e5                	mov    %esp,%ebp
80105462:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105465:	8b 45 0c             	mov    0xc(%ebp),%eax
80105468:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
8010546b:	8b 45 08             	mov    0x8(%ebp),%eax
8010546e:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105471:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105474:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105477:	73 3d                	jae    801054b6 <memmove+0x57>
80105479:	8b 45 10             	mov    0x10(%ebp),%eax
8010547c:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010547f:	01 d0                	add    %edx,%eax
80105481:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105484:	76 30                	jbe    801054b6 <memmove+0x57>
    s += n;
80105486:	8b 45 10             	mov    0x10(%ebp),%eax
80105489:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
8010548c:	8b 45 10             	mov    0x10(%ebp),%eax
8010548f:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105492:	eb 13                	jmp    801054a7 <memmove+0x48>
      *--d = *--s;
80105494:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105498:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
8010549c:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010549f:	0f b6 10             	movzbl (%eax),%edx
801054a2:	8b 45 f8             	mov    -0x8(%ebp),%eax
801054a5:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
801054a7:	8b 45 10             	mov    0x10(%ebp),%eax
801054aa:	8d 50 ff             	lea    -0x1(%eax),%edx
801054ad:	89 55 10             	mov    %edx,0x10(%ebp)
801054b0:	85 c0                	test   %eax,%eax
801054b2:	75 e0                	jne    80105494 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
801054b4:	eb 26                	jmp    801054dc <memmove+0x7d>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
801054b6:	eb 17                	jmp    801054cf <memmove+0x70>
      *d++ = *s++;
801054b8:	8b 45 f8             	mov    -0x8(%ebp),%eax
801054bb:	8d 50 01             	lea    0x1(%eax),%edx
801054be:	89 55 f8             	mov    %edx,-0x8(%ebp)
801054c1:	8b 55 fc             	mov    -0x4(%ebp),%edx
801054c4:	8d 4a 01             	lea    0x1(%edx),%ecx
801054c7:	89 4d fc             	mov    %ecx,-0x4(%ebp)
801054ca:	0f b6 12             	movzbl (%edx),%edx
801054cd:	88 10                	mov    %dl,(%eax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
801054cf:	8b 45 10             	mov    0x10(%ebp),%eax
801054d2:	8d 50 ff             	lea    -0x1(%eax),%edx
801054d5:	89 55 10             	mov    %edx,0x10(%ebp)
801054d8:	85 c0                	test   %eax,%eax
801054da:	75 dc                	jne    801054b8 <memmove+0x59>
      *d++ = *s++;

  return dst;
801054dc:	8b 45 08             	mov    0x8(%ebp),%eax
}
801054df:	c9                   	leave  
801054e0:	c3                   	ret    

801054e1 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
801054e1:	55                   	push   %ebp
801054e2:	89 e5                	mov    %esp,%ebp
801054e4:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
801054e7:	8b 45 10             	mov    0x10(%ebp),%eax
801054ea:	89 44 24 08          	mov    %eax,0x8(%esp)
801054ee:	8b 45 0c             	mov    0xc(%ebp),%eax
801054f1:	89 44 24 04          	mov    %eax,0x4(%esp)
801054f5:	8b 45 08             	mov    0x8(%ebp),%eax
801054f8:	89 04 24             	mov    %eax,(%esp)
801054fb:	e8 5f ff ff ff       	call   8010545f <memmove>
}
80105500:	c9                   	leave  
80105501:	c3                   	ret    

80105502 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105502:	55                   	push   %ebp
80105503:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105505:	eb 0c                	jmp    80105513 <strncmp+0x11>
    n--, p++, q++;
80105507:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010550b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
8010550f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105513:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105517:	74 1a                	je     80105533 <strncmp+0x31>
80105519:	8b 45 08             	mov    0x8(%ebp),%eax
8010551c:	0f b6 00             	movzbl (%eax),%eax
8010551f:	84 c0                	test   %al,%al
80105521:	74 10                	je     80105533 <strncmp+0x31>
80105523:	8b 45 08             	mov    0x8(%ebp),%eax
80105526:	0f b6 10             	movzbl (%eax),%edx
80105529:	8b 45 0c             	mov    0xc(%ebp),%eax
8010552c:	0f b6 00             	movzbl (%eax),%eax
8010552f:	38 c2                	cmp    %al,%dl
80105531:	74 d4                	je     80105507 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105533:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105537:	75 07                	jne    80105540 <strncmp+0x3e>
    return 0;
80105539:	b8 00 00 00 00       	mov    $0x0,%eax
8010553e:	eb 16                	jmp    80105556 <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
80105540:	8b 45 08             	mov    0x8(%ebp),%eax
80105543:	0f b6 00             	movzbl (%eax),%eax
80105546:	0f b6 d0             	movzbl %al,%edx
80105549:	8b 45 0c             	mov    0xc(%ebp),%eax
8010554c:	0f b6 00             	movzbl (%eax),%eax
8010554f:	0f b6 c0             	movzbl %al,%eax
80105552:	29 c2                	sub    %eax,%edx
80105554:	89 d0                	mov    %edx,%eax
}
80105556:	5d                   	pop    %ebp
80105557:	c3                   	ret    

80105558 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105558:	55                   	push   %ebp
80105559:	89 e5                	mov    %esp,%ebp
8010555b:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
8010555e:	8b 45 08             	mov    0x8(%ebp),%eax
80105561:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105564:	90                   	nop
80105565:	8b 45 10             	mov    0x10(%ebp),%eax
80105568:	8d 50 ff             	lea    -0x1(%eax),%edx
8010556b:	89 55 10             	mov    %edx,0x10(%ebp)
8010556e:	85 c0                	test   %eax,%eax
80105570:	7e 1e                	jle    80105590 <strncpy+0x38>
80105572:	8b 45 08             	mov    0x8(%ebp),%eax
80105575:	8d 50 01             	lea    0x1(%eax),%edx
80105578:	89 55 08             	mov    %edx,0x8(%ebp)
8010557b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010557e:	8d 4a 01             	lea    0x1(%edx),%ecx
80105581:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105584:	0f b6 12             	movzbl (%edx),%edx
80105587:	88 10                	mov    %dl,(%eax)
80105589:	0f b6 00             	movzbl (%eax),%eax
8010558c:	84 c0                	test   %al,%al
8010558e:	75 d5                	jne    80105565 <strncpy+0xd>
    ;
  while(n-- > 0)
80105590:	eb 0c                	jmp    8010559e <strncpy+0x46>
    *s++ = 0;
80105592:	8b 45 08             	mov    0x8(%ebp),%eax
80105595:	8d 50 01             	lea    0x1(%eax),%edx
80105598:	89 55 08             	mov    %edx,0x8(%ebp)
8010559b:	c6 00 00             	movb   $0x0,(%eax)
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
8010559e:	8b 45 10             	mov    0x10(%ebp),%eax
801055a1:	8d 50 ff             	lea    -0x1(%eax),%edx
801055a4:	89 55 10             	mov    %edx,0x10(%ebp)
801055a7:	85 c0                	test   %eax,%eax
801055a9:	7f e7                	jg     80105592 <strncpy+0x3a>
    *s++ = 0;
  return os;
801055ab:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801055ae:	c9                   	leave  
801055af:	c3                   	ret    

801055b0 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
801055b0:	55                   	push   %ebp
801055b1:	89 e5                	mov    %esp,%ebp
801055b3:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
801055b6:	8b 45 08             	mov    0x8(%ebp),%eax
801055b9:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
801055bc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801055c0:	7f 05                	jg     801055c7 <safestrcpy+0x17>
    return os;
801055c2:	8b 45 fc             	mov    -0x4(%ebp),%eax
801055c5:	eb 31                	jmp    801055f8 <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
801055c7:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801055cb:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801055cf:	7e 1e                	jle    801055ef <safestrcpy+0x3f>
801055d1:	8b 45 08             	mov    0x8(%ebp),%eax
801055d4:	8d 50 01             	lea    0x1(%eax),%edx
801055d7:	89 55 08             	mov    %edx,0x8(%ebp)
801055da:	8b 55 0c             	mov    0xc(%ebp),%edx
801055dd:	8d 4a 01             	lea    0x1(%edx),%ecx
801055e0:	89 4d 0c             	mov    %ecx,0xc(%ebp)
801055e3:	0f b6 12             	movzbl (%edx),%edx
801055e6:	88 10                	mov    %dl,(%eax)
801055e8:	0f b6 00             	movzbl (%eax),%eax
801055eb:	84 c0                	test   %al,%al
801055ed:	75 d8                	jne    801055c7 <safestrcpy+0x17>
    ;
  *s = 0;
801055ef:	8b 45 08             	mov    0x8(%ebp),%eax
801055f2:	c6 00 00             	movb   $0x0,(%eax)
  return os;
801055f5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801055f8:	c9                   	leave  
801055f9:	c3                   	ret    

801055fa <strlen>:

int
strlen(const char *s)
{
801055fa:	55                   	push   %ebp
801055fb:	89 e5                	mov    %esp,%ebp
801055fd:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105600:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105607:	eb 04                	jmp    8010560d <strlen+0x13>
80105609:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010560d:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105610:	8b 45 08             	mov    0x8(%ebp),%eax
80105613:	01 d0                	add    %edx,%eax
80105615:	0f b6 00             	movzbl (%eax),%eax
80105618:	84 c0                	test   %al,%al
8010561a:	75 ed                	jne    80105609 <strlen+0xf>
    ;
  return n;
8010561c:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010561f:	c9                   	leave  
80105620:	c3                   	ret    

80105621 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105621:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105625:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105629:	55                   	push   %ebp
  pushl %ebx
8010562a:	53                   	push   %ebx
  pushl %esi
8010562b:	56                   	push   %esi
  pushl %edi
8010562c:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
8010562d:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
8010562f:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105631:	5f                   	pop    %edi
  popl %esi
80105632:	5e                   	pop    %esi
  popl %ebx
80105633:	5b                   	pop    %ebx
  popl %ebp
80105634:	5d                   	pop    %ebp
  ret
80105635:	c3                   	ret    

80105636 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80105636:	55                   	push   %ebp
80105637:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
80105639:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010563f:	8b 00                	mov    (%eax),%eax
80105641:	3b 45 08             	cmp    0x8(%ebp),%eax
80105644:	76 12                	jbe    80105658 <fetchint+0x22>
80105646:	8b 45 08             	mov    0x8(%ebp),%eax
80105649:	8d 50 04             	lea    0x4(%eax),%edx
8010564c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105652:	8b 00                	mov    (%eax),%eax
80105654:	39 c2                	cmp    %eax,%edx
80105656:	76 07                	jbe    8010565f <fetchint+0x29>
    return -1;
80105658:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010565d:	eb 0f                	jmp    8010566e <fetchint+0x38>
  *ip = *(int*)(addr);
8010565f:	8b 45 08             	mov    0x8(%ebp),%eax
80105662:	8b 10                	mov    (%eax),%edx
80105664:	8b 45 0c             	mov    0xc(%ebp),%eax
80105667:	89 10                	mov    %edx,(%eax)
  return 0;
80105669:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010566e:	5d                   	pop    %ebp
8010566f:	c3                   	ret    

80105670 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80105670:	55                   	push   %ebp
80105671:	89 e5                	mov    %esp,%ebp
80105673:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
80105676:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010567c:	8b 00                	mov    (%eax),%eax
8010567e:	3b 45 08             	cmp    0x8(%ebp),%eax
80105681:	77 07                	ja     8010568a <fetchstr+0x1a>
    return -1;
80105683:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105688:	eb 46                	jmp    801056d0 <fetchstr+0x60>
  *pp = (char*)addr;
8010568a:	8b 55 08             	mov    0x8(%ebp),%edx
8010568d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105690:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
80105692:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105698:	8b 00                	mov    (%eax),%eax
8010569a:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
8010569d:	8b 45 0c             	mov    0xc(%ebp),%eax
801056a0:	8b 00                	mov    (%eax),%eax
801056a2:	89 45 fc             	mov    %eax,-0x4(%ebp)
801056a5:	eb 1c                	jmp    801056c3 <fetchstr+0x53>
    if(*s == 0)
801056a7:	8b 45 fc             	mov    -0x4(%ebp),%eax
801056aa:	0f b6 00             	movzbl (%eax),%eax
801056ad:	84 c0                	test   %al,%al
801056af:	75 0e                	jne    801056bf <fetchstr+0x4f>
      return s - *pp;
801056b1:	8b 55 fc             	mov    -0x4(%ebp),%edx
801056b4:	8b 45 0c             	mov    0xc(%ebp),%eax
801056b7:	8b 00                	mov    (%eax),%eax
801056b9:	29 c2                	sub    %eax,%edx
801056bb:	89 d0                	mov    %edx,%eax
801056bd:	eb 11                	jmp    801056d0 <fetchstr+0x60>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
801056bf:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801056c3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801056c6:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801056c9:	72 dc                	jb     801056a7 <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
801056cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801056d0:	c9                   	leave  
801056d1:	c3                   	ret    

801056d2 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801056d2:	55                   	push   %ebp
801056d3:	89 e5                	mov    %esp,%ebp
801056d5:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->tf->esp + 4 + 4*n, ip);
801056d8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056de:	8b 40 18             	mov    0x18(%eax),%eax
801056e1:	8b 50 44             	mov    0x44(%eax),%edx
801056e4:	8b 45 08             	mov    0x8(%ebp),%eax
801056e7:	c1 e0 02             	shl    $0x2,%eax
801056ea:	01 d0                	add    %edx,%eax
801056ec:	8d 50 04             	lea    0x4(%eax),%edx
801056ef:	8b 45 0c             	mov    0xc(%ebp),%eax
801056f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801056f6:	89 14 24             	mov    %edx,(%esp)
801056f9:	e8 38 ff ff ff       	call   80105636 <fetchint>
}
801056fe:	c9                   	leave  
801056ff:	c3                   	ret    

80105700 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80105700:	55                   	push   %ebp
80105701:	89 e5                	mov    %esp,%ebp
80105703:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80105706:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105709:	89 44 24 04          	mov    %eax,0x4(%esp)
8010570d:	8b 45 08             	mov    0x8(%ebp),%eax
80105710:	89 04 24             	mov    %eax,(%esp)
80105713:	e8 ba ff ff ff       	call   801056d2 <argint>
80105718:	85 c0                	test   %eax,%eax
8010571a:	79 07                	jns    80105723 <argptr+0x23>
    return -1;
8010571c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105721:	eb 3d                	jmp    80105760 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105723:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105726:	89 c2                	mov    %eax,%edx
80105728:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010572e:	8b 00                	mov    (%eax),%eax
80105730:	39 c2                	cmp    %eax,%edx
80105732:	73 16                	jae    8010574a <argptr+0x4a>
80105734:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105737:	89 c2                	mov    %eax,%edx
80105739:	8b 45 10             	mov    0x10(%ebp),%eax
8010573c:	01 c2                	add    %eax,%edx
8010573e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105744:	8b 00                	mov    (%eax),%eax
80105746:	39 c2                	cmp    %eax,%edx
80105748:	76 07                	jbe    80105751 <argptr+0x51>
    return -1;
8010574a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010574f:	eb 0f                	jmp    80105760 <argptr+0x60>
  *pp = (char*)i;
80105751:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105754:	89 c2                	mov    %eax,%edx
80105756:	8b 45 0c             	mov    0xc(%ebp),%eax
80105759:	89 10                	mov    %edx,(%eax)
  return 0;
8010575b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105760:	c9                   	leave  
80105761:	c3                   	ret    

80105762 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105762:	55                   	push   %ebp
80105763:	89 e5                	mov    %esp,%ebp
80105765:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105768:	8d 45 fc             	lea    -0x4(%ebp),%eax
8010576b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010576f:	8b 45 08             	mov    0x8(%ebp),%eax
80105772:	89 04 24             	mov    %eax,(%esp)
80105775:	e8 58 ff ff ff       	call   801056d2 <argint>
8010577a:	85 c0                	test   %eax,%eax
8010577c:	79 07                	jns    80105785 <argstr+0x23>
    return -1;
8010577e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105783:	eb 12                	jmp    80105797 <argstr+0x35>
  return fetchstr(addr, pp);
80105785:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105788:	8b 55 0c             	mov    0xc(%ebp),%edx
8010578b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010578f:	89 04 24             	mov    %eax,(%esp)
80105792:	e8 d9 fe ff ff       	call   80105670 <fetchstr>
}
80105797:	c9                   	leave  
80105798:	c3                   	ret    

80105799 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
80105799:	55                   	push   %ebp
8010579a:	89 e5                	mov    %esp,%ebp
8010579c:	53                   	push   %ebx
8010579d:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
801057a0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057a6:	8b 40 18             	mov    0x18(%eax),%eax
801057a9:	8b 40 1c             	mov    0x1c(%eax),%eax
801057ac:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
801057af:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801057b3:	7e 30                	jle    801057e5 <syscall+0x4c>
801057b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057b8:	83 f8 15             	cmp    $0x15,%eax
801057bb:	77 28                	ja     801057e5 <syscall+0x4c>
801057bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057c0:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801057c7:	85 c0                	test   %eax,%eax
801057c9:	74 1a                	je     801057e5 <syscall+0x4c>
    proc->tf->eax = syscalls[num]();
801057cb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057d1:	8b 58 18             	mov    0x18(%eax),%ebx
801057d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057d7:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801057de:	ff d0                	call   *%eax
801057e0:	89 43 1c             	mov    %eax,0x1c(%ebx)
801057e3:	eb 3d                	jmp    80105822 <syscall+0x89>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
801057e5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057eb:	8d 48 6c             	lea    0x6c(%eax),%ecx
801057ee:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
801057f4:	8b 40 10             	mov    0x10(%eax),%eax
801057f7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801057fa:	89 54 24 0c          	mov    %edx,0xc(%esp)
801057fe:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105802:	89 44 24 04          	mov    %eax,0x4(%esp)
80105806:	c7 04 24 5e 8b 10 80 	movl   $0x80108b5e,(%esp)
8010580d:	e8 8e ab ff ff       	call   801003a0 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105812:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105818:	8b 40 18             	mov    0x18(%eax),%eax
8010581b:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105822:	83 c4 24             	add    $0x24,%esp
80105825:	5b                   	pop    %ebx
80105826:	5d                   	pop    %ebp
80105827:	c3                   	ret    

80105828 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105828:	55                   	push   %ebp
80105829:	89 e5                	mov    %esp,%ebp
8010582b:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
8010582e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105831:	89 44 24 04          	mov    %eax,0x4(%esp)
80105835:	8b 45 08             	mov    0x8(%ebp),%eax
80105838:	89 04 24             	mov    %eax,(%esp)
8010583b:	e8 92 fe ff ff       	call   801056d2 <argint>
80105840:	85 c0                	test   %eax,%eax
80105842:	79 07                	jns    8010584b <argfd+0x23>
    return -1;
80105844:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105849:	eb 50                	jmp    8010589b <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
8010584b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010584e:	85 c0                	test   %eax,%eax
80105850:	78 21                	js     80105873 <argfd+0x4b>
80105852:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105855:	83 f8 0f             	cmp    $0xf,%eax
80105858:	7f 19                	jg     80105873 <argfd+0x4b>
8010585a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105860:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105863:	83 c2 08             	add    $0x8,%edx
80105866:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010586a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010586d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105871:	75 07                	jne    8010587a <argfd+0x52>
    return -1;
80105873:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105878:	eb 21                	jmp    8010589b <argfd+0x73>
  if(pfd)
8010587a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010587e:	74 08                	je     80105888 <argfd+0x60>
    *pfd = fd;
80105880:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105883:	8b 45 0c             	mov    0xc(%ebp),%eax
80105886:	89 10                	mov    %edx,(%eax)
  if(pf)
80105888:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010588c:	74 08                	je     80105896 <argfd+0x6e>
    *pf = f;
8010588e:	8b 45 10             	mov    0x10(%ebp),%eax
80105891:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105894:	89 10                	mov    %edx,(%eax)
  return 0;
80105896:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010589b:	c9                   	leave  
8010589c:	c3                   	ret    

8010589d <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
8010589d:	55                   	push   %ebp
8010589e:	89 e5                	mov    %esp,%ebp
801058a0:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801058a3:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801058aa:	eb 30                	jmp    801058dc <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
801058ac:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801058b2:	8b 55 fc             	mov    -0x4(%ebp),%edx
801058b5:	83 c2 08             	add    $0x8,%edx
801058b8:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801058bc:	85 c0                	test   %eax,%eax
801058be:	75 18                	jne    801058d8 <fdalloc+0x3b>
      proc->ofile[fd] = f;
801058c0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801058c6:	8b 55 fc             	mov    -0x4(%ebp),%edx
801058c9:	8d 4a 08             	lea    0x8(%edx),%ecx
801058cc:	8b 55 08             	mov    0x8(%ebp),%edx
801058cf:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
801058d3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801058d6:	eb 0f                	jmp    801058e7 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801058d8:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801058dc:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
801058e0:	7e ca                	jle    801058ac <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
801058e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801058e7:	c9                   	leave  
801058e8:	c3                   	ret    

801058e9 <sys_dup>:

int
sys_dup(void)
{
801058e9:	55                   	push   %ebp
801058ea:	89 e5                	mov    %esp,%ebp
801058ec:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
801058ef:	8d 45 f0             	lea    -0x10(%ebp),%eax
801058f2:	89 44 24 08          	mov    %eax,0x8(%esp)
801058f6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801058fd:	00 
801058fe:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105905:	e8 1e ff ff ff       	call   80105828 <argfd>
8010590a:	85 c0                	test   %eax,%eax
8010590c:	79 07                	jns    80105915 <sys_dup+0x2c>
    return -1;
8010590e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105913:	eb 29                	jmp    8010593e <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105915:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105918:	89 04 24             	mov    %eax,(%esp)
8010591b:	e8 7d ff ff ff       	call   8010589d <fdalloc>
80105920:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105923:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105927:	79 07                	jns    80105930 <sys_dup+0x47>
    return -1;
80105929:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010592e:	eb 0e                	jmp    8010593e <sys_dup+0x55>
  filedup(f);
80105930:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105933:	89 04 24             	mov    %eax,(%esp)
80105936:	e8 4b b6 ff ff       	call   80100f86 <filedup>
  return fd;
8010593b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010593e:	c9                   	leave  
8010593f:	c3                   	ret    

80105940 <sys_read>:

int
sys_read(void)
{
80105940:	55                   	push   %ebp
80105941:	89 e5                	mov    %esp,%ebp
80105943:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105946:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105949:	89 44 24 08          	mov    %eax,0x8(%esp)
8010594d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105954:	00 
80105955:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010595c:	e8 c7 fe ff ff       	call   80105828 <argfd>
80105961:	85 c0                	test   %eax,%eax
80105963:	78 35                	js     8010599a <sys_read+0x5a>
80105965:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105968:	89 44 24 04          	mov    %eax,0x4(%esp)
8010596c:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105973:	e8 5a fd ff ff       	call   801056d2 <argint>
80105978:	85 c0                	test   %eax,%eax
8010597a:	78 1e                	js     8010599a <sys_read+0x5a>
8010597c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010597f:	89 44 24 08          	mov    %eax,0x8(%esp)
80105983:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105986:	89 44 24 04          	mov    %eax,0x4(%esp)
8010598a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105991:	e8 6a fd ff ff       	call   80105700 <argptr>
80105996:	85 c0                	test   %eax,%eax
80105998:	79 07                	jns    801059a1 <sys_read+0x61>
    return -1;
8010599a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010599f:	eb 19                	jmp    801059ba <sys_read+0x7a>
  return fileread(f, p, n);
801059a1:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801059a4:	8b 55 ec             	mov    -0x14(%ebp),%edx
801059a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059aa:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801059ae:	89 54 24 04          	mov    %edx,0x4(%esp)
801059b2:	89 04 24             	mov    %eax,(%esp)
801059b5:	e8 39 b7 ff ff       	call   801010f3 <fileread>
}
801059ba:	c9                   	leave  
801059bb:	c3                   	ret    

801059bc <sys_write>:

int
sys_write(void)
{
801059bc:	55                   	push   %ebp
801059bd:	89 e5                	mov    %esp,%ebp
801059bf:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801059c2:	8d 45 f4             	lea    -0xc(%ebp),%eax
801059c5:	89 44 24 08          	mov    %eax,0x8(%esp)
801059c9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801059d0:	00 
801059d1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801059d8:	e8 4b fe ff ff       	call   80105828 <argfd>
801059dd:	85 c0                	test   %eax,%eax
801059df:	78 35                	js     80105a16 <sys_write+0x5a>
801059e1:	8d 45 f0             	lea    -0x10(%ebp),%eax
801059e4:	89 44 24 04          	mov    %eax,0x4(%esp)
801059e8:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801059ef:	e8 de fc ff ff       	call   801056d2 <argint>
801059f4:	85 c0                	test   %eax,%eax
801059f6:	78 1e                	js     80105a16 <sys_write+0x5a>
801059f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059fb:	89 44 24 08          	mov    %eax,0x8(%esp)
801059ff:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105a02:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a06:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105a0d:	e8 ee fc ff ff       	call   80105700 <argptr>
80105a12:	85 c0                	test   %eax,%eax
80105a14:	79 07                	jns    80105a1d <sys_write+0x61>
    return -1;
80105a16:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a1b:	eb 19                	jmp    80105a36 <sys_write+0x7a>
  return filewrite(f, p, n);
80105a1d:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105a20:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105a23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a26:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105a2a:	89 54 24 04          	mov    %edx,0x4(%esp)
80105a2e:	89 04 24             	mov    %eax,(%esp)
80105a31:	e8 79 b7 ff ff       	call   801011af <filewrite>
}
80105a36:	c9                   	leave  
80105a37:	c3                   	ret    

80105a38 <sys_close>:

int
sys_close(void)
{
80105a38:	55                   	push   %ebp
80105a39:	89 e5                	mov    %esp,%ebp
80105a3b:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
80105a3e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105a41:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a45:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105a48:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a4c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105a53:	e8 d0 fd ff ff       	call   80105828 <argfd>
80105a58:	85 c0                	test   %eax,%eax
80105a5a:	79 07                	jns    80105a63 <sys_close+0x2b>
    return -1;
80105a5c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a61:	eb 24                	jmp    80105a87 <sys_close+0x4f>
  proc->ofile[fd] = 0;
80105a63:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105a69:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105a6c:	83 c2 08             	add    $0x8,%edx
80105a6f:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105a76:	00 
  fileclose(f);
80105a77:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a7a:	89 04 24             	mov    %eax,(%esp)
80105a7d:	e8 4c b5 ff ff       	call   80100fce <fileclose>
  return 0;
80105a82:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105a87:	c9                   	leave  
80105a88:	c3                   	ret    

80105a89 <sys_fstat>:

int
sys_fstat(void)
{
80105a89:	55                   	push   %ebp
80105a8a:	89 e5                	mov    %esp,%ebp
80105a8c:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80105a8f:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105a92:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a96:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105a9d:	00 
80105a9e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105aa5:	e8 7e fd ff ff       	call   80105828 <argfd>
80105aaa:	85 c0                	test   %eax,%eax
80105aac:	78 1f                	js     80105acd <sys_fstat+0x44>
80105aae:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80105ab5:	00 
80105ab6:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105ab9:	89 44 24 04          	mov    %eax,0x4(%esp)
80105abd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105ac4:	e8 37 fc ff ff       	call   80105700 <argptr>
80105ac9:	85 c0                	test   %eax,%eax
80105acb:	79 07                	jns    80105ad4 <sys_fstat+0x4b>
    return -1;
80105acd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ad2:	eb 12                	jmp    80105ae6 <sys_fstat+0x5d>
  return filestat(f, st);
80105ad4:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105ad7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ada:	89 54 24 04          	mov    %edx,0x4(%esp)
80105ade:	89 04 24             	mov    %eax,(%esp)
80105ae1:	e8 be b5 ff ff       	call   801010a4 <filestat>
}
80105ae6:	c9                   	leave  
80105ae7:	c3                   	ret    

80105ae8 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80105ae8:	55                   	push   %ebp
80105ae9:	89 e5                	mov    %esp,%ebp
80105aeb:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80105aee:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105af1:	89 44 24 04          	mov    %eax,0x4(%esp)
80105af5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105afc:	e8 61 fc ff ff       	call   80105762 <argstr>
80105b01:	85 c0                	test   %eax,%eax
80105b03:	78 17                	js     80105b1c <sys_link+0x34>
80105b05:	8d 45 dc             	lea    -0x24(%ebp),%eax
80105b08:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b0c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105b13:	e8 4a fc ff ff       	call   80105762 <argstr>
80105b18:	85 c0                	test   %eax,%eax
80105b1a:	79 0a                	jns    80105b26 <sys_link+0x3e>
    return -1;
80105b1c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b21:	e9 42 01 00 00       	jmp    80105c68 <sys_link+0x180>

  begin_op();
80105b26:	e8 00 da ff ff       	call   8010352b <begin_op>
  if((ip = namei(old)) == 0){
80105b2b:	8b 45 d8             	mov    -0x28(%ebp),%eax
80105b2e:	89 04 24             	mov    %eax,(%esp)
80105b31:	e8 eb c9 ff ff       	call   80102521 <namei>
80105b36:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105b39:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105b3d:	75 0f                	jne    80105b4e <sys_link+0x66>
    end_op();
80105b3f:	e8 6b da ff ff       	call   801035af <end_op>
    return -1;
80105b44:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b49:	e9 1a 01 00 00       	jmp    80105c68 <sys_link+0x180>
  }

  ilock(ip);
80105b4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b51:	89 04 24             	mov    %eax,(%esp)
80105b54:	e8 02 bd ff ff       	call   8010185b <ilock>
  if(ip->type == T_DIR){
80105b59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b5c:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105b60:	66 83 f8 01          	cmp    $0x1,%ax
80105b64:	75 1a                	jne    80105b80 <sys_link+0x98>
    iunlockput(ip);
80105b66:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b69:	89 04 24             	mov    %eax,(%esp)
80105b6c:	e8 6e bf ff ff       	call   80101adf <iunlockput>
    end_op();
80105b71:	e8 39 da ff ff       	call   801035af <end_op>
    return -1;
80105b76:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b7b:	e9 e8 00 00 00       	jmp    80105c68 <sys_link+0x180>
  }

  ip->nlink++;
80105b80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b83:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105b87:	8d 50 01             	lea    0x1(%eax),%edx
80105b8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b8d:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105b91:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b94:	89 04 24             	mov    %eax,(%esp)
80105b97:	e8 03 bb ff ff       	call   8010169f <iupdate>
  iunlock(ip);
80105b9c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b9f:	89 04 24             	mov    %eax,(%esp)
80105ba2:	e8 02 be ff ff       	call   801019a9 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80105ba7:	8b 45 dc             	mov    -0x24(%ebp),%eax
80105baa:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80105bad:	89 54 24 04          	mov    %edx,0x4(%esp)
80105bb1:	89 04 24             	mov    %eax,(%esp)
80105bb4:	e8 8a c9 ff ff       	call   80102543 <nameiparent>
80105bb9:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105bbc:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105bc0:	75 02                	jne    80105bc4 <sys_link+0xdc>
    goto bad;
80105bc2:	eb 68                	jmp    80105c2c <sys_link+0x144>
  ilock(dp);
80105bc4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bc7:	89 04 24             	mov    %eax,(%esp)
80105bca:	e8 8c bc ff ff       	call   8010185b <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80105bcf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bd2:	8b 10                	mov    (%eax),%edx
80105bd4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bd7:	8b 00                	mov    (%eax),%eax
80105bd9:	39 c2                	cmp    %eax,%edx
80105bdb:	75 20                	jne    80105bfd <sys_link+0x115>
80105bdd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105be0:	8b 40 04             	mov    0x4(%eax),%eax
80105be3:	89 44 24 08          	mov    %eax,0x8(%esp)
80105be7:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80105bea:	89 44 24 04          	mov    %eax,0x4(%esp)
80105bee:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bf1:	89 04 24             	mov    %eax,(%esp)
80105bf4:	e8 27 c6 ff ff       	call   80102220 <dirlink>
80105bf9:	85 c0                	test   %eax,%eax
80105bfb:	79 0d                	jns    80105c0a <sys_link+0x122>
    iunlockput(dp);
80105bfd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c00:	89 04 24             	mov    %eax,(%esp)
80105c03:	e8 d7 be ff ff       	call   80101adf <iunlockput>
    goto bad;
80105c08:	eb 22                	jmp    80105c2c <sys_link+0x144>
  }
  iunlockput(dp);
80105c0a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c0d:	89 04 24             	mov    %eax,(%esp)
80105c10:	e8 ca be ff ff       	call   80101adf <iunlockput>
  iput(ip);
80105c15:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c18:	89 04 24             	mov    %eax,(%esp)
80105c1b:	e8 ee bd ff ff       	call   80101a0e <iput>

  end_op();
80105c20:	e8 8a d9 ff ff       	call   801035af <end_op>

  return 0;
80105c25:	b8 00 00 00 00       	mov    $0x0,%eax
80105c2a:	eb 3c                	jmp    80105c68 <sys_link+0x180>

bad:
  ilock(ip);
80105c2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c2f:	89 04 24             	mov    %eax,(%esp)
80105c32:	e8 24 bc ff ff       	call   8010185b <ilock>
  ip->nlink--;
80105c37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c3a:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105c3e:	8d 50 ff             	lea    -0x1(%eax),%edx
80105c41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c44:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105c48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c4b:	89 04 24             	mov    %eax,(%esp)
80105c4e:	e8 4c ba ff ff       	call   8010169f <iupdate>
  iunlockput(ip);
80105c53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c56:	89 04 24             	mov    %eax,(%esp)
80105c59:	e8 81 be ff ff       	call   80101adf <iunlockput>
  end_op();
80105c5e:	e8 4c d9 ff ff       	call   801035af <end_op>
  return -1;
80105c63:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105c68:	c9                   	leave  
80105c69:	c3                   	ret    

80105c6a <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80105c6a:	55                   	push   %ebp
80105c6b:	89 e5                	mov    %esp,%ebp
80105c6d:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105c70:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80105c77:	eb 4b                	jmp    80105cc4 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105c79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c7c:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105c83:	00 
80105c84:	89 44 24 08          	mov    %eax,0x8(%esp)
80105c88:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105c8b:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c8f:	8b 45 08             	mov    0x8(%ebp),%eax
80105c92:	89 04 24             	mov    %eax,(%esp)
80105c95:	e8 ce c0 ff ff       	call   80101d68 <readi>
80105c9a:	83 f8 10             	cmp    $0x10,%eax
80105c9d:	74 0c                	je     80105cab <isdirempty+0x41>
      panic("isdirempty: readi");
80105c9f:	c7 04 24 7a 8b 10 80 	movl   $0x80108b7a,(%esp)
80105ca6:	e8 8f a8 ff ff       	call   8010053a <panic>
    if(de.inum != 0)
80105cab:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80105caf:	66 85 c0             	test   %ax,%ax
80105cb2:	74 07                	je     80105cbb <isdirempty+0x51>
      return 0;
80105cb4:	b8 00 00 00 00       	mov    $0x0,%eax
80105cb9:	eb 1b                	jmp    80105cd6 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105cbb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cbe:	83 c0 10             	add    $0x10,%eax
80105cc1:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105cc4:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105cc7:	8b 45 08             	mov    0x8(%ebp),%eax
80105cca:	8b 40 18             	mov    0x18(%eax),%eax
80105ccd:	39 c2                	cmp    %eax,%edx
80105ccf:	72 a8                	jb     80105c79 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80105cd1:	b8 01 00 00 00       	mov    $0x1,%eax
}
80105cd6:	c9                   	leave  
80105cd7:	c3                   	ret    

80105cd8 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80105cd8:	55                   	push   %ebp
80105cd9:	89 e5                	mov    %esp,%ebp
80105cdb:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80105cde:	8d 45 cc             	lea    -0x34(%ebp),%eax
80105ce1:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ce5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105cec:	e8 71 fa ff ff       	call   80105762 <argstr>
80105cf1:	85 c0                	test   %eax,%eax
80105cf3:	79 0a                	jns    80105cff <sys_unlink+0x27>
    return -1;
80105cf5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cfa:	e9 af 01 00 00       	jmp    80105eae <sys_unlink+0x1d6>

  begin_op();
80105cff:	e8 27 d8 ff ff       	call   8010352b <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80105d04:	8b 45 cc             	mov    -0x34(%ebp),%eax
80105d07:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80105d0a:	89 54 24 04          	mov    %edx,0x4(%esp)
80105d0e:	89 04 24             	mov    %eax,(%esp)
80105d11:	e8 2d c8 ff ff       	call   80102543 <nameiparent>
80105d16:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105d19:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105d1d:	75 0f                	jne    80105d2e <sys_unlink+0x56>
    end_op();
80105d1f:	e8 8b d8 ff ff       	call   801035af <end_op>
    return -1;
80105d24:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d29:	e9 80 01 00 00       	jmp    80105eae <sys_unlink+0x1d6>
  }

  ilock(dp);
80105d2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d31:	89 04 24             	mov    %eax,(%esp)
80105d34:	e8 22 bb ff ff       	call   8010185b <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80105d39:	c7 44 24 04 8c 8b 10 	movl   $0x80108b8c,0x4(%esp)
80105d40:	80 
80105d41:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105d44:	89 04 24             	mov    %eax,(%esp)
80105d47:	e8 22 c3 ff ff       	call   8010206e <namecmp>
80105d4c:	85 c0                	test   %eax,%eax
80105d4e:	0f 84 45 01 00 00    	je     80105e99 <sys_unlink+0x1c1>
80105d54:	c7 44 24 04 8e 8b 10 	movl   $0x80108b8e,0x4(%esp)
80105d5b:	80 
80105d5c:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105d5f:	89 04 24             	mov    %eax,(%esp)
80105d62:	e8 07 c3 ff ff       	call   8010206e <namecmp>
80105d67:	85 c0                	test   %eax,%eax
80105d69:	0f 84 2a 01 00 00    	je     80105e99 <sys_unlink+0x1c1>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80105d6f:	8d 45 c8             	lea    -0x38(%ebp),%eax
80105d72:	89 44 24 08          	mov    %eax,0x8(%esp)
80105d76:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105d79:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d80:	89 04 24             	mov    %eax,(%esp)
80105d83:	e8 08 c3 ff ff       	call   80102090 <dirlookup>
80105d88:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105d8b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105d8f:	75 05                	jne    80105d96 <sys_unlink+0xbe>
    goto bad;
80105d91:	e9 03 01 00 00       	jmp    80105e99 <sys_unlink+0x1c1>
  ilock(ip);
80105d96:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d99:	89 04 24             	mov    %eax,(%esp)
80105d9c:	e8 ba ba ff ff       	call   8010185b <ilock>

  if(ip->nlink < 1)
80105da1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105da4:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105da8:	66 85 c0             	test   %ax,%ax
80105dab:	7f 0c                	jg     80105db9 <sys_unlink+0xe1>
    panic("unlink: nlink < 1");
80105dad:	c7 04 24 91 8b 10 80 	movl   $0x80108b91,(%esp)
80105db4:	e8 81 a7 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80105db9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dbc:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105dc0:	66 83 f8 01          	cmp    $0x1,%ax
80105dc4:	75 1f                	jne    80105de5 <sys_unlink+0x10d>
80105dc6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dc9:	89 04 24             	mov    %eax,(%esp)
80105dcc:	e8 99 fe ff ff       	call   80105c6a <isdirempty>
80105dd1:	85 c0                	test   %eax,%eax
80105dd3:	75 10                	jne    80105de5 <sys_unlink+0x10d>
    iunlockput(ip);
80105dd5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dd8:	89 04 24             	mov    %eax,(%esp)
80105ddb:	e8 ff bc ff ff       	call   80101adf <iunlockput>
    goto bad;
80105de0:	e9 b4 00 00 00       	jmp    80105e99 <sys_unlink+0x1c1>
  }

  memset(&de, 0, sizeof(de));
80105de5:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105dec:	00 
80105ded:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105df4:	00 
80105df5:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105df8:	89 04 24             	mov    %eax,(%esp)
80105dfb:	e8 90 f5 ff ff       	call   80105390 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105e00:	8b 45 c8             	mov    -0x38(%ebp),%eax
80105e03:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105e0a:	00 
80105e0b:	89 44 24 08          	mov    %eax,0x8(%esp)
80105e0f:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105e12:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e16:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e19:	89 04 24             	mov    %eax,(%esp)
80105e1c:	e8 b8 c0 ff ff       	call   80101ed9 <writei>
80105e21:	83 f8 10             	cmp    $0x10,%eax
80105e24:	74 0c                	je     80105e32 <sys_unlink+0x15a>
    panic("unlink: writei");
80105e26:	c7 04 24 a3 8b 10 80 	movl   $0x80108ba3,(%esp)
80105e2d:	e8 08 a7 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR){
80105e32:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e35:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105e39:	66 83 f8 01          	cmp    $0x1,%ax
80105e3d:	75 1c                	jne    80105e5b <sys_unlink+0x183>
    dp->nlink--;
80105e3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e42:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105e46:	8d 50 ff             	lea    -0x1(%eax),%edx
80105e49:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e4c:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105e50:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e53:	89 04 24             	mov    %eax,(%esp)
80105e56:	e8 44 b8 ff ff       	call   8010169f <iupdate>
  }
  iunlockput(dp);
80105e5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e5e:	89 04 24             	mov    %eax,(%esp)
80105e61:	e8 79 bc ff ff       	call   80101adf <iunlockput>

  ip->nlink--;
80105e66:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e69:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105e6d:	8d 50 ff             	lea    -0x1(%eax),%edx
80105e70:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e73:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105e77:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e7a:	89 04 24             	mov    %eax,(%esp)
80105e7d:	e8 1d b8 ff ff       	call   8010169f <iupdate>
  iunlockput(ip);
80105e82:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e85:	89 04 24             	mov    %eax,(%esp)
80105e88:	e8 52 bc ff ff       	call   80101adf <iunlockput>

  end_op();
80105e8d:	e8 1d d7 ff ff       	call   801035af <end_op>

  return 0;
80105e92:	b8 00 00 00 00       	mov    $0x0,%eax
80105e97:	eb 15                	jmp    80105eae <sys_unlink+0x1d6>

bad:
  iunlockput(dp);
80105e99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e9c:	89 04 24             	mov    %eax,(%esp)
80105e9f:	e8 3b bc ff ff       	call   80101adf <iunlockput>
  end_op();
80105ea4:	e8 06 d7 ff ff       	call   801035af <end_op>
  return -1;
80105ea9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105eae:	c9                   	leave  
80105eaf:	c3                   	ret    

80105eb0 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80105eb0:	55                   	push   %ebp
80105eb1:	89 e5                	mov    %esp,%ebp
80105eb3:	83 ec 48             	sub    $0x48,%esp
80105eb6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105eb9:	8b 55 10             	mov    0x10(%ebp),%edx
80105ebc:	8b 45 14             	mov    0x14(%ebp),%eax
80105ebf:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80105ec3:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80105ec7:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80105ecb:	8d 45 de             	lea    -0x22(%ebp),%eax
80105ece:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ed2:	8b 45 08             	mov    0x8(%ebp),%eax
80105ed5:	89 04 24             	mov    %eax,(%esp)
80105ed8:	e8 66 c6 ff ff       	call   80102543 <nameiparent>
80105edd:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105ee0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105ee4:	75 0a                	jne    80105ef0 <create+0x40>
    return 0;
80105ee6:	b8 00 00 00 00       	mov    $0x0,%eax
80105eeb:	e9 a0 01 00 00       	jmp    80106090 <create+0x1e0>
  ilock(dp);
80105ef0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ef3:	89 04 24             	mov    %eax,(%esp)
80105ef6:	e8 60 b9 ff ff       	call   8010185b <ilock>

  if (dp->type == T_DEV) {
80105efb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105efe:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105f02:	66 83 f8 03          	cmp    $0x3,%ax
80105f06:	75 15                	jne    80105f1d <create+0x6d>
    iunlockput(dp);
80105f08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f0b:	89 04 24             	mov    %eax,(%esp)
80105f0e:	e8 cc bb ff ff       	call   80101adf <iunlockput>
    return 0;
80105f13:	b8 00 00 00 00       	mov    $0x0,%eax
80105f18:	e9 73 01 00 00       	jmp    80106090 <create+0x1e0>
  }

  if((ip = dirlookup(dp, name, &off)) != 0){
80105f1d:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105f20:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f24:	8d 45 de             	lea    -0x22(%ebp),%eax
80105f27:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f2e:	89 04 24             	mov    %eax,(%esp)
80105f31:	e8 5a c1 ff ff       	call   80102090 <dirlookup>
80105f36:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105f39:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105f3d:	74 47                	je     80105f86 <create+0xd6>
    iunlockput(dp);
80105f3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f42:	89 04 24             	mov    %eax,(%esp)
80105f45:	e8 95 bb ff ff       	call   80101adf <iunlockput>
    ilock(ip);
80105f4a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f4d:	89 04 24             	mov    %eax,(%esp)
80105f50:	e8 06 b9 ff ff       	call   8010185b <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80105f55:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80105f5a:	75 15                	jne    80105f71 <create+0xc1>
80105f5c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f5f:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105f63:	66 83 f8 02          	cmp    $0x2,%ax
80105f67:	75 08                	jne    80105f71 <create+0xc1>
      return ip;
80105f69:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f6c:	e9 1f 01 00 00       	jmp    80106090 <create+0x1e0>
    iunlockput(ip);
80105f71:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f74:	89 04 24             	mov    %eax,(%esp)
80105f77:	e8 63 bb ff ff       	call   80101adf <iunlockput>
    return 0;
80105f7c:	b8 00 00 00 00       	mov    $0x0,%eax
80105f81:	e9 0a 01 00 00       	jmp    80106090 <create+0x1e0>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80105f86:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80105f8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f8d:	8b 00                	mov    (%eax),%eax
80105f8f:	89 54 24 04          	mov    %edx,0x4(%esp)
80105f93:	89 04 24             	mov    %eax,(%esp)
80105f96:	e8 25 b6 ff ff       	call   801015c0 <ialloc>
80105f9b:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105f9e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105fa2:	75 0c                	jne    80105fb0 <create+0x100>
    panic("create: ialloc");
80105fa4:	c7 04 24 b2 8b 10 80 	movl   $0x80108bb2,(%esp)
80105fab:	e8 8a a5 ff ff       	call   8010053a <panic>

  ilock(ip);
80105fb0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fb3:	89 04 24             	mov    %eax,(%esp)
80105fb6:	e8 a0 b8 ff ff       	call   8010185b <ilock>
  ip->major = major;
80105fbb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fbe:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80105fc2:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80105fc6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fc9:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80105fcd:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80105fd1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fd4:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80105fda:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fdd:	89 04 24             	mov    %eax,(%esp)
80105fe0:	e8 ba b6 ff ff       	call   8010169f <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80105fe5:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80105fea:	75 6a                	jne    80106056 <create+0x1a6>
    dp->nlink++;  // for ".."
80105fec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fef:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105ff3:	8d 50 01             	lea    0x1(%eax),%edx
80105ff6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ff9:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105ffd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106000:	89 04 24             	mov    %eax,(%esp)
80106003:	e8 97 b6 ff ff       	call   8010169f <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80106008:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010600b:	8b 40 04             	mov    0x4(%eax),%eax
8010600e:	89 44 24 08          	mov    %eax,0x8(%esp)
80106012:	c7 44 24 04 8c 8b 10 	movl   $0x80108b8c,0x4(%esp)
80106019:	80 
8010601a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010601d:	89 04 24             	mov    %eax,(%esp)
80106020:	e8 fb c1 ff ff       	call   80102220 <dirlink>
80106025:	85 c0                	test   %eax,%eax
80106027:	78 21                	js     8010604a <create+0x19a>
80106029:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010602c:	8b 40 04             	mov    0x4(%eax),%eax
8010602f:	89 44 24 08          	mov    %eax,0x8(%esp)
80106033:	c7 44 24 04 8e 8b 10 	movl   $0x80108b8e,0x4(%esp)
8010603a:	80 
8010603b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010603e:	89 04 24             	mov    %eax,(%esp)
80106041:	e8 da c1 ff ff       	call   80102220 <dirlink>
80106046:	85 c0                	test   %eax,%eax
80106048:	79 0c                	jns    80106056 <create+0x1a6>
      panic("create dots");
8010604a:	c7 04 24 c1 8b 10 80 	movl   $0x80108bc1,(%esp)
80106051:	e8 e4 a4 ff ff       	call   8010053a <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80106056:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106059:	8b 40 04             	mov    0x4(%eax),%eax
8010605c:	89 44 24 08          	mov    %eax,0x8(%esp)
80106060:	8d 45 de             	lea    -0x22(%ebp),%eax
80106063:	89 44 24 04          	mov    %eax,0x4(%esp)
80106067:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010606a:	89 04 24             	mov    %eax,(%esp)
8010606d:	e8 ae c1 ff ff       	call   80102220 <dirlink>
80106072:	85 c0                	test   %eax,%eax
80106074:	79 0c                	jns    80106082 <create+0x1d2>
    panic("create: dirlink");
80106076:	c7 04 24 cd 8b 10 80 	movl   $0x80108bcd,(%esp)
8010607d:	e8 b8 a4 ff ff       	call   8010053a <panic>

  iunlockput(dp);
80106082:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106085:	89 04 24             	mov    %eax,(%esp)
80106088:	e8 52 ba ff ff       	call   80101adf <iunlockput>

  return ip;
8010608d:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106090:	c9                   	leave  
80106091:	c3                   	ret    

80106092 <sys_open>:

int
sys_open(void)
{
80106092:	55                   	push   %ebp
80106093:	89 e5                	mov    %esp,%ebp
80106095:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80106098:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010609b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010609f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801060a6:	e8 b7 f6 ff ff       	call   80105762 <argstr>
801060ab:	85 c0                	test   %eax,%eax
801060ad:	78 17                	js     801060c6 <sys_open+0x34>
801060af:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801060b2:	89 44 24 04          	mov    %eax,0x4(%esp)
801060b6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801060bd:	e8 10 f6 ff ff       	call   801056d2 <argint>
801060c2:	85 c0                	test   %eax,%eax
801060c4:	79 0a                	jns    801060d0 <sys_open+0x3e>
    return -1;
801060c6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060cb:	e9 5c 01 00 00       	jmp    8010622c <sys_open+0x19a>

  begin_op();
801060d0:	e8 56 d4 ff ff       	call   8010352b <begin_op>

  if(omode & O_CREATE){
801060d5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801060d8:	25 00 02 00 00       	and    $0x200,%eax
801060dd:	85 c0                	test   %eax,%eax
801060df:	74 3b                	je     8010611c <sys_open+0x8a>
    ip = create(path, T_FILE, 0, 0);
801060e1:	8b 45 e8             	mov    -0x18(%ebp),%eax
801060e4:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801060eb:	00 
801060ec:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801060f3:	00 
801060f4:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
801060fb:	00 
801060fc:	89 04 24             	mov    %eax,(%esp)
801060ff:	e8 ac fd ff ff       	call   80105eb0 <create>
80106104:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
80106107:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010610b:	75 6b                	jne    80106178 <sys_open+0xe6>
      end_op();
8010610d:	e8 9d d4 ff ff       	call   801035af <end_op>
      return -1;
80106112:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106117:	e9 10 01 00 00       	jmp    8010622c <sys_open+0x19a>
    }
  } else {
    if((ip = namei(path)) == 0){
8010611c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010611f:	89 04 24             	mov    %eax,(%esp)
80106122:	e8 fa c3 ff ff       	call   80102521 <namei>
80106127:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010612a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010612e:	75 0f                	jne    8010613f <sys_open+0xad>
      end_op();
80106130:	e8 7a d4 ff ff       	call   801035af <end_op>
      return -1;
80106135:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010613a:	e9 ed 00 00 00       	jmp    8010622c <sys_open+0x19a>
    }
    ilock(ip);
8010613f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106142:	89 04 24             	mov    %eax,(%esp)
80106145:	e8 11 b7 ff ff       	call   8010185b <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
8010614a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010614d:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106151:	66 83 f8 01          	cmp    $0x1,%ax
80106155:	75 21                	jne    80106178 <sys_open+0xe6>
80106157:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010615a:	85 c0                	test   %eax,%eax
8010615c:	74 1a                	je     80106178 <sys_open+0xe6>
      iunlockput(ip);
8010615e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106161:	89 04 24             	mov    %eax,(%esp)
80106164:	e8 76 b9 ff ff       	call   80101adf <iunlockput>
      end_op();
80106169:	e8 41 d4 ff ff       	call   801035af <end_op>
      return -1;
8010616e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106173:	e9 b4 00 00 00       	jmp    8010622c <sys_open+0x19a>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106178:	e8 a9 ad ff ff       	call   80100f26 <filealloc>
8010617d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106180:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106184:	74 14                	je     8010619a <sys_open+0x108>
80106186:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106189:	89 04 24             	mov    %eax,(%esp)
8010618c:	e8 0c f7 ff ff       	call   8010589d <fdalloc>
80106191:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106194:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106198:	79 28                	jns    801061c2 <sys_open+0x130>
    if(f)
8010619a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010619e:	74 0b                	je     801061ab <sys_open+0x119>
      fileclose(f);
801061a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061a3:	89 04 24             	mov    %eax,(%esp)
801061a6:	e8 23 ae ff ff       	call   80100fce <fileclose>
    iunlockput(ip);
801061ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061ae:	89 04 24             	mov    %eax,(%esp)
801061b1:	e8 29 b9 ff ff       	call   80101adf <iunlockput>
    end_op();
801061b6:	e8 f4 d3 ff ff       	call   801035af <end_op>
    return -1;
801061bb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061c0:	eb 6a                	jmp    8010622c <sys_open+0x19a>
  }
  iunlock(ip);
801061c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061c5:	89 04 24             	mov    %eax,(%esp)
801061c8:	e8 dc b7 ff ff       	call   801019a9 <iunlock>
  end_op();
801061cd:	e8 dd d3 ff ff       	call   801035af <end_op>

  f->type = FD_INODE;
801061d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061d5:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
801061db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061de:	8b 55 f4             	mov    -0xc(%ebp),%edx
801061e1:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
801061e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061e7:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
801061ee:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801061f1:	83 e0 01             	and    $0x1,%eax
801061f4:	85 c0                	test   %eax,%eax
801061f6:	0f 94 c0             	sete   %al
801061f9:	89 c2                	mov    %eax,%edx
801061fb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061fe:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106201:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106204:	83 e0 01             	and    $0x1,%eax
80106207:	85 c0                	test   %eax,%eax
80106209:	75 0a                	jne    80106215 <sys_open+0x183>
8010620b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010620e:	83 e0 02             	and    $0x2,%eax
80106211:	85 c0                	test   %eax,%eax
80106213:	74 07                	je     8010621c <sys_open+0x18a>
80106215:	b8 01 00 00 00       	mov    $0x1,%eax
8010621a:	eb 05                	jmp    80106221 <sys_open+0x18f>
8010621c:	b8 00 00 00 00       	mov    $0x0,%eax
80106221:	89 c2                	mov    %eax,%edx
80106223:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106226:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80106229:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
8010622c:	c9                   	leave  
8010622d:	c3                   	ret    

8010622e <sys_mkdir>:

int
sys_mkdir(void)
{
8010622e:	55                   	push   %ebp
8010622f:	89 e5                	mov    %esp,%ebp
80106231:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80106234:	e8 f2 d2 ff ff       	call   8010352b <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80106239:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010623c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106240:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106247:	e8 16 f5 ff ff       	call   80105762 <argstr>
8010624c:	85 c0                	test   %eax,%eax
8010624e:	78 2c                	js     8010627c <sys_mkdir+0x4e>
80106250:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106253:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
8010625a:	00 
8010625b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106262:	00 
80106263:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010626a:	00 
8010626b:	89 04 24             	mov    %eax,(%esp)
8010626e:	e8 3d fc ff ff       	call   80105eb0 <create>
80106273:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106276:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010627a:	75 0c                	jne    80106288 <sys_mkdir+0x5a>
    end_op();
8010627c:	e8 2e d3 ff ff       	call   801035af <end_op>
    return -1;
80106281:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106286:	eb 15                	jmp    8010629d <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80106288:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010628b:	89 04 24             	mov    %eax,(%esp)
8010628e:	e8 4c b8 ff ff       	call   80101adf <iunlockput>
  end_op();
80106293:	e8 17 d3 ff ff       	call   801035af <end_op>
  return 0;
80106298:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010629d:	c9                   	leave  
8010629e:	c3                   	ret    

8010629f <sys_mknod>:

int
sys_mknod(void)
{
8010629f:	55                   	push   %ebp
801062a0:	89 e5                	mov    %esp,%ebp
801062a2:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_op();
801062a5:	e8 81 d2 ff ff       	call   8010352b <begin_op>
  if((len=argstr(0, &path)) < 0 ||
801062aa:	8d 45 ec             	lea    -0x14(%ebp),%eax
801062ad:	89 44 24 04          	mov    %eax,0x4(%esp)
801062b1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801062b8:	e8 a5 f4 ff ff       	call   80105762 <argstr>
801062bd:	89 45 f4             	mov    %eax,-0xc(%ebp)
801062c0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801062c4:	78 5e                	js     80106324 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
801062c6:	8d 45 e8             	lea    -0x18(%ebp),%eax
801062c9:	89 44 24 04          	mov    %eax,0x4(%esp)
801062cd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801062d4:	e8 f9 f3 ff ff       	call   801056d2 <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
801062d9:	85 c0                	test   %eax,%eax
801062db:	78 47                	js     80106324 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801062dd:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801062e0:	89 44 24 04          	mov    %eax,0x4(%esp)
801062e4:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801062eb:	e8 e2 f3 ff ff       	call   801056d2 <argint>
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
801062f0:	85 c0                	test   %eax,%eax
801062f2:	78 30                	js     80106324 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
801062f4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801062f7:	0f bf c8             	movswl %ax,%ecx
801062fa:	8b 45 e8             	mov    -0x18(%ebp),%eax
801062fd:	0f bf d0             	movswl %ax,%edx
80106300:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106303:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106307:	89 54 24 08          	mov    %edx,0x8(%esp)
8010630b:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106312:	00 
80106313:	89 04 24             	mov    %eax,(%esp)
80106316:	e8 95 fb ff ff       	call   80105eb0 <create>
8010631b:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010631e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106322:	75 0c                	jne    80106330 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
80106324:	e8 86 d2 ff ff       	call   801035af <end_op>
    return -1;
80106329:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010632e:	eb 15                	jmp    80106345 <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106330:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106333:	89 04 24             	mov    %eax,(%esp)
80106336:	e8 a4 b7 ff ff       	call   80101adf <iunlockput>
  end_op();
8010633b:	e8 6f d2 ff ff       	call   801035af <end_op>
  return 0;
80106340:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106345:	c9                   	leave  
80106346:	c3                   	ret    

80106347 <sys_chdir>:

int
sys_chdir(void)
{
80106347:	55                   	push   %ebp
80106348:	89 e5                	mov    %esp,%ebp
8010634a:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
8010634d:	e8 d9 d1 ff ff       	call   8010352b <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80106352:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106355:	89 44 24 04          	mov    %eax,0x4(%esp)
80106359:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106360:	e8 fd f3 ff ff       	call   80105762 <argstr>
80106365:	85 c0                	test   %eax,%eax
80106367:	78 14                	js     8010637d <sys_chdir+0x36>
80106369:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010636c:	89 04 24             	mov    %eax,(%esp)
8010636f:	e8 ad c1 ff ff       	call   80102521 <namei>
80106374:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106377:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010637b:	75 0f                	jne    8010638c <sys_chdir+0x45>
    end_op();
8010637d:	e8 2d d2 ff ff       	call   801035af <end_op>
    return -1;
80106382:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106387:	e9 a2 00 00 00       	jmp    8010642e <sys_chdir+0xe7>
  }
  ilock(ip);
8010638c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010638f:	89 04 24             	mov    %eax,(%esp)
80106392:	e8 c4 b4 ff ff       	call   8010185b <ilock>
  if(ip->type != T_DIR && !IS_DEV_DIR(ip)) {
80106397:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010639a:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010639e:	66 83 f8 01          	cmp    $0x1,%ax
801063a2:	74 58                	je     801063fc <sys_chdir+0xb5>
801063a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063a7:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801063ab:	66 83 f8 03          	cmp    $0x3,%ax
801063af:	75 34                	jne    801063e5 <sys_chdir+0x9e>
801063b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063b4:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801063b8:	98                   	cwtl   
801063b9:	c1 e0 04             	shl    $0x4,%eax
801063bc:	05 e0 11 11 80       	add    $0x801111e0,%eax
801063c1:	8b 00                	mov    (%eax),%eax
801063c3:	85 c0                	test   %eax,%eax
801063c5:	74 1e                	je     801063e5 <sys_chdir+0x9e>
801063c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063ca:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801063ce:	98                   	cwtl   
801063cf:	c1 e0 04             	shl    $0x4,%eax
801063d2:	05 e0 11 11 80       	add    $0x801111e0,%eax
801063d7:	8b 00                	mov    (%eax),%eax
801063d9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801063dc:	89 14 24             	mov    %edx,(%esp)
801063df:	ff d0                	call   *%eax
801063e1:	85 c0                	test   %eax,%eax
801063e3:	75 17                	jne    801063fc <sys_chdir+0xb5>
    iunlockput(ip);
801063e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063e8:	89 04 24             	mov    %eax,(%esp)
801063eb:	e8 ef b6 ff ff       	call   80101adf <iunlockput>
    end_op();
801063f0:	e8 ba d1 ff ff       	call   801035af <end_op>
    return -1;
801063f5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063fa:	eb 32                	jmp    8010642e <sys_chdir+0xe7>
  }
  iunlock(ip);
801063fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063ff:	89 04 24             	mov    %eax,(%esp)
80106402:	e8 a2 b5 ff ff       	call   801019a9 <iunlock>
  iput(proc->cwd);
80106407:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010640d:	8b 40 68             	mov    0x68(%eax),%eax
80106410:	89 04 24             	mov    %eax,(%esp)
80106413:	e8 f6 b5 ff ff       	call   80101a0e <iput>
  end_op();
80106418:	e8 92 d1 ff ff       	call   801035af <end_op>
  proc->cwd = ip;
8010641d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106423:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106426:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80106429:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010642e:	c9                   	leave  
8010642f:	c3                   	ret    

80106430 <sys_exec>:

int
sys_exec(void)
{
80106430:	55                   	push   %ebp
80106431:	89 e5                	mov    %esp,%ebp
80106433:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106439:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010643c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106440:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106447:	e8 16 f3 ff ff       	call   80105762 <argstr>
8010644c:	85 c0                	test   %eax,%eax
8010644e:	78 1a                	js     8010646a <sys_exec+0x3a>
80106450:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80106456:	89 44 24 04          	mov    %eax,0x4(%esp)
8010645a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106461:	e8 6c f2 ff ff       	call   801056d2 <argint>
80106466:	85 c0                	test   %eax,%eax
80106468:	79 0a                	jns    80106474 <sys_exec+0x44>
    return -1;
8010646a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010646f:	e9 c8 00 00 00       	jmp    8010653c <sys_exec+0x10c>
  }
  memset(argv, 0, sizeof(argv));
80106474:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010647b:	00 
8010647c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106483:	00 
80106484:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
8010648a:	89 04 24             	mov    %eax,(%esp)
8010648d:	e8 fe ee ff ff       	call   80105390 <memset>
  for(i=0;; i++){
80106492:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106499:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010649c:	83 f8 1f             	cmp    $0x1f,%eax
8010649f:	76 0a                	jbe    801064ab <sys_exec+0x7b>
      return -1;
801064a1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064a6:	e9 91 00 00 00       	jmp    8010653c <sys_exec+0x10c>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
801064ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064ae:	c1 e0 02             	shl    $0x2,%eax
801064b1:	89 c2                	mov    %eax,%edx
801064b3:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
801064b9:	01 c2                	add    %eax,%edx
801064bb:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
801064c1:	89 44 24 04          	mov    %eax,0x4(%esp)
801064c5:	89 14 24             	mov    %edx,(%esp)
801064c8:	e8 69 f1 ff ff       	call   80105636 <fetchint>
801064cd:	85 c0                	test   %eax,%eax
801064cf:	79 07                	jns    801064d8 <sys_exec+0xa8>
      return -1;
801064d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064d6:	eb 64                	jmp    8010653c <sys_exec+0x10c>
    if(uarg == 0){
801064d8:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
801064de:	85 c0                	test   %eax,%eax
801064e0:	75 26                	jne    80106508 <sys_exec+0xd8>
      argv[i] = 0;
801064e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064e5:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
801064ec:	00 00 00 00 
      break;
801064f0:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
801064f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064f4:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
801064fa:	89 54 24 04          	mov    %edx,0x4(%esp)
801064fe:	89 04 24             	mov    %eax,(%esp)
80106501:	e8 e9 a5 ff ff       	call   80100aef <exec>
80106506:	eb 34                	jmp    8010653c <sys_exec+0x10c>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80106508:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
8010650e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106511:	c1 e2 02             	shl    $0x2,%edx
80106514:	01 c2                	add    %eax,%edx
80106516:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
8010651c:	89 54 24 04          	mov    %edx,0x4(%esp)
80106520:	89 04 24             	mov    %eax,(%esp)
80106523:	e8 48 f1 ff ff       	call   80105670 <fetchstr>
80106528:	85 c0                	test   %eax,%eax
8010652a:	79 07                	jns    80106533 <sys_exec+0x103>
      return -1;
8010652c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106531:	eb 09                	jmp    8010653c <sys_exec+0x10c>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106533:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
80106537:	e9 5d ff ff ff       	jmp    80106499 <sys_exec+0x69>
  return exec(path, argv);
}
8010653c:	c9                   	leave  
8010653d:	c3                   	ret    

8010653e <sys_pipe>:

int
sys_pipe(void)
{
8010653e:	55                   	push   %ebp
8010653f:	89 e5                	mov    %esp,%ebp
80106541:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106544:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
8010654b:	00 
8010654c:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010654f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106553:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010655a:	e8 a1 f1 ff ff       	call   80105700 <argptr>
8010655f:	85 c0                	test   %eax,%eax
80106561:	79 0a                	jns    8010656d <sys_pipe+0x2f>
    return -1;
80106563:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106568:	e9 9b 00 00 00       	jmp    80106608 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
8010656d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106570:	89 44 24 04          	mov    %eax,0x4(%esp)
80106574:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106577:	89 04 24             	mov    %eax,(%esp)
8010657a:	e8 c2 da ff ff       	call   80104041 <pipealloc>
8010657f:	85 c0                	test   %eax,%eax
80106581:	79 07                	jns    8010658a <sys_pipe+0x4c>
    return -1;
80106583:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106588:	eb 7e                	jmp    80106608 <sys_pipe+0xca>
  fd0 = -1;
8010658a:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106591:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106594:	89 04 24             	mov    %eax,(%esp)
80106597:	e8 01 f3 ff ff       	call   8010589d <fdalloc>
8010659c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010659f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801065a3:	78 14                	js     801065b9 <sys_pipe+0x7b>
801065a5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801065a8:	89 04 24             	mov    %eax,(%esp)
801065ab:	e8 ed f2 ff ff       	call   8010589d <fdalloc>
801065b0:	89 45 f0             	mov    %eax,-0x10(%ebp)
801065b3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801065b7:	79 37                	jns    801065f0 <sys_pipe+0xb2>
    if(fd0 >= 0)
801065b9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801065bd:	78 14                	js     801065d3 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
801065bf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801065c5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801065c8:	83 c2 08             	add    $0x8,%edx
801065cb:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801065d2:	00 
    fileclose(rf);
801065d3:	8b 45 e8             	mov    -0x18(%ebp),%eax
801065d6:	89 04 24             	mov    %eax,(%esp)
801065d9:	e8 f0 a9 ff ff       	call   80100fce <fileclose>
    fileclose(wf);
801065de:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801065e1:	89 04 24             	mov    %eax,(%esp)
801065e4:	e8 e5 a9 ff ff       	call   80100fce <fileclose>
    return -1;
801065e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065ee:	eb 18                	jmp    80106608 <sys_pipe+0xca>
  }
  fd[0] = fd0;
801065f0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801065f3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801065f6:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
801065f8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801065fb:	8d 50 04             	lea    0x4(%eax),%edx
801065fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106601:	89 02                	mov    %eax,(%edx)
  return 0;
80106603:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106608:	c9                   	leave  
80106609:	c3                   	ret    

8010660a <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
8010660a:	55                   	push   %ebp
8010660b:	89 e5                	mov    %esp,%ebp
8010660d:	83 ec 08             	sub    $0x8,%esp
  return fork();
80106610:	e8 d7 e0 ff ff       	call   801046ec <fork>
}
80106615:	c9                   	leave  
80106616:	c3                   	ret    

80106617 <sys_exit>:

int
sys_exit(void)
{
80106617:	55                   	push   %ebp
80106618:	89 e5                	mov    %esp,%ebp
8010661a:	83 ec 08             	sub    $0x8,%esp
  exit();
8010661d:	e8 45 e2 ff ff       	call   80104867 <exit>
  return 0;  // not reached
80106622:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106627:	c9                   	leave  
80106628:	c3                   	ret    

80106629 <sys_wait>:

int
sys_wait(void)
{
80106629:	55                   	push   %ebp
8010662a:	89 e5                	mov    %esp,%ebp
8010662c:	83 ec 08             	sub    $0x8,%esp
  return wait();
8010662f:	e8 55 e3 ff ff       	call   80104989 <wait>
}
80106634:	c9                   	leave  
80106635:	c3                   	ret    

80106636 <sys_kill>:

int
sys_kill(void)
{
80106636:	55                   	push   %ebp
80106637:	89 e5                	mov    %esp,%ebp
80106639:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
8010663c:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010663f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106643:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010664a:	e8 83 f0 ff ff       	call   801056d2 <argint>
8010664f:	85 c0                	test   %eax,%eax
80106651:	79 07                	jns    8010665a <sys_kill+0x24>
    return -1;
80106653:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106658:	eb 0b                	jmp    80106665 <sys_kill+0x2f>
  return kill(pid);
8010665a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010665d:	89 04 24             	mov    %eax,(%esp)
80106660:	e8 df e6 ff ff       	call   80104d44 <kill>
}
80106665:	c9                   	leave  
80106666:	c3                   	ret    

80106667 <sys_getpid>:

int
sys_getpid(void)
{
80106667:	55                   	push   %ebp
80106668:	89 e5                	mov    %esp,%ebp
  return proc->pid;
8010666a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106670:	8b 40 10             	mov    0x10(%eax),%eax
}
80106673:	5d                   	pop    %ebp
80106674:	c3                   	ret    

80106675 <sys_sbrk>:

int
sys_sbrk(void)
{
80106675:	55                   	push   %ebp
80106676:	89 e5                	mov    %esp,%ebp
80106678:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
8010667b:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010667e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106682:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106689:	e8 44 f0 ff ff       	call   801056d2 <argint>
8010668e:	85 c0                	test   %eax,%eax
80106690:	79 07                	jns    80106699 <sys_sbrk+0x24>
    return -1;
80106692:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106697:	eb 24                	jmp    801066bd <sys_sbrk+0x48>
  addr = proc->sz;
80106699:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010669f:	8b 00                	mov    (%eax),%eax
801066a1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
801066a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066a7:	89 04 24             	mov    %eax,(%esp)
801066aa:	e8 98 df ff ff       	call   80104647 <growproc>
801066af:	85 c0                	test   %eax,%eax
801066b1:	79 07                	jns    801066ba <sys_sbrk+0x45>
    return -1;
801066b3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801066b8:	eb 03                	jmp    801066bd <sys_sbrk+0x48>
  return addr;
801066ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801066bd:	c9                   	leave  
801066be:	c3                   	ret    

801066bf <sys_sleep>:

int
sys_sleep(void)
{
801066bf:	55                   	push   %ebp
801066c0:	89 e5                	mov    %esp,%ebp
801066c2:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
801066c5:	8d 45 f0             	lea    -0x10(%ebp),%eax
801066c8:	89 44 24 04          	mov    %eax,0x4(%esp)
801066cc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801066d3:	e8 fa ef ff ff       	call   801056d2 <argint>
801066d8:	85 c0                	test   %eax,%eax
801066da:	79 07                	jns    801066e3 <sys_sleep+0x24>
    return -1;
801066dc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801066e1:	eb 6c                	jmp    8010674f <sys_sleep+0x90>
  acquire(&tickslock);
801066e3:	c7 04 24 e0 48 11 80 	movl   $0x801148e0,(%esp)
801066ea:	e8 4d ea ff ff       	call   8010513c <acquire>
  ticks0 = ticks;
801066ef:	a1 20 51 11 80       	mov    0x80115120,%eax
801066f4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
801066f7:	eb 34                	jmp    8010672d <sys_sleep+0x6e>
    if(proc->killed){
801066f9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801066ff:	8b 40 24             	mov    0x24(%eax),%eax
80106702:	85 c0                	test   %eax,%eax
80106704:	74 13                	je     80106719 <sys_sleep+0x5a>
      release(&tickslock);
80106706:	c7 04 24 e0 48 11 80 	movl   $0x801148e0,(%esp)
8010670d:	e8 8c ea ff ff       	call   8010519e <release>
      return -1;
80106712:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106717:	eb 36                	jmp    8010674f <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80106719:	c7 44 24 04 e0 48 11 	movl   $0x801148e0,0x4(%esp)
80106720:	80 
80106721:	c7 04 24 20 51 11 80 	movl   $0x80115120,(%esp)
80106728:	e8 13 e5 ff ff       	call   80104c40 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
8010672d:	a1 20 51 11 80       	mov    0x80115120,%eax
80106732:	2b 45 f4             	sub    -0xc(%ebp),%eax
80106735:	89 c2                	mov    %eax,%edx
80106737:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010673a:	39 c2                	cmp    %eax,%edx
8010673c:	72 bb                	jb     801066f9 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
8010673e:	c7 04 24 e0 48 11 80 	movl   $0x801148e0,(%esp)
80106745:	e8 54 ea ff ff       	call   8010519e <release>
  return 0;
8010674a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010674f:	c9                   	leave  
80106750:	c3                   	ret    

80106751 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106751:	55                   	push   %ebp
80106752:	89 e5                	mov    %esp,%ebp
80106754:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80106757:	c7 04 24 e0 48 11 80 	movl   $0x801148e0,(%esp)
8010675e:	e8 d9 e9 ff ff       	call   8010513c <acquire>
  xticks = ticks;
80106763:	a1 20 51 11 80       	mov    0x80115120,%eax
80106768:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
8010676b:	c7 04 24 e0 48 11 80 	movl   $0x801148e0,(%esp)
80106772:	e8 27 ea ff ff       	call   8010519e <release>
  return xticks;
80106777:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010677a:	c9                   	leave  
8010677b:	c3                   	ret    

8010677c <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010677c:	55                   	push   %ebp
8010677d:	89 e5                	mov    %esp,%ebp
8010677f:	83 ec 08             	sub    $0x8,%esp
80106782:	8b 55 08             	mov    0x8(%ebp),%edx
80106785:	8b 45 0c             	mov    0xc(%ebp),%eax
80106788:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010678c:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010678f:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106793:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106797:	ee                   	out    %al,(%dx)
}
80106798:	c9                   	leave  
80106799:	c3                   	ret    

8010679a <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
8010679a:	55                   	push   %ebp
8010679b:	89 e5                	mov    %esp,%ebp
8010679d:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
801067a0:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
801067a7:	00 
801067a8:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
801067af:	e8 c8 ff ff ff       	call   8010677c <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
801067b4:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
801067bb:	00 
801067bc:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801067c3:	e8 b4 ff ff ff       	call   8010677c <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
801067c8:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
801067cf:	00 
801067d0:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801067d7:	e8 a0 ff ff ff       	call   8010677c <outb>
  picenable(IRQ_TIMER);
801067dc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801067e3:	e8 ec d6 ff ff       	call   80103ed4 <picenable>
}
801067e8:	c9                   	leave  
801067e9:	c3                   	ret    

801067ea <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
801067ea:	1e                   	push   %ds
  pushl %es
801067eb:	06                   	push   %es
  pushl %fs
801067ec:	0f a0                	push   %fs
  pushl %gs
801067ee:	0f a8                	push   %gs
  pushal
801067f0:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
801067f1:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
801067f5:	8e d8                	mov    %eax,%ds
  movw %ax, %es
801067f7:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
801067f9:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
801067fd:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
801067ff:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80106801:	54                   	push   %esp
  call trap
80106802:	e8 d8 01 00 00       	call   801069df <trap>
  addl $4, %esp
80106807:	83 c4 04             	add    $0x4,%esp

8010680a <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
8010680a:	61                   	popa   
  popl %gs
8010680b:	0f a9                	pop    %gs
  popl %fs
8010680d:	0f a1                	pop    %fs
  popl %es
8010680f:	07                   	pop    %es
  popl %ds
80106810:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80106811:	83 c4 08             	add    $0x8,%esp
  iret
80106814:	cf                   	iret   

80106815 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80106815:	55                   	push   %ebp
80106816:	89 e5                	mov    %esp,%ebp
80106818:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
8010681b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010681e:	83 e8 01             	sub    $0x1,%eax
80106821:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80106825:	8b 45 08             	mov    0x8(%ebp),%eax
80106828:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010682c:	8b 45 08             	mov    0x8(%ebp),%eax
8010682f:	c1 e8 10             	shr    $0x10,%eax
80106832:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80106836:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106839:	0f 01 18             	lidtl  (%eax)
}
8010683c:	c9                   	leave  
8010683d:	c3                   	ret    

8010683e <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
8010683e:	55                   	push   %ebp
8010683f:	89 e5                	mov    %esp,%ebp
80106841:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80106844:	0f 20 d0             	mov    %cr2,%eax
80106847:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
8010684a:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010684d:	c9                   	leave  
8010684e:	c3                   	ret    

8010684f <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
8010684f:	55                   	push   %ebp
80106850:	89 e5                	mov    %esp,%ebp
80106852:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106855:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010685c:	e9 c3 00 00 00       	jmp    80106924 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80106861:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106864:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
8010686b:	89 c2                	mov    %eax,%edx
8010686d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106870:	66 89 14 c5 20 49 11 	mov    %dx,-0x7feeb6e0(,%eax,8)
80106877:	80 
80106878:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010687b:	66 c7 04 c5 22 49 11 	movw   $0x8,-0x7feeb6de(,%eax,8)
80106882:	80 08 00 
80106885:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106888:	0f b6 14 c5 24 49 11 	movzbl -0x7feeb6dc(,%eax,8),%edx
8010688f:	80 
80106890:	83 e2 e0             	and    $0xffffffe0,%edx
80106893:	88 14 c5 24 49 11 80 	mov    %dl,-0x7feeb6dc(,%eax,8)
8010689a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010689d:	0f b6 14 c5 24 49 11 	movzbl -0x7feeb6dc(,%eax,8),%edx
801068a4:	80 
801068a5:	83 e2 1f             	and    $0x1f,%edx
801068a8:	88 14 c5 24 49 11 80 	mov    %dl,-0x7feeb6dc(,%eax,8)
801068af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068b2:	0f b6 14 c5 25 49 11 	movzbl -0x7feeb6db(,%eax,8),%edx
801068b9:	80 
801068ba:	83 e2 f0             	and    $0xfffffff0,%edx
801068bd:	83 ca 0e             	or     $0xe,%edx
801068c0:	88 14 c5 25 49 11 80 	mov    %dl,-0x7feeb6db(,%eax,8)
801068c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068ca:	0f b6 14 c5 25 49 11 	movzbl -0x7feeb6db(,%eax,8),%edx
801068d1:	80 
801068d2:	83 e2 ef             	and    $0xffffffef,%edx
801068d5:	88 14 c5 25 49 11 80 	mov    %dl,-0x7feeb6db(,%eax,8)
801068dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068df:	0f b6 14 c5 25 49 11 	movzbl -0x7feeb6db(,%eax,8),%edx
801068e6:	80 
801068e7:	83 e2 9f             	and    $0xffffff9f,%edx
801068ea:	88 14 c5 25 49 11 80 	mov    %dl,-0x7feeb6db(,%eax,8)
801068f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068f4:	0f b6 14 c5 25 49 11 	movzbl -0x7feeb6db(,%eax,8),%edx
801068fb:	80 
801068fc:	83 ca 80             	or     $0xffffff80,%edx
801068ff:	88 14 c5 25 49 11 80 	mov    %dl,-0x7feeb6db(,%eax,8)
80106906:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106909:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
80106910:	c1 e8 10             	shr    $0x10,%eax
80106913:	89 c2                	mov    %eax,%edx
80106915:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106918:	66 89 14 c5 26 49 11 	mov    %dx,-0x7feeb6da(,%eax,8)
8010691f:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106920:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106924:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
8010692b:	0f 8e 30 ff ff ff    	jle    80106861 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106931:	a1 98 b1 10 80       	mov    0x8010b198,%eax
80106936:	66 a3 20 4b 11 80    	mov    %ax,0x80114b20
8010693c:	66 c7 05 22 4b 11 80 	movw   $0x8,0x80114b22
80106943:	08 00 
80106945:	0f b6 05 24 4b 11 80 	movzbl 0x80114b24,%eax
8010694c:	83 e0 e0             	and    $0xffffffe0,%eax
8010694f:	a2 24 4b 11 80       	mov    %al,0x80114b24
80106954:	0f b6 05 24 4b 11 80 	movzbl 0x80114b24,%eax
8010695b:	83 e0 1f             	and    $0x1f,%eax
8010695e:	a2 24 4b 11 80       	mov    %al,0x80114b24
80106963:	0f b6 05 25 4b 11 80 	movzbl 0x80114b25,%eax
8010696a:	83 c8 0f             	or     $0xf,%eax
8010696d:	a2 25 4b 11 80       	mov    %al,0x80114b25
80106972:	0f b6 05 25 4b 11 80 	movzbl 0x80114b25,%eax
80106979:	83 e0 ef             	and    $0xffffffef,%eax
8010697c:	a2 25 4b 11 80       	mov    %al,0x80114b25
80106981:	0f b6 05 25 4b 11 80 	movzbl 0x80114b25,%eax
80106988:	83 c8 60             	or     $0x60,%eax
8010698b:	a2 25 4b 11 80       	mov    %al,0x80114b25
80106990:	0f b6 05 25 4b 11 80 	movzbl 0x80114b25,%eax
80106997:	83 c8 80             	or     $0xffffff80,%eax
8010699a:	a2 25 4b 11 80       	mov    %al,0x80114b25
8010699f:	a1 98 b1 10 80       	mov    0x8010b198,%eax
801069a4:	c1 e8 10             	shr    $0x10,%eax
801069a7:	66 a3 26 4b 11 80    	mov    %ax,0x80114b26
  
  initlock(&tickslock, "time");
801069ad:	c7 44 24 04 e0 8b 10 	movl   $0x80108be0,0x4(%esp)
801069b4:	80 
801069b5:	c7 04 24 e0 48 11 80 	movl   $0x801148e0,(%esp)
801069bc:	e8 5a e7 ff ff       	call   8010511b <initlock>
}
801069c1:	c9                   	leave  
801069c2:	c3                   	ret    

801069c3 <idtinit>:

void
idtinit(void)
{
801069c3:	55                   	push   %ebp
801069c4:	89 e5                	mov    %esp,%ebp
801069c6:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
801069c9:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
801069d0:	00 
801069d1:	c7 04 24 20 49 11 80 	movl   $0x80114920,(%esp)
801069d8:	e8 38 fe ff ff       	call   80106815 <lidt>
}
801069dd:	c9                   	leave  
801069de:	c3                   	ret    

801069df <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
801069df:	55                   	push   %ebp
801069e0:	89 e5                	mov    %esp,%ebp
801069e2:	57                   	push   %edi
801069e3:	56                   	push   %esi
801069e4:	53                   	push   %ebx
801069e5:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
801069e8:	8b 45 08             	mov    0x8(%ebp),%eax
801069eb:	8b 40 30             	mov    0x30(%eax),%eax
801069ee:	83 f8 40             	cmp    $0x40,%eax
801069f1:	75 3f                	jne    80106a32 <trap+0x53>
    if(proc->killed)
801069f3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801069f9:	8b 40 24             	mov    0x24(%eax),%eax
801069fc:	85 c0                	test   %eax,%eax
801069fe:	74 05                	je     80106a05 <trap+0x26>
      exit();
80106a00:	e8 62 de ff ff       	call   80104867 <exit>
    proc->tf = tf;
80106a05:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a0b:	8b 55 08             	mov    0x8(%ebp),%edx
80106a0e:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80106a11:	e8 83 ed ff ff       	call   80105799 <syscall>
    if(proc->killed)
80106a16:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a1c:	8b 40 24             	mov    0x24(%eax),%eax
80106a1f:	85 c0                	test   %eax,%eax
80106a21:	74 0a                	je     80106a2d <trap+0x4e>
      exit();
80106a23:	e8 3f de ff ff       	call   80104867 <exit>
    return;
80106a28:	e9 2d 02 00 00       	jmp    80106c5a <trap+0x27b>
80106a2d:	e9 28 02 00 00       	jmp    80106c5a <trap+0x27b>
  }

  switch(tf->trapno){
80106a32:	8b 45 08             	mov    0x8(%ebp),%eax
80106a35:	8b 40 30             	mov    0x30(%eax),%eax
80106a38:	83 e8 20             	sub    $0x20,%eax
80106a3b:	83 f8 1f             	cmp    $0x1f,%eax
80106a3e:	0f 87 bc 00 00 00    	ja     80106b00 <trap+0x121>
80106a44:	8b 04 85 88 8c 10 80 	mov    -0x7fef7378(,%eax,4),%eax
80106a4b:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
80106a4d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106a53:	0f b6 00             	movzbl (%eax),%eax
80106a56:	84 c0                	test   %al,%al
80106a58:	75 31                	jne    80106a8b <trap+0xac>
      acquire(&tickslock);
80106a5a:	c7 04 24 e0 48 11 80 	movl   $0x801148e0,(%esp)
80106a61:	e8 d6 e6 ff ff       	call   8010513c <acquire>
      ticks++;
80106a66:	a1 20 51 11 80       	mov    0x80115120,%eax
80106a6b:	83 c0 01             	add    $0x1,%eax
80106a6e:	a3 20 51 11 80       	mov    %eax,0x80115120
      wakeup(&ticks);
80106a73:	c7 04 24 20 51 11 80 	movl   $0x80115120,(%esp)
80106a7a:	e8 9a e2 ff ff       	call   80104d19 <wakeup>
      release(&tickslock);
80106a7f:	c7 04 24 e0 48 11 80 	movl   $0x801148e0,(%esp)
80106a86:	e8 13 e7 ff ff       	call   8010519e <release>
    }
    lapiceoi();
80106a8b:	e8 5b c5 ff ff       	call   80102feb <lapiceoi>
    break;
80106a90:	e9 41 01 00 00       	jmp    80106bd6 <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80106a95:	e8 5f bd ff ff       	call   801027f9 <ideintr>
    lapiceoi();
80106a9a:	e8 4c c5 ff ff       	call   80102feb <lapiceoi>
    break;
80106a9f:	e9 32 01 00 00       	jmp    80106bd6 <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
80106aa4:	e8 11 c3 ff ff       	call   80102dba <kbdintr>
    lapiceoi();
80106aa9:	e8 3d c5 ff ff       	call   80102feb <lapiceoi>
    break;
80106aae:	e9 23 01 00 00       	jmp    80106bd6 <trap+0x1f7>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
80106ab3:	e8 97 03 00 00       	call   80106e4f <uartintr>
    lapiceoi();
80106ab8:	e8 2e c5 ff ff       	call   80102feb <lapiceoi>
    break;
80106abd:	e9 14 01 00 00       	jmp    80106bd6 <trap+0x1f7>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106ac2:	8b 45 08             	mov    0x8(%ebp),%eax
80106ac5:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80106ac8:	8b 45 08             	mov    0x8(%ebp),%eax
80106acb:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106acf:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80106ad2:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106ad8:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106adb:	0f b6 c0             	movzbl %al,%eax
80106ade:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106ae2:	89 54 24 08          	mov    %edx,0x8(%esp)
80106ae6:	89 44 24 04          	mov    %eax,0x4(%esp)
80106aea:	c7 04 24 e8 8b 10 80 	movl   $0x80108be8,(%esp)
80106af1:	e8 aa 98 ff ff       	call   801003a0 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80106af6:	e8 f0 c4 ff ff       	call   80102feb <lapiceoi>
    break;
80106afb:	e9 d6 00 00 00       	jmp    80106bd6 <trap+0x1f7>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80106b00:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b06:	85 c0                	test   %eax,%eax
80106b08:	74 11                	je     80106b1b <trap+0x13c>
80106b0a:	8b 45 08             	mov    0x8(%ebp),%eax
80106b0d:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106b11:	0f b7 c0             	movzwl %ax,%eax
80106b14:	83 e0 03             	and    $0x3,%eax
80106b17:	85 c0                	test   %eax,%eax
80106b19:	75 46                	jne    80106b61 <trap+0x182>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106b1b:	e8 1e fd ff ff       	call   8010683e <rcr2>
80106b20:	8b 55 08             	mov    0x8(%ebp),%edx
80106b23:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106b26:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80106b2d:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106b30:	0f b6 ca             	movzbl %dl,%ecx
80106b33:	8b 55 08             	mov    0x8(%ebp),%edx
80106b36:	8b 52 30             	mov    0x30(%edx),%edx
80106b39:	89 44 24 10          	mov    %eax,0x10(%esp)
80106b3d:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80106b41:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106b45:	89 54 24 04          	mov    %edx,0x4(%esp)
80106b49:	c7 04 24 0c 8c 10 80 	movl   $0x80108c0c,(%esp)
80106b50:	e8 4b 98 ff ff       	call   801003a0 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80106b55:	c7 04 24 3e 8c 10 80 	movl   $0x80108c3e,(%esp)
80106b5c:	e8 d9 99 ff ff       	call   8010053a <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106b61:	e8 d8 fc ff ff       	call   8010683e <rcr2>
80106b66:	89 c2                	mov    %eax,%edx
80106b68:	8b 45 08             	mov    0x8(%ebp),%eax
80106b6b:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106b6e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106b74:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106b77:	0f b6 f0             	movzbl %al,%esi
80106b7a:	8b 45 08             	mov    0x8(%ebp),%eax
80106b7d:	8b 58 34             	mov    0x34(%eax),%ebx
80106b80:	8b 45 08             	mov    0x8(%ebp),%eax
80106b83:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106b86:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b8c:	83 c0 6c             	add    $0x6c,%eax
80106b8f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106b92:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106b98:	8b 40 10             	mov    0x10(%eax),%eax
80106b9b:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80106b9f:	89 7c 24 18          	mov    %edi,0x18(%esp)
80106ba3:	89 74 24 14          	mov    %esi,0x14(%esp)
80106ba7:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80106bab:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106baf:	8b 75 e4             	mov    -0x1c(%ebp),%esi
80106bb2:	89 74 24 08          	mov    %esi,0x8(%esp)
80106bb6:	89 44 24 04          	mov    %eax,0x4(%esp)
80106bba:	c7 04 24 44 8c 10 80 	movl   $0x80108c44,(%esp)
80106bc1:	e8 da 97 ff ff       	call   801003a0 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80106bc6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106bcc:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80106bd3:	eb 01                	jmp    80106bd6 <trap+0x1f7>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80106bd5:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106bd6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106bdc:	85 c0                	test   %eax,%eax
80106bde:	74 24                	je     80106c04 <trap+0x225>
80106be0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106be6:	8b 40 24             	mov    0x24(%eax),%eax
80106be9:	85 c0                	test   %eax,%eax
80106beb:	74 17                	je     80106c04 <trap+0x225>
80106bed:	8b 45 08             	mov    0x8(%ebp),%eax
80106bf0:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106bf4:	0f b7 c0             	movzwl %ax,%eax
80106bf7:	83 e0 03             	and    $0x3,%eax
80106bfa:	83 f8 03             	cmp    $0x3,%eax
80106bfd:	75 05                	jne    80106c04 <trap+0x225>
    exit();
80106bff:	e8 63 dc ff ff       	call   80104867 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80106c04:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106c0a:	85 c0                	test   %eax,%eax
80106c0c:	74 1e                	je     80106c2c <trap+0x24d>
80106c0e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106c14:	8b 40 0c             	mov    0xc(%eax),%eax
80106c17:	83 f8 04             	cmp    $0x4,%eax
80106c1a:	75 10                	jne    80106c2c <trap+0x24d>
80106c1c:	8b 45 08             	mov    0x8(%ebp),%eax
80106c1f:	8b 40 30             	mov    0x30(%eax),%eax
80106c22:	83 f8 20             	cmp    $0x20,%eax
80106c25:	75 05                	jne    80106c2c <trap+0x24d>
    yield();
80106c27:	e8 b6 df ff ff       	call   80104be2 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106c2c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106c32:	85 c0                	test   %eax,%eax
80106c34:	74 24                	je     80106c5a <trap+0x27b>
80106c36:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106c3c:	8b 40 24             	mov    0x24(%eax),%eax
80106c3f:	85 c0                	test   %eax,%eax
80106c41:	74 17                	je     80106c5a <trap+0x27b>
80106c43:	8b 45 08             	mov    0x8(%ebp),%eax
80106c46:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106c4a:	0f b7 c0             	movzwl %ax,%eax
80106c4d:	83 e0 03             	and    $0x3,%eax
80106c50:	83 f8 03             	cmp    $0x3,%eax
80106c53:	75 05                	jne    80106c5a <trap+0x27b>
    exit();
80106c55:	e8 0d dc ff ff       	call   80104867 <exit>
}
80106c5a:	83 c4 3c             	add    $0x3c,%esp
80106c5d:	5b                   	pop    %ebx
80106c5e:	5e                   	pop    %esi
80106c5f:	5f                   	pop    %edi
80106c60:	5d                   	pop    %ebp
80106c61:	c3                   	ret    

80106c62 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80106c62:	55                   	push   %ebp
80106c63:	89 e5                	mov    %esp,%ebp
80106c65:	83 ec 14             	sub    $0x14,%esp
80106c68:	8b 45 08             	mov    0x8(%ebp),%eax
80106c6b:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80106c6f:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80106c73:	89 c2                	mov    %eax,%edx
80106c75:	ec                   	in     (%dx),%al
80106c76:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80106c79:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80106c7d:	c9                   	leave  
80106c7e:	c3                   	ret    

80106c7f <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106c7f:	55                   	push   %ebp
80106c80:	89 e5                	mov    %esp,%ebp
80106c82:	83 ec 08             	sub    $0x8,%esp
80106c85:	8b 55 08             	mov    0x8(%ebp),%edx
80106c88:	8b 45 0c             	mov    0xc(%ebp),%eax
80106c8b:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106c8f:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106c92:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106c96:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106c9a:	ee                   	out    %al,(%dx)
}
80106c9b:	c9                   	leave  
80106c9c:	c3                   	ret    

80106c9d <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80106c9d:	55                   	push   %ebp
80106c9e:	89 e5                	mov    %esp,%ebp
80106ca0:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80106ca3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106caa:	00 
80106cab:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106cb2:	e8 c8 ff ff ff       	call   80106c7f <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80106cb7:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80106cbe:	00 
80106cbf:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106cc6:	e8 b4 ff ff ff       	call   80106c7f <outb>
  outb(COM1+0, 115200/9600);
80106ccb:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80106cd2:	00 
80106cd3:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106cda:	e8 a0 ff ff ff       	call   80106c7f <outb>
  outb(COM1+1, 0);
80106cdf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106ce6:	00 
80106ce7:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106cee:	e8 8c ff ff ff       	call   80106c7f <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80106cf3:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106cfa:	00 
80106cfb:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106d02:	e8 78 ff ff ff       	call   80106c7f <outb>
  outb(COM1+4, 0);
80106d07:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106d0e:	00 
80106d0f:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80106d16:	e8 64 ff ff ff       	call   80106c7f <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80106d1b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106d22:	00 
80106d23:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106d2a:	e8 50 ff ff ff       	call   80106c7f <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80106d2f:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106d36:	e8 27 ff ff ff       	call   80106c62 <inb>
80106d3b:	3c ff                	cmp    $0xff,%al
80106d3d:	75 02                	jne    80106d41 <uartinit+0xa4>
    return;
80106d3f:	eb 6a                	jmp    80106dab <uartinit+0x10e>
  uart = 1;
80106d41:	c7 05 4c b6 10 80 01 	movl   $0x1,0x8010b64c
80106d48:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80106d4b:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106d52:	e8 0b ff ff ff       	call   80106c62 <inb>
  inb(COM1+0);
80106d57:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106d5e:	e8 ff fe ff ff       	call   80106c62 <inb>
  picenable(IRQ_COM1);
80106d63:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106d6a:	e8 65 d1 ff ff       	call   80103ed4 <picenable>
  ioapicenable(IRQ_COM1, 0);
80106d6f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106d76:	00 
80106d77:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106d7e:	e8 f5 bc ff ff       	call   80102a78 <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106d83:	c7 45 f4 08 8d 10 80 	movl   $0x80108d08,-0xc(%ebp)
80106d8a:	eb 15                	jmp    80106da1 <uartinit+0x104>
    uartputc(*p);
80106d8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d8f:	0f b6 00             	movzbl (%eax),%eax
80106d92:	0f be c0             	movsbl %al,%eax
80106d95:	89 04 24             	mov    %eax,(%esp)
80106d98:	e8 10 00 00 00       	call   80106dad <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106d9d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106da1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106da4:	0f b6 00             	movzbl (%eax),%eax
80106da7:	84 c0                	test   %al,%al
80106da9:	75 e1                	jne    80106d8c <uartinit+0xef>
    uartputc(*p);
}
80106dab:	c9                   	leave  
80106dac:	c3                   	ret    

80106dad <uartputc>:

void
uartputc(int c)
{
80106dad:	55                   	push   %ebp
80106dae:	89 e5                	mov    %esp,%ebp
80106db0:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80106db3:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80106db8:	85 c0                	test   %eax,%eax
80106dba:	75 02                	jne    80106dbe <uartputc+0x11>
    return;
80106dbc:	eb 4b                	jmp    80106e09 <uartputc+0x5c>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106dbe:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106dc5:	eb 10                	jmp    80106dd7 <uartputc+0x2a>
    microdelay(10);
80106dc7:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80106dce:	e8 3d c2 ff ff       	call   80103010 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106dd3:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106dd7:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80106ddb:	7f 16                	jg     80106df3 <uartputc+0x46>
80106ddd:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106de4:	e8 79 fe ff ff       	call   80106c62 <inb>
80106de9:	0f b6 c0             	movzbl %al,%eax
80106dec:	83 e0 20             	and    $0x20,%eax
80106def:	85 c0                	test   %eax,%eax
80106df1:	74 d4                	je     80106dc7 <uartputc+0x1a>
    microdelay(10);
  outb(COM1+0, c);
80106df3:	8b 45 08             	mov    0x8(%ebp),%eax
80106df6:	0f b6 c0             	movzbl %al,%eax
80106df9:	89 44 24 04          	mov    %eax,0x4(%esp)
80106dfd:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106e04:	e8 76 fe ff ff       	call   80106c7f <outb>
}
80106e09:	c9                   	leave  
80106e0a:	c3                   	ret    

80106e0b <uartgetc>:

static int
uartgetc(void)
{
80106e0b:	55                   	push   %ebp
80106e0c:	89 e5                	mov    %esp,%ebp
80106e0e:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80106e11:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80106e16:	85 c0                	test   %eax,%eax
80106e18:	75 07                	jne    80106e21 <uartgetc+0x16>
    return -1;
80106e1a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106e1f:	eb 2c                	jmp    80106e4d <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80106e21:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106e28:	e8 35 fe ff ff       	call   80106c62 <inb>
80106e2d:	0f b6 c0             	movzbl %al,%eax
80106e30:	83 e0 01             	and    $0x1,%eax
80106e33:	85 c0                	test   %eax,%eax
80106e35:	75 07                	jne    80106e3e <uartgetc+0x33>
    return -1;
80106e37:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106e3c:	eb 0f                	jmp    80106e4d <uartgetc+0x42>
  return inb(COM1+0);
80106e3e:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106e45:	e8 18 fe ff ff       	call   80106c62 <inb>
80106e4a:	0f b6 c0             	movzbl %al,%eax
}
80106e4d:	c9                   	leave  
80106e4e:	c3                   	ret    

80106e4f <uartintr>:

void
uartintr(void)
{
80106e4f:	55                   	push   %ebp
80106e50:	89 e5                	mov    %esp,%ebp
80106e52:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80106e55:	c7 04 24 0b 6e 10 80 	movl   $0x80106e0b,(%esp)
80106e5c:	e8 4c 99 ff ff       	call   801007ad <consoleintr>
}
80106e61:	c9                   	leave  
80106e62:	c3                   	ret    

80106e63 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80106e63:	6a 00                	push   $0x0
  pushl $0
80106e65:	6a 00                	push   $0x0
  jmp alltraps
80106e67:	e9 7e f9 ff ff       	jmp    801067ea <alltraps>

80106e6c <vector1>:
.globl vector1
vector1:
  pushl $0
80106e6c:	6a 00                	push   $0x0
  pushl $1
80106e6e:	6a 01                	push   $0x1
  jmp alltraps
80106e70:	e9 75 f9 ff ff       	jmp    801067ea <alltraps>

80106e75 <vector2>:
.globl vector2
vector2:
  pushl $0
80106e75:	6a 00                	push   $0x0
  pushl $2
80106e77:	6a 02                	push   $0x2
  jmp alltraps
80106e79:	e9 6c f9 ff ff       	jmp    801067ea <alltraps>

80106e7e <vector3>:
.globl vector3
vector3:
  pushl $0
80106e7e:	6a 00                	push   $0x0
  pushl $3
80106e80:	6a 03                	push   $0x3
  jmp alltraps
80106e82:	e9 63 f9 ff ff       	jmp    801067ea <alltraps>

80106e87 <vector4>:
.globl vector4
vector4:
  pushl $0
80106e87:	6a 00                	push   $0x0
  pushl $4
80106e89:	6a 04                	push   $0x4
  jmp alltraps
80106e8b:	e9 5a f9 ff ff       	jmp    801067ea <alltraps>

80106e90 <vector5>:
.globl vector5
vector5:
  pushl $0
80106e90:	6a 00                	push   $0x0
  pushl $5
80106e92:	6a 05                	push   $0x5
  jmp alltraps
80106e94:	e9 51 f9 ff ff       	jmp    801067ea <alltraps>

80106e99 <vector6>:
.globl vector6
vector6:
  pushl $0
80106e99:	6a 00                	push   $0x0
  pushl $6
80106e9b:	6a 06                	push   $0x6
  jmp alltraps
80106e9d:	e9 48 f9 ff ff       	jmp    801067ea <alltraps>

80106ea2 <vector7>:
.globl vector7
vector7:
  pushl $0
80106ea2:	6a 00                	push   $0x0
  pushl $7
80106ea4:	6a 07                	push   $0x7
  jmp alltraps
80106ea6:	e9 3f f9 ff ff       	jmp    801067ea <alltraps>

80106eab <vector8>:
.globl vector8
vector8:
  pushl $8
80106eab:	6a 08                	push   $0x8
  jmp alltraps
80106ead:	e9 38 f9 ff ff       	jmp    801067ea <alltraps>

80106eb2 <vector9>:
.globl vector9
vector9:
  pushl $0
80106eb2:	6a 00                	push   $0x0
  pushl $9
80106eb4:	6a 09                	push   $0x9
  jmp alltraps
80106eb6:	e9 2f f9 ff ff       	jmp    801067ea <alltraps>

80106ebb <vector10>:
.globl vector10
vector10:
  pushl $10
80106ebb:	6a 0a                	push   $0xa
  jmp alltraps
80106ebd:	e9 28 f9 ff ff       	jmp    801067ea <alltraps>

80106ec2 <vector11>:
.globl vector11
vector11:
  pushl $11
80106ec2:	6a 0b                	push   $0xb
  jmp alltraps
80106ec4:	e9 21 f9 ff ff       	jmp    801067ea <alltraps>

80106ec9 <vector12>:
.globl vector12
vector12:
  pushl $12
80106ec9:	6a 0c                	push   $0xc
  jmp alltraps
80106ecb:	e9 1a f9 ff ff       	jmp    801067ea <alltraps>

80106ed0 <vector13>:
.globl vector13
vector13:
  pushl $13
80106ed0:	6a 0d                	push   $0xd
  jmp alltraps
80106ed2:	e9 13 f9 ff ff       	jmp    801067ea <alltraps>

80106ed7 <vector14>:
.globl vector14
vector14:
  pushl $14
80106ed7:	6a 0e                	push   $0xe
  jmp alltraps
80106ed9:	e9 0c f9 ff ff       	jmp    801067ea <alltraps>

80106ede <vector15>:
.globl vector15
vector15:
  pushl $0
80106ede:	6a 00                	push   $0x0
  pushl $15
80106ee0:	6a 0f                	push   $0xf
  jmp alltraps
80106ee2:	e9 03 f9 ff ff       	jmp    801067ea <alltraps>

80106ee7 <vector16>:
.globl vector16
vector16:
  pushl $0
80106ee7:	6a 00                	push   $0x0
  pushl $16
80106ee9:	6a 10                	push   $0x10
  jmp alltraps
80106eeb:	e9 fa f8 ff ff       	jmp    801067ea <alltraps>

80106ef0 <vector17>:
.globl vector17
vector17:
  pushl $17
80106ef0:	6a 11                	push   $0x11
  jmp alltraps
80106ef2:	e9 f3 f8 ff ff       	jmp    801067ea <alltraps>

80106ef7 <vector18>:
.globl vector18
vector18:
  pushl $0
80106ef7:	6a 00                	push   $0x0
  pushl $18
80106ef9:	6a 12                	push   $0x12
  jmp alltraps
80106efb:	e9 ea f8 ff ff       	jmp    801067ea <alltraps>

80106f00 <vector19>:
.globl vector19
vector19:
  pushl $0
80106f00:	6a 00                	push   $0x0
  pushl $19
80106f02:	6a 13                	push   $0x13
  jmp alltraps
80106f04:	e9 e1 f8 ff ff       	jmp    801067ea <alltraps>

80106f09 <vector20>:
.globl vector20
vector20:
  pushl $0
80106f09:	6a 00                	push   $0x0
  pushl $20
80106f0b:	6a 14                	push   $0x14
  jmp alltraps
80106f0d:	e9 d8 f8 ff ff       	jmp    801067ea <alltraps>

80106f12 <vector21>:
.globl vector21
vector21:
  pushl $0
80106f12:	6a 00                	push   $0x0
  pushl $21
80106f14:	6a 15                	push   $0x15
  jmp alltraps
80106f16:	e9 cf f8 ff ff       	jmp    801067ea <alltraps>

80106f1b <vector22>:
.globl vector22
vector22:
  pushl $0
80106f1b:	6a 00                	push   $0x0
  pushl $22
80106f1d:	6a 16                	push   $0x16
  jmp alltraps
80106f1f:	e9 c6 f8 ff ff       	jmp    801067ea <alltraps>

80106f24 <vector23>:
.globl vector23
vector23:
  pushl $0
80106f24:	6a 00                	push   $0x0
  pushl $23
80106f26:	6a 17                	push   $0x17
  jmp alltraps
80106f28:	e9 bd f8 ff ff       	jmp    801067ea <alltraps>

80106f2d <vector24>:
.globl vector24
vector24:
  pushl $0
80106f2d:	6a 00                	push   $0x0
  pushl $24
80106f2f:	6a 18                	push   $0x18
  jmp alltraps
80106f31:	e9 b4 f8 ff ff       	jmp    801067ea <alltraps>

80106f36 <vector25>:
.globl vector25
vector25:
  pushl $0
80106f36:	6a 00                	push   $0x0
  pushl $25
80106f38:	6a 19                	push   $0x19
  jmp alltraps
80106f3a:	e9 ab f8 ff ff       	jmp    801067ea <alltraps>

80106f3f <vector26>:
.globl vector26
vector26:
  pushl $0
80106f3f:	6a 00                	push   $0x0
  pushl $26
80106f41:	6a 1a                	push   $0x1a
  jmp alltraps
80106f43:	e9 a2 f8 ff ff       	jmp    801067ea <alltraps>

80106f48 <vector27>:
.globl vector27
vector27:
  pushl $0
80106f48:	6a 00                	push   $0x0
  pushl $27
80106f4a:	6a 1b                	push   $0x1b
  jmp alltraps
80106f4c:	e9 99 f8 ff ff       	jmp    801067ea <alltraps>

80106f51 <vector28>:
.globl vector28
vector28:
  pushl $0
80106f51:	6a 00                	push   $0x0
  pushl $28
80106f53:	6a 1c                	push   $0x1c
  jmp alltraps
80106f55:	e9 90 f8 ff ff       	jmp    801067ea <alltraps>

80106f5a <vector29>:
.globl vector29
vector29:
  pushl $0
80106f5a:	6a 00                	push   $0x0
  pushl $29
80106f5c:	6a 1d                	push   $0x1d
  jmp alltraps
80106f5e:	e9 87 f8 ff ff       	jmp    801067ea <alltraps>

80106f63 <vector30>:
.globl vector30
vector30:
  pushl $0
80106f63:	6a 00                	push   $0x0
  pushl $30
80106f65:	6a 1e                	push   $0x1e
  jmp alltraps
80106f67:	e9 7e f8 ff ff       	jmp    801067ea <alltraps>

80106f6c <vector31>:
.globl vector31
vector31:
  pushl $0
80106f6c:	6a 00                	push   $0x0
  pushl $31
80106f6e:	6a 1f                	push   $0x1f
  jmp alltraps
80106f70:	e9 75 f8 ff ff       	jmp    801067ea <alltraps>

80106f75 <vector32>:
.globl vector32
vector32:
  pushl $0
80106f75:	6a 00                	push   $0x0
  pushl $32
80106f77:	6a 20                	push   $0x20
  jmp alltraps
80106f79:	e9 6c f8 ff ff       	jmp    801067ea <alltraps>

80106f7e <vector33>:
.globl vector33
vector33:
  pushl $0
80106f7e:	6a 00                	push   $0x0
  pushl $33
80106f80:	6a 21                	push   $0x21
  jmp alltraps
80106f82:	e9 63 f8 ff ff       	jmp    801067ea <alltraps>

80106f87 <vector34>:
.globl vector34
vector34:
  pushl $0
80106f87:	6a 00                	push   $0x0
  pushl $34
80106f89:	6a 22                	push   $0x22
  jmp alltraps
80106f8b:	e9 5a f8 ff ff       	jmp    801067ea <alltraps>

80106f90 <vector35>:
.globl vector35
vector35:
  pushl $0
80106f90:	6a 00                	push   $0x0
  pushl $35
80106f92:	6a 23                	push   $0x23
  jmp alltraps
80106f94:	e9 51 f8 ff ff       	jmp    801067ea <alltraps>

80106f99 <vector36>:
.globl vector36
vector36:
  pushl $0
80106f99:	6a 00                	push   $0x0
  pushl $36
80106f9b:	6a 24                	push   $0x24
  jmp alltraps
80106f9d:	e9 48 f8 ff ff       	jmp    801067ea <alltraps>

80106fa2 <vector37>:
.globl vector37
vector37:
  pushl $0
80106fa2:	6a 00                	push   $0x0
  pushl $37
80106fa4:	6a 25                	push   $0x25
  jmp alltraps
80106fa6:	e9 3f f8 ff ff       	jmp    801067ea <alltraps>

80106fab <vector38>:
.globl vector38
vector38:
  pushl $0
80106fab:	6a 00                	push   $0x0
  pushl $38
80106fad:	6a 26                	push   $0x26
  jmp alltraps
80106faf:	e9 36 f8 ff ff       	jmp    801067ea <alltraps>

80106fb4 <vector39>:
.globl vector39
vector39:
  pushl $0
80106fb4:	6a 00                	push   $0x0
  pushl $39
80106fb6:	6a 27                	push   $0x27
  jmp alltraps
80106fb8:	e9 2d f8 ff ff       	jmp    801067ea <alltraps>

80106fbd <vector40>:
.globl vector40
vector40:
  pushl $0
80106fbd:	6a 00                	push   $0x0
  pushl $40
80106fbf:	6a 28                	push   $0x28
  jmp alltraps
80106fc1:	e9 24 f8 ff ff       	jmp    801067ea <alltraps>

80106fc6 <vector41>:
.globl vector41
vector41:
  pushl $0
80106fc6:	6a 00                	push   $0x0
  pushl $41
80106fc8:	6a 29                	push   $0x29
  jmp alltraps
80106fca:	e9 1b f8 ff ff       	jmp    801067ea <alltraps>

80106fcf <vector42>:
.globl vector42
vector42:
  pushl $0
80106fcf:	6a 00                	push   $0x0
  pushl $42
80106fd1:	6a 2a                	push   $0x2a
  jmp alltraps
80106fd3:	e9 12 f8 ff ff       	jmp    801067ea <alltraps>

80106fd8 <vector43>:
.globl vector43
vector43:
  pushl $0
80106fd8:	6a 00                	push   $0x0
  pushl $43
80106fda:	6a 2b                	push   $0x2b
  jmp alltraps
80106fdc:	e9 09 f8 ff ff       	jmp    801067ea <alltraps>

80106fe1 <vector44>:
.globl vector44
vector44:
  pushl $0
80106fe1:	6a 00                	push   $0x0
  pushl $44
80106fe3:	6a 2c                	push   $0x2c
  jmp alltraps
80106fe5:	e9 00 f8 ff ff       	jmp    801067ea <alltraps>

80106fea <vector45>:
.globl vector45
vector45:
  pushl $0
80106fea:	6a 00                	push   $0x0
  pushl $45
80106fec:	6a 2d                	push   $0x2d
  jmp alltraps
80106fee:	e9 f7 f7 ff ff       	jmp    801067ea <alltraps>

80106ff3 <vector46>:
.globl vector46
vector46:
  pushl $0
80106ff3:	6a 00                	push   $0x0
  pushl $46
80106ff5:	6a 2e                	push   $0x2e
  jmp alltraps
80106ff7:	e9 ee f7 ff ff       	jmp    801067ea <alltraps>

80106ffc <vector47>:
.globl vector47
vector47:
  pushl $0
80106ffc:	6a 00                	push   $0x0
  pushl $47
80106ffe:	6a 2f                	push   $0x2f
  jmp alltraps
80107000:	e9 e5 f7 ff ff       	jmp    801067ea <alltraps>

80107005 <vector48>:
.globl vector48
vector48:
  pushl $0
80107005:	6a 00                	push   $0x0
  pushl $48
80107007:	6a 30                	push   $0x30
  jmp alltraps
80107009:	e9 dc f7 ff ff       	jmp    801067ea <alltraps>

8010700e <vector49>:
.globl vector49
vector49:
  pushl $0
8010700e:	6a 00                	push   $0x0
  pushl $49
80107010:	6a 31                	push   $0x31
  jmp alltraps
80107012:	e9 d3 f7 ff ff       	jmp    801067ea <alltraps>

80107017 <vector50>:
.globl vector50
vector50:
  pushl $0
80107017:	6a 00                	push   $0x0
  pushl $50
80107019:	6a 32                	push   $0x32
  jmp alltraps
8010701b:	e9 ca f7 ff ff       	jmp    801067ea <alltraps>

80107020 <vector51>:
.globl vector51
vector51:
  pushl $0
80107020:	6a 00                	push   $0x0
  pushl $51
80107022:	6a 33                	push   $0x33
  jmp alltraps
80107024:	e9 c1 f7 ff ff       	jmp    801067ea <alltraps>

80107029 <vector52>:
.globl vector52
vector52:
  pushl $0
80107029:	6a 00                	push   $0x0
  pushl $52
8010702b:	6a 34                	push   $0x34
  jmp alltraps
8010702d:	e9 b8 f7 ff ff       	jmp    801067ea <alltraps>

80107032 <vector53>:
.globl vector53
vector53:
  pushl $0
80107032:	6a 00                	push   $0x0
  pushl $53
80107034:	6a 35                	push   $0x35
  jmp alltraps
80107036:	e9 af f7 ff ff       	jmp    801067ea <alltraps>

8010703b <vector54>:
.globl vector54
vector54:
  pushl $0
8010703b:	6a 00                	push   $0x0
  pushl $54
8010703d:	6a 36                	push   $0x36
  jmp alltraps
8010703f:	e9 a6 f7 ff ff       	jmp    801067ea <alltraps>

80107044 <vector55>:
.globl vector55
vector55:
  pushl $0
80107044:	6a 00                	push   $0x0
  pushl $55
80107046:	6a 37                	push   $0x37
  jmp alltraps
80107048:	e9 9d f7 ff ff       	jmp    801067ea <alltraps>

8010704d <vector56>:
.globl vector56
vector56:
  pushl $0
8010704d:	6a 00                	push   $0x0
  pushl $56
8010704f:	6a 38                	push   $0x38
  jmp alltraps
80107051:	e9 94 f7 ff ff       	jmp    801067ea <alltraps>

80107056 <vector57>:
.globl vector57
vector57:
  pushl $0
80107056:	6a 00                	push   $0x0
  pushl $57
80107058:	6a 39                	push   $0x39
  jmp alltraps
8010705a:	e9 8b f7 ff ff       	jmp    801067ea <alltraps>

8010705f <vector58>:
.globl vector58
vector58:
  pushl $0
8010705f:	6a 00                	push   $0x0
  pushl $58
80107061:	6a 3a                	push   $0x3a
  jmp alltraps
80107063:	e9 82 f7 ff ff       	jmp    801067ea <alltraps>

80107068 <vector59>:
.globl vector59
vector59:
  pushl $0
80107068:	6a 00                	push   $0x0
  pushl $59
8010706a:	6a 3b                	push   $0x3b
  jmp alltraps
8010706c:	e9 79 f7 ff ff       	jmp    801067ea <alltraps>

80107071 <vector60>:
.globl vector60
vector60:
  pushl $0
80107071:	6a 00                	push   $0x0
  pushl $60
80107073:	6a 3c                	push   $0x3c
  jmp alltraps
80107075:	e9 70 f7 ff ff       	jmp    801067ea <alltraps>

8010707a <vector61>:
.globl vector61
vector61:
  pushl $0
8010707a:	6a 00                	push   $0x0
  pushl $61
8010707c:	6a 3d                	push   $0x3d
  jmp alltraps
8010707e:	e9 67 f7 ff ff       	jmp    801067ea <alltraps>

80107083 <vector62>:
.globl vector62
vector62:
  pushl $0
80107083:	6a 00                	push   $0x0
  pushl $62
80107085:	6a 3e                	push   $0x3e
  jmp alltraps
80107087:	e9 5e f7 ff ff       	jmp    801067ea <alltraps>

8010708c <vector63>:
.globl vector63
vector63:
  pushl $0
8010708c:	6a 00                	push   $0x0
  pushl $63
8010708e:	6a 3f                	push   $0x3f
  jmp alltraps
80107090:	e9 55 f7 ff ff       	jmp    801067ea <alltraps>

80107095 <vector64>:
.globl vector64
vector64:
  pushl $0
80107095:	6a 00                	push   $0x0
  pushl $64
80107097:	6a 40                	push   $0x40
  jmp alltraps
80107099:	e9 4c f7 ff ff       	jmp    801067ea <alltraps>

8010709e <vector65>:
.globl vector65
vector65:
  pushl $0
8010709e:	6a 00                	push   $0x0
  pushl $65
801070a0:	6a 41                	push   $0x41
  jmp alltraps
801070a2:	e9 43 f7 ff ff       	jmp    801067ea <alltraps>

801070a7 <vector66>:
.globl vector66
vector66:
  pushl $0
801070a7:	6a 00                	push   $0x0
  pushl $66
801070a9:	6a 42                	push   $0x42
  jmp alltraps
801070ab:	e9 3a f7 ff ff       	jmp    801067ea <alltraps>

801070b0 <vector67>:
.globl vector67
vector67:
  pushl $0
801070b0:	6a 00                	push   $0x0
  pushl $67
801070b2:	6a 43                	push   $0x43
  jmp alltraps
801070b4:	e9 31 f7 ff ff       	jmp    801067ea <alltraps>

801070b9 <vector68>:
.globl vector68
vector68:
  pushl $0
801070b9:	6a 00                	push   $0x0
  pushl $68
801070bb:	6a 44                	push   $0x44
  jmp alltraps
801070bd:	e9 28 f7 ff ff       	jmp    801067ea <alltraps>

801070c2 <vector69>:
.globl vector69
vector69:
  pushl $0
801070c2:	6a 00                	push   $0x0
  pushl $69
801070c4:	6a 45                	push   $0x45
  jmp alltraps
801070c6:	e9 1f f7 ff ff       	jmp    801067ea <alltraps>

801070cb <vector70>:
.globl vector70
vector70:
  pushl $0
801070cb:	6a 00                	push   $0x0
  pushl $70
801070cd:	6a 46                	push   $0x46
  jmp alltraps
801070cf:	e9 16 f7 ff ff       	jmp    801067ea <alltraps>

801070d4 <vector71>:
.globl vector71
vector71:
  pushl $0
801070d4:	6a 00                	push   $0x0
  pushl $71
801070d6:	6a 47                	push   $0x47
  jmp alltraps
801070d8:	e9 0d f7 ff ff       	jmp    801067ea <alltraps>

801070dd <vector72>:
.globl vector72
vector72:
  pushl $0
801070dd:	6a 00                	push   $0x0
  pushl $72
801070df:	6a 48                	push   $0x48
  jmp alltraps
801070e1:	e9 04 f7 ff ff       	jmp    801067ea <alltraps>

801070e6 <vector73>:
.globl vector73
vector73:
  pushl $0
801070e6:	6a 00                	push   $0x0
  pushl $73
801070e8:	6a 49                	push   $0x49
  jmp alltraps
801070ea:	e9 fb f6 ff ff       	jmp    801067ea <alltraps>

801070ef <vector74>:
.globl vector74
vector74:
  pushl $0
801070ef:	6a 00                	push   $0x0
  pushl $74
801070f1:	6a 4a                	push   $0x4a
  jmp alltraps
801070f3:	e9 f2 f6 ff ff       	jmp    801067ea <alltraps>

801070f8 <vector75>:
.globl vector75
vector75:
  pushl $0
801070f8:	6a 00                	push   $0x0
  pushl $75
801070fa:	6a 4b                	push   $0x4b
  jmp alltraps
801070fc:	e9 e9 f6 ff ff       	jmp    801067ea <alltraps>

80107101 <vector76>:
.globl vector76
vector76:
  pushl $0
80107101:	6a 00                	push   $0x0
  pushl $76
80107103:	6a 4c                	push   $0x4c
  jmp alltraps
80107105:	e9 e0 f6 ff ff       	jmp    801067ea <alltraps>

8010710a <vector77>:
.globl vector77
vector77:
  pushl $0
8010710a:	6a 00                	push   $0x0
  pushl $77
8010710c:	6a 4d                	push   $0x4d
  jmp alltraps
8010710e:	e9 d7 f6 ff ff       	jmp    801067ea <alltraps>

80107113 <vector78>:
.globl vector78
vector78:
  pushl $0
80107113:	6a 00                	push   $0x0
  pushl $78
80107115:	6a 4e                	push   $0x4e
  jmp alltraps
80107117:	e9 ce f6 ff ff       	jmp    801067ea <alltraps>

8010711c <vector79>:
.globl vector79
vector79:
  pushl $0
8010711c:	6a 00                	push   $0x0
  pushl $79
8010711e:	6a 4f                	push   $0x4f
  jmp alltraps
80107120:	e9 c5 f6 ff ff       	jmp    801067ea <alltraps>

80107125 <vector80>:
.globl vector80
vector80:
  pushl $0
80107125:	6a 00                	push   $0x0
  pushl $80
80107127:	6a 50                	push   $0x50
  jmp alltraps
80107129:	e9 bc f6 ff ff       	jmp    801067ea <alltraps>

8010712e <vector81>:
.globl vector81
vector81:
  pushl $0
8010712e:	6a 00                	push   $0x0
  pushl $81
80107130:	6a 51                	push   $0x51
  jmp alltraps
80107132:	e9 b3 f6 ff ff       	jmp    801067ea <alltraps>

80107137 <vector82>:
.globl vector82
vector82:
  pushl $0
80107137:	6a 00                	push   $0x0
  pushl $82
80107139:	6a 52                	push   $0x52
  jmp alltraps
8010713b:	e9 aa f6 ff ff       	jmp    801067ea <alltraps>

80107140 <vector83>:
.globl vector83
vector83:
  pushl $0
80107140:	6a 00                	push   $0x0
  pushl $83
80107142:	6a 53                	push   $0x53
  jmp alltraps
80107144:	e9 a1 f6 ff ff       	jmp    801067ea <alltraps>

80107149 <vector84>:
.globl vector84
vector84:
  pushl $0
80107149:	6a 00                	push   $0x0
  pushl $84
8010714b:	6a 54                	push   $0x54
  jmp alltraps
8010714d:	e9 98 f6 ff ff       	jmp    801067ea <alltraps>

80107152 <vector85>:
.globl vector85
vector85:
  pushl $0
80107152:	6a 00                	push   $0x0
  pushl $85
80107154:	6a 55                	push   $0x55
  jmp alltraps
80107156:	e9 8f f6 ff ff       	jmp    801067ea <alltraps>

8010715b <vector86>:
.globl vector86
vector86:
  pushl $0
8010715b:	6a 00                	push   $0x0
  pushl $86
8010715d:	6a 56                	push   $0x56
  jmp alltraps
8010715f:	e9 86 f6 ff ff       	jmp    801067ea <alltraps>

80107164 <vector87>:
.globl vector87
vector87:
  pushl $0
80107164:	6a 00                	push   $0x0
  pushl $87
80107166:	6a 57                	push   $0x57
  jmp alltraps
80107168:	e9 7d f6 ff ff       	jmp    801067ea <alltraps>

8010716d <vector88>:
.globl vector88
vector88:
  pushl $0
8010716d:	6a 00                	push   $0x0
  pushl $88
8010716f:	6a 58                	push   $0x58
  jmp alltraps
80107171:	e9 74 f6 ff ff       	jmp    801067ea <alltraps>

80107176 <vector89>:
.globl vector89
vector89:
  pushl $0
80107176:	6a 00                	push   $0x0
  pushl $89
80107178:	6a 59                	push   $0x59
  jmp alltraps
8010717a:	e9 6b f6 ff ff       	jmp    801067ea <alltraps>

8010717f <vector90>:
.globl vector90
vector90:
  pushl $0
8010717f:	6a 00                	push   $0x0
  pushl $90
80107181:	6a 5a                	push   $0x5a
  jmp alltraps
80107183:	e9 62 f6 ff ff       	jmp    801067ea <alltraps>

80107188 <vector91>:
.globl vector91
vector91:
  pushl $0
80107188:	6a 00                	push   $0x0
  pushl $91
8010718a:	6a 5b                	push   $0x5b
  jmp alltraps
8010718c:	e9 59 f6 ff ff       	jmp    801067ea <alltraps>

80107191 <vector92>:
.globl vector92
vector92:
  pushl $0
80107191:	6a 00                	push   $0x0
  pushl $92
80107193:	6a 5c                	push   $0x5c
  jmp alltraps
80107195:	e9 50 f6 ff ff       	jmp    801067ea <alltraps>

8010719a <vector93>:
.globl vector93
vector93:
  pushl $0
8010719a:	6a 00                	push   $0x0
  pushl $93
8010719c:	6a 5d                	push   $0x5d
  jmp alltraps
8010719e:	e9 47 f6 ff ff       	jmp    801067ea <alltraps>

801071a3 <vector94>:
.globl vector94
vector94:
  pushl $0
801071a3:	6a 00                	push   $0x0
  pushl $94
801071a5:	6a 5e                	push   $0x5e
  jmp alltraps
801071a7:	e9 3e f6 ff ff       	jmp    801067ea <alltraps>

801071ac <vector95>:
.globl vector95
vector95:
  pushl $0
801071ac:	6a 00                	push   $0x0
  pushl $95
801071ae:	6a 5f                	push   $0x5f
  jmp alltraps
801071b0:	e9 35 f6 ff ff       	jmp    801067ea <alltraps>

801071b5 <vector96>:
.globl vector96
vector96:
  pushl $0
801071b5:	6a 00                	push   $0x0
  pushl $96
801071b7:	6a 60                	push   $0x60
  jmp alltraps
801071b9:	e9 2c f6 ff ff       	jmp    801067ea <alltraps>

801071be <vector97>:
.globl vector97
vector97:
  pushl $0
801071be:	6a 00                	push   $0x0
  pushl $97
801071c0:	6a 61                	push   $0x61
  jmp alltraps
801071c2:	e9 23 f6 ff ff       	jmp    801067ea <alltraps>

801071c7 <vector98>:
.globl vector98
vector98:
  pushl $0
801071c7:	6a 00                	push   $0x0
  pushl $98
801071c9:	6a 62                	push   $0x62
  jmp alltraps
801071cb:	e9 1a f6 ff ff       	jmp    801067ea <alltraps>

801071d0 <vector99>:
.globl vector99
vector99:
  pushl $0
801071d0:	6a 00                	push   $0x0
  pushl $99
801071d2:	6a 63                	push   $0x63
  jmp alltraps
801071d4:	e9 11 f6 ff ff       	jmp    801067ea <alltraps>

801071d9 <vector100>:
.globl vector100
vector100:
  pushl $0
801071d9:	6a 00                	push   $0x0
  pushl $100
801071db:	6a 64                	push   $0x64
  jmp alltraps
801071dd:	e9 08 f6 ff ff       	jmp    801067ea <alltraps>

801071e2 <vector101>:
.globl vector101
vector101:
  pushl $0
801071e2:	6a 00                	push   $0x0
  pushl $101
801071e4:	6a 65                	push   $0x65
  jmp alltraps
801071e6:	e9 ff f5 ff ff       	jmp    801067ea <alltraps>

801071eb <vector102>:
.globl vector102
vector102:
  pushl $0
801071eb:	6a 00                	push   $0x0
  pushl $102
801071ed:	6a 66                	push   $0x66
  jmp alltraps
801071ef:	e9 f6 f5 ff ff       	jmp    801067ea <alltraps>

801071f4 <vector103>:
.globl vector103
vector103:
  pushl $0
801071f4:	6a 00                	push   $0x0
  pushl $103
801071f6:	6a 67                	push   $0x67
  jmp alltraps
801071f8:	e9 ed f5 ff ff       	jmp    801067ea <alltraps>

801071fd <vector104>:
.globl vector104
vector104:
  pushl $0
801071fd:	6a 00                	push   $0x0
  pushl $104
801071ff:	6a 68                	push   $0x68
  jmp alltraps
80107201:	e9 e4 f5 ff ff       	jmp    801067ea <alltraps>

80107206 <vector105>:
.globl vector105
vector105:
  pushl $0
80107206:	6a 00                	push   $0x0
  pushl $105
80107208:	6a 69                	push   $0x69
  jmp alltraps
8010720a:	e9 db f5 ff ff       	jmp    801067ea <alltraps>

8010720f <vector106>:
.globl vector106
vector106:
  pushl $0
8010720f:	6a 00                	push   $0x0
  pushl $106
80107211:	6a 6a                	push   $0x6a
  jmp alltraps
80107213:	e9 d2 f5 ff ff       	jmp    801067ea <alltraps>

80107218 <vector107>:
.globl vector107
vector107:
  pushl $0
80107218:	6a 00                	push   $0x0
  pushl $107
8010721a:	6a 6b                	push   $0x6b
  jmp alltraps
8010721c:	e9 c9 f5 ff ff       	jmp    801067ea <alltraps>

80107221 <vector108>:
.globl vector108
vector108:
  pushl $0
80107221:	6a 00                	push   $0x0
  pushl $108
80107223:	6a 6c                	push   $0x6c
  jmp alltraps
80107225:	e9 c0 f5 ff ff       	jmp    801067ea <alltraps>

8010722a <vector109>:
.globl vector109
vector109:
  pushl $0
8010722a:	6a 00                	push   $0x0
  pushl $109
8010722c:	6a 6d                	push   $0x6d
  jmp alltraps
8010722e:	e9 b7 f5 ff ff       	jmp    801067ea <alltraps>

80107233 <vector110>:
.globl vector110
vector110:
  pushl $0
80107233:	6a 00                	push   $0x0
  pushl $110
80107235:	6a 6e                	push   $0x6e
  jmp alltraps
80107237:	e9 ae f5 ff ff       	jmp    801067ea <alltraps>

8010723c <vector111>:
.globl vector111
vector111:
  pushl $0
8010723c:	6a 00                	push   $0x0
  pushl $111
8010723e:	6a 6f                	push   $0x6f
  jmp alltraps
80107240:	e9 a5 f5 ff ff       	jmp    801067ea <alltraps>

80107245 <vector112>:
.globl vector112
vector112:
  pushl $0
80107245:	6a 00                	push   $0x0
  pushl $112
80107247:	6a 70                	push   $0x70
  jmp alltraps
80107249:	e9 9c f5 ff ff       	jmp    801067ea <alltraps>

8010724e <vector113>:
.globl vector113
vector113:
  pushl $0
8010724e:	6a 00                	push   $0x0
  pushl $113
80107250:	6a 71                	push   $0x71
  jmp alltraps
80107252:	e9 93 f5 ff ff       	jmp    801067ea <alltraps>

80107257 <vector114>:
.globl vector114
vector114:
  pushl $0
80107257:	6a 00                	push   $0x0
  pushl $114
80107259:	6a 72                	push   $0x72
  jmp alltraps
8010725b:	e9 8a f5 ff ff       	jmp    801067ea <alltraps>

80107260 <vector115>:
.globl vector115
vector115:
  pushl $0
80107260:	6a 00                	push   $0x0
  pushl $115
80107262:	6a 73                	push   $0x73
  jmp alltraps
80107264:	e9 81 f5 ff ff       	jmp    801067ea <alltraps>

80107269 <vector116>:
.globl vector116
vector116:
  pushl $0
80107269:	6a 00                	push   $0x0
  pushl $116
8010726b:	6a 74                	push   $0x74
  jmp alltraps
8010726d:	e9 78 f5 ff ff       	jmp    801067ea <alltraps>

80107272 <vector117>:
.globl vector117
vector117:
  pushl $0
80107272:	6a 00                	push   $0x0
  pushl $117
80107274:	6a 75                	push   $0x75
  jmp alltraps
80107276:	e9 6f f5 ff ff       	jmp    801067ea <alltraps>

8010727b <vector118>:
.globl vector118
vector118:
  pushl $0
8010727b:	6a 00                	push   $0x0
  pushl $118
8010727d:	6a 76                	push   $0x76
  jmp alltraps
8010727f:	e9 66 f5 ff ff       	jmp    801067ea <alltraps>

80107284 <vector119>:
.globl vector119
vector119:
  pushl $0
80107284:	6a 00                	push   $0x0
  pushl $119
80107286:	6a 77                	push   $0x77
  jmp alltraps
80107288:	e9 5d f5 ff ff       	jmp    801067ea <alltraps>

8010728d <vector120>:
.globl vector120
vector120:
  pushl $0
8010728d:	6a 00                	push   $0x0
  pushl $120
8010728f:	6a 78                	push   $0x78
  jmp alltraps
80107291:	e9 54 f5 ff ff       	jmp    801067ea <alltraps>

80107296 <vector121>:
.globl vector121
vector121:
  pushl $0
80107296:	6a 00                	push   $0x0
  pushl $121
80107298:	6a 79                	push   $0x79
  jmp alltraps
8010729a:	e9 4b f5 ff ff       	jmp    801067ea <alltraps>

8010729f <vector122>:
.globl vector122
vector122:
  pushl $0
8010729f:	6a 00                	push   $0x0
  pushl $122
801072a1:	6a 7a                	push   $0x7a
  jmp alltraps
801072a3:	e9 42 f5 ff ff       	jmp    801067ea <alltraps>

801072a8 <vector123>:
.globl vector123
vector123:
  pushl $0
801072a8:	6a 00                	push   $0x0
  pushl $123
801072aa:	6a 7b                	push   $0x7b
  jmp alltraps
801072ac:	e9 39 f5 ff ff       	jmp    801067ea <alltraps>

801072b1 <vector124>:
.globl vector124
vector124:
  pushl $0
801072b1:	6a 00                	push   $0x0
  pushl $124
801072b3:	6a 7c                	push   $0x7c
  jmp alltraps
801072b5:	e9 30 f5 ff ff       	jmp    801067ea <alltraps>

801072ba <vector125>:
.globl vector125
vector125:
  pushl $0
801072ba:	6a 00                	push   $0x0
  pushl $125
801072bc:	6a 7d                	push   $0x7d
  jmp alltraps
801072be:	e9 27 f5 ff ff       	jmp    801067ea <alltraps>

801072c3 <vector126>:
.globl vector126
vector126:
  pushl $0
801072c3:	6a 00                	push   $0x0
  pushl $126
801072c5:	6a 7e                	push   $0x7e
  jmp alltraps
801072c7:	e9 1e f5 ff ff       	jmp    801067ea <alltraps>

801072cc <vector127>:
.globl vector127
vector127:
  pushl $0
801072cc:	6a 00                	push   $0x0
  pushl $127
801072ce:	6a 7f                	push   $0x7f
  jmp alltraps
801072d0:	e9 15 f5 ff ff       	jmp    801067ea <alltraps>

801072d5 <vector128>:
.globl vector128
vector128:
  pushl $0
801072d5:	6a 00                	push   $0x0
  pushl $128
801072d7:	68 80 00 00 00       	push   $0x80
  jmp alltraps
801072dc:	e9 09 f5 ff ff       	jmp    801067ea <alltraps>

801072e1 <vector129>:
.globl vector129
vector129:
  pushl $0
801072e1:	6a 00                	push   $0x0
  pushl $129
801072e3:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801072e8:	e9 fd f4 ff ff       	jmp    801067ea <alltraps>

801072ed <vector130>:
.globl vector130
vector130:
  pushl $0
801072ed:	6a 00                	push   $0x0
  pushl $130
801072ef:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801072f4:	e9 f1 f4 ff ff       	jmp    801067ea <alltraps>

801072f9 <vector131>:
.globl vector131
vector131:
  pushl $0
801072f9:	6a 00                	push   $0x0
  pushl $131
801072fb:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107300:	e9 e5 f4 ff ff       	jmp    801067ea <alltraps>

80107305 <vector132>:
.globl vector132
vector132:
  pushl $0
80107305:	6a 00                	push   $0x0
  pushl $132
80107307:	68 84 00 00 00       	push   $0x84
  jmp alltraps
8010730c:	e9 d9 f4 ff ff       	jmp    801067ea <alltraps>

80107311 <vector133>:
.globl vector133
vector133:
  pushl $0
80107311:	6a 00                	push   $0x0
  pushl $133
80107313:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80107318:	e9 cd f4 ff ff       	jmp    801067ea <alltraps>

8010731d <vector134>:
.globl vector134
vector134:
  pushl $0
8010731d:	6a 00                	push   $0x0
  pushl $134
8010731f:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80107324:	e9 c1 f4 ff ff       	jmp    801067ea <alltraps>

80107329 <vector135>:
.globl vector135
vector135:
  pushl $0
80107329:	6a 00                	push   $0x0
  pushl $135
8010732b:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80107330:	e9 b5 f4 ff ff       	jmp    801067ea <alltraps>

80107335 <vector136>:
.globl vector136
vector136:
  pushl $0
80107335:	6a 00                	push   $0x0
  pushl $136
80107337:	68 88 00 00 00       	push   $0x88
  jmp alltraps
8010733c:	e9 a9 f4 ff ff       	jmp    801067ea <alltraps>

80107341 <vector137>:
.globl vector137
vector137:
  pushl $0
80107341:	6a 00                	push   $0x0
  pushl $137
80107343:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80107348:	e9 9d f4 ff ff       	jmp    801067ea <alltraps>

8010734d <vector138>:
.globl vector138
vector138:
  pushl $0
8010734d:	6a 00                	push   $0x0
  pushl $138
8010734f:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80107354:	e9 91 f4 ff ff       	jmp    801067ea <alltraps>

80107359 <vector139>:
.globl vector139
vector139:
  pushl $0
80107359:	6a 00                	push   $0x0
  pushl $139
8010735b:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80107360:	e9 85 f4 ff ff       	jmp    801067ea <alltraps>

80107365 <vector140>:
.globl vector140
vector140:
  pushl $0
80107365:	6a 00                	push   $0x0
  pushl $140
80107367:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
8010736c:	e9 79 f4 ff ff       	jmp    801067ea <alltraps>

80107371 <vector141>:
.globl vector141
vector141:
  pushl $0
80107371:	6a 00                	push   $0x0
  pushl $141
80107373:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80107378:	e9 6d f4 ff ff       	jmp    801067ea <alltraps>

8010737d <vector142>:
.globl vector142
vector142:
  pushl $0
8010737d:	6a 00                	push   $0x0
  pushl $142
8010737f:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107384:	e9 61 f4 ff ff       	jmp    801067ea <alltraps>

80107389 <vector143>:
.globl vector143
vector143:
  pushl $0
80107389:	6a 00                	push   $0x0
  pushl $143
8010738b:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107390:	e9 55 f4 ff ff       	jmp    801067ea <alltraps>

80107395 <vector144>:
.globl vector144
vector144:
  pushl $0
80107395:	6a 00                	push   $0x0
  pushl $144
80107397:	68 90 00 00 00       	push   $0x90
  jmp alltraps
8010739c:	e9 49 f4 ff ff       	jmp    801067ea <alltraps>

801073a1 <vector145>:
.globl vector145
vector145:
  pushl $0
801073a1:	6a 00                	push   $0x0
  pushl $145
801073a3:	68 91 00 00 00       	push   $0x91
  jmp alltraps
801073a8:	e9 3d f4 ff ff       	jmp    801067ea <alltraps>

801073ad <vector146>:
.globl vector146
vector146:
  pushl $0
801073ad:	6a 00                	push   $0x0
  pushl $146
801073af:	68 92 00 00 00       	push   $0x92
  jmp alltraps
801073b4:	e9 31 f4 ff ff       	jmp    801067ea <alltraps>

801073b9 <vector147>:
.globl vector147
vector147:
  pushl $0
801073b9:	6a 00                	push   $0x0
  pushl $147
801073bb:	68 93 00 00 00       	push   $0x93
  jmp alltraps
801073c0:	e9 25 f4 ff ff       	jmp    801067ea <alltraps>

801073c5 <vector148>:
.globl vector148
vector148:
  pushl $0
801073c5:	6a 00                	push   $0x0
  pushl $148
801073c7:	68 94 00 00 00       	push   $0x94
  jmp alltraps
801073cc:	e9 19 f4 ff ff       	jmp    801067ea <alltraps>

801073d1 <vector149>:
.globl vector149
vector149:
  pushl $0
801073d1:	6a 00                	push   $0x0
  pushl $149
801073d3:	68 95 00 00 00       	push   $0x95
  jmp alltraps
801073d8:	e9 0d f4 ff ff       	jmp    801067ea <alltraps>

801073dd <vector150>:
.globl vector150
vector150:
  pushl $0
801073dd:	6a 00                	push   $0x0
  pushl $150
801073df:	68 96 00 00 00       	push   $0x96
  jmp alltraps
801073e4:	e9 01 f4 ff ff       	jmp    801067ea <alltraps>

801073e9 <vector151>:
.globl vector151
vector151:
  pushl $0
801073e9:	6a 00                	push   $0x0
  pushl $151
801073eb:	68 97 00 00 00       	push   $0x97
  jmp alltraps
801073f0:	e9 f5 f3 ff ff       	jmp    801067ea <alltraps>

801073f5 <vector152>:
.globl vector152
vector152:
  pushl $0
801073f5:	6a 00                	push   $0x0
  pushl $152
801073f7:	68 98 00 00 00       	push   $0x98
  jmp alltraps
801073fc:	e9 e9 f3 ff ff       	jmp    801067ea <alltraps>

80107401 <vector153>:
.globl vector153
vector153:
  pushl $0
80107401:	6a 00                	push   $0x0
  pushl $153
80107403:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107408:	e9 dd f3 ff ff       	jmp    801067ea <alltraps>

8010740d <vector154>:
.globl vector154
vector154:
  pushl $0
8010740d:	6a 00                	push   $0x0
  pushl $154
8010740f:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80107414:	e9 d1 f3 ff ff       	jmp    801067ea <alltraps>

80107419 <vector155>:
.globl vector155
vector155:
  pushl $0
80107419:	6a 00                	push   $0x0
  pushl $155
8010741b:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107420:	e9 c5 f3 ff ff       	jmp    801067ea <alltraps>

80107425 <vector156>:
.globl vector156
vector156:
  pushl $0
80107425:	6a 00                	push   $0x0
  pushl $156
80107427:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
8010742c:	e9 b9 f3 ff ff       	jmp    801067ea <alltraps>

80107431 <vector157>:
.globl vector157
vector157:
  pushl $0
80107431:	6a 00                	push   $0x0
  pushl $157
80107433:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80107438:	e9 ad f3 ff ff       	jmp    801067ea <alltraps>

8010743d <vector158>:
.globl vector158
vector158:
  pushl $0
8010743d:	6a 00                	push   $0x0
  pushl $158
8010743f:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107444:	e9 a1 f3 ff ff       	jmp    801067ea <alltraps>

80107449 <vector159>:
.globl vector159
vector159:
  pushl $0
80107449:	6a 00                	push   $0x0
  pushl $159
8010744b:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107450:	e9 95 f3 ff ff       	jmp    801067ea <alltraps>

80107455 <vector160>:
.globl vector160
vector160:
  pushl $0
80107455:	6a 00                	push   $0x0
  pushl $160
80107457:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
8010745c:	e9 89 f3 ff ff       	jmp    801067ea <alltraps>

80107461 <vector161>:
.globl vector161
vector161:
  pushl $0
80107461:	6a 00                	push   $0x0
  pushl $161
80107463:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80107468:	e9 7d f3 ff ff       	jmp    801067ea <alltraps>

8010746d <vector162>:
.globl vector162
vector162:
  pushl $0
8010746d:	6a 00                	push   $0x0
  pushl $162
8010746f:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107474:	e9 71 f3 ff ff       	jmp    801067ea <alltraps>

80107479 <vector163>:
.globl vector163
vector163:
  pushl $0
80107479:	6a 00                	push   $0x0
  pushl $163
8010747b:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107480:	e9 65 f3 ff ff       	jmp    801067ea <alltraps>

80107485 <vector164>:
.globl vector164
vector164:
  pushl $0
80107485:	6a 00                	push   $0x0
  pushl $164
80107487:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
8010748c:	e9 59 f3 ff ff       	jmp    801067ea <alltraps>

80107491 <vector165>:
.globl vector165
vector165:
  pushl $0
80107491:	6a 00                	push   $0x0
  pushl $165
80107493:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107498:	e9 4d f3 ff ff       	jmp    801067ea <alltraps>

8010749d <vector166>:
.globl vector166
vector166:
  pushl $0
8010749d:	6a 00                	push   $0x0
  pushl $166
8010749f:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
801074a4:	e9 41 f3 ff ff       	jmp    801067ea <alltraps>

801074a9 <vector167>:
.globl vector167
vector167:
  pushl $0
801074a9:	6a 00                	push   $0x0
  pushl $167
801074ab:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
801074b0:	e9 35 f3 ff ff       	jmp    801067ea <alltraps>

801074b5 <vector168>:
.globl vector168
vector168:
  pushl $0
801074b5:	6a 00                	push   $0x0
  pushl $168
801074b7:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
801074bc:	e9 29 f3 ff ff       	jmp    801067ea <alltraps>

801074c1 <vector169>:
.globl vector169
vector169:
  pushl $0
801074c1:	6a 00                	push   $0x0
  pushl $169
801074c3:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
801074c8:	e9 1d f3 ff ff       	jmp    801067ea <alltraps>

801074cd <vector170>:
.globl vector170
vector170:
  pushl $0
801074cd:	6a 00                	push   $0x0
  pushl $170
801074cf:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
801074d4:	e9 11 f3 ff ff       	jmp    801067ea <alltraps>

801074d9 <vector171>:
.globl vector171
vector171:
  pushl $0
801074d9:	6a 00                	push   $0x0
  pushl $171
801074db:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
801074e0:	e9 05 f3 ff ff       	jmp    801067ea <alltraps>

801074e5 <vector172>:
.globl vector172
vector172:
  pushl $0
801074e5:	6a 00                	push   $0x0
  pushl $172
801074e7:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
801074ec:	e9 f9 f2 ff ff       	jmp    801067ea <alltraps>

801074f1 <vector173>:
.globl vector173
vector173:
  pushl $0
801074f1:	6a 00                	push   $0x0
  pushl $173
801074f3:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
801074f8:	e9 ed f2 ff ff       	jmp    801067ea <alltraps>

801074fd <vector174>:
.globl vector174
vector174:
  pushl $0
801074fd:	6a 00                	push   $0x0
  pushl $174
801074ff:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107504:	e9 e1 f2 ff ff       	jmp    801067ea <alltraps>

80107509 <vector175>:
.globl vector175
vector175:
  pushl $0
80107509:	6a 00                	push   $0x0
  pushl $175
8010750b:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107510:	e9 d5 f2 ff ff       	jmp    801067ea <alltraps>

80107515 <vector176>:
.globl vector176
vector176:
  pushl $0
80107515:	6a 00                	push   $0x0
  pushl $176
80107517:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
8010751c:	e9 c9 f2 ff ff       	jmp    801067ea <alltraps>

80107521 <vector177>:
.globl vector177
vector177:
  pushl $0
80107521:	6a 00                	push   $0x0
  pushl $177
80107523:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107528:	e9 bd f2 ff ff       	jmp    801067ea <alltraps>

8010752d <vector178>:
.globl vector178
vector178:
  pushl $0
8010752d:	6a 00                	push   $0x0
  pushl $178
8010752f:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107534:	e9 b1 f2 ff ff       	jmp    801067ea <alltraps>

80107539 <vector179>:
.globl vector179
vector179:
  pushl $0
80107539:	6a 00                	push   $0x0
  pushl $179
8010753b:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107540:	e9 a5 f2 ff ff       	jmp    801067ea <alltraps>

80107545 <vector180>:
.globl vector180
vector180:
  pushl $0
80107545:	6a 00                	push   $0x0
  pushl $180
80107547:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
8010754c:	e9 99 f2 ff ff       	jmp    801067ea <alltraps>

80107551 <vector181>:
.globl vector181
vector181:
  pushl $0
80107551:	6a 00                	push   $0x0
  pushl $181
80107553:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107558:	e9 8d f2 ff ff       	jmp    801067ea <alltraps>

8010755d <vector182>:
.globl vector182
vector182:
  pushl $0
8010755d:	6a 00                	push   $0x0
  pushl $182
8010755f:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107564:	e9 81 f2 ff ff       	jmp    801067ea <alltraps>

80107569 <vector183>:
.globl vector183
vector183:
  pushl $0
80107569:	6a 00                	push   $0x0
  pushl $183
8010756b:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107570:	e9 75 f2 ff ff       	jmp    801067ea <alltraps>

80107575 <vector184>:
.globl vector184
vector184:
  pushl $0
80107575:	6a 00                	push   $0x0
  pushl $184
80107577:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
8010757c:	e9 69 f2 ff ff       	jmp    801067ea <alltraps>

80107581 <vector185>:
.globl vector185
vector185:
  pushl $0
80107581:	6a 00                	push   $0x0
  pushl $185
80107583:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107588:	e9 5d f2 ff ff       	jmp    801067ea <alltraps>

8010758d <vector186>:
.globl vector186
vector186:
  pushl $0
8010758d:	6a 00                	push   $0x0
  pushl $186
8010758f:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107594:	e9 51 f2 ff ff       	jmp    801067ea <alltraps>

80107599 <vector187>:
.globl vector187
vector187:
  pushl $0
80107599:	6a 00                	push   $0x0
  pushl $187
8010759b:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
801075a0:	e9 45 f2 ff ff       	jmp    801067ea <alltraps>

801075a5 <vector188>:
.globl vector188
vector188:
  pushl $0
801075a5:	6a 00                	push   $0x0
  pushl $188
801075a7:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
801075ac:	e9 39 f2 ff ff       	jmp    801067ea <alltraps>

801075b1 <vector189>:
.globl vector189
vector189:
  pushl $0
801075b1:	6a 00                	push   $0x0
  pushl $189
801075b3:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
801075b8:	e9 2d f2 ff ff       	jmp    801067ea <alltraps>

801075bd <vector190>:
.globl vector190
vector190:
  pushl $0
801075bd:	6a 00                	push   $0x0
  pushl $190
801075bf:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
801075c4:	e9 21 f2 ff ff       	jmp    801067ea <alltraps>

801075c9 <vector191>:
.globl vector191
vector191:
  pushl $0
801075c9:	6a 00                	push   $0x0
  pushl $191
801075cb:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
801075d0:	e9 15 f2 ff ff       	jmp    801067ea <alltraps>

801075d5 <vector192>:
.globl vector192
vector192:
  pushl $0
801075d5:	6a 00                	push   $0x0
  pushl $192
801075d7:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
801075dc:	e9 09 f2 ff ff       	jmp    801067ea <alltraps>

801075e1 <vector193>:
.globl vector193
vector193:
  pushl $0
801075e1:	6a 00                	push   $0x0
  pushl $193
801075e3:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
801075e8:	e9 fd f1 ff ff       	jmp    801067ea <alltraps>

801075ed <vector194>:
.globl vector194
vector194:
  pushl $0
801075ed:	6a 00                	push   $0x0
  pushl $194
801075ef:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
801075f4:	e9 f1 f1 ff ff       	jmp    801067ea <alltraps>

801075f9 <vector195>:
.globl vector195
vector195:
  pushl $0
801075f9:	6a 00                	push   $0x0
  pushl $195
801075fb:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107600:	e9 e5 f1 ff ff       	jmp    801067ea <alltraps>

80107605 <vector196>:
.globl vector196
vector196:
  pushl $0
80107605:	6a 00                	push   $0x0
  pushl $196
80107607:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
8010760c:	e9 d9 f1 ff ff       	jmp    801067ea <alltraps>

80107611 <vector197>:
.globl vector197
vector197:
  pushl $0
80107611:	6a 00                	push   $0x0
  pushl $197
80107613:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107618:	e9 cd f1 ff ff       	jmp    801067ea <alltraps>

8010761d <vector198>:
.globl vector198
vector198:
  pushl $0
8010761d:	6a 00                	push   $0x0
  pushl $198
8010761f:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107624:	e9 c1 f1 ff ff       	jmp    801067ea <alltraps>

80107629 <vector199>:
.globl vector199
vector199:
  pushl $0
80107629:	6a 00                	push   $0x0
  pushl $199
8010762b:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107630:	e9 b5 f1 ff ff       	jmp    801067ea <alltraps>

80107635 <vector200>:
.globl vector200
vector200:
  pushl $0
80107635:	6a 00                	push   $0x0
  pushl $200
80107637:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
8010763c:	e9 a9 f1 ff ff       	jmp    801067ea <alltraps>

80107641 <vector201>:
.globl vector201
vector201:
  pushl $0
80107641:	6a 00                	push   $0x0
  pushl $201
80107643:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80107648:	e9 9d f1 ff ff       	jmp    801067ea <alltraps>

8010764d <vector202>:
.globl vector202
vector202:
  pushl $0
8010764d:	6a 00                	push   $0x0
  pushl $202
8010764f:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107654:	e9 91 f1 ff ff       	jmp    801067ea <alltraps>

80107659 <vector203>:
.globl vector203
vector203:
  pushl $0
80107659:	6a 00                	push   $0x0
  pushl $203
8010765b:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107660:	e9 85 f1 ff ff       	jmp    801067ea <alltraps>

80107665 <vector204>:
.globl vector204
vector204:
  pushl $0
80107665:	6a 00                	push   $0x0
  pushl $204
80107667:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
8010766c:	e9 79 f1 ff ff       	jmp    801067ea <alltraps>

80107671 <vector205>:
.globl vector205
vector205:
  pushl $0
80107671:	6a 00                	push   $0x0
  pushl $205
80107673:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107678:	e9 6d f1 ff ff       	jmp    801067ea <alltraps>

8010767d <vector206>:
.globl vector206
vector206:
  pushl $0
8010767d:	6a 00                	push   $0x0
  pushl $206
8010767f:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107684:	e9 61 f1 ff ff       	jmp    801067ea <alltraps>

80107689 <vector207>:
.globl vector207
vector207:
  pushl $0
80107689:	6a 00                	push   $0x0
  pushl $207
8010768b:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107690:	e9 55 f1 ff ff       	jmp    801067ea <alltraps>

80107695 <vector208>:
.globl vector208
vector208:
  pushl $0
80107695:	6a 00                	push   $0x0
  pushl $208
80107697:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
8010769c:	e9 49 f1 ff ff       	jmp    801067ea <alltraps>

801076a1 <vector209>:
.globl vector209
vector209:
  pushl $0
801076a1:	6a 00                	push   $0x0
  pushl $209
801076a3:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
801076a8:	e9 3d f1 ff ff       	jmp    801067ea <alltraps>

801076ad <vector210>:
.globl vector210
vector210:
  pushl $0
801076ad:	6a 00                	push   $0x0
  pushl $210
801076af:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
801076b4:	e9 31 f1 ff ff       	jmp    801067ea <alltraps>

801076b9 <vector211>:
.globl vector211
vector211:
  pushl $0
801076b9:	6a 00                	push   $0x0
  pushl $211
801076bb:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
801076c0:	e9 25 f1 ff ff       	jmp    801067ea <alltraps>

801076c5 <vector212>:
.globl vector212
vector212:
  pushl $0
801076c5:	6a 00                	push   $0x0
  pushl $212
801076c7:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
801076cc:	e9 19 f1 ff ff       	jmp    801067ea <alltraps>

801076d1 <vector213>:
.globl vector213
vector213:
  pushl $0
801076d1:	6a 00                	push   $0x0
  pushl $213
801076d3:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
801076d8:	e9 0d f1 ff ff       	jmp    801067ea <alltraps>

801076dd <vector214>:
.globl vector214
vector214:
  pushl $0
801076dd:	6a 00                	push   $0x0
  pushl $214
801076df:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
801076e4:	e9 01 f1 ff ff       	jmp    801067ea <alltraps>

801076e9 <vector215>:
.globl vector215
vector215:
  pushl $0
801076e9:	6a 00                	push   $0x0
  pushl $215
801076eb:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
801076f0:	e9 f5 f0 ff ff       	jmp    801067ea <alltraps>

801076f5 <vector216>:
.globl vector216
vector216:
  pushl $0
801076f5:	6a 00                	push   $0x0
  pushl $216
801076f7:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
801076fc:	e9 e9 f0 ff ff       	jmp    801067ea <alltraps>

80107701 <vector217>:
.globl vector217
vector217:
  pushl $0
80107701:	6a 00                	push   $0x0
  pushl $217
80107703:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107708:	e9 dd f0 ff ff       	jmp    801067ea <alltraps>

8010770d <vector218>:
.globl vector218
vector218:
  pushl $0
8010770d:	6a 00                	push   $0x0
  pushl $218
8010770f:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80107714:	e9 d1 f0 ff ff       	jmp    801067ea <alltraps>

80107719 <vector219>:
.globl vector219
vector219:
  pushl $0
80107719:	6a 00                	push   $0x0
  pushl $219
8010771b:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107720:	e9 c5 f0 ff ff       	jmp    801067ea <alltraps>

80107725 <vector220>:
.globl vector220
vector220:
  pushl $0
80107725:	6a 00                	push   $0x0
  pushl $220
80107727:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
8010772c:	e9 b9 f0 ff ff       	jmp    801067ea <alltraps>

80107731 <vector221>:
.globl vector221
vector221:
  pushl $0
80107731:	6a 00                	push   $0x0
  pushl $221
80107733:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80107738:	e9 ad f0 ff ff       	jmp    801067ea <alltraps>

8010773d <vector222>:
.globl vector222
vector222:
  pushl $0
8010773d:	6a 00                	push   $0x0
  pushl $222
8010773f:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80107744:	e9 a1 f0 ff ff       	jmp    801067ea <alltraps>

80107749 <vector223>:
.globl vector223
vector223:
  pushl $0
80107749:	6a 00                	push   $0x0
  pushl $223
8010774b:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107750:	e9 95 f0 ff ff       	jmp    801067ea <alltraps>

80107755 <vector224>:
.globl vector224
vector224:
  pushl $0
80107755:	6a 00                	push   $0x0
  pushl $224
80107757:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
8010775c:	e9 89 f0 ff ff       	jmp    801067ea <alltraps>

80107761 <vector225>:
.globl vector225
vector225:
  pushl $0
80107761:	6a 00                	push   $0x0
  pushl $225
80107763:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80107768:	e9 7d f0 ff ff       	jmp    801067ea <alltraps>

8010776d <vector226>:
.globl vector226
vector226:
  pushl $0
8010776d:	6a 00                	push   $0x0
  pushl $226
8010776f:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107774:	e9 71 f0 ff ff       	jmp    801067ea <alltraps>

80107779 <vector227>:
.globl vector227
vector227:
  pushl $0
80107779:	6a 00                	push   $0x0
  pushl $227
8010777b:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80107780:	e9 65 f0 ff ff       	jmp    801067ea <alltraps>

80107785 <vector228>:
.globl vector228
vector228:
  pushl $0
80107785:	6a 00                	push   $0x0
  pushl $228
80107787:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
8010778c:	e9 59 f0 ff ff       	jmp    801067ea <alltraps>

80107791 <vector229>:
.globl vector229
vector229:
  pushl $0
80107791:	6a 00                	push   $0x0
  pushl $229
80107793:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80107798:	e9 4d f0 ff ff       	jmp    801067ea <alltraps>

8010779d <vector230>:
.globl vector230
vector230:
  pushl $0
8010779d:	6a 00                	push   $0x0
  pushl $230
8010779f:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
801077a4:	e9 41 f0 ff ff       	jmp    801067ea <alltraps>

801077a9 <vector231>:
.globl vector231
vector231:
  pushl $0
801077a9:	6a 00                	push   $0x0
  pushl $231
801077ab:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
801077b0:	e9 35 f0 ff ff       	jmp    801067ea <alltraps>

801077b5 <vector232>:
.globl vector232
vector232:
  pushl $0
801077b5:	6a 00                	push   $0x0
  pushl $232
801077b7:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
801077bc:	e9 29 f0 ff ff       	jmp    801067ea <alltraps>

801077c1 <vector233>:
.globl vector233
vector233:
  pushl $0
801077c1:	6a 00                	push   $0x0
  pushl $233
801077c3:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
801077c8:	e9 1d f0 ff ff       	jmp    801067ea <alltraps>

801077cd <vector234>:
.globl vector234
vector234:
  pushl $0
801077cd:	6a 00                	push   $0x0
  pushl $234
801077cf:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
801077d4:	e9 11 f0 ff ff       	jmp    801067ea <alltraps>

801077d9 <vector235>:
.globl vector235
vector235:
  pushl $0
801077d9:	6a 00                	push   $0x0
  pushl $235
801077db:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
801077e0:	e9 05 f0 ff ff       	jmp    801067ea <alltraps>

801077e5 <vector236>:
.globl vector236
vector236:
  pushl $0
801077e5:	6a 00                	push   $0x0
  pushl $236
801077e7:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
801077ec:	e9 f9 ef ff ff       	jmp    801067ea <alltraps>

801077f1 <vector237>:
.globl vector237
vector237:
  pushl $0
801077f1:	6a 00                	push   $0x0
  pushl $237
801077f3:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
801077f8:	e9 ed ef ff ff       	jmp    801067ea <alltraps>

801077fd <vector238>:
.globl vector238
vector238:
  pushl $0
801077fd:	6a 00                	push   $0x0
  pushl $238
801077ff:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107804:	e9 e1 ef ff ff       	jmp    801067ea <alltraps>

80107809 <vector239>:
.globl vector239
vector239:
  pushl $0
80107809:	6a 00                	push   $0x0
  pushl $239
8010780b:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107810:	e9 d5 ef ff ff       	jmp    801067ea <alltraps>

80107815 <vector240>:
.globl vector240
vector240:
  pushl $0
80107815:	6a 00                	push   $0x0
  pushl $240
80107817:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
8010781c:	e9 c9 ef ff ff       	jmp    801067ea <alltraps>

80107821 <vector241>:
.globl vector241
vector241:
  pushl $0
80107821:	6a 00                	push   $0x0
  pushl $241
80107823:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80107828:	e9 bd ef ff ff       	jmp    801067ea <alltraps>

8010782d <vector242>:
.globl vector242
vector242:
  pushl $0
8010782d:	6a 00                	push   $0x0
  pushl $242
8010782f:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80107834:	e9 b1 ef ff ff       	jmp    801067ea <alltraps>

80107839 <vector243>:
.globl vector243
vector243:
  pushl $0
80107839:	6a 00                	push   $0x0
  pushl $243
8010783b:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107840:	e9 a5 ef ff ff       	jmp    801067ea <alltraps>

80107845 <vector244>:
.globl vector244
vector244:
  pushl $0
80107845:	6a 00                	push   $0x0
  pushl $244
80107847:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
8010784c:	e9 99 ef ff ff       	jmp    801067ea <alltraps>

80107851 <vector245>:
.globl vector245
vector245:
  pushl $0
80107851:	6a 00                	push   $0x0
  pushl $245
80107853:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80107858:	e9 8d ef ff ff       	jmp    801067ea <alltraps>

8010785d <vector246>:
.globl vector246
vector246:
  pushl $0
8010785d:	6a 00                	push   $0x0
  pushl $246
8010785f:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80107864:	e9 81 ef ff ff       	jmp    801067ea <alltraps>

80107869 <vector247>:
.globl vector247
vector247:
  pushl $0
80107869:	6a 00                	push   $0x0
  pushl $247
8010786b:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80107870:	e9 75 ef ff ff       	jmp    801067ea <alltraps>

80107875 <vector248>:
.globl vector248
vector248:
  pushl $0
80107875:	6a 00                	push   $0x0
  pushl $248
80107877:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
8010787c:	e9 69 ef ff ff       	jmp    801067ea <alltraps>

80107881 <vector249>:
.globl vector249
vector249:
  pushl $0
80107881:	6a 00                	push   $0x0
  pushl $249
80107883:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80107888:	e9 5d ef ff ff       	jmp    801067ea <alltraps>

8010788d <vector250>:
.globl vector250
vector250:
  pushl $0
8010788d:	6a 00                	push   $0x0
  pushl $250
8010788f:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80107894:	e9 51 ef ff ff       	jmp    801067ea <alltraps>

80107899 <vector251>:
.globl vector251
vector251:
  pushl $0
80107899:	6a 00                	push   $0x0
  pushl $251
8010789b:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
801078a0:	e9 45 ef ff ff       	jmp    801067ea <alltraps>

801078a5 <vector252>:
.globl vector252
vector252:
  pushl $0
801078a5:	6a 00                	push   $0x0
  pushl $252
801078a7:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
801078ac:	e9 39 ef ff ff       	jmp    801067ea <alltraps>

801078b1 <vector253>:
.globl vector253
vector253:
  pushl $0
801078b1:	6a 00                	push   $0x0
  pushl $253
801078b3:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
801078b8:	e9 2d ef ff ff       	jmp    801067ea <alltraps>

801078bd <vector254>:
.globl vector254
vector254:
  pushl $0
801078bd:	6a 00                	push   $0x0
  pushl $254
801078bf:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
801078c4:	e9 21 ef ff ff       	jmp    801067ea <alltraps>

801078c9 <vector255>:
.globl vector255
vector255:
  pushl $0
801078c9:	6a 00                	push   $0x0
  pushl $255
801078cb:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
801078d0:	e9 15 ef ff ff       	jmp    801067ea <alltraps>

801078d5 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
801078d5:	55                   	push   %ebp
801078d6:	89 e5                	mov    %esp,%ebp
801078d8:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
801078db:	8b 45 0c             	mov    0xc(%ebp),%eax
801078de:	83 e8 01             	sub    $0x1,%eax
801078e1:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801078e5:	8b 45 08             	mov    0x8(%ebp),%eax
801078e8:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801078ec:	8b 45 08             	mov    0x8(%ebp),%eax
801078ef:	c1 e8 10             	shr    $0x10,%eax
801078f2:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
801078f6:	8d 45 fa             	lea    -0x6(%ebp),%eax
801078f9:	0f 01 10             	lgdtl  (%eax)
}
801078fc:	c9                   	leave  
801078fd:	c3                   	ret    

801078fe <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
801078fe:	55                   	push   %ebp
801078ff:	89 e5                	mov    %esp,%ebp
80107901:	83 ec 04             	sub    $0x4,%esp
80107904:	8b 45 08             	mov    0x8(%ebp),%eax
80107907:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
8010790b:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010790f:	0f 00 d8             	ltr    %ax
}
80107912:	c9                   	leave  
80107913:	c3                   	ret    

80107914 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80107914:	55                   	push   %ebp
80107915:	89 e5                	mov    %esp,%ebp
80107917:	83 ec 04             	sub    $0x4,%esp
8010791a:	8b 45 08             	mov    0x8(%ebp),%eax
8010791d:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80107921:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107925:	8e e8                	mov    %eax,%gs
}
80107927:	c9                   	leave  
80107928:	c3                   	ret    

80107929 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80107929:	55                   	push   %ebp
8010792a:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
8010792c:	8b 45 08             	mov    0x8(%ebp),%eax
8010792f:	0f 22 d8             	mov    %eax,%cr3
}
80107932:	5d                   	pop    %ebp
80107933:	c3                   	ret    

80107934 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80107934:	55                   	push   %ebp
80107935:	89 e5                	mov    %esp,%ebp
80107937:	8b 45 08             	mov    0x8(%ebp),%eax
8010793a:	05 00 00 00 80       	add    $0x80000000,%eax
8010793f:	5d                   	pop    %ebp
80107940:	c3                   	ret    

80107941 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80107941:	55                   	push   %ebp
80107942:	89 e5                	mov    %esp,%ebp
80107944:	8b 45 08             	mov    0x8(%ebp),%eax
80107947:	05 00 00 00 80       	add    $0x80000000,%eax
8010794c:	5d                   	pop    %ebp
8010794d:	c3                   	ret    

8010794e <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
8010794e:	55                   	push   %ebp
8010794f:	89 e5                	mov    %esp,%ebp
80107951:	53                   	push   %ebx
80107952:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80107955:	e8 39 b6 ff ff       	call   80102f93 <cpunum>
8010795a:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80107960:	05 a0 23 11 80       	add    $0x801123a0,%eax
80107965:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80107968:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010796b:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80107971:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107974:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
8010797a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010797d:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80107981:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107984:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107988:	83 e2 f0             	and    $0xfffffff0,%edx
8010798b:	83 ca 0a             	or     $0xa,%edx
8010798e:	88 50 7d             	mov    %dl,0x7d(%eax)
80107991:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107994:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107998:	83 ca 10             	or     $0x10,%edx
8010799b:	88 50 7d             	mov    %dl,0x7d(%eax)
8010799e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079a1:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801079a5:	83 e2 9f             	and    $0xffffff9f,%edx
801079a8:	88 50 7d             	mov    %dl,0x7d(%eax)
801079ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079ae:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801079b2:	83 ca 80             	or     $0xffffff80,%edx
801079b5:	88 50 7d             	mov    %dl,0x7d(%eax)
801079b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079bb:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801079bf:	83 ca 0f             	or     $0xf,%edx
801079c2:	88 50 7e             	mov    %dl,0x7e(%eax)
801079c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079c8:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801079cc:	83 e2 ef             	and    $0xffffffef,%edx
801079cf:	88 50 7e             	mov    %dl,0x7e(%eax)
801079d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079d5:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801079d9:	83 e2 df             	and    $0xffffffdf,%edx
801079dc:	88 50 7e             	mov    %dl,0x7e(%eax)
801079df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079e2:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801079e6:	83 ca 40             	or     $0x40,%edx
801079e9:	88 50 7e             	mov    %dl,0x7e(%eax)
801079ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079ef:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801079f3:	83 ca 80             	or     $0xffffff80,%edx
801079f6:	88 50 7e             	mov    %dl,0x7e(%eax)
801079f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079fc:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80107a00:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a03:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80107a0a:	ff ff 
80107a0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a0f:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80107a16:	00 00 
80107a18:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a1b:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80107a22:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a25:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107a2c:	83 e2 f0             	and    $0xfffffff0,%edx
80107a2f:	83 ca 02             	or     $0x2,%edx
80107a32:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107a38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a3b:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107a42:	83 ca 10             	or     $0x10,%edx
80107a45:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107a4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a4e:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107a55:	83 e2 9f             	and    $0xffffff9f,%edx
80107a58:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107a5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a61:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107a68:	83 ca 80             	or     $0xffffff80,%edx
80107a6b:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107a71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a74:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107a7b:	83 ca 0f             	or     $0xf,%edx
80107a7e:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107a84:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a87:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107a8e:	83 e2 ef             	and    $0xffffffef,%edx
80107a91:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107a97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a9a:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107aa1:	83 e2 df             	and    $0xffffffdf,%edx
80107aa4:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107aaa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aad:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107ab4:	83 ca 40             	or     $0x40,%edx
80107ab7:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107abd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ac0:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107ac7:	83 ca 80             	or     $0xffffff80,%edx
80107aca:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107ad0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ad3:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80107ada:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107add:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80107ae4:	ff ff 
80107ae6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ae9:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80107af0:	00 00 
80107af2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107af5:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80107afc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aff:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107b06:	83 e2 f0             	and    $0xfffffff0,%edx
80107b09:	83 ca 0a             	or     $0xa,%edx
80107b0c:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107b12:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b15:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107b1c:	83 ca 10             	or     $0x10,%edx
80107b1f:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107b25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b28:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107b2f:	83 ca 60             	or     $0x60,%edx
80107b32:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107b38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b3b:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107b42:	83 ca 80             	or     $0xffffff80,%edx
80107b45:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107b4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b4e:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107b55:	83 ca 0f             	or     $0xf,%edx
80107b58:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107b5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b61:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107b68:	83 e2 ef             	and    $0xffffffef,%edx
80107b6b:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107b71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b74:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107b7b:	83 e2 df             	and    $0xffffffdf,%edx
80107b7e:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107b84:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b87:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107b8e:	83 ca 40             	or     $0x40,%edx
80107b91:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107b97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b9a:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107ba1:	83 ca 80             	or     $0xffffff80,%edx
80107ba4:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107baa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bad:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80107bb4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bb7:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80107bbe:	ff ff 
80107bc0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bc3:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80107bca:	00 00 
80107bcc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bcf:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80107bd6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bd9:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107be0:	83 e2 f0             	and    $0xfffffff0,%edx
80107be3:	83 ca 02             	or     $0x2,%edx
80107be6:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107bec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bef:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107bf6:	83 ca 10             	or     $0x10,%edx
80107bf9:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107bff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c02:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107c09:	83 ca 60             	or     $0x60,%edx
80107c0c:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107c12:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c15:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107c1c:	83 ca 80             	or     $0xffffff80,%edx
80107c1f:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107c25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c28:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107c2f:	83 ca 0f             	or     $0xf,%edx
80107c32:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107c38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c3b:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107c42:	83 e2 ef             	and    $0xffffffef,%edx
80107c45:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107c4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c4e:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107c55:	83 e2 df             	and    $0xffffffdf,%edx
80107c58:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107c5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c61:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107c68:	83 ca 40             	or     $0x40,%edx
80107c6b:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107c71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c74:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107c7b:	83 ca 80             	or     $0xffffff80,%edx
80107c7e:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107c84:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c87:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80107c8e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c91:	05 b4 00 00 00       	add    $0xb4,%eax
80107c96:	89 c3                	mov    %eax,%ebx
80107c98:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c9b:	05 b4 00 00 00       	add    $0xb4,%eax
80107ca0:	c1 e8 10             	shr    $0x10,%eax
80107ca3:	89 c1                	mov    %eax,%ecx
80107ca5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ca8:	05 b4 00 00 00       	add    $0xb4,%eax
80107cad:	c1 e8 18             	shr    $0x18,%eax
80107cb0:	89 c2                	mov    %eax,%edx
80107cb2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cb5:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80107cbc:	00 00 
80107cbe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cc1:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80107cc8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ccb:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80107cd1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cd4:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107cdb:	83 e1 f0             	and    $0xfffffff0,%ecx
80107cde:	83 c9 02             	or     $0x2,%ecx
80107ce1:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107ce7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cea:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107cf1:	83 c9 10             	or     $0x10,%ecx
80107cf4:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107cfa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cfd:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107d04:	83 e1 9f             	and    $0xffffff9f,%ecx
80107d07:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107d0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d10:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107d17:	83 c9 80             	or     $0xffffff80,%ecx
80107d1a:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107d20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d23:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107d2a:	83 e1 f0             	and    $0xfffffff0,%ecx
80107d2d:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107d33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d36:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107d3d:	83 e1 ef             	and    $0xffffffef,%ecx
80107d40:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107d46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d49:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107d50:	83 e1 df             	and    $0xffffffdf,%ecx
80107d53:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107d59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d5c:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107d63:	83 c9 40             	or     $0x40,%ecx
80107d66:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107d6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d6f:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107d76:	83 c9 80             	or     $0xffffff80,%ecx
80107d79:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107d7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d82:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80107d88:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d8b:	83 c0 70             	add    $0x70,%eax
80107d8e:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80107d95:	00 
80107d96:	89 04 24             	mov    %eax,(%esp)
80107d99:	e8 37 fb ff ff       	call   801078d5 <lgdt>
  loadgs(SEG_KCPU << 3);
80107d9e:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80107da5:	e8 6a fb ff ff       	call   80107914 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80107daa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dad:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80107db3:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80107dba:	00 00 00 00 
}
80107dbe:	83 c4 24             	add    $0x24,%esp
80107dc1:	5b                   	pop    %ebx
80107dc2:	5d                   	pop    %ebp
80107dc3:	c3                   	ret    

80107dc4 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80107dc4:	55                   	push   %ebp
80107dc5:	89 e5                	mov    %esp,%ebp
80107dc7:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80107dca:	8b 45 0c             	mov    0xc(%ebp),%eax
80107dcd:	c1 e8 16             	shr    $0x16,%eax
80107dd0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107dd7:	8b 45 08             	mov    0x8(%ebp),%eax
80107dda:	01 d0                	add    %edx,%eax
80107ddc:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80107ddf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107de2:	8b 00                	mov    (%eax),%eax
80107de4:	83 e0 01             	and    $0x1,%eax
80107de7:	85 c0                	test   %eax,%eax
80107de9:	74 17                	je     80107e02 <walkpgdir+0x3e>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80107deb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107dee:	8b 00                	mov    (%eax),%eax
80107df0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107df5:	89 04 24             	mov    %eax,(%esp)
80107df8:	e8 44 fb ff ff       	call   80107941 <p2v>
80107dfd:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107e00:	eb 4b                	jmp    80107e4d <walkpgdir+0x89>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80107e02:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80107e06:	74 0e                	je     80107e16 <walkpgdir+0x52>
80107e08:	e8 f0 ad ff ff       	call   80102bfd <kalloc>
80107e0d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107e10:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107e14:	75 07                	jne    80107e1d <walkpgdir+0x59>
      return 0;
80107e16:	b8 00 00 00 00       	mov    $0x0,%eax
80107e1b:	eb 47                	jmp    80107e64 <walkpgdir+0xa0>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80107e1d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107e24:	00 
80107e25:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107e2c:	00 
80107e2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e30:	89 04 24             	mov    %eax,(%esp)
80107e33:	e8 58 d5 ff ff       	call   80105390 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80107e38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e3b:	89 04 24             	mov    %eax,(%esp)
80107e3e:	e8 f1 fa ff ff       	call   80107934 <v2p>
80107e43:	83 c8 07             	or     $0x7,%eax
80107e46:	89 c2                	mov    %eax,%edx
80107e48:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107e4b:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80107e4d:	8b 45 0c             	mov    0xc(%ebp),%eax
80107e50:	c1 e8 0c             	shr    $0xc,%eax
80107e53:	25 ff 03 00 00       	and    $0x3ff,%eax
80107e58:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107e5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e62:	01 d0                	add    %edx,%eax
}
80107e64:	c9                   	leave  
80107e65:	c3                   	ret    

80107e66 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80107e66:	55                   	push   %ebp
80107e67:	89 e5                	mov    %esp,%ebp
80107e69:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80107e6c:	8b 45 0c             	mov    0xc(%ebp),%eax
80107e6f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107e74:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80107e77:	8b 55 0c             	mov    0xc(%ebp),%edx
80107e7a:	8b 45 10             	mov    0x10(%ebp),%eax
80107e7d:	01 d0                	add    %edx,%eax
80107e7f:	83 e8 01             	sub    $0x1,%eax
80107e82:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107e87:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80107e8a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80107e91:	00 
80107e92:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e95:	89 44 24 04          	mov    %eax,0x4(%esp)
80107e99:	8b 45 08             	mov    0x8(%ebp),%eax
80107e9c:	89 04 24             	mov    %eax,(%esp)
80107e9f:	e8 20 ff ff ff       	call   80107dc4 <walkpgdir>
80107ea4:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107ea7:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107eab:	75 07                	jne    80107eb4 <mappages+0x4e>
      return -1;
80107ead:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107eb2:	eb 48                	jmp    80107efc <mappages+0x96>
    if(*pte & PTE_P)
80107eb4:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107eb7:	8b 00                	mov    (%eax),%eax
80107eb9:	83 e0 01             	and    $0x1,%eax
80107ebc:	85 c0                	test   %eax,%eax
80107ebe:	74 0c                	je     80107ecc <mappages+0x66>
      panic("remap");
80107ec0:	c7 04 24 10 8d 10 80 	movl   $0x80108d10,(%esp)
80107ec7:	e8 6e 86 ff ff       	call   8010053a <panic>
    *pte = pa | perm | PTE_P;
80107ecc:	8b 45 18             	mov    0x18(%ebp),%eax
80107ecf:	0b 45 14             	or     0x14(%ebp),%eax
80107ed2:	83 c8 01             	or     $0x1,%eax
80107ed5:	89 c2                	mov    %eax,%edx
80107ed7:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107eda:	89 10                	mov    %edx,(%eax)
    if(a == last)
80107edc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107edf:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107ee2:	75 08                	jne    80107eec <mappages+0x86>
      break;
80107ee4:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80107ee5:	b8 00 00 00 00       	mov    $0x0,%eax
80107eea:	eb 10                	jmp    80107efc <mappages+0x96>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
80107eec:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80107ef3:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80107efa:	eb 8e                	jmp    80107e8a <mappages+0x24>
  return 0;
}
80107efc:	c9                   	leave  
80107efd:	c3                   	ret    

80107efe <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
80107efe:	55                   	push   %ebp
80107eff:	89 e5                	mov    %esp,%ebp
80107f01:	53                   	push   %ebx
80107f02:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80107f05:	e8 f3 ac ff ff       	call   80102bfd <kalloc>
80107f0a:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107f0d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107f11:	75 0a                	jne    80107f1d <setupkvm+0x1f>
    return 0;
80107f13:	b8 00 00 00 00       	mov    $0x0,%eax
80107f18:	e9 98 00 00 00       	jmp    80107fb5 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80107f1d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107f24:	00 
80107f25:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107f2c:	00 
80107f2d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f30:	89 04 24             	mov    %eax,(%esp)
80107f33:	e8 58 d4 ff ff       	call   80105390 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80107f38:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80107f3f:	e8 fd f9 ff ff       	call   80107941 <p2v>
80107f44:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80107f49:	76 0c                	jbe    80107f57 <setupkvm+0x59>
    panic("PHYSTOP too high");
80107f4b:	c7 04 24 16 8d 10 80 	movl   $0x80108d16,(%esp)
80107f52:	e8 e3 85 ff ff       	call   8010053a <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107f57:	c7 45 f4 a0 b4 10 80 	movl   $0x8010b4a0,-0xc(%ebp)
80107f5e:	eb 49                	jmp    80107fa9 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80107f60:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f63:	8b 48 0c             	mov    0xc(%eax),%ecx
80107f66:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f69:	8b 50 04             	mov    0x4(%eax),%edx
80107f6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f6f:	8b 58 08             	mov    0x8(%eax),%ebx
80107f72:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f75:	8b 40 04             	mov    0x4(%eax),%eax
80107f78:	29 c3                	sub    %eax,%ebx
80107f7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f7d:	8b 00                	mov    (%eax),%eax
80107f7f:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80107f83:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107f87:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107f8b:	89 44 24 04          	mov    %eax,0x4(%esp)
80107f8f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f92:	89 04 24             	mov    %eax,(%esp)
80107f95:	e8 cc fe ff ff       	call   80107e66 <mappages>
80107f9a:	85 c0                	test   %eax,%eax
80107f9c:	79 07                	jns    80107fa5 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80107f9e:	b8 00 00 00 00       	mov    $0x0,%eax
80107fa3:	eb 10                	jmp    80107fb5 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107fa5:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80107fa9:	81 7d f4 e0 b4 10 80 	cmpl   $0x8010b4e0,-0xc(%ebp)
80107fb0:	72 ae                	jb     80107f60 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80107fb2:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80107fb5:	83 c4 34             	add    $0x34,%esp
80107fb8:	5b                   	pop    %ebx
80107fb9:	5d                   	pop    %ebp
80107fba:	c3                   	ret    

80107fbb <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80107fbb:	55                   	push   %ebp
80107fbc:	89 e5                	mov    %esp,%ebp
80107fbe:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80107fc1:	e8 38 ff ff ff       	call   80107efe <setupkvm>
80107fc6:	a3 78 51 11 80       	mov    %eax,0x80115178
  switchkvm();
80107fcb:	e8 02 00 00 00       	call   80107fd2 <switchkvm>
}
80107fd0:	c9                   	leave  
80107fd1:	c3                   	ret    

80107fd2 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80107fd2:	55                   	push   %ebp
80107fd3:	89 e5                	mov    %esp,%ebp
80107fd5:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80107fd8:	a1 78 51 11 80       	mov    0x80115178,%eax
80107fdd:	89 04 24             	mov    %eax,(%esp)
80107fe0:	e8 4f f9 ff ff       	call   80107934 <v2p>
80107fe5:	89 04 24             	mov    %eax,(%esp)
80107fe8:	e8 3c f9 ff ff       	call   80107929 <lcr3>
}
80107fed:	c9                   	leave  
80107fee:	c3                   	ret    

80107fef <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80107fef:	55                   	push   %ebp
80107ff0:	89 e5                	mov    %esp,%ebp
80107ff2:	53                   	push   %ebx
80107ff3:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80107ff6:	e8 95 d2 ff ff       	call   80105290 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80107ffb:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108001:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108008:	83 c2 08             	add    $0x8,%edx
8010800b:	89 d3                	mov    %edx,%ebx
8010800d:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108014:	83 c2 08             	add    $0x8,%edx
80108017:	c1 ea 10             	shr    $0x10,%edx
8010801a:	89 d1                	mov    %edx,%ecx
8010801c:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108023:	83 c2 08             	add    $0x8,%edx
80108026:	c1 ea 18             	shr    $0x18,%edx
80108029:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80108030:	67 00 
80108032:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80108039:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
8010803f:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108046:	83 e1 f0             	and    $0xfffffff0,%ecx
80108049:	83 c9 09             	or     $0x9,%ecx
8010804c:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108052:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108059:	83 c9 10             	or     $0x10,%ecx
8010805c:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108062:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108069:	83 e1 9f             	and    $0xffffff9f,%ecx
8010806c:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108072:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108079:	83 c9 80             	or     $0xffffff80,%ecx
8010807c:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108082:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108089:	83 e1 f0             	and    $0xfffffff0,%ecx
8010808c:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108092:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108099:	83 e1 ef             	and    $0xffffffef,%ecx
8010809c:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801080a2:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801080a9:	83 e1 df             	and    $0xffffffdf,%ecx
801080ac:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801080b2:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801080b9:	83 c9 40             	or     $0x40,%ecx
801080bc:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801080c2:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801080c9:	83 e1 7f             	and    $0x7f,%ecx
801080cc:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801080d2:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
801080d8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801080de:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
801080e5:	83 e2 ef             	and    $0xffffffef,%edx
801080e8:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
801080ee:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801080f4:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
801080fa:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108100:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80108107:	8b 52 08             	mov    0x8(%edx),%edx
8010810a:	81 c2 00 10 00 00    	add    $0x1000,%edx
80108110:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80108113:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
8010811a:	e8 df f7 ff ff       	call   801078fe <ltr>
  if(p->pgdir == 0)
8010811f:	8b 45 08             	mov    0x8(%ebp),%eax
80108122:	8b 40 04             	mov    0x4(%eax),%eax
80108125:	85 c0                	test   %eax,%eax
80108127:	75 0c                	jne    80108135 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80108129:	c7 04 24 27 8d 10 80 	movl   $0x80108d27,(%esp)
80108130:	e8 05 84 ff ff       	call   8010053a <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80108135:	8b 45 08             	mov    0x8(%ebp),%eax
80108138:	8b 40 04             	mov    0x4(%eax),%eax
8010813b:	89 04 24             	mov    %eax,(%esp)
8010813e:	e8 f1 f7 ff ff       	call   80107934 <v2p>
80108143:	89 04 24             	mov    %eax,(%esp)
80108146:	e8 de f7 ff ff       	call   80107929 <lcr3>
  popcli();
8010814b:	e8 84 d1 ff ff       	call   801052d4 <popcli>
}
80108150:	83 c4 14             	add    $0x14,%esp
80108153:	5b                   	pop    %ebx
80108154:	5d                   	pop    %ebp
80108155:	c3                   	ret    

80108156 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80108156:	55                   	push   %ebp
80108157:	89 e5                	mov    %esp,%ebp
80108159:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
8010815c:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80108163:	76 0c                	jbe    80108171 <inituvm+0x1b>
    panic("inituvm: more than a page");
80108165:	c7 04 24 3b 8d 10 80 	movl   $0x80108d3b,(%esp)
8010816c:	e8 c9 83 ff ff       	call   8010053a <panic>
  mem = kalloc();
80108171:	e8 87 aa ff ff       	call   80102bfd <kalloc>
80108176:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80108179:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108180:	00 
80108181:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108188:	00 
80108189:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010818c:	89 04 24             	mov    %eax,(%esp)
8010818f:	e8 fc d1 ff ff       	call   80105390 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108194:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108197:	89 04 24             	mov    %eax,(%esp)
8010819a:	e8 95 f7 ff ff       	call   80107934 <v2p>
8010819f:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801081a6:	00 
801081a7:	89 44 24 0c          	mov    %eax,0xc(%esp)
801081ab:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801081b2:	00 
801081b3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801081ba:	00 
801081bb:	8b 45 08             	mov    0x8(%ebp),%eax
801081be:	89 04 24             	mov    %eax,(%esp)
801081c1:	e8 a0 fc ff ff       	call   80107e66 <mappages>
  memmove(mem, init, sz);
801081c6:	8b 45 10             	mov    0x10(%ebp),%eax
801081c9:	89 44 24 08          	mov    %eax,0x8(%esp)
801081cd:	8b 45 0c             	mov    0xc(%ebp),%eax
801081d0:	89 44 24 04          	mov    %eax,0x4(%esp)
801081d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081d7:	89 04 24             	mov    %eax,(%esp)
801081da:	e8 80 d2 ff ff       	call   8010545f <memmove>
}
801081df:	c9                   	leave  
801081e0:	c3                   	ret    

801081e1 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
801081e1:	55                   	push   %ebp
801081e2:	89 e5                	mov    %esp,%ebp
801081e4:	53                   	push   %ebx
801081e5:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
801081e8:	8b 45 0c             	mov    0xc(%ebp),%eax
801081eb:	25 ff 0f 00 00       	and    $0xfff,%eax
801081f0:	85 c0                	test   %eax,%eax
801081f2:	74 0c                	je     80108200 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
801081f4:	c7 04 24 58 8d 10 80 	movl   $0x80108d58,(%esp)
801081fb:	e8 3a 83 ff ff       	call   8010053a <panic>
  for(i = 0; i < sz; i += PGSIZE){
80108200:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108207:	e9 a9 00 00 00       	jmp    801082b5 <loaduvm+0xd4>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
8010820c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010820f:	8b 55 0c             	mov    0xc(%ebp),%edx
80108212:	01 d0                	add    %edx,%eax
80108214:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010821b:	00 
8010821c:	89 44 24 04          	mov    %eax,0x4(%esp)
80108220:	8b 45 08             	mov    0x8(%ebp),%eax
80108223:	89 04 24             	mov    %eax,(%esp)
80108226:	e8 99 fb ff ff       	call   80107dc4 <walkpgdir>
8010822b:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010822e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108232:	75 0c                	jne    80108240 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80108234:	c7 04 24 7b 8d 10 80 	movl   $0x80108d7b,(%esp)
8010823b:	e8 fa 82 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80108240:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108243:	8b 00                	mov    (%eax),%eax
80108245:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010824a:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
8010824d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108250:	8b 55 18             	mov    0x18(%ebp),%edx
80108253:	29 c2                	sub    %eax,%edx
80108255:	89 d0                	mov    %edx,%eax
80108257:	3d ff 0f 00 00       	cmp    $0xfff,%eax
8010825c:	77 0f                	ja     8010826d <loaduvm+0x8c>
      n = sz - i;
8010825e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108261:	8b 55 18             	mov    0x18(%ebp),%edx
80108264:	29 c2                	sub    %eax,%edx
80108266:	89 d0                	mov    %edx,%eax
80108268:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010826b:	eb 07                	jmp    80108274 <loaduvm+0x93>
    else
      n = PGSIZE;
8010826d:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80108274:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108277:	8b 55 14             	mov    0x14(%ebp),%edx
8010827a:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
8010827d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108280:	89 04 24             	mov    %eax,(%esp)
80108283:	e8 b9 f6 ff ff       	call   80107941 <p2v>
80108288:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010828b:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010828f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108293:	89 44 24 04          	mov    %eax,0x4(%esp)
80108297:	8b 45 10             	mov    0x10(%ebp),%eax
8010829a:	89 04 24             	mov    %eax,(%esp)
8010829d:	e8 c6 9a ff ff       	call   80101d68 <readi>
801082a2:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801082a5:	74 07                	je     801082ae <loaduvm+0xcd>
      return -1;
801082a7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801082ac:	eb 18                	jmp    801082c6 <loaduvm+0xe5>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
801082ae:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801082b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082b8:	3b 45 18             	cmp    0x18(%ebp),%eax
801082bb:	0f 82 4b ff ff ff    	jb     8010820c <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
801082c1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801082c6:	83 c4 24             	add    $0x24,%esp
801082c9:	5b                   	pop    %ebx
801082ca:	5d                   	pop    %ebp
801082cb:	c3                   	ret    

801082cc <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801082cc:	55                   	push   %ebp
801082cd:	89 e5                	mov    %esp,%ebp
801082cf:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
801082d2:	8b 45 10             	mov    0x10(%ebp),%eax
801082d5:	85 c0                	test   %eax,%eax
801082d7:	79 0a                	jns    801082e3 <allocuvm+0x17>
    return 0;
801082d9:	b8 00 00 00 00       	mov    $0x0,%eax
801082de:	e9 c1 00 00 00       	jmp    801083a4 <allocuvm+0xd8>
  if(newsz < oldsz)
801082e3:	8b 45 10             	mov    0x10(%ebp),%eax
801082e6:	3b 45 0c             	cmp    0xc(%ebp),%eax
801082e9:	73 08                	jae    801082f3 <allocuvm+0x27>
    return oldsz;
801082eb:	8b 45 0c             	mov    0xc(%ebp),%eax
801082ee:	e9 b1 00 00 00       	jmp    801083a4 <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
801082f3:	8b 45 0c             	mov    0xc(%ebp),%eax
801082f6:	05 ff 0f 00 00       	add    $0xfff,%eax
801082fb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108300:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80108303:	e9 8d 00 00 00       	jmp    80108395 <allocuvm+0xc9>
    mem = kalloc();
80108308:	e8 f0 a8 ff ff       	call   80102bfd <kalloc>
8010830d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80108310:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108314:	75 2c                	jne    80108342 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80108316:	c7 04 24 99 8d 10 80 	movl   $0x80108d99,(%esp)
8010831d:	e8 7e 80 ff ff       	call   801003a0 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80108322:	8b 45 0c             	mov    0xc(%ebp),%eax
80108325:	89 44 24 08          	mov    %eax,0x8(%esp)
80108329:	8b 45 10             	mov    0x10(%ebp),%eax
8010832c:	89 44 24 04          	mov    %eax,0x4(%esp)
80108330:	8b 45 08             	mov    0x8(%ebp),%eax
80108333:	89 04 24             	mov    %eax,(%esp)
80108336:	e8 6b 00 00 00       	call   801083a6 <deallocuvm>
      return 0;
8010833b:	b8 00 00 00 00       	mov    $0x0,%eax
80108340:	eb 62                	jmp    801083a4 <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80108342:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108349:	00 
8010834a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108351:	00 
80108352:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108355:	89 04 24             	mov    %eax,(%esp)
80108358:	e8 33 d0 ff ff       	call   80105390 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
8010835d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108360:	89 04 24             	mov    %eax,(%esp)
80108363:	e8 cc f5 ff ff       	call   80107934 <v2p>
80108368:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010836b:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108372:	00 
80108373:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108377:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010837e:	00 
8010837f:	89 54 24 04          	mov    %edx,0x4(%esp)
80108383:	8b 45 08             	mov    0x8(%ebp),%eax
80108386:	89 04 24             	mov    %eax,(%esp)
80108389:	e8 d8 fa ff ff       	call   80107e66 <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
8010838e:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108395:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108398:	3b 45 10             	cmp    0x10(%ebp),%eax
8010839b:	0f 82 67 ff ff ff    	jb     80108308 <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
801083a1:	8b 45 10             	mov    0x10(%ebp),%eax
}
801083a4:	c9                   	leave  
801083a5:	c3                   	ret    

801083a6 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801083a6:	55                   	push   %ebp
801083a7:	89 e5                	mov    %esp,%ebp
801083a9:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801083ac:	8b 45 10             	mov    0x10(%ebp),%eax
801083af:	3b 45 0c             	cmp    0xc(%ebp),%eax
801083b2:	72 08                	jb     801083bc <deallocuvm+0x16>
    return oldsz;
801083b4:	8b 45 0c             	mov    0xc(%ebp),%eax
801083b7:	e9 a4 00 00 00       	jmp    80108460 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
801083bc:	8b 45 10             	mov    0x10(%ebp),%eax
801083bf:	05 ff 0f 00 00       	add    $0xfff,%eax
801083c4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801083c9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
801083cc:	e9 80 00 00 00       	jmp    80108451 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
801083d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083d4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801083db:	00 
801083dc:	89 44 24 04          	mov    %eax,0x4(%esp)
801083e0:	8b 45 08             	mov    0x8(%ebp),%eax
801083e3:	89 04 24             	mov    %eax,(%esp)
801083e6:	e8 d9 f9 ff ff       	call   80107dc4 <walkpgdir>
801083eb:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
801083ee:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801083f2:	75 09                	jne    801083fd <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
801083f4:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
801083fb:	eb 4d                	jmp    8010844a <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
801083fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108400:	8b 00                	mov    (%eax),%eax
80108402:	83 e0 01             	and    $0x1,%eax
80108405:	85 c0                	test   %eax,%eax
80108407:	74 41                	je     8010844a <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80108409:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010840c:	8b 00                	mov    (%eax),%eax
8010840e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108413:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80108416:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010841a:	75 0c                	jne    80108428 <deallocuvm+0x82>
        panic("kfree");
8010841c:	c7 04 24 b1 8d 10 80 	movl   $0x80108db1,(%esp)
80108423:	e8 12 81 ff ff       	call   8010053a <panic>
      char *v = p2v(pa);
80108428:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010842b:	89 04 24             	mov    %eax,(%esp)
8010842e:	e8 0e f5 ff ff       	call   80107941 <p2v>
80108433:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80108436:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108439:	89 04 24             	mov    %eax,(%esp)
8010843c:	e8 23 a7 ff ff       	call   80102b64 <kfree>
      *pte = 0;
80108441:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108444:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
8010844a:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108451:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108454:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108457:	0f 82 74 ff ff ff    	jb     801083d1 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
8010845d:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108460:	c9                   	leave  
80108461:	c3                   	ret    

80108462 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80108462:	55                   	push   %ebp
80108463:	89 e5                	mov    %esp,%ebp
80108465:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80108468:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010846c:	75 0c                	jne    8010847a <freevm+0x18>
    panic("freevm: no pgdir");
8010846e:	c7 04 24 b7 8d 10 80 	movl   $0x80108db7,(%esp)
80108475:	e8 c0 80 ff ff       	call   8010053a <panic>
  deallocuvm(pgdir, KERNBASE, 0);
8010847a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108481:	00 
80108482:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80108489:	80 
8010848a:	8b 45 08             	mov    0x8(%ebp),%eax
8010848d:	89 04 24             	mov    %eax,(%esp)
80108490:	e8 11 ff ff ff       	call   801083a6 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80108495:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010849c:	eb 48                	jmp    801084e6 <freevm+0x84>
    if(pgdir[i] & PTE_P){
8010849e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084a1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801084a8:	8b 45 08             	mov    0x8(%ebp),%eax
801084ab:	01 d0                	add    %edx,%eax
801084ad:	8b 00                	mov    (%eax),%eax
801084af:	83 e0 01             	and    $0x1,%eax
801084b2:	85 c0                	test   %eax,%eax
801084b4:	74 2c                	je     801084e2 <freevm+0x80>
      char * v = p2v(PTE_ADDR(pgdir[i]));
801084b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084b9:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801084c0:	8b 45 08             	mov    0x8(%ebp),%eax
801084c3:	01 d0                	add    %edx,%eax
801084c5:	8b 00                	mov    (%eax),%eax
801084c7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801084cc:	89 04 24             	mov    %eax,(%esp)
801084cf:	e8 6d f4 ff ff       	call   80107941 <p2v>
801084d4:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
801084d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801084da:	89 04 24             	mov    %eax,(%esp)
801084dd:	e8 82 a6 ff ff       	call   80102b64 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
801084e2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801084e6:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
801084ed:	76 af                	jbe    8010849e <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
801084ef:	8b 45 08             	mov    0x8(%ebp),%eax
801084f2:	89 04 24             	mov    %eax,(%esp)
801084f5:	e8 6a a6 ff ff       	call   80102b64 <kfree>
}
801084fa:	c9                   	leave  
801084fb:	c3                   	ret    

801084fc <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
801084fc:	55                   	push   %ebp
801084fd:	89 e5                	mov    %esp,%ebp
801084ff:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108502:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108509:	00 
8010850a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010850d:	89 44 24 04          	mov    %eax,0x4(%esp)
80108511:	8b 45 08             	mov    0x8(%ebp),%eax
80108514:	89 04 24             	mov    %eax,(%esp)
80108517:	e8 a8 f8 ff ff       	call   80107dc4 <walkpgdir>
8010851c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
8010851f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108523:	75 0c                	jne    80108531 <clearpteu+0x35>
    panic("clearpteu");
80108525:	c7 04 24 c8 8d 10 80 	movl   $0x80108dc8,(%esp)
8010852c:	e8 09 80 ff ff       	call   8010053a <panic>
  *pte &= ~PTE_U;
80108531:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108534:	8b 00                	mov    (%eax),%eax
80108536:	83 e0 fb             	and    $0xfffffffb,%eax
80108539:	89 c2                	mov    %eax,%edx
8010853b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010853e:	89 10                	mov    %edx,(%eax)
}
80108540:	c9                   	leave  
80108541:	c3                   	ret    

80108542 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80108542:	55                   	push   %ebp
80108543:	89 e5                	mov    %esp,%ebp
80108545:	53                   	push   %ebx
80108546:	83 ec 44             	sub    $0x44,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80108549:	e8 b0 f9 ff ff       	call   80107efe <setupkvm>
8010854e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108551:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108555:	75 0a                	jne    80108561 <copyuvm+0x1f>
    return 0;
80108557:	b8 00 00 00 00       	mov    $0x0,%eax
8010855c:	e9 fd 00 00 00       	jmp    8010865e <copyuvm+0x11c>
  for(i = 0; i < sz; i += PGSIZE){
80108561:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108568:	e9 d0 00 00 00       	jmp    8010863d <copyuvm+0xfb>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
8010856d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108570:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108577:	00 
80108578:	89 44 24 04          	mov    %eax,0x4(%esp)
8010857c:	8b 45 08             	mov    0x8(%ebp),%eax
8010857f:	89 04 24             	mov    %eax,(%esp)
80108582:	e8 3d f8 ff ff       	call   80107dc4 <walkpgdir>
80108587:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010858a:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010858e:	75 0c                	jne    8010859c <copyuvm+0x5a>
      panic("copyuvm: pte should exist");
80108590:	c7 04 24 d2 8d 10 80 	movl   $0x80108dd2,(%esp)
80108597:	e8 9e 7f ff ff       	call   8010053a <panic>
    if(!(*pte & PTE_P))
8010859c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010859f:	8b 00                	mov    (%eax),%eax
801085a1:	83 e0 01             	and    $0x1,%eax
801085a4:	85 c0                	test   %eax,%eax
801085a6:	75 0c                	jne    801085b4 <copyuvm+0x72>
      panic("copyuvm: page not present");
801085a8:	c7 04 24 ec 8d 10 80 	movl   $0x80108dec,(%esp)
801085af:	e8 86 7f ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
801085b4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801085b7:	8b 00                	mov    (%eax),%eax
801085b9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801085be:	89 45 e8             	mov    %eax,-0x18(%ebp)
    flags = PTE_FLAGS(*pte);
801085c1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801085c4:	8b 00                	mov    (%eax),%eax
801085c6:	25 ff 0f 00 00       	and    $0xfff,%eax
801085cb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if((mem = kalloc()) == 0)
801085ce:	e8 2a a6 ff ff       	call   80102bfd <kalloc>
801085d3:	89 45 e0             	mov    %eax,-0x20(%ebp)
801085d6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801085da:	75 02                	jne    801085de <copyuvm+0x9c>
      goto bad;
801085dc:	eb 70                	jmp    8010864e <copyuvm+0x10c>
    memmove(mem, (char*)p2v(pa), PGSIZE);
801085de:	8b 45 e8             	mov    -0x18(%ebp),%eax
801085e1:	89 04 24             	mov    %eax,(%esp)
801085e4:	e8 58 f3 ff ff       	call   80107941 <p2v>
801085e9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801085f0:	00 
801085f1:	89 44 24 04          	mov    %eax,0x4(%esp)
801085f5:	8b 45 e0             	mov    -0x20(%ebp),%eax
801085f8:	89 04 24             	mov    %eax,(%esp)
801085fb:	e8 5f ce ff ff       	call   8010545f <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
80108600:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
80108603:	8b 45 e0             	mov    -0x20(%ebp),%eax
80108606:	89 04 24             	mov    %eax,(%esp)
80108609:	e8 26 f3 ff ff       	call   80107934 <v2p>
8010860e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108611:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80108615:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108619:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108620:	00 
80108621:	89 54 24 04          	mov    %edx,0x4(%esp)
80108625:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108628:	89 04 24             	mov    %eax,(%esp)
8010862b:	e8 36 f8 ff ff       	call   80107e66 <mappages>
80108630:	85 c0                	test   %eax,%eax
80108632:	79 02                	jns    80108636 <copyuvm+0xf4>
      goto bad;
80108634:	eb 18                	jmp    8010864e <copyuvm+0x10c>
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80108636:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010863d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108640:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108643:	0f 82 24 ff ff ff    	jb     8010856d <copyuvm+0x2b>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
      goto bad;
  }
  return d;
80108649:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010864c:	eb 10                	jmp    8010865e <copyuvm+0x11c>

bad:
  freevm(d);
8010864e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108651:	89 04 24             	mov    %eax,(%esp)
80108654:	e8 09 fe ff ff       	call   80108462 <freevm>
  return 0;
80108659:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010865e:	83 c4 44             	add    $0x44,%esp
80108661:	5b                   	pop    %ebx
80108662:	5d                   	pop    %ebp
80108663:	c3                   	ret    

80108664 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80108664:	55                   	push   %ebp
80108665:	89 e5                	mov    %esp,%ebp
80108667:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010866a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108671:	00 
80108672:	8b 45 0c             	mov    0xc(%ebp),%eax
80108675:	89 44 24 04          	mov    %eax,0x4(%esp)
80108679:	8b 45 08             	mov    0x8(%ebp),%eax
8010867c:	89 04 24             	mov    %eax,(%esp)
8010867f:	e8 40 f7 ff ff       	call   80107dc4 <walkpgdir>
80108684:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
80108687:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010868a:	8b 00                	mov    (%eax),%eax
8010868c:	83 e0 01             	and    $0x1,%eax
8010868f:	85 c0                	test   %eax,%eax
80108691:	75 07                	jne    8010869a <uva2ka+0x36>
    return 0;
80108693:	b8 00 00 00 00       	mov    $0x0,%eax
80108698:	eb 25                	jmp    801086bf <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
8010869a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010869d:	8b 00                	mov    (%eax),%eax
8010869f:	83 e0 04             	and    $0x4,%eax
801086a2:	85 c0                	test   %eax,%eax
801086a4:	75 07                	jne    801086ad <uva2ka+0x49>
    return 0;
801086a6:	b8 00 00 00 00       	mov    $0x0,%eax
801086ab:	eb 12                	jmp    801086bf <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
801086ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086b0:	8b 00                	mov    (%eax),%eax
801086b2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801086b7:	89 04 24             	mov    %eax,(%esp)
801086ba:	e8 82 f2 ff ff       	call   80107941 <p2v>
}
801086bf:	c9                   	leave  
801086c0:	c3                   	ret    

801086c1 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801086c1:	55                   	push   %ebp
801086c2:	89 e5                	mov    %esp,%ebp
801086c4:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
801086c7:	8b 45 10             	mov    0x10(%ebp),%eax
801086ca:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
801086cd:	e9 87 00 00 00       	jmp    80108759 <copyout+0x98>
    va0 = (uint)PGROUNDDOWN(va);
801086d2:	8b 45 0c             	mov    0xc(%ebp),%eax
801086d5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801086da:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
801086dd:	8b 45 ec             	mov    -0x14(%ebp),%eax
801086e0:	89 44 24 04          	mov    %eax,0x4(%esp)
801086e4:	8b 45 08             	mov    0x8(%ebp),%eax
801086e7:	89 04 24             	mov    %eax,(%esp)
801086ea:	e8 75 ff ff ff       	call   80108664 <uva2ka>
801086ef:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
801086f2:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801086f6:	75 07                	jne    801086ff <copyout+0x3e>
      return -1;
801086f8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801086fd:	eb 69                	jmp    80108768 <copyout+0xa7>
    n = PGSIZE - (va - va0);
801086ff:	8b 45 0c             	mov    0xc(%ebp),%eax
80108702:	8b 55 ec             	mov    -0x14(%ebp),%edx
80108705:	29 c2                	sub    %eax,%edx
80108707:	89 d0                	mov    %edx,%eax
80108709:	05 00 10 00 00       	add    $0x1000,%eax
8010870e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80108711:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108714:	3b 45 14             	cmp    0x14(%ebp),%eax
80108717:	76 06                	jbe    8010871f <copyout+0x5e>
      n = len;
80108719:	8b 45 14             	mov    0x14(%ebp),%eax
8010871c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
8010871f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108722:	8b 55 0c             	mov    0xc(%ebp),%edx
80108725:	29 c2                	sub    %eax,%edx
80108727:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010872a:	01 c2                	add    %eax,%edx
8010872c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010872f:	89 44 24 08          	mov    %eax,0x8(%esp)
80108733:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108736:	89 44 24 04          	mov    %eax,0x4(%esp)
8010873a:	89 14 24             	mov    %edx,(%esp)
8010873d:	e8 1d cd ff ff       	call   8010545f <memmove>
    len -= n;
80108742:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108745:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80108748:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010874b:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
8010874e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108751:	05 00 10 00 00       	add    $0x1000,%eax
80108756:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80108759:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010875d:	0f 85 6f ff ff ff    	jne    801086d2 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
80108763:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108768:	c9                   	leave  
80108769:	c3                   	ret    
