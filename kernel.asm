
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
80100015:	b8 00 b0 10 00       	mov    $0x10b000,%eax
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
80100028:	bc 50 d6 10 80       	mov    $0x8010d650,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 29 39 10 80       	mov    $0x80103929,%eax
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
8010003a:	c7 44 24 04 8c 90 10 	movl   $0x8010908c,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
80100049:	e8 ed 59 00 00       	call   80105a3b <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 70 15 11 80 64 	movl   $0x80111564,0x80111570
80100055:	15 11 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 74 15 11 80 64 	movl   $0x80111564,0x80111574
8010005f:	15 11 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 94 d6 10 80 	movl   $0x8010d694,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 74 15 11 80    	mov    0x80111574,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c 64 15 11 80 	movl   $0x80111564,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 74 15 11 80       	mov    0x80111574,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 74 15 11 80       	mov    %eax,0x80111574

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 64 15 11 80 	cmpl   $0x80111564,-0xc(%ebp)
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
801000b6:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
801000bd:	e8 9a 59 00 00       	call   80105a5c <acquire>

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 74 15 11 80       	mov    0x80111574,%eax
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
801000fd:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
80100104:	e8 b5 59 00 00       	call   80105abe <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 d6 10 	movl   $0x8010d660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 4f 4d 00 00       	call   80104e73 <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 64 15 11 80 	cmpl   $0x80111564,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
  }

  // Not cached; recycle some non-busy and clean buffer.
  // "clean" because B_DIRTY and !B_BUSY means log.c
  // hasn't yet committed the changes to the buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 70 15 11 80       	mov    0x80111570,%eax
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
80100175:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
8010017c:	e8 3d 59 00 00       	call   80105abe <release>
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
8010018f:	81 7d f4 64 15 11 80 	cmpl   $0x80111564,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 93 90 10 80 	movl   $0x80109093,(%esp)
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
801001d3:	e8 db 27 00 00       	call   801029b3 <iderw>
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
801001ef:	c7 04 24 a4 90 10 80 	movl   $0x801090a4,(%esp)
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
80100210:	e8 9e 27 00 00       	call   801029b3 <iderw>
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
80100229:	c7 04 24 ab 90 10 80 	movl   $0x801090ab,(%esp)
80100230:	e8 05 03 00 00       	call   8010053a <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
8010023c:	e8 1b 58 00 00       	call   80105a5c <acquire>

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
8010025f:	8b 15 74 15 11 80    	mov    0x80111574,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c 64 15 11 80 	movl   $0x80111564,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 74 15 11 80       	mov    0x80111574,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 74 15 11 80       	mov    %eax,0x80111574

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
8010029d:	e8 ad 4c 00 00       	call   80104f4f <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
801002a9:	e8 10 58 00 00       	call   80105abe <release>
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
80100340:	0f b6 80 04 a0 10 80 	movzbl -0x7fef5ffc(%eax),%eax
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
801003a6:	a1 f4 c5 10 80       	mov    0x8010c5f4,%eax
801003ab:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003ae:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003b2:	74 0c                	je     801003c0 <cprintf+0x20>
    acquire(&cons.lock);
801003b4:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
801003bb:	e8 9c 56 00 00       	call   80105a5c <acquire>

  if (fmt == 0)
801003c0:	8b 45 08             	mov    0x8(%ebp),%eax
801003c3:	85 c0                	test   %eax,%eax
801003c5:	75 0c                	jne    801003d3 <cprintf+0x33>
    panic("null fmt");
801003c7:	c7 04 24 b2 90 10 80 	movl   $0x801090b2,(%esp)
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
801004b0:	c7 45 ec bb 90 10 80 	movl   $0x801090bb,-0x14(%ebp)
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
8010052c:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
80100533:	e8 86 55 00 00       	call   80105abe <release>
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
80100545:	c7 05 f4 c5 10 80 00 	movl   $0x0,0x8010c5f4
8010054c:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
8010054f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100555:	0f b6 00             	movzbl (%eax),%eax
80100558:	0f b6 c0             	movzbl %al,%eax
8010055b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010055f:	c7 04 24 c2 90 10 80 	movl   $0x801090c2,(%esp)
80100566:	e8 35 fe ff ff       	call   801003a0 <cprintf>
  cprintf(s);
8010056b:	8b 45 08             	mov    0x8(%ebp),%eax
8010056e:	89 04 24             	mov    %eax,(%esp)
80100571:	e8 2a fe ff ff       	call   801003a0 <cprintf>
  cprintf("\n");
80100576:	c7 04 24 d1 90 10 80 	movl   $0x801090d1,(%esp)
8010057d:	e8 1e fe ff ff       	call   801003a0 <cprintf>
  getcallerpcs(&s, pcs);
80100582:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100585:	89 44 24 04          	mov    %eax,0x4(%esp)
80100589:	8d 45 08             	lea    0x8(%ebp),%eax
8010058c:	89 04 24             	mov    %eax,(%esp)
8010058f:	e8 79 55 00 00       	call   80105b0d <getcallerpcs>
  for(i=0; i<10; i++)
80100594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059b:	eb 1b                	jmp    801005b8 <panic+0x7e>
    cprintf(" %p", pcs[i]);
8010059d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a0:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801005a8:	c7 04 24 d3 90 10 80 	movl   $0x801090d3,(%esp)
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
801005be:	c7 05 a0 c5 10 80 01 	movl   $0x1,0x8010c5a0
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
8010066a:	8b 0d 00 a0 10 80    	mov    0x8010a000,%ecx
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
80100693:	a1 00 a0 10 80       	mov    0x8010a000,%eax
80100698:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
8010069e:	a1 00 a0 10 80       	mov    0x8010a000,%eax
801006a3:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801006aa:	00 
801006ab:	89 54 24 04          	mov    %edx,0x4(%esp)
801006af:	89 04 24             	mov    %eax,(%esp)
801006b2:	e8 c8 56 00 00       	call   80105d7f <memmove>
    pos -= 80;
801006b7:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801006bb:	b8 80 07 00 00       	mov    $0x780,%eax
801006c0:	2b 45 f4             	sub    -0xc(%ebp),%eax
801006c3:	8d 14 00             	lea    (%eax,%eax,1),%edx
801006c6:	a1 00 a0 10 80       	mov    0x8010a000,%eax
801006cb:	8b 4d f4             	mov    -0xc(%ebp),%ecx
801006ce:	01 c9                	add    %ecx,%ecx
801006d0:	01 c8                	add    %ecx,%eax
801006d2:	89 54 24 08          	mov    %edx,0x8(%esp)
801006d6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801006dd:	00 
801006de:	89 04 24             	mov    %eax,(%esp)
801006e1:	e8 ca 55 00 00       	call   80105cb0 <memset>
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
8010073d:	a1 00 a0 10 80       	mov    0x8010a000,%eax
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
80100756:	a1 a0 c5 10 80       	mov    0x8010c5a0,%eax
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
80100776:	e8 52 6f 00 00       	call   801076cd <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 46 6f 00 00       	call   801076cd <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 3a 6f 00 00       	call   801076cd <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 2d 6f 00 00       	call   801076cd <uartputc>
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
801007b3:	c7 04 24 80 17 11 80 	movl   $0x80111780,(%esp)
801007ba:	e8 9d 52 00 00       	call   80105a5c <acquire>
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
801007ea:	e8 06 48 00 00       	call   80104ff5 <procdump>
      break;
801007ef:	e9 07 01 00 00       	jmp    801008fb <consoleintr+0x14e>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
801007f4:	a1 3c 18 11 80       	mov    0x8011183c,%eax
801007f9:	83 e8 01             	sub    $0x1,%eax
801007fc:	a3 3c 18 11 80       	mov    %eax,0x8011183c
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
80100810:	8b 15 3c 18 11 80    	mov    0x8011183c,%edx
80100816:	a1 38 18 11 80       	mov    0x80111838,%eax
8010081b:	39 c2                	cmp    %eax,%edx
8010081d:	74 16                	je     80100835 <consoleintr+0x88>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
8010081f:	a1 3c 18 11 80       	mov    0x8011183c,%eax
80100824:	83 e8 01             	sub    $0x1,%eax
80100827:	83 e0 7f             	and    $0x7f,%eax
8010082a:	0f b6 80 b4 17 11 80 	movzbl -0x7feee84c(%eax),%eax
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
8010083a:	8b 15 3c 18 11 80    	mov    0x8011183c,%edx
80100840:	a1 38 18 11 80       	mov    0x80111838,%eax
80100845:	39 c2                	cmp    %eax,%edx
80100847:	74 1e                	je     80100867 <consoleintr+0xba>
        input.e--;
80100849:	a1 3c 18 11 80       	mov    0x8011183c,%eax
8010084e:	83 e8 01             	sub    $0x1,%eax
80100851:	a3 3c 18 11 80       	mov    %eax,0x8011183c
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
80100876:	8b 15 3c 18 11 80    	mov    0x8011183c,%edx
8010087c:	a1 34 18 11 80       	mov    0x80111834,%eax
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
8010089d:	a1 3c 18 11 80       	mov    0x8011183c,%eax
801008a2:	8d 50 01             	lea    0x1(%eax),%edx
801008a5:	89 15 3c 18 11 80    	mov    %edx,0x8011183c
801008ab:	83 e0 7f             	and    $0x7f,%eax
801008ae:	89 c2                	mov    %eax,%edx
801008b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008b3:	88 82 b4 17 11 80    	mov    %al,-0x7feee84c(%edx)
        consputc(c);
801008b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008bc:	89 04 24             	mov    %eax,(%esp)
801008bf:	e8 8c fe ff ff       	call   80100750 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801008c4:	83 7d f4 0a          	cmpl   $0xa,-0xc(%ebp)
801008c8:	74 18                	je     801008e2 <consoleintr+0x135>
801008ca:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
801008ce:	74 12                	je     801008e2 <consoleintr+0x135>
801008d0:	a1 3c 18 11 80       	mov    0x8011183c,%eax
801008d5:	8b 15 34 18 11 80    	mov    0x80111834,%edx
801008db:	83 ea 80             	sub    $0xffffff80,%edx
801008de:	39 d0                	cmp    %edx,%eax
801008e0:	75 18                	jne    801008fa <consoleintr+0x14d>
          input.w = input.e;
801008e2:	a1 3c 18 11 80       	mov    0x8011183c,%eax
801008e7:	a3 38 18 11 80       	mov    %eax,0x80111838
          wakeup(&input.r);
801008ec:	c7 04 24 34 18 11 80 	movl   $0x80111834,(%esp)
801008f3:	e8 57 46 00 00       	call   80104f4f <wakeup>
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
8010090d:	c7 04 24 80 17 11 80 	movl   $0x80111780,(%esp)
80100914:	e8 a5 51 00 00       	call   80105abe <release>
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
80100927:	e8 74 11 00 00       	call   80101aa0 <iunlock>
  target = n;
8010092c:	8b 45 14             	mov    0x14(%ebp),%eax
8010092f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
80100932:	c7 04 24 80 17 11 80 	movl   $0x80111780,(%esp)
80100939:	e8 1e 51 00 00       	call   80105a5c <acquire>
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
80100952:	c7 04 24 80 17 11 80 	movl   $0x80111780,(%esp)
80100959:	e8 60 51 00 00       	call   80105abe <release>
        ilock(ip);
8010095e:	8b 45 08             	mov    0x8(%ebp),%eax
80100961:	89 04 24             	mov    %eax,(%esp)
80100964:	e8 e9 0f 00 00       	call   80101952 <ilock>
        return -1;
80100969:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010096e:	e9 a5 00 00 00       	jmp    80100a18 <consoleread+0xfd>
      }
      sleep(&input.r, &input.lock);
80100973:	c7 44 24 04 80 17 11 	movl   $0x80111780,0x4(%esp)
8010097a:	80 
8010097b:	c7 04 24 34 18 11 80 	movl   $0x80111834,(%esp)
80100982:	e8 ec 44 00 00       	call   80104e73 <sleep>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
80100987:	8b 15 34 18 11 80    	mov    0x80111834,%edx
8010098d:	a1 38 18 11 80       	mov    0x80111838,%eax
80100992:	39 c2                	cmp    %eax,%edx
80100994:	74 af                	je     80100945 <consoleread+0x2a>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
80100996:	a1 34 18 11 80       	mov    0x80111834,%eax
8010099b:	8d 50 01             	lea    0x1(%eax),%edx
8010099e:	89 15 34 18 11 80    	mov    %edx,0x80111834
801009a4:	83 e0 7f             	and    $0x7f,%eax
801009a7:	0f b6 80 b4 17 11 80 	movzbl -0x7feee84c(%eax),%eax
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
801009c2:	a1 34 18 11 80       	mov    0x80111834,%eax
801009c7:	83 e8 01             	sub    $0x1,%eax
801009ca:	a3 34 18 11 80       	mov    %eax,0x80111834
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
801009f7:	c7 04 24 80 17 11 80 	movl   $0x80111780,(%esp)
801009fe:	e8 bb 50 00 00       	call   80105abe <release>
  ilock(ip);
80100a03:	8b 45 08             	mov    0x8(%ebp),%eax
80100a06:	89 04 24             	mov    %eax,(%esp)
80100a09:	e8 44 0f 00 00       	call   80101952 <ilock>

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
80100a26:	e8 75 10 00 00       	call   80101aa0 <iunlock>
  acquire(&cons.lock);
80100a2b:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
80100a32:	e8 25 50 00 00       	call   80105a5c <acquire>
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
80100a65:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
80100a6c:	e8 4d 50 00 00       	call   80105abe <release>
  ilock(ip);
80100a71:	8b 45 08             	mov    0x8(%ebp),%eax
80100a74:	89 04 24             	mov    %eax,(%esp)
80100a77:	e8 d6 0e 00 00       	call   80101952 <ilock>

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
80100a87:	c7 44 24 04 d7 90 10 	movl   $0x801090d7,0x4(%esp)
80100a8e:	80 
80100a8f:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
80100a96:	e8 a0 4f 00 00       	call   80105a3b <initlock>
  initlock(&input.lock, "input");
80100a9b:	c7 44 24 04 df 90 10 	movl   $0x801090df,0x4(%esp)
80100aa2:	80 
80100aa3:	c7 04 24 80 17 11 80 	movl   $0x80111780,(%esp)
80100aaa:	e8 8c 4f 00 00       	call   80105a3b <initlock>

  devsw[CONSOLE].write = consolewrite;
80100aaf:	c7 05 fc 21 11 80 1a 	movl   $0x80100a1a,0x801121fc
80100ab6:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ab9:	c7 05 f8 21 11 80 1b 	movl   $0x8010091b,0x801121f8
80100ac0:	09 10 80 
  cons.locking = 1;
80100ac3:	c7 05 f4 c5 10 80 01 	movl   $0x1,0x8010c5f4
80100aca:	00 00 00 

  picenable(IRQ_KBD);
80100acd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ad4:	e8 f2 34 00 00       	call   80103fcb <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ad9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100ae0:	00 
80100ae1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ae8:	e8 82 20 00 00       	call   80102b6f <ioapicenable>
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
80100af2:	53                   	push   %ebx
80100af3:	81 ec 34 01 00 00    	sub    $0x134,%esp
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;

  begin_op();
80100af9:	e8 24 2b 00 00       	call   80103622 <begin_op>
  if((ip = namei(path)) == 0){
80100afe:	8b 45 08             	mov    0x8(%ebp),%eax
80100b01:	89 04 24             	mov    %eax,(%esp)
80100b04:	e8 0f 1b 00 00       	call   80102618 <namei>
80100b09:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b0c:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b10:	75 0f                	jne    80100b21 <exec+0x32>
    end_op();
80100b12:	e8 8f 2b 00 00       	call   801036a6 <end_op>
    return -1;
80100b17:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b1c:	e9 d7 04 00 00       	jmp    80100ff8 <exec+0x509>
  }
  ilock(ip);
80100b21:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b24:	89 04 24             	mov    %eax,(%esp)
80100b27:	e8 26 0e 00 00       	call   80101952 <ilock>
  pgdir = 0;
80100b2c:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
 

  

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
80100b33:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
80100b3a:	00 
80100b3b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100b42:	00 
80100b43:	8d 85 0c ff ff ff    	lea    -0xf4(%ebp),%eax
80100b49:	89 44 24 04          	mov    %eax,0x4(%esp)
80100b4d:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b50:	89 04 24             	mov    %eax,(%esp)
80100b53:	e8 07 13 00 00       	call   80101e5f <readi>
80100b58:	83 f8 33             	cmp    $0x33,%eax
80100b5b:	77 05                	ja     80100b62 <exec+0x73>
    goto bad;
80100b5d:	e9 6a 04 00 00       	jmp    80100fcc <exec+0x4dd>
  if(elf.magic != ELF_MAGIC)
80100b62:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100b68:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b6d:	74 05                	je     80100b74 <exec+0x85>
    goto bad;
80100b6f:	e9 58 04 00 00       	jmp    80100fcc <exec+0x4dd>

  if((pgdir = setupkvm()) == 0)
80100b74:	e8 a5 7c 00 00       	call   8010881e <setupkvm>
80100b79:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100b7c:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100b80:	75 05                	jne    80100b87 <exec+0x98>
    goto bad;
80100b82:	e9 45 04 00 00       	jmp    80100fcc <exec+0x4dd>

  // Load program into memory.
  sz = 0;
80100b87:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100b8e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100b95:	8b 85 28 ff ff ff    	mov    -0xd8(%ebp),%eax
80100b9b:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100b9e:	e9 cb 00 00 00       	jmp    80100c6e <exec+0x17f>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100ba3:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100ba6:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80100bad:	00 
80100bae:	89 44 24 08          	mov    %eax,0x8(%esp)
80100bb2:	8d 85 ec fe ff ff    	lea    -0x114(%ebp),%eax
80100bb8:	89 44 24 04          	mov    %eax,0x4(%esp)
80100bbc:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100bbf:	89 04 24             	mov    %eax,(%esp)
80100bc2:	e8 98 12 00 00       	call   80101e5f <readi>
80100bc7:	83 f8 20             	cmp    $0x20,%eax
80100bca:	74 05                	je     80100bd1 <exec+0xe2>
      goto bad;
80100bcc:	e9 fb 03 00 00       	jmp    80100fcc <exec+0x4dd>
    if(ph.type != ELF_PROG_LOAD)
80100bd1:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100bd7:	83 f8 01             	cmp    $0x1,%eax
80100bda:	74 05                	je     80100be1 <exec+0xf2>
      continue;
80100bdc:	e9 80 00 00 00       	jmp    80100c61 <exec+0x172>
    if(ph.memsz < ph.filesz)
80100be1:	8b 95 00 ff ff ff    	mov    -0x100(%ebp),%edx
80100be7:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100bed:	39 c2                	cmp    %eax,%edx
80100bef:	73 05                	jae    80100bf6 <exec+0x107>
      goto bad;
80100bf1:	e9 d6 03 00 00       	jmp    80100fcc <exec+0x4dd>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100bf6:	8b 95 f4 fe ff ff    	mov    -0x10c(%ebp),%edx
80100bfc:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
80100c02:	01 d0                	add    %edx,%eax
80100c04:	89 44 24 08          	mov    %eax,0x8(%esp)
80100c08:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c0b:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c0f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c12:	89 04 24             	mov    %eax,(%esp)
80100c15:	e8 d2 7f 00 00       	call   80108bec <allocuvm>
80100c1a:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100c1d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100c21:	75 05                	jne    80100c28 <exec+0x139>
      goto bad;
80100c23:	e9 a4 03 00 00       	jmp    80100fcc <exec+0x4dd>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100c28:	8b 8d fc fe ff ff    	mov    -0x104(%ebp),%ecx
80100c2e:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100c34:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
80100c3a:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80100c3e:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100c42:	8b 55 d8             	mov    -0x28(%ebp),%edx
80100c45:	89 54 24 08          	mov    %edx,0x8(%esp)
80100c49:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c4d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c50:	89 04 24             	mov    %eax,(%esp)
80100c53:	e8 a9 7e 00 00       	call   80108b01 <loaduvm>
80100c58:	85 c0                	test   %eax,%eax
80100c5a:	79 05                	jns    80100c61 <exec+0x172>
      goto bad;
80100c5c:	e9 6b 03 00 00       	jmp    80100fcc <exec+0x4dd>
  if((pgdir = setupkvm()) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100c61:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100c65:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100c68:	83 c0 20             	add    $0x20,%eax
80100c6b:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100c6e:	0f b7 85 38 ff ff ff 	movzwl -0xc8(%ebp),%eax
80100c75:	0f b7 c0             	movzwl %ax,%eax
80100c78:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100c7b:	0f 8f 22 ff ff ff    	jg     80100ba3 <exec+0xb4>
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }

  proc->exe= ip;
80100c81:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100c87:	8b 55 d8             	mov    -0x28(%ebp),%edx
80100c8a:	89 50 7c             	mov    %edx,0x7c(%eax)

  iunlockput(ip);
80100c8d:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100c90:	89 04 24             	mov    %eax,(%esp)
80100c93:	e8 3e 0f 00 00       	call   80101bd6 <iunlockput>
  end_op();
80100c98:	e8 09 2a 00 00       	call   801036a6 <end_op>
  ip = 0;
80100c9d:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100ca4:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100ca7:	05 ff 0f 00 00       	add    $0xfff,%eax
80100cac:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100cb1:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100cb4:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cb7:	05 00 20 00 00       	add    $0x2000,%eax
80100cbc:	89 44 24 08          	mov    %eax,0x8(%esp)
80100cc0:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cc3:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cc7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cca:	89 04 24             	mov    %eax,(%esp)
80100ccd:	e8 1a 7f 00 00       	call   80108bec <allocuvm>
80100cd2:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100cd5:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100cd9:	75 05                	jne    80100ce0 <exec+0x1f1>
    goto bad;
80100cdb:	e9 ec 02 00 00       	jmp    80100fcc <exec+0x4dd>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100ce0:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100ce3:	2d 00 20 00 00       	sub    $0x2000,%eax
80100ce8:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cec:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cef:	89 04 24             	mov    %eax,(%esp)
80100cf2:	e8 25 81 00 00       	call   80108e1c <clearpteu>
  sp = sz;
80100cf7:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cfa:	89 45 dc             	mov    %eax,-0x24(%ebp)

 
  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100cfd:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100d04:	e9 9a 00 00 00       	jmp    80100da3 <exec+0x2b4>
    if(argc >= MAXARG)
80100d09:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100d0d:	76 05                	jbe    80100d14 <exec+0x225>
      goto bad;
80100d0f:	e9 b8 02 00 00       	jmp    80100fcc <exec+0x4dd>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100d14:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d17:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100d1e:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d21:	01 d0                	add    %edx,%eax
80100d23:	8b 00                	mov    (%eax),%eax
80100d25:	89 04 24             	mov    %eax,(%esp)
80100d28:	e8 ed 51 00 00       	call   80105f1a <strlen>
80100d2d:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100d30:	29 c2                	sub    %eax,%edx
80100d32:	89 d0                	mov    %edx,%eax
80100d34:	83 e8 01             	sub    $0x1,%eax
80100d37:	83 e0 fc             	and    $0xfffffffc,%eax
80100d3a:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100d3d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d40:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100d47:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d4a:	01 d0                	add    %edx,%eax
80100d4c:	8b 00                	mov    (%eax),%eax
80100d4e:	89 04 24             	mov    %eax,(%esp)
80100d51:	e8 c4 51 00 00       	call   80105f1a <strlen>
80100d56:	83 c0 01             	add    $0x1,%eax
80100d59:	89 c2                	mov    %eax,%edx
80100d5b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d5e:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
80100d65:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d68:	01 c8                	add    %ecx,%eax
80100d6a:	8b 00                	mov    (%eax),%eax
80100d6c:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100d70:	89 44 24 08          	mov    %eax,0x8(%esp)
80100d74:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d77:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d7b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d7e:	89 04 24             	mov    %eax,(%esp)
80100d81:	e8 5b 82 00 00       	call   80108fe1 <copyout>
80100d86:	85 c0                	test   %eax,%eax
80100d88:	79 05                	jns    80100d8f <exec+0x2a0>
      goto bad;
80100d8a:	e9 3d 02 00 00       	jmp    80100fcc <exec+0x4dd>
    ustack[3+argc] = sp;
80100d8f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d92:	8d 50 03             	lea    0x3(%eax),%edx
80100d95:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d98:	89 84 95 40 ff ff ff 	mov    %eax,-0xc0(%ebp,%edx,4)
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

 
  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100d9f:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100da3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100da6:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100dad:	8b 45 0c             	mov    0xc(%ebp),%eax
80100db0:	01 d0                	add    %edx,%eax
80100db2:	8b 00                	mov    (%eax),%eax
80100db4:	85 c0                	test   %eax,%eax
80100db6:	0f 85 4d ff ff ff    	jne    80100d09 <exec+0x21a>
      goto bad;
    ustack[3+argc] = sp;


  }
  ustack[3+argc] = 0;
80100dbc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dbf:	83 c0 03             	add    $0x3,%eax
80100dc2:	c7 84 85 40 ff ff ff 	movl   $0x0,-0xc0(%ebp,%eax,4)
80100dc9:	00 00 00 00 



  ustack[0] = 0xffffffff;  // fake return PC
80100dcd:	c7 85 40 ff ff ff ff 	movl   $0xffffffff,-0xc0(%ebp)
80100dd4:	ff ff ff 
  ustack[1] = argc;
80100dd7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dda:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100de0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100de3:	83 c0 01             	add    $0x1,%eax
80100de6:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100ded:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100df0:	29 d0                	sub    %edx,%eax
80100df2:	89 85 48 ff ff ff    	mov    %eax,-0xb8(%ebp)

  sp -= (3+argc+1) * 4;
80100df8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dfb:	83 c0 04             	add    $0x4,%eax
80100dfe:	c1 e0 02             	shl    $0x2,%eax
80100e01:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100e04:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e07:	83 c0 04             	add    $0x4,%eax
80100e0a:	c1 e0 02             	shl    $0x2,%eax
80100e0d:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100e11:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
80100e17:	89 44 24 08          	mov    %eax,0x8(%esp)
80100e1b:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e1e:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e22:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e25:	89 04 24             	mov    %eax,(%esp)
80100e28:	e8 b4 81 00 00       	call   80108fe1 <copyout>
80100e2d:	85 c0                	test   %eax,%eax
80100e2f:	79 05                	jns    80100e36 <exec+0x347>
    goto bad;
80100e31:	e9 96 01 00 00       	jmp    80100fcc <exec+0x4dd>

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e36:	8b 45 08             	mov    0x8(%ebp),%eax
80100e39:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100e3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e3f:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100e42:	eb 17                	jmp    80100e5b <exec+0x36c>
    if(*s == '/')
80100e44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e47:	0f b6 00             	movzbl (%eax),%eax
80100e4a:	3c 2f                	cmp    $0x2f,%al
80100e4c:	75 09                	jne    80100e57 <exec+0x368>
      last = s+1;
80100e4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e51:	83 c0 01             	add    $0x1,%eax
80100e54:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e57:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100e5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e5e:	0f b6 00             	movzbl (%eax),%eax
80100e61:	84 c0                	test   %al,%al
80100e63:	75 df                	jne    80100e44 <exec+0x355>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80100e65:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e6b:	8d 50 28             	lea    0x28(%eax),%edx
80100e6e:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100e75:	00 
80100e76:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100e79:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e7d:	89 14 24             	mov    %edx,(%esp)
80100e80:	e8 4b 50 00 00       	call   80105ed0 <safestrcpy>
  safestrcpy(proc->cmdline, path, strlen(path)+1);
80100e85:	8b 45 08             	mov    0x8(%ebp),%eax
80100e88:	89 04 24             	mov    %eax,(%esp)
80100e8b:	e8 8a 50 00 00       	call   80105f1a <strlen>
80100e90:	83 c0 01             	add    $0x1,%eax
80100e93:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80100e9a:	83 ea 80             	sub    $0xffffff80,%edx
80100e9d:	89 44 24 08          	mov    %eax,0x8(%esp)
80100ea1:	8b 45 08             	mov    0x8(%ebp),%eax
80100ea4:	89 44 24 04          	mov    %eax,0x4(%esp)
80100ea8:	89 14 24             	mov    %edx,(%esp)
80100eab:	e8 20 50 00 00       	call   80105ed0 <safestrcpy>
//  cprintf( "path : %s \n", proc->cmdline);
  for (i=0; i < MAXARGS; i++)  {
80100eb0:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100eb7:	e9 88 00 00 00       	jmp    80100f44 <exec+0x455>
	  if (argv[i]){
80100ebc:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100ebf:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100ec6:	8b 45 0c             	mov    0xc(%ebp),%eax
80100ec9:	01 d0                	add    %edx,%eax
80100ecb:	8b 00                	mov    (%eax),%eax
80100ecd:	85 c0                	test   %eax,%eax
80100ecf:	74 57                	je     80100f28 <exec+0x439>
		  safestrcpy(proc->args[i], argv[i], strlen(argv[i])+1);
80100ed1:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100ed4:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100edb:	8b 45 0c             	mov    0xc(%ebp),%eax
80100ede:	01 d0                	add    %edx,%eax
80100ee0:	8b 00                	mov    (%eax),%eax
80100ee2:	89 04 24             	mov    %eax,(%esp)
80100ee5:	e8 30 50 00 00       	call   80105f1a <strlen>
80100eea:	8d 48 01             	lea    0x1(%eax),%ecx
80100eed:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100ef0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100ef7:	8b 45 0c             	mov    0xc(%ebp),%eax
80100efa:	01 d0                	add    %edx,%eax
80100efc:	8b 00                	mov    (%eax),%eax
80100efe:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80100f05:	8b 5d ec             	mov    -0x14(%ebp),%ebx
80100f08:	6b db 64             	imul   $0x64,%ebx,%ebx
80100f0b:	81 c3 e0 00 00 00    	add    $0xe0,%ebx
80100f11:	01 da                	add    %ebx,%edx
80100f13:	83 c2 04             	add    $0x4,%edx
80100f16:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80100f1a:	89 44 24 04          	mov    %eax,0x4(%esp)
80100f1e:	89 14 24             	mov    %edx,(%esp)
80100f21:	e8 aa 4f 00 00       	call   80105ed0 <safestrcpy>
80100f26:	eb 18                	jmp    80100f40 <exec+0x451>
//		  cprintf( "arg : %s \n", proc->args[i]);
	  }
	  else proc->args[i][0]='\0';
80100f28:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80100f2f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100f32:	6b c0 64             	imul   $0x64,%eax,%eax
80100f35:	01 d0                	add    %edx,%eax
80100f37:	05 e0 00 00 00       	add    $0xe0,%eax
80100f3c:	c6 40 04 00          	movb   $0x0,0x4(%eax)
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
  safestrcpy(proc->cmdline, path, strlen(path)+1);
//  cprintf( "path : %s \n", proc->cmdline);
  for (i=0; i < MAXARGS; i++)  {
80100f40:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100f44:	83 7d ec 09          	cmpl   $0x9,-0x14(%ebp)
80100f48:	0f 8e 6e ff ff ff    	jle    80100ebc <exec+0x3cd>
	  else proc->args[i][0]='\0';
  }
  


  proc->cmdline[strlen(path)]=0 ;
80100f4e:	65 8b 1d 04 00 00 00 	mov    %gs:0x4,%ebx
80100f55:	8b 45 08             	mov    0x8(%ebp),%eax
80100f58:	89 04 24             	mov    %eax,(%esp)
80100f5b:	e8 ba 4f 00 00       	call   80105f1a <strlen>
80100f60:	c6 84 03 80 00 00 00 	movb   $0x0,0x80(%ebx,%eax,1)
80100f67:	00 


  // cprintf(" ******* cmdline %s\n", proc->cmdline);
  // Commit to the user image.
  oldpgdir = proc->pgdir;
80100f68:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f6e:	8b 40 04             	mov    0x4(%eax),%eax
80100f71:	89 45 d0             	mov    %eax,-0x30(%ebp)
  proc->pgdir = pgdir;
80100f74:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f7a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100f7d:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80100f80:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f86:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100f89:	89 10                	mov    %edx,(%eax)
  proc->tf->eip = elf.entry;  // main
80100f8b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f91:	8b 40 18             	mov    0x18(%eax),%eax
80100f94:	8b 95 24 ff ff ff    	mov    -0xdc(%ebp),%edx
80100f9a:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
80100f9d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100fa3:	8b 40 18             	mov    0x18(%eax),%eax
80100fa6:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100fa9:	89 50 44             	mov    %edx,0x44(%eax)
  
  switchuvm(proc);
80100fac:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100fb2:	89 04 24             	mov    %eax,(%esp)
80100fb5:	e8 55 79 00 00       	call   8010890f <switchuvm>
  freevm(oldpgdir);
80100fba:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100fbd:	89 04 24             	mov    %eax,(%esp)
80100fc0:	e8 bd 7d 00 00       	call   80108d82 <freevm>
  return 0;
80100fc5:	b8 00 00 00 00       	mov    $0x0,%eax
80100fca:	eb 2c                	jmp    80100ff8 <exec+0x509>

 bad:
  if(pgdir)
80100fcc:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100fd0:	74 0b                	je     80100fdd <exec+0x4ee>
    freevm(pgdir);
80100fd2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100fd5:	89 04 24             	mov    %eax,(%esp)
80100fd8:	e8 a5 7d 00 00       	call   80108d82 <freevm>
  if(ip){
80100fdd:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100fe1:	74 10                	je     80100ff3 <exec+0x504>
    iunlockput(ip);
80100fe3:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100fe6:	89 04 24             	mov    %eax,(%esp)
80100fe9:	e8 e8 0b 00 00       	call   80101bd6 <iunlockput>
    end_op();
80100fee:	e8 b3 26 00 00       	call   801036a6 <end_op>
  }
  return -1;
80100ff3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100ff8:	81 c4 34 01 00 00    	add    $0x134,%esp
80100ffe:	5b                   	pop    %ebx
80100fff:	5d                   	pop    %ebp
80101000:	c3                   	ret    

80101001 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80101001:	55                   	push   %ebp
80101002:	89 e5                	mov    %esp,%ebp
80101004:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
80101007:	c7 44 24 04 e5 90 10 	movl   $0x801090e5,0x4(%esp)
8010100e:	80 
8010100f:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
80101016:	e8 20 4a 00 00       	call   80105a3b <initlock>
}
8010101b:	c9                   	leave  
8010101c:	c3                   	ret    

8010101d <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
8010101d:	55                   	push   %ebp
8010101e:	89 e5                	mov    %esp,%ebp
80101020:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
80101023:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
8010102a:	e8 2d 4a 00 00       	call   80105a5c <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
8010102f:	c7 45 f4 74 18 11 80 	movl   $0x80111874,-0xc(%ebp)
80101036:	eb 29                	jmp    80101061 <filealloc+0x44>
    if(f->ref == 0){
80101038:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010103b:	8b 40 04             	mov    0x4(%eax),%eax
8010103e:	85 c0                	test   %eax,%eax
80101040:	75 1b                	jne    8010105d <filealloc+0x40>
      f->ref = 1;
80101042:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101045:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
8010104c:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
80101053:	e8 66 4a 00 00       	call   80105abe <release>
      return f;
80101058:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010105b:	eb 1e                	jmp    8010107b <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
8010105d:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80101061:	81 7d f4 d4 21 11 80 	cmpl   $0x801121d4,-0xc(%ebp)
80101068:	72 ce                	jb     80101038 <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
8010106a:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
80101071:	e8 48 4a 00 00       	call   80105abe <release>
  return 0;
80101076:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010107b:	c9                   	leave  
8010107c:	c3                   	ret    

8010107d <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
8010107d:	55                   	push   %ebp
8010107e:	89 e5                	mov    %esp,%ebp
80101080:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
80101083:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
8010108a:	e8 cd 49 00 00       	call   80105a5c <acquire>
  if(f->ref < 1)
8010108f:	8b 45 08             	mov    0x8(%ebp),%eax
80101092:	8b 40 04             	mov    0x4(%eax),%eax
80101095:	85 c0                	test   %eax,%eax
80101097:	7f 0c                	jg     801010a5 <filedup+0x28>
    panic("filedup");
80101099:	c7 04 24 ec 90 10 80 	movl   $0x801090ec,(%esp)
801010a0:	e8 95 f4 ff ff       	call   8010053a <panic>
  f->ref++;
801010a5:	8b 45 08             	mov    0x8(%ebp),%eax
801010a8:	8b 40 04             	mov    0x4(%eax),%eax
801010ab:	8d 50 01             	lea    0x1(%eax),%edx
801010ae:	8b 45 08             	mov    0x8(%ebp),%eax
801010b1:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
801010b4:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
801010bb:	e8 fe 49 00 00       	call   80105abe <release>
  return f;
801010c0:	8b 45 08             	mov    0x8(%ebp),%eax
}
801010c3:	c9                   	leave  
801010c4:	c3                   	ret    

801010c5 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
801010c5:	55                   	push   %ebp
801010c6:	89 e5                	mov    %esp,%ebp
801010c8:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
801010cb:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
801010d2:	e8 85 49 00 00       	call   80105a5c <acquire>
  if(f->ref < 1)
801010d7:	8b 45 08             	mov    0x8(%ebp),%eax
801010da:	8b 40 04             	mov    0x4(%eax),%eax
801010dd:	85 c0                	test   %eax,%eax
801010df:	7f 0c                	jg     801010ed <fileclose+0x28>
    panic("fileclose");
801010e1:	c7 04 24 f4 90 10 80 	movl   $0x801090f4,(%esp)
801010e8:	e8 4d f4 ff ff       	call   8010053a <panic>
  if(--f->ref > 0){
801010ed:	8b 45 08             	mov    0x8(%ebp),%eax
801010f0:	8b 40 04             	mov    0x4(%eax),%eax
801010f3:	8d 50 ff             	lea    -0x1(%eax),%edx
801010f6:	8b 45 08             	mov    0x8(%ebp),%eax
801010f9:	89 50 04             	mov    %edx,0x4(%eax)
801010fc:	8b 45 08             	mov    0x8(%ebp),%eax
801010ff:	8b 40 04             	mov    0x4(%eax),%eax
80101102:	85 c0                	test   %eax,%eax
80101104:	7e 11                	jle    80101117 <fileclose+0x52>
    release(&ftable.lock);
80101106:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
8010110d:	e8 ac 49 00 00       	call   80105abe <release>
80101112:	e9 82 00 00 00       	jmp    80101199 <fileclose+0xd4>
    return;
  }
  ff = *f;
80101117:	8b 45 08             	mov    0x8(%ebp),%eax
8010111a:	8b 10                	mov    (%eax),%edx
8010111c:	89 55 e0             	mov    %edx,-0x20(%ebp)
8010111f:	8b 50 04             	mov    0x4(%eax),%edx
80101122:	89 55 e4             	mov    %edx,-0x1c(%ebp)
80101125:	8b 50 08             	mov    0x8(%eax),%edx
80101128:	89 55 e8             	mov    %edx,-0x18(%ebp)
8010112b:	8b 50 0c             	mov    0xc(%eax),%edx
8010112e:	89 55 ec             	mov    %edx,-0x14(%ebp)
80101131:	8b 50 10             	mov    0x10(%eax),%edx
80101134:	89 55 f0             	mov    %edx,-0x10(%ebp)
80101137:	8b 40 14             	mov    0x14(%eax),%eax
8010113a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
8010113d:	8b 45 08             	mov    0x8(%ebp),%eax
80101140:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
80101147:	8b 45 08             	mov    0x8(%ebp),%eax
8010114a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
80101150:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
80101157:	e8 62 49 00 00       	call   80105abe <release>
  
  if(ff.type == FD_PIPE)
8010115c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010115f:	83 f8 01             	cmp    $0x1,%eax
80101162:	75 18                	jne    8010117c <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
80101164:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
80101168:	0f be d0             	movsbl %al,%edx
8010116b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010116e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101172:	89 04 24             	mov    %eax,(%esp)
80101175:	e8 01 31 00 00       	call   8010427b <pipeclose>
8010117a:	eb 1d                	jmp    80101199 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
8010117c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010117f:	83 f8 02             	cmp    $0x2,%eax
80101182:	75 15                	jne    80101199 <fileclose+0xd4>
    begin_op();
80101184:	e8 99 24 00 00       	call   80103622 <begin_op>
    iput(ff.ip);
80101189:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010118c:	89 04 24             	mov    %eax,(%esp)
8010118f:	e8 71 09 00 00       	call   80101b05 <iput>
    end_op();
80101194:	e8 0d 25 00 00       	call   801036a6 <end_op>
  }
}
80101199:	c9                   	leave  
8010119a:	c3                   	ret    

8010119b <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
8010119b:	55                   	push   %ebp
8010119c:	89 e5                	mov    %esp,%ebp
8010119e:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
801011a1:	8b 45 08             	mov    0x8(%ebp),%eax
801011a4:	8b 00                	mov    (%eax),%eax
801011a6:	83 f8 02             	cmp    $0x2,%eax
801011a9:	75 38                	jne    801011e3 <filestat+0x48>
    ilock(f->ip);
801011ab:	8b 45 08             	mov    0x8(%ebp),%eax
801011ae:	8b 40 10             	mov    0x10(%eax),%eax
801011b1:	89 04 24             	mov    %eax,(%esp)
801011b4:	e8 99 07 00 00       	call   80101952 <ilock>
    stati(f->ip, st);
801011b9:	8b 45 08             	mov    0x8(%ebp),%eax
801011bc:	8b 40 10             	mov    0x10(%eax),%eax
801011bf:	8b 55 0c             	mov    0xc(%ebp),%edx
801011c2:	89 54 24 04          	mov    %edx,0x4(%esp)
801011c6:	89 04 24             	mov    %eax,(%esp)
801011c9:	e8 4c 0c 00 00       	call   80101e1a <stati>
    iunlock(f->ip);
801011ce:	8b 45 08             	mov    0x8(%ebp),%eax
801011d1:	8b 40 10             	mov    0x10(%eax),%eax
801011d4:	89 04 24             	mov    %eax,(%esp)
801011d7:	e8 c4 08 00 00       	call   80101aa0 <iunlock>
    return 0;
801011dc:	b8 00 00 00 00       	mov    $0x0,%eax
801011e1:	eb 05                	jmp    801011e8 <filestat+0x4d>
  }
  return -1;
801011e3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801011e8:	c9                   	leave  
801011e9:	c3                   	ret    

801011ea <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
801011ea:	55                   	push   %ebp
801011eb:	89 e5                	mov    %esp,%ebp
801011ed:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
801011f0:	8b 45 08             	mov    0x8(%ebp),%eax
801011f3:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801011f7:	84 c0                	test   %al,%al
801011f9:	75 0a                	jne    80101205 <fileread+0x1b>
    return -1;
801011fb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101200:	e9 9f 00 00 00       	jmp    801012a4 <fileread+0xba>
  if(f->type == FD_PIPE)
80101205:	8b 45 08             	mov    0x8(%ebp),%eax
80101208:	8b 00                	mov    (%eax),%eax
8010120a:	83 f8 01             	cmp    $0x1,%eax
8010120d:	75 1e                	jne    8010122d <fileread+0x43>
    return piperead(f->pipe, addr, n);
8010120f:	8b 45 08             	mov    0x8(%ebp),%eax
80101212:	8b 40 0c             	mov    0xc(%eax),%eax
80101215:	8b 55 10             	mov    0x10(%ebp),%edx
80101218:	89 54 24 08          	mov    %edx,0x8(%esp)
8010121c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010121f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101223:	89 04 24             	mov    %eax,(%esp)
80101226:	e8 d1 31 00 00       	call   801043fc <piperead>
8010122b:	eb 77                	jmp    801012a4 <fileread+0xba>
  if(f->type == FD_INODE){
8010122d:	8b 45 08             	mov    0x8(%ebp),%eax
80101230:	8b 00                	mov    (%eax),%eax
80101232:	83 f8 02             	cmp    $0x2,%eax
80101235:	75 61                	jne    80101298 <fileread+0xae>
    ilock(f->ip);
80101237:	8b 45 08             	mov    0x8(%ebp),%eax
8010123a:	8b 40 10             	mov    0x10(%eax),%eax
8010123d:	89 04 24             	mov    %eax,(%esp)
80101240:	e8 0d 07 00 00       	call   80101952 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
80101245:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101248:	8b 45 08             	mov    0x8(%ebp),%eax
8010124b:	8b 50 14             	mov    0x14(%eax),%edx
8010124e:	8b 45 08             	mov    0x8(%ebp),%eax
80101251:	8b 40 10             	mov    0x10(%eax),%eax
80101254:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101258:	89 54 24 08          	mov    %edx,0x8(%esp)
8010125c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010125f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101263:	89 04 24             	mov    %eax,(%esp)
80101266:	e8 f4 0b 00 00       	call   80101e5f <readi>
8010126b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010126e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101272:	7e 11                	jle    80101285 <fileread+0x9b>
      f->off += r;
80101274:	8b 45 08             	mov    0x8(%ebp),%eax
80101277:	8b 50 14             	mov    0x14(%eax),%edx
8010127a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010127d:	01 c2                	add    %eax,%edx
8010127f:	8b 45 08             	mov    0x8(%ebp),%eax
80101282:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
80101285:	8b 45 08             	mov    0x8(%ebp),%eax
80101288:	8b 40 10             	mov    0x10(%eax),%eax
8010128b:	89 04 24             	mov    %eax,(%esp)
8010128e:	e8 0d 08 00 00       	call   80101aa0 <iunlock>
    return r;
80101293:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101296:	eb 0c                	jmp    801012a4 <fileread+0xba>
  }
  panic("fileread");
80101298:	c7 04 24 fe 90 10 80 	movl   $0x801090fe,(%esp)
8010129f:	e8 96 f2 ff ff       	call   8010053a <panic>
}
801012a4:	c9                   	leave  
801012a5:	c3                   	ret    

801012a6 <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
801012a6:	55                   	push   %ebp
801012a7:	89 e5                	mov    %esp,%ebp
801012a9:	53                   	push   %ebx
801012aa:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
801012ad:	8b 45 08             	mov    0x8(%ebp),%eax
801012b0:	0f b6 40 09          	movzbl 0x9(%eax),%eax
801012b4:	84 c0                	test   %al,%al
801012b6:	75 0a                	jne    801012c2 <filewrite+0x1c>
    return -1;
801012b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801012bd:	e9 20 01 00 00       	jmp    801013e2 <filewrite+0x13c>
  if(f->type == FD_PIPE)
801012c2:	8b 45 08             	mov    0x8(%ebp),%eax
801012c5:	8b 00                	mov    (%eax),%eax
801012c7:	83 f8 01             	cmp    $0x1,%eax
801012ca:	75 21                	jne    801012ed <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
801012cc:	8b 45 08             	mov    0x8(%ebp),%eax
801012cf:	8b 40 0c             	mov    0xc(%eax),%eax
801012d2:	8b 55 10             	mov    0x10(%ebp),%edx
801012d5:	89 54 24 08          	mov    %edx,0x8(%esp)
801012d9:	8b 55 0c             	mov    0xc(%ebp),%edx
801012dc:	89 54 24 04          	mov    %edx,0x4(%esp)
801012e0:	89 04 24             	mov    %eax,(%esp)
801012e3:	e8 25 30 00 00       	call   8010430d <pipewrite>
801012e8:	e9 f5 00 00 00       	jmp    801013e2 <filewrite+0x13c>
  if(f->type == FD_INODE){
801012ed:	8b 45 08             	mov    0x8(%ebp),%eax
801012f0:	8b 00                	mov    (%eax),%eax
801012f2:	83 f8 02             	cmp    $0x2,%eax
801012f5:	0f 85 db 00 00 00    	jne    801013d6 <filewrite+0x130>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
801012fb:	c7 45 ec 00 1a 00 00 	movl   $0x1a00,-0x14(%ebp)
    int i = 0;
80101302:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
80101309:	e9 a8 00 00 00       	jmp    801013b6 <filewrite+0x110>
      int n1 = n - i;
8010130e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101311:	8b 55 10             	mov    0x10(%ebp),%edx
80101314:	29 c2                	sub    %eax,%edx
80101316:	89 d0                	mov    %edx,%eax
80101318:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
8010131b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010131e:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80101321:	7e 06                	jle    80101329 <filewrite+0x83>
        n1 = max;
80101323:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101326:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_op();
80101329:	e8 f4 22 00 00       	call   80103622 <begin_op>
      ilock(f->ip);
8010132e:	8b 45 08             	mov    0x8(%ebp),%eax
80101331:	8b 40 10             	mov    0x10(%eax),%eax
80101334:	89 04 24             	mov    %eax,(%esp)
80101337:	e8 16 06 00 00       	call   80101952 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
8010133c:	8b 4d f0             	mov    -0x10(%ebp),%ecx
8010133f:	8b 45 08             	mov    0x8(%ebp),%eax
80101342:	8b 50 14             	mov    0x14(%eax),%edx
80101345:	8b 5d f4             	mov    -0xc(%ebp),%ebx
80101348:	8b 45 0c             	mov    0xc(%ebp),%eax
8010134b:	01 c3                	add    %eax,%ebx
8010134d:	8b 45 08             	mov    0x8(%ebp),%eax
80101350:	8b 40 10             	mov    0x10(%eax),%eax
80101353:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101357:	89 54 24 08          	mov    %edx,0x8(%esp)
8010135b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
8010135f:	89 04 24             	mov    %eax,(%esp)
80101362:	e8 69 0c 00 00       	call   80101fd0 <writei>
80101367:	89 45 e8             	mov    %eax,-0x18(%ebp)
8010136a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010136e:	7e 11                	jle    80101381 <filewrite+0xdb>
        f->off += r;
80101370:	8b 45 08             	mov    0x8(%ebp),%eax
80101373:	8b 50 14             	mov    0x14(%eax),%edx
80101376:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101379:	01 c2                	add    %eax,%edx
8010137b:	8b 45 08             	mov    0x8(%ebp),%eax
8010137e:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
80101381:	8b 45 08             	mov    0x8(%ebp),%eax
80101384:	8b 40 10             	mov    0x10(%eax),%eax
80101387:	89 04 24             	mov    %eax,(%esp)
8010138a:	e8 11 07 00 00       	call   80101aa0 <iunlock>
      end_op();
8010138f:	e8 12 23 00 00       	call   801036a6 <end_op>

      if(r < 0)
80101394:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101398:	79 02                	jns    8010139c <filewrite+0xf6>
        break;
8010139a:	eb 26                	jmp    801013c2 <filewrite+0x11c>
      if(r != n1)
8010139c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010139f:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801013a2:	74 0c                	je     801013b0 <filewrite+0x10a>
        panic("short filewrite");
801013a4:	c7 04 24 07 91 10 80 	movl   $0x80109107,(%esp)
801013ab:	e8 8a f1 ff ff       	call   8010053a <panic>
      i += r;
801013b0:	8b 45 e8             	mov    -0x18(%ebp),%eax
801013b3:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
801013b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013b9:	3b 45 10             	cmp    0x10(%ebp),%eax
801013bc:	0f 8c 4c ff ff ff    	jl     8010130e <filewrite+0x68>
        break;
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
801013c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013c5:	3b 45 10             	cmp    0x10(%ebp),%eax
801013c8:	75 05                	jne    801013cf <filewrite+0x129>
801013ca:	8b 45 10             	mov    0x10(%ebp),%eax
801013cd:	eb 05                	jmp    801013d4 <filewrite+0x12e>
801013cf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801013d4:	eb 0c                	jmp    801013e2 <filewrite+0x13c>
  }
  panic("filewrite");
801013d6:	c7 04 24 17 91 10 80 	movl   $0x80109117,(%esp)
801013dd:	e8 58 f1 ff ff       	call   8010053a <panic>
}
801013e2:	83 c4 24             	add    $0x24,%esp
801013e5:	5b                   	pop    %ebx
801013e6:	5d                   	pop    %ebp
801013e7:	c3                   	ret    

801013e8 <readsb>:
static void itrunc(struct inode*);

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
801013e8:	55                   	push   %ebp
801013e9:	89 e5                	mov    %esp,%ebp
801013eb:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
801013ee:	8b 45 08             	mov    0x8(%ebp),%eax
801013f1:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801013f8:	00 
801013f9:	89 04 24             	mov    %eax,(%esp)
801013fc:	e8 a5 ed ff ff       	call   801001a6 <bread>
80101401:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
80101404:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101407:	83 c0 18             	add    $0x18,%eax
8010140a:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80101411:	00 
80101412:	89 44 24 04          	mov    %eax,0x4(%esp)
80101416:	8b 45 0c             	mov    0xc(%ebp),%eax
80101419:	89 04 24             	mov    %eax,(%esp)
8010141c:	e8 5e 49 00 00       	call   80105d7f <memmove>
  brelse(bp);
80101421:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101424:	89 04 24             	mov    %eax,(%esp)
80101427:	e8 eb ed ff ff       	call   80100217 <brelse>
}
8010142c:	c9                   	leave  
8010142d:	c3                   	ret    

8010142e <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
8010142e:	55                   	push   %ebp
8010142f:	89 e5                	mov    %esp,%ebp
80101431:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
80101434:	8b 55 0c             	mov    0xc(%ebp),%edx
80101437:	8b 45 08             	mov    0x8(%ebp),%eax
8010143a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010143e:	89 04 24             	mov    %eax,(%esp)
80101441:	e8 60 ed ff ff       	call   801001a6 <bread>
80101446:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
80101449:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010144c:	83 c0 18             	add    $0x18,%eax
8010144f:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80101456:	00 
80101457:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010145e:	00 
8010145f:	89 04 24             	mov    %eax,(%esp)
80101462:	e8 49 48 00 00       	call   80105cb0 <memset>
  log_write(bp);
80101467:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010146a:	89 04 24             	mov    %eax,(%esp)
8010146d:	e8 bb 23 00 00       	call   8010382d <log_write>
  brelse(bp);
80101472:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101475:	89 04 24             	mov    %eax,(%esp)
80101478:	e8 9a ed ff ff       	call   80100217 <brelse>
}
8010147d:	c9                   	leave  
8010147e:	c3                   	ret    

8010147f <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
8010147f:	55                   	push   %ebp
80101480:	89 e5                	mov    %esp,%ebp
80101482:	83 ec 38             	sub    $0x38,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
80101485:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
8010148c:	8b 45 08             	mov    0x8(%ebp),%eax
8010148f:	8d 55 d8             	lea    -0x28(%ebp),%edx
80101492:	89 54 24 04          	mov    %edx,0x4(%esp)
80101496:	89 04 24             	mov    %eax,(%esp)
80101499:	e8 4a ff ff ff       	call   801013e8 <readsb>
  for(b = 0; b < sb.size; b += BPB){
8010149e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801014a5:	e9 07 01 00 00       	jmp    801015b1 <balloc+0x132>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
801014aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801014ad:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
801014b3:	85 c0                	test   %eax,%eax
801014b5:	0f 48 c2             	cmovs  %edx,%eax
801014b8:	c1 f8 0c             	sar    $0xc,%eax
801014bb:	8b 55 e0             	mov    -0x20(%ebp),%edx
801014be:	c1 ea 03             	shr    $0x3,%edx
801014c1:	01 d0                	add    %edx,%eax
801014c3:	83 c0 03             	add    $0x3,%eax
801014c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801014ca:	8b 45 08             	mov    0x8(%ebp),%eax
801014cd:	89 04 24             	mov    %eax,(%esp)
801014d0:	e8 d1 ec ff ff       	call   801001a6 <bread>
801014d5:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801014d8:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801014df:	e9 9d 00 00 00       	jmp    80101581 <balloc+0x102>
      m = 1 << (bi % 8);
801014e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014e7:	99                   	cltd   
801014e8:	c1 ea 1d             	shr    $0x1d,%edx
801014eb:	01 d0                	add    %edx,%eax
801014ed:	83 e0 07             	and    $0x7,%eax
801014f0:	29 d0                	sub    %edx,%eax
801014f2:	ba 01 00 00 00       	mov    $0x1,%edx
801014f7:	89 c1                	mov    %eax,%ecx
801014f9:	d3 e2                	shl    %cl,%edx
801014fb:	89 d0                	mov    %edx,%eax
801014fd:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
80101500:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101503:	8d 50 07             	lea    0x7(%eax),%edx
80101506:	85 c0                	test   %eax,%eax
80101508:	0f 48 c2             	cmovs  %edx,%eax
8010150b:	c1 f8 03             	sar    $0x3,%eax
8010150e:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101511:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101516:	0f b6 c0             	movzbl %al,%eax
80101519:	23 45 e8             	and    -0x18(%ebp),%eax
8010151c:	85 c0                	test   %eax,%eax
8010151e:	75 5d                	jne    8010157d <balloc+0xfe>
        bp->data[bi/8] |= m;  // Mark block in use.
80101520:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101523:	8d 50 07             	lea    0x7(%eax),%edx
80101526:	85 c0                	test   %eax,%eax
80101528:	0f 48 c2             	cmovs  %edx,%eax
8010152b:	c1 f8 03             	sar    $0x3,%eax
8010152e:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101531:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101536:	89 d1                	mov    %edx,%ecx
80101538:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010153b:	09 ca                	or     %ecx,%edx
8010153d:	89 d1                	mov    %edx,%ecx
8010153f:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101542:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
80101546:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101549:	89 04 24             	mov    %eax,(%esp)
8010154c:	e8 dc 22 00 00       	call   8010382d <log_write>
        brelse(bp);
80101551:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101554:	89 04 24             	mov    %eax,(%esp)
80101557:	e8 bb ec ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
8010155c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010155f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101562:	01 c2                	add    %eax,%edx
80101564:	8b 45 08             	mov    0x8(%ebp),%eax
80101567:	89 54 24 04          	mov    %edx,0x4(%esp)
8010156b:	89 04 24             	mov    %eax,(%esp)
8010156e:	e8 bb fe ff ff       	call   8010142e <bzero>
        return b + bi;
80101573:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101576:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101579:	01 d0                	add    %edx,%eax
8010157b:	eb 4e                	jmp    801015cb <balloc+0x14c>

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010157d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101581:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
80101588:	7f 15                	jg     8010159f <balloc+0x120>
8010158a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010158d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101590:	01 d0                	add    %edx,%eax
80101592:	89 c2                	mov    %eax,%edx
80101594:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101597:	39 c2                	cmp    %eax,%edx
80101599:	0f 82 45 ff ff ff    	jb     801014e4 <balloc+0x65>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
8010159f:	8b 45 ec             	mov    -0x14(%ebp),%eax
801015a2:	89 04 24             	mov    %eax,(%esp)
801015a5:	e8 6d ec ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
801015aa:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801015b1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015b4:	8b 45 d8             	mov    -0x28(%ebp),%eax
801015b7:	39 c2                	cmp    %eax,%edx
801015b9:	0f 82 eb fe ff ff    	jb     801014aa <balloc+0x2b>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
801015bf:	c7 04 24 21 91 10 80 	movl   $0x80109121,(%esp)
801015c6:	e8 6f ef ff ff       	call   8010053a <panic>
}
801015cb:	c9                   	leave  
801015cc:	c3                   	ret    

801015cd <bfree>:

// Free a disk block.
static void
bfree(int dev, uint b)
{
801015cd:	55                   	push   %ebp
801015ce:	89 e5                	mov    %esp,%ebp
801015d0:	83 ec 38             	sub    $0x38,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
801015d3:	8d 45 dc             	lea    -0x24(%ebp),%eax
801015d6:	89 44 24 04          	mov    %eax,0x4(%esp)
801015da:	8b 45 08             	mov    0x8(%ebp),%eax
801015dd:	89 04 24             	mov    %eax,(%esp)
801015e0:	e8 03 fe ff ff       	call   801013e8 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
801015e5:	8b 45 0c             	mov    0xc(%ebp),%eax
801015e8:	c1 e8 0c             	shr    $0xc,%eax
801015eb:	89 c2                	mov    %eax,%edx
801015ed:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801015f0:	c1 e8 03             	shr    $0x3,%eax
801015f3:	01 d0                	add    %edx,%eax
801015f5:	8d 50 03             	lea    0x3(%eax),%edx
801015f8:	8b 45 08             	mov    0x8(%ebp),%eax
801015fb:	89 54 24 04          	mov    %edx,0x4(%esp)
801015ff:	89 04 24             	mov    %eax,(%esp)
80101602:	e8 9f eb ff ff       	call   801001a6 <bread>
80101607:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
8010160a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010160d:	25 ff 0f 00 00       	and    $0xfff,%eax
80101612:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
80101615:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101618:	99                   	cltd   
80101619:	c1 ea 1d             	shr    $0x1d,%edx
8010161c:	01 d0                	add    %edx,%eax
8010161e:	83 e0 07             	and    $0x7,%eax
80101621:	29 d0                	sub    %edx,%eax
80101623:	ba 01 00 00 00       	mov    $0x1,%edx
80101628:	89 c1                	mov    %eax,%ecx
8010162a:	d3 e2                	shl    %cl,%edx
8010162c:	89 d0                	mov    %edx,%eax
8010162e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
80101631:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101634:	8d 50 07             	lea    0x7(%eax),%edx
80101637:	85 c0                	test   %eax,%eax
80101639:	0f 48 c2             	cmovs  %edx,%eax
8010163c:	c1 f8 03             	sar    $0x3,%eax
8010163f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101642:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101647:	0f b6 c0             	movzbl %al,%eax
8010164a:	23 45 ec             	and    -0x14(%ebp),%eax
8010164d:	85 c0                	test   %eax,%eax
8010164f:	75 0c                	jne    8010165d <bfree+0x90>
    panic("freeing free block");
80101651:	c7 04 24 37 91 10 80 	movl   $0x80109137,(%esp)
80101658:	e8 dd ee ff ff       	call   8010053a <panic>
  bp->data[bi/8] &= ~m;
8010165d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101660:	8d 50 07             	lea    0x7(%eax),%edx
80101663:	85 c0                	test   %eax,%eax
80101665:	0f 48 c2             	cmovs  %edx,%eax
80101668:	c1 f8 03             	sar    $0x3,%eax
8010166b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010166e:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101673:	8b 4d ec             	mov    -0x14(%ebp),%ecx
80101676:	f7 d1                	not    %ecx
80101678:	21 ca                	and    %ecx,%edx
8010167a:	89 d1                	mov    %edx,%ecx
8010167c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010167f:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
80101683:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101686:	89 04 24             	mov    %eax,(%esp)
80101689:	e8 9f 21 00 00       	call   8010382d <log_write>
  brelse(bp);
8010168e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101691:	89 04 24             	mov    %eax,(%esp)
80101694:	e8 7e eb ff ff       	call   80100217 <brelse>
}
80101699:	c9                   	leave  
8010169a:	c3                   	ret    

8010169b <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
8010169b:	55                   	push   %ebp
8010169c:	89 e5                	mov    %esp,%ebp
8010169e:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
801016a1:	c7 44 24 04 4a 91 10 	movl   $0x8010914a,0x4(%esp)
801016a8:	80 
801016a9:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
801016b0:	e8 86 43 00 00       	call   80105a3b <initlock>
}
801016b5:	c9                   	leave  
801016b6:	c3                   	ret    

801016b7 <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
801016b7:	55                   	push   %ebp
801016b8:	89 e5                	mov    %esp,%ebp
801016ba:	83 ec 38             	sub    $0x38,%esp
801016bd:	8b 45 0c             	mov    0xc(%ebp),%eax
801016c0:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
801016c4:	8b 45 08             	mov    0x8(%ebp),%eax
801016c7:	8d 55 dc             	lea    -0x24(%ebp),%edx
801016ca:	89 54 24 04          	mov    %edx,0x4(%esp)
801016ce:	89 04 24             	mov    %eax,(%esp)
801016d1:	e8 12 fd ff ff       	call   801013e8 <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
801016d6:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
801016dd:	e9 98 00 00 00       	jmp    8010177a <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
801016e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016e5:	c1 e8 03             	shr    $0x3,%eax
801016e8:	83 c0 02             	add    $0x2,%eax
801016eb:	89 44 24 04          	mov    %eax,0x4(%esp)
801016ef:	8b 45 08             	mov    0x8(%ebp),%eax
801016f2:	89 04 24             	mov    %eax,(%esp)
801016f5:	e8 ac ea ff ff       	call   801001a6 <bread>
801016fa:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
801016fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101700:	8d 50 18             	lea    0x18(%eax),%edx
80101703:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101706:	83 e0 07             	and    $0x7,%eax
80101709:	c1 e0 06             	shl    $0x6,%eax
8010170c:	01 d0                	add    %edx,%eax
8010170e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
80101711:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101714:	0f b7 00             	movzwl (%eax),%eax
80101717:	66 85 c0             	test   %ax,%ax
8010171a:	75 4f                	jne    8010176b <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
8010171c:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
80101723:	00 
80101724:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010172b:	00 
8010172c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010172f:	89 04 24             	mov    %eax,(%esp)
80101732:	e8 79 45 00 00       	call   80105cb0 <memset>
      dip->type = type;
80101737:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010173a:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
8010173e:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80101741:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101744:	89 04 24             	mov    %eax,(%esp)
80101747:	e8 e1 20 00 00       	call   8010382d <log_write>
      brelse(bp);
8010174c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010174f:	89 04 24             	mov    %eax,(%esp)
80101752:	e8 c0 ea ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
80101757:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010175a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010175e:	8b 45 08             	mov    0x8(%ebp),%eax
80101761:	89 04 24             	mov    %eax,(%esp)
80101764:	e8 e5 00 00 00       	call   8010184e <iget>
80101769:	eb 29                	jmp    80101794 <ialloc+0xdd>
    }
    brelse(bp);
8010176b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010176e:	89 04 24             	mov    %eax,(%esp)
80101771:	e8 a1 ea ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
80101776:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010177a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010177d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101780:	39 c2                	cmp    %eax,%edx
80101782:	0f 82 5a ff ff ff    	jb     801016e2 <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
80101788:	c7 04 24 51 91 10 80 	movl   $0x80109151,(%esp)
8010178f:	e8 a6 ed ff ff       	call   8010053a <panic>
}
80101794:	c9                   	leave  
80101795:	c3                   	ret    

80101796 <iupdate>:

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
80101796:	55                   	push   %ebp
80101797:	89 e5                	mov    %esp,%ebp
80101799:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
8010179c:	8b 45 08             	mov    0x8(%ebp),%eax
8010179f:	8b 40 04             	mov    0x4(%eax),%eax
801017a2:	c1 e8 03             	shr    $0x3,%eax
801017a5:	8d 50 02             	lea    0x2(%eax),%edx
801017a8:	8b 45 08             	mov    0x8(%ebp),%eax
801017ab:	8b 00                	mov    (%eax),%eax
801017ad:	89 54 24 04          	mov    %edx,0x4(%esp)
801017b1:	89 04 24             	mov    %eax,(%esp)
801017b4:	e8 ed e9 ff ff       	call   801001a6 <bread>
801017b9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
801017bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017bf:	8d 50 18             	lea    0x18(%eax),%edx
801017c2:	8b 45 08             	mov    0x8(%ebp),%eax
801017c5:	8b 40 04             	mov    0x4(%eax),%eax
801017c8:	83 e0 07             	and    $0x7,%eax
801017cb:	c1 e0 06             	shl    $0x6,%eax
801017ce:	01 d0                	add    %edx,%eax
801017d0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
801017d3:	8b 45 08             	mov    0x8(%ebp),%eax
801017d6:	0f b7 50 10          	movzwl 0x10(%eax),%edx
801017da:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017dd:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
801017e0:	8b 45 08             	mov    0x8(%ebp),%eax
801017e3:	0f b7 50 12          	movzwl 0x12(%eax),%edx
801017e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017ea:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
801017ee:	8b 45 08             	mov    0x8(%ebp),%eax
801017f1:	0f b7 50 14          	movzwl 0x14(%eax),%edx
801017f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017f8:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
801017fc:	8b 45 08             	mov    0x8(%ebp),%eax
801017ff:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101803:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101806:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
8010180a:	8b 45 08             	mov    0x8(%ebp),%eax
8010180d:	8b 50 18             	mov    0x18(%eax),%edx
80101810:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101813:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
80101816:	8b 45 08             	mov    0x8(%ebp),%eax
80101819:	8d 50 1c             	lea    0x1c(%eax),%edx
8010181c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010181f:	83 c0 0c             	add    $0xc,%eax
80101822:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101829:	00 
8010182a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010182e:	89 04 24             	mov    %eax,(%esp)
80101831:	e8 49 45 00 00       	call   80105d7f <memmove>
  log_write(bp);
80101836:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101839:	89 04 24             	mov    %eax,(%esp)
8010183c:	e8 ec 1f 00 00       	call   8010382d <log_write>
  brelse(bp);
80101841:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101844:	89 04 24             	mov    %eax,(%esp)
80101847:	e8 cb e9 ff ff       	call   80100217 <brelse>
}
8010184c:	c9                   	leave  
8010184d:	c3                   	ret    

8010184e <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
8010184e:	55                   	push   %ebp
8010184f:	89 e5                	mov    %esp,%ebp
80101851:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
80101854:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
8010185b:	e8 fc 41 00 00       	call   80105a5c <acquire>

  // Is the inode already cached?
  empty = 0;
80101860:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101867:	c7 45 f4 b4 22 11 80 	movl   $0x801122b4,-0xc(%ebp)
8010186e:	eb 59                	jmp    801018c9 <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
80101870:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101873:	8b 40 08             	mov    0x8(%eax),%eax
80101876:	85 c0                	test   %eax,%eax
80101878:	7e 35                	jle    801018af <iget+0x61>
8010187a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010187d:	8b 00                	mov    (%eax),%eax
8010187f:	3b 45 08             	cmp    0x8(%ebp),%eax
80101882:	75 2b                	jne    801018af <iget+0x61>
80101884:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101887:	8b 40 04             	mov    0x4(%eax),%eax
8010188a:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010188d:	75 20                	jne    801018af <iget+0x61>
      ip->ref++;
8010188f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101892:	8b 40 08             	mov    0x8(%eax),%eax
80101895:	8d 50 01             	lea    0x1(%eax),%edx
80101898:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010189b:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
8010189e:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
801018a5:	e8 14 42 00 00       	call   80105abe <release>
      return ip;
801018aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018ad:	eb 6f                	jmp    8010191e <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801018af:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801018b3:	75 10                	jne    801018c5 <iget+0x77>
801018b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018b8:	8b 40 08             	mov    0x8(%eax),%eax
801018bb:	85 c0                	test   %eax,%eax
801018bd:	75 06                	jne    801018c5 <iget+0x77>
      empty = ip;
801018bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018c2:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801018c5:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
801018c9:	81 7d f4 54 32 11 80 	cmpl   $0x80113254,-0xc(%ebp)
801018d0:	72 9e                	jb     80101870 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
801018d2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801018d6:	75 0c                	jne    801018e4 <iget+0x96>
    panic("iget: no inodes");
801018d8:	c7 04 24 63 91 10 80 	movl   $0x80109163,(%esp)
801018df:	e8 56 ec ff ff       	call   8010053a <panic>

  ip = empty;
801018e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018e7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
801018ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018ed:	8b 55 08             	mov    0x8(%ebp),%edx
801018f0:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
801018f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018f5:	8b 55 0c             	mov    0xc(%ebp),%edx
801018f8:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
801018fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018fe:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
80101905:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101908:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
8010190f:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101916:	e8 a3 41 00 00       	call   80105abe <release>

  return ip;
8010191b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010191e:	c9                   	leave  
8010191f:	c3                   	ret    

80101920 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
80101920:	55                   	push   %ebp
80101921:	89 e5                	mov    %esp,%ebp
80101923:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101926:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
8010192d:	e8 2a 41 00 00       	call   80105a5c <acquire>
  ip->ref++;
80101932:	8b 45 08             	mov    0x8(%ebp),%eax
80101935:	8b 40 08             	mov    0x8(%eax),%eax
80101938:	8d 50 01             	lea    0x1(%eax),%edx
8010193b:	8b 45 08             	mov    0x8(%ebp),%eax
8010193e:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101941:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101948:	e8 71 41 00 00       	call   80105abe <release>
  return ip;
8010194d:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101950:	c9                   	leave  
80101951:	c3                   	ret    

80101952 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
80101952:	55                   	push   %ebp
80101953:	89 e5                	mov    %esp,%ebp
80101955:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
80101958:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010195c:	74 0a                	je     80101968 <ilock+0x16>
8010195e:	8b 45 08             	mov    0x8(%ebp),%eax
80101961:	8b 40 08             	mov    0x8(%eax),%eax
80101964:	85 c0                	test   %eax,%eax
80101966:	7f 0c                	jg     80101974 <ilock+0x22>
    panic("ilock");
80101968:	c7 04 24 73 91 10 80 	movl   $0x80109173,(%esp)
8010196f:	e8 c6 eb ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80101974:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
8010197b:	e8 dc 40 00 00       	call   80105a5c <acquire>
  while(ip->flags & I_BUSY)
80101980:	eb 13                	jmp    80101995 <ilock+0x43>
    sleep(ip, &icache.lock);
80101982:	c7 44 24 04 80 22 11 	movl   $0x80112280,0x4(%esp)
80101989:	80 
8010198a:	8b 45 08             	mov    0x8(%ebp),%eax
8010198d:	89 04 24             	mov    %eax,(%esp)
80101990:	e8 de 34 00 00       	call   80104e73 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
80101995:	8b 45 08             	mov    0x8(%ebp),%eax
80101998:	8b 40 0c             	mov    0xc(%eax),%eax
8010199b:	83 e0 01             	and    $0x1,%eax
8010199e:	85 c0                	test   %eax,%eax
801019a0:	75 e0                	jne    80101982 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
801019a2:	8b 45 08             	mov    0x8(%ebp),%eax
801019a5:	8b 40 0c             	mov    0xc(%eax),%eax
801019a8:	83 c8 01             	or     $0x1,%eax
801019ab:	89 c2                	mov    %eax,%edx
801019ad:	8b 45 08             	mov    0x8(%ebp),%eax
801019b0:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
801019b3:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
801019ba:	e8 ff 40 00 00       	call   80105abe <release>

  if(!(ip->flags & I_VALID)){
801019bf:	8b 45 08             	mov    0x8(%ebp),%eax
801019c2:	8b 40 0c             	mov    0xc(%eax),%eax
801019c5:	83 e0 02             	and    $0x2,%eax
801019c8:	85 c0                	test   %eax,%eax
801019ca:	0f 85 ce 00 00 00    	jne    80101a9e <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
801019d0:	8b 45 08             	mov    0x8(%ebp),%eax
801019d3:	8b 40 04             	mov    0x4(%eax),%eax
801019d6:	c1 e8 03             	shr    $0x3,%eax
801019d9:	8d 50 02             	lea    0x2(%eax),%edx
801019dc:	8b 45 08             	mov    0x8(%ebp),%eax
801019df:	8b 00                	mov    (%eax),%eax
801019e1:	89 54 24 04          	mov    %edx,0x4(%esp)
801019e5:	89 04 24             	mov    %eax,(%esp)
801019e8:	e8 b9 e7 ff ff       	call   801001a6 <bread>
801019ed:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
801019f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019f3:	8d 50 18             	lea    0x18(%eax),%edx
801019f6:	8b 45 08             	mov    0x8(%ebp),%eax
801019f9:	8b 40 04             	mov    0x4(%eax),%eax
801019fc:	83 e0 07             	and    $0x7,%eax
801019ff:	c1 e0 06             	shl    $0x6,%eax
80101a02:	01 d0                	add    %edx,%eax
80101a04:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80101a07:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a0a:	0f b7 10             	movzwl (%eax),%edx
80101a0d:	8b 45 08             	mov    0x8(%ebp),%eax
80101a10:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
80101a14:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a17:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101a1b:	8b 45 08             	mov    0x8(%ebp),%eax
80101a1e:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
80101a22:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a25:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101a29:	8b 45 08             	mov    0x8(%ebp),%eax
80101a2c:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
80101a30:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a33:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101a37:	8b 45 08             	mov    0x8(%ebp),%eax
80101a3a:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
80101a3e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a41:	8b 50 08             	mov    0x8(%eax),%edx
80101a44:	8b 45 08             	mov    0x8(%ebp),%eax
80101a47:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101a4a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a4d:	8d 50 0c             	lea    0xc(%eax),%edx
80101a50:	8b 45 08             	mov    0x8(%ebp),%eax
80101a53:	83 c0 1c             	add    $0x1c,%eax
80101a56:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101a5d:	00 
80101a5e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101a62:	89 04 24             	mov    %eax,(%esp)
80101a65:	e8 15 43 00 00       	call   80105d7f <memmove>
    brelse(bp);
80101a6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a6d:	89 04 24             	mov    %eax,(%esp)
80101a70:	e8 a2 e7 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
80101a75:	8b 45 08             	mov    0x8(%ebp),%eax
80101a78:	8b 40 0c             	mov    0xc(%eax),%eax
80101a7b:	83 c8 02             	or     $0x2,%eax
80101a7e:	89 c2                	mov    %eax,%edx
80101a80:	8b 45 08             	mov    0x8(%ebp),%eax
80101a83:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
80101a86:	8b 45 08             	mov    0x8(%ebp),%eax
80101a89:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101a8d:	66 85 c0             	test   %ax,%ax
80101a90:	75 0c                	jne    80101a9e <ilock+0x14c>
      panic("ilock: no type");
80101a92:	c7 04 24 79 91 10 80 	movl   $0x80109179,(%esp)
80101a99:	e8 9c ea ff ff       	call   8010053a <panic>
  }
}
80101a9e:	c9                   	leave  
80101a9f:	c3                   	ret    

80101aa0 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80101aa0:	55                   	push   %ebp
80101aa1:	89 e5                	mov    %esp,%ebp
80101aa3:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
80101aa6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101aaa:	74 17                	je     80101ac3 <iunlock+0x23>
80101aac:	8b 45 08             	mov    0x8(%ebp),%eax
80101aaf:	8b 40 0c             	mov    0xc(%eax),%eax
80101ab2:	83 e0 01             	and    $0x1,%eax
80101ab5:	85 c0                	test   %eax,%eax
80101ab7:	74 0a                	je     80101ac3 <iunlock+0x23>
80101ab9:	8b 45 08             	mov    0x8(%ebp),%eax
80101abc:	8b 40 08             	mov    0x8(%eax),%eax
80101abf:	85 c0                	test   %eax,%eax
80101ac1:	7f 0c                	jg     80101acf <iunlock+0x2f>
    panic("iunlock");
80101ac3:	c7 04 24 88 91 10 80 	movl   $0x80109188,(%esp)
80101aca:	e8 6b ea ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80101acf:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101ad6:	e8 81 3f 00 00       	call   80105a5c <acquire>
  ip->flags &= ~I_BUSY;
80101adb:	8b 45 08             	mov    0x8(%ebp),%eax
80101ade:	8b 40 0c             	mov    0xc(%eax),%eax
80101ae1:	83 e0 fe             	and    $0xfffffffe,%eax
80101ae4:	89 c2                	mov    %eax,%edx
80101ae6:	8b 45 08             	mov    0x8(%ebp),%eax
80101ae9:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80101aec:	8b 45 08             	mov    0x8(%ebp),%eax
80101aef:	89 04 24             	mov    %eax,(%esp)
80101af2:	e8 58 34 00 00       	call   80104f4f <wakeup>
  release(&icache.lock);
80101af7:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101afe:	e8 bb 3f 00 00       	call   80105abe <release>
}
80101b03:	c9                   	leave  
80101b04:	c3                   	ret    

80101b05 <iput>:
// to it, free the inode (and its content) on disk.
// All calls to iput() must be inside a transaction in
// case it has to free the inode.
void
iput(struct inode *ip)
{
80101b05:	55                   	push   %ebp
80101b06:	89 e5                	mov    %esp,%ebp
80101b08:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101b0b:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101b12:	e8 45 3f 00 00       	call   80105a5c <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101b17:	8b 45 08             	mov    0x8(%ebp),%eax
80101b1a:	8b 40 08             	mov    0x8(%eax),%eax
80101b1d:	83 f8 01             	cmp    $0x1,%eax
80101b20:	0f 85 93 00 00 00    	jne    80101bb9 <iput+0xb4>
80101b26:	8b 45 08             	mov    0x8(%ebp),%eax
80101b29:	8b 40 0c             	mov    0xc(%eax),%eax
80101b2c:	83 e0 02             	and    $0x2,%eax
80101b2f:	85 c0                	test   %eax,%eax
80101b31:	0f 84 82 00 00 00    	je     80101bb9 <iput+0xb4>
80101b37:	8b 45 08             	mov    0x8(%ebp),%eax
80101b3a:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101b3e:	66 85 c0             	test   %ax,%ax
80101b41:	75 76                	jne    80101bb9 <iput+0xb4>
    // inode has no links and no other references: truncate and free.
    if(ip->flags & I_BUSY)
80101b43:	8b 45 08             	mov    0x8(%ebp),%eax
80101b46:	8b 40 0c             	mov    0xc(%eax),%eax
80101b49:	83 e0 01             	and    $0x1,%eax
80101b4c:	85 c0                	test   %eax,%eax
80101b4e:	74 0c                	je     80101b5c <iput+0x57>
      panic("iput busy");
80101b50:	c7 04 24 90 91 10 80 	movl   $0x80109190,(%esp)
80101b57:	e8 de e9 ff ff       	call   8010053a <panic>
    ip->flags |= I_BUSY;
80101b5c:	8b 45 08             	mov    0x8(%ebp),%eax
80101b5f:	8b 40 0c             	mov    0xc(%eax),%eax
80101b62:	83 c8 01             	or     $0x1,%eax
80101b65:	89 c2                	mov    %eax,%edx
80101b67:	8b 45 08             	mov    0x8(%ebp),%eax
80101b6a:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101b6d:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101b74:	e8 45 3f 00 00       	call   80105abe <release>
    itrunc(ip);
80101b79:	8b 45 08             	mov    0x8(%ebp),%eax
80101b7c:	89 04 24             	mov    %eax,(%esp)
80101b7f:	e8 7d 01 00 00       	call   80101d01 <itrunc>
    ip->type = 0;
80101b84:	8b 45 08             	mov    0x8(%ebp),%eax
80101b87:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101b8d:	8b 45 08             	mov    0x8(%ebp),%eax
80101b90:	89 04 24             	mov    %eax,(%esp)
80101b93:	e8 fe fb ff ff       	call   80101796 <iupdate>
    acquire(&icache.lock);
80101b98:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101b9f:	e8 b8 3e 00 00       	call   80105a5c <acquire>
    ip->flags = 0;
80101ba4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ba7:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101bae:	8b 45 08             	mov    0x8(%ebp),%eax
80101bb1:	89 04 24             	mov    %eax,(%esp)
80101bb4:	e8 96 33 00 00       	call   80104f4f <wakeup>
  }
  ip->ref--;
80101bb9:	8b 45 08             	mov    0x8(%ebp),%eax
80101bbc:	8b 40 08             	mov    0x8(%eax),%eax
80101bbf:	8d 50 ff             	lea    -0x1(%eax),%edx
80101bc2:	8b 45 08             	mov    0x8(%ebp),%eax
80101bc5:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101bc8:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101bcf:	e8 ea 3e 00 00       	call   80105abe <release>
}
80101bd4:	c9                   	leave  
80101bd5:	c3                   	ret    

80101bd6 <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101bd6:	55                   	push   %ebp
80101bd7:	89 e5                	mov    %esp,%ebp
80101bd9:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101bdc:	8b 45 08             	mov    0x8(%ebp),%eax
80101bdf:	89 04 24             	mov    %eax,(%esp)
80101be2:	e8 b9 fe ff ff       	call   80101aa0 <iunlock>
  iput(ip);
80101be7:	8b 45 08             	mov    0x8(%ebp),%eax
80101bea:	89 04 24             	mov    %eax,(%esp)
80101bed:	e8 13 ff ff ff       	call   80101b05 <iput>
}
80101bf2:	c9                   	leave  
80101bf3:	c3                   	ret    

80101bf4 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101bf4:	55                   	push   %ebp
80101bf5:	89 e5                	mov    %esp,%ebp
80101bf7:	53                   	push   %ebx
80101bf8:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101bfb:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101bff:	77 3e                	ja     80101c3f <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101c01:	8b 45 08             	mov    0x8(%ebp),%eax
80101c04:	8b 55 0c             	mov    0xc(%ebp),%edx
80101c07:	83 c2 04             	add    $0x4,%edx
80101c0a:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101c0e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c11:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101c15:	75 20                	jne    80101c37 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101c17:	8b 45 08             	mov    0x8(%ebp),%eax
80101c1a:	8b 00                	mov    (%eax),%eax
80101c1c:	89 04 24             	mov    %eax,(%esp)
80101c1f:	e8 5b f8 ff ff       	call   8010147f <balloc>
80101c24:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c27:	8b 45 08             	mov    0x8(%ebp),%eax
80101c2a:	8b 55 0c             	mov    0xc(%ebp),%edx
80101c2d:	8d 4a 04             	lea    0x4(%edx),%ecx
80101c30:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c33:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101c37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c3a:	e9 bc 00 00 00       	jmp    80101cfb <bmap+0x107>
  }
  bn -= NDIRECT;
80101c3f:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101c43:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101c47:	0f 87 a2 00 00 00    	ja     80101cef <bmap+0xfb>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101c4d:	8b 45 08             	mov    0x8(%ebp),%eax
80101c50:	8b 40 4c             	mov    0x4c(%eax),%eax
80101c53:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c56:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101c5a:	75 19                	jne    80101c75 <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101c5c:	8b 45 08             	mov    0x8(%ebp),%eax
80101c5f:	8b 00                	mov    (%eax),%eax
80101c61:	89 04 24             	mov    %eax,(%esp)
80101c64:	e8 16 f8 ff ff       	call   8010147f <balloc>
80101c69:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c6c:	8b 45 08             	mov    0x8(%ebp),%eax
80101c6f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c72:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80101c75:	8b 45 08             	mov    0x8(%ebp),%eax
80101c78:	8b 00                	mov    (%eax),%eax
80101c7a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c7d:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c81:	89 04 24             	mov    %eax,(%esp)
80101c84:	e8 1d e5 ff ff       	call   801001a6 <bread>
80101c89:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101c8c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c8f:	83 c0 18             	add    $0x18,%eax
80101c92:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101c95:	8b 45 0c             	mov    0xc(%ebp),%eax
80101c98:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101c9f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ca2:	01 d0                	add    %edx,%eax
80101ca4:	8b 00                	mov    (%eax),%eax
80101ca6:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101ca9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101cad:	75 30                	jne    80101cdf <bmap+0xeb>
      a[bn] = addr = balloc(ip->dev);
80101caf:	8b 45 0c             	mov    0xc(%ebp),%eax
80101cb2:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101cb9:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101cbc:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80101cbf:	8b 45 08             	mov    0x8(%ebp),%eax
80101cc2:	8b 00                	mov    (%eax),%eax
80101cc4:	89 04 24             	mov    %eax,(%esp)
80101cc7:	e8 b3 f7 ff ff       	call   8010147f <balloc>
80101ccc:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101ccf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101cd2:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101cd4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cd7:	89 04 24             	mov    %eax,(%esp)
80101cda:	e8 4e 1b 00 00       	call   8010382d <log_write>
    }
    brelse(bp);
80101cdf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ce2:	89 04 24             	mov    %eax,(%esp)
80101ce5:	e8 2d e5 ff ff       	call   80100217 <brelse>
    return addr;
80101cea:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ced:	eb 0c                	jmp    80101cfb <bmap+0x107>
  }

  panic("bmap: out of range");
80101cef:	c7 04 24 9a 91 10 80 	movl   $0x8010919a,(%esp)
80101cf6:	e8 3f e8 ff ff       	call   8010053a <panic>
}
80101cfb:	83 c4 24             	add    $0x24,%esp
80101cfe:	5b                   	pop    %ebx
80101cff:	5d                   	pop    %ebp
80101d00:	c3                   	ret    

80101d01 <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101d01:	55                   	push   %ebp
80101d02:	89 e5                	mov    %esp,%ebp
80101d04:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101d07:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101d0e:	eb 44                	jmp    80101d54 <itrunc+0x53>
    if(ip->addrs[i]){
80101d10:	8b 45 08             	mov    0x8(%ebp),%eax
80101d13:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d16:	83 c2 04             	add    $0x4,%edx
80101d19:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101d1d:	85 c0                	test   %eax,%eax
80101d1f:	74 2f                	je     80101d50 <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101d21:	8b 45 08             	mov    0x8(%ebp),%eax
80101d24:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d27:	83 c2 04             	add    $0x4,%edx
80101d2a:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101d2e:	8b 45 08             	mov    0x8(%ebp),%eax
80101d31:	8b 00                	mov    (%eax),%eax
80101d33:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d37:	89 04 24             	mov    %eax,(%esp)
80101d3a:	e8 8e f8 ff ff       	call   801015cd <bfree>
      ip->addrs[i] = 0;
80101d3f:	8b 45 08             	mov    0x8(%ebp),%eax
80101d42:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d45:	83 c2 04             	add    $0x4,%edx
80101d48:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101d4f:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101d50:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101d54:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101d58:	7e b6                	jle    80101d10 <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80101d5a:	8b 45 08             	mov    0x8(%ebp),%eax
80101d5d:	8b 40 4c             	mov    0x4c(%eax),%eax
80101d60:	85 c0                	test   %eax,%eax
80101d62:	0f 84 9b 00 00 00    	je     80101e03 <itrunc+0x102>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101d68:	8b 45 08             	mov    0x8(%ebp),%eax
80101d6b:	8b 50 4c             	mov    0x4c(%eax),%edx
80101d6e:	8b 45 08             	mov    0x8(%ebp),%eax
80101d71:	8b 00                	mov    (%eax),%eax
80101d73:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d77:	89 04 24             	mov    %eax,(%esp)
80101d7a:	e8 27 e4 ff ff       	call   801001a6 <bread>
80101d7f:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101d82:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d85:	83 c0 18             	add    $0x18,%eax
80101d88:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101d8b:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101d92:	eb 3b                	jmp    80101dcf <itrunc+0xce>
      if(a[j])
80101d94:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d97:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101d9e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101da1:	01 d0                	add    %edx,%eax
80101da3:	8b 00                	mov    (%eax),%eax
80101da5:	85 c0                	test   %eax,%eax
80101da7:	74 22                	je     80101dcb <itrunc+0xca>
        bfree(ip->dev, a[j]);
80101da9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101dac:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101db3:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101db6:	01 d0                	add    %edx,%eax
80101db8:	8b 10                	mov    (%eax),%edx
80101dba:	8b 45 08             	mov    0x8(%ebp),%eax
80101dbd:	8b 00                	mov    (%eax),%eax
80101dbf:	89 54 24 04          	mov    %edx,0x4(%esp)
80101dc3:	89 04 24             	mov    %eax,(%esp)
80101dc6:	e8 02 f8 ff ff       	call   801015cd <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101dcb:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101dcf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101dd2:	83 f8 7f             	cmp    $0x7f,%eax
80101dd5:	76 bd                	jbe    80101d94 <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101dd7:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101dda:	89 04 24             	mov    %eax,(%esp)
80101ddd:	e8 35 e4 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101de2:	8b 45 08             	mov    0x8(%ebp),%eax
80101de5:	8b 50 4c             	mov    0x4c(%eax),%edx
80101de8:	8b 45 08             	mov    0x8(%ebp),%eax
80101deb:	8b 00                	mov    (%eax),%eax
80101ded:	89 54 24 04          	mov    %edx,0x4(%esp)
80101df1:	89 04 24             	mov    %eax,(%esp)
80101df4:	e8 d4 f7 ff ff       	call   801015cd <bfree>
    ip->addrs[NDIRECT] = 0;
80101df9:	8b 45 08             	mov    0x8(%ebp),%eax
80101dfc:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80101e03:	8b 45 08             	mov    0x8(%ebp),%eax
80101e06:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80101e0d:	8b 45 08             	mov    0x8(%ebp),%eax
80101e10:	89 04 24             	mov    %eax,(%esp)
80101e13:	e8 7e f9 ff ff       	call   80101796 <iupdate>
}
80101e18:	c9                   	leave  
80101e19:	c3                   	ret    

80101e1a <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80101e1a:	55                   	push   %ebp
80101e1b:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101e1d:	8b 45 08             	mov    0x8(%ebp),%eax
80101e20:	8b 00                	mov    (%eax),%eax
80101e22:	89 c2                	mov    %eax,%edx
80101e24:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e27:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101e2a:	8b 45 08             	mov    0x8(%ebp),%eax
80101e2d:	8b 50 04             	mov    0x4(%eax),%edx
80101e30:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e33:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101e36:	8b 45 08             	mov    0x8(%ebp),%eax
80101e39:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101e3d:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e40:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101e43:	8b 45 08             	mov    0x8(%ebp),%eax
80101e46:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101e4a:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e4d:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101e51:	8b 45 08             	mov    0x8(%ebp),%eax
80101e54:	8b 50 18             	mov    0x18(%eax),%edx
80101e57:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e5a:	89 50 10             	mov    %edx,0x10(%eax)
}
80101e5d:	5d                   	pop    %ebp
80101e5e:	c3                   	ret    

80101e5f <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101e5f:	55                   	push   %ebp
80101e60:	89 e5                	mov    %esp,%ebp
80101e62:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101e65:	8b 45 08             	mov    0x8(%ebp),%eax
80101e68:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101e6c:	66 83 f8 03          	cmp    $0x3,%ax
80101e70:	75 6d                	jne    80101edf <readi+0x80>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101e72:	8b 45 08             	mov    0x8(%ebp),%eax
80101e75:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101e79:	66 85 c0             	test   %ax,%ax
80101e7c:	78 23                	js     80101ea1 <readi+0x42>
80101e7e:	8b 45 08             	mov    0x8(%ebp),%eax
80101e81:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101e85:	66 83 f8 09          	cmp    $0x9,%ax
80101e89:	7f 16                	jg     80101ea1 <readi+0x42>
80101e8b:	8b 45 08             	mov    0x8(%ebp),%eax
80101e8e:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101e92:	98                   	cwtl   
80101e93:	c1 e0 04             	shl    $0x4,%eax
80101e96:	05 e8 21 11 80       	add    $0x801121e8,%eax
80101e9b:	8b 00                	mov    (%eax),%eax
80101e9d:	85 c0                	test   %eax,%eax
80101e9f:	75 0a                	jne    80101eab <readi+0x4c>
      return -1;
80101ea1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101ea6:	e9 23 01 00 00       	jmp    80101fce <readi+0x16f>
    return devsw[ip->major].read(ip, dst, off, n);
80101eab:	8b 45 08             	mov    0x8(%ebp),%eax
80101eae:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101eb2:	98                   	cwtl   
80101eb3:	c1 e0 04             	shl    $0x4,%eax
80101eb6:	05 e8 21 11 80       	add    $0x801121e8,%eax
80101ebb:	8b 00                	mov    (%eax),%eax
80101ebd:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101ec0:	8b 55 10             	mov    0x10(%ebp),%edx
80101ec3:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101ec7:	89 54 24 08          	mov    %edx,0x8(%esp)
80101ecb:	8b 55 0c             	mov    0xc(%ebp),%edx
80101ece:	89 54 24 04          	mov    %edx,0x4(%esp)
80101ed2:	8b 55 08             	mov    0x8(%ebp),%edx
80101ed5:	89 14 24             	mov    %edx,(%esp)
80101ed8:	ff d0                	call   *%eax
80101eda:	e9 ef 00 00 00       	jmp    80101fce <readi+0x16f>
  }

  if(off > ip->size || off + n < off)
80101edf:	8b 45 08             	mov    0x8(%ebp),%eax
80101ee2:	8b 40 18             	mov    0x18(%eax),%eax
80101ee5:	3b 45 10             	cmp    0x10(%ebp),%eax
80101ee8:	72 0d                	jb     80101ef7 <readi+0x98>
80101eea:	8b 45 14             	mov    0x14(%ebp),%eax
80101eed:	8b 55 10             	mov    0x10(%ebp),%edx
80101ef0:	01 d0                	add    %edx,%eax
80101ef2:	3b 45 10             	cmp    0x10(%ebp),%eax
80101ef5:	73 0a                	jae    80101f01 <readi+0xa2>
    return -1;
80101ef7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101efc:	e9 cd 00 00 00       	jmp    80101fce <readi+0x16f>
  if(off + n > ip->size)
80101f01:	8b 45 14             	mov    0x14(%ebp),%eax
80101f04:	8b 55 10             	mov    0x10(%ebp),%edx
80101f07:	01 c2                	add    %eax,%edx
80101f09:	8b 45 08             	mov    0x8(%ebp),%eax
80101f0c:	8b 40 18             	mov    0x18(%eax),%eax
80101f0f:	39 c2                	cmp    %eax,%edx
80101f11:	76 0c                	jbe    80101f1f <readi+0xc0>
    n = ip->size - off;
80101f13:	8b 45 08             	mov    0x8(%ebp),%eax
80101f16:	8b 40 18             	mov    0x18(%eax),%eax
80101f19:	2b 45 10             	sub    0x10(%ebp),%eax
80101f1c:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101f1f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101f26:	e9 94 00 00 00       	jmp    80101fbf <readi+0x160>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101f2b:	8b 45 10             	mov    0x10(%ebp),%eax
80101f2e:	c1 e8 09             	shr    $0x9,%eax
80101f31:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f35:	8b 45 08             	mov    0x8(%ebp),%eax
80101f38:	89 04 24             	mov    %eax,(%esp)
80101f3b:	e8 b4 fc ff ff       	call   80101bf4 <bmap>
80101f40:	8b 55 08             	mov    0x8(%ebp),%edx
80101f43:	8b 12                	mov    (%edx),%edx
80101f45:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f49:	89 14 24             	mov    %edx,(%esp)
80101f4c:	e8 55 e2 ff ff       	call   801001a6 <bread>
80101f51:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101f54:	8b 45 10             	mov    0x10(%ebp),%eax
80101f57:	25 ff 01 00 00       	and    $0x1ff,%eax
80101f5c:	89 c2                	mov    %eax,%edx
80101f5e:	b8 00 02 00 00       	mov    $0x200,%eax
80101f63:	29 d0                	sub    %edx,%eax
80101f65:	89 c2                	mov    %eax,%edx
80101f67:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101f6a:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101f6d:	29 c1                	sub    %eax,%ecx
80101f6f:	89 c8                	mov    %ecx,%eax
80101f71:	39 c2                	cmp    %eax,%edx
80101f73:	0f 46 c2             	cmovbe %edx,%eax
80101f76:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80101f79:	8b 45 10             	mov    0x10(%ebp),%eax
80101f7c:	25 ff 01 00 00       	and    $0x1ff,%eax
80101f81:	8d 50 10             	lea    0x10(%eax),%edx
80101f84:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f87:	01 d0                	add    %edx,%eax
80101f89:	8d 50 08             	lea    0x8(%eax),%edx
80101f8c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f8f:	89 44 24 08          	mov    %eax,0x8(%esp)
80101f93:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f97:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f9a:	89 04 24             	mov    %eax,(%esp)
80101f9d:	e8 dd 3d 00 00       	call   80105d7f <memmove>
    brelse(bp);
80101fa2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fa5:	89 04 24             	mov    %eax,(%esp)
80101fa8:	e8 6a e2 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101fad:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fb0:	01 45 f4             	add    %eax,-0xc(%ebp)
80101fb3:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fb6:	01 45 10             	add    %eax,0x10(%ebp)
80101fb9:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fbc:	01 45 0c             	add    %eax,0xc(%ebp)
80101fbf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101fc2:	3b 45 14             	cmp    0x14(%ebp),%eax
80101fc5:	0f 82 60 ff ff ff    	jb     80101f2b <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80101fcb:	8b 45 14             	mov    0x14(%ebp),%eax
}
80101fce:	c9                   	leave  
80101fcf:	c3                   	ret    

80101fd0 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80101fd0:	55                   	push   %ebp
80101fd1:	89 e5                	mov    %esp,%ebp
80101fd3:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101fd6:	8b 45 08             	mov    0x8(%ebp),%eax
80101fd9:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101fdd:	66 83 f8 03          	cmp    $0x3,%ax
80101fe1:	75 66                	jne    80102049 <writei+0x79>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80101fe3:	8b 45 08             	mov    0x8(%ebp),%eax
80101fe6:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101fea:	66 85 c0             	test   %ax,%ax
80101fed:	78 23                	js     80102012 <writei+0x42>
80101fef:	8b 45 08             	mov    0x8(%ebp),%eax
80101ff2:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101ff6:	66 83 f8 09          	cmp    $0x9,%ax
80101ffa:	7f 16                	jg     80102012 <writei+0x42>
80101ffc:	8b 45 08             	mov    0x8(%ebp),%eax
80101fff:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102003:	98                   	cwtl   
80102004:	c1 e0 04             	shl    $0x4,%eax
80102007:	05 ec 21 11 80       	add    $0x801121ec,%eax
8010200c:	8b 00                	mov    (%eax),%eax
8010200e:	85 c0                	test   %eax,%eax
80102010:	75 0a                	jne    8010201c <writei+0x4c>
      return -1;
80102012:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102017:	e9 47 01 00 00       	jmp    80102163 <writei+0x193>
    return devsw[ip->major].write(ip, src, n);
8010201c:	8b 45 08             	mov    0x8(%ebp),%eax
8010201f:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102023:	98                   	cwtl   
80102024:	c1 e0 04             	shl    $0x4,%eax
80102027:	05 ec 21 11 80       	add    $0x801121ec,%eax
8010202c:	8b 00                	mov    (%eax),%eax
8010202e:	8b 55 14             	mov    0x14(%ebp),%edx
80102031:	89 54 24 08          	mov    %edx,0x8(%esp)
80102035:	8b 55 0c             	mov    0xc(%ebp),%edx
80102038:	89 54 24 04          	mov    %edx,0x4(%esp)
8010203c:	8b 55 08             	mov    0x8(%ebp),%edx
8010203f:	89 14 24             	mov    %edx,(%esp)
80102042:	ff d0                	call   *%eax
80102044:	e9 1a 01 00 00       	jmp    80102163 <writei+0x193>
  }

  if(off > ip->size || off + n < off)
80102049:	8b 45 08             	mov    0x8(%ebp),%eax
8010204c:	8b 40 18             	mov    0x18(%eax),%eax
8010204f:	3b 45 10             	cmp    0x10(%ebp),%eax
80102052:	72 0d                	jb     80102061 <writei+0x91>
80102054:	8b 45 14             	mov    0x14(%ebp),%eax
80102057:	8b 55 10             	mov    0x10(%ebp),%edx
8010205a:	01 d0                	add    %edx,%eax
8010205c:	3b 45 10             	cmp    0x10(%ebp),%eax
8010205f:	73 0a                	jae    8010206b <writei+0x9b>
    return -1;
80102061:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102066:	e9 f8 00 00 00       	jmp    80102163 <writei+0x193>
  if(off + n > MAXFILE*BSIZE)
8010206b:	8b 45 14             	mov    0x14(%ebp),%eax
8010206e:	8b 55 10             	mov    0x10(%ebp),%edx
80102071:	01 d0                	add    %edx,%eax
80102073:	3d 00 18 01 00       	cmp    $0x11800,%eax
80102078:	76 0a                	jbe    80102084 <writei+0xb4>
    return -1;
8010207a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010207f:	e9 df 00 00 00       	jmp    80102163 <writei+0x193>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102084:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010208b:	e9 9f 00 00 00       	jmp    8010212f <writei+0x15f>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80102090:	8b 45 10             	mov    0x10(%ebp),%eax
80102093:	c1 e8 09             	shr    $0x9,%eax
80102096:	89 44 24 04          	mov    %eax,0x4(%esp)
8010209a:	8b 45 08             	mov    0x8(%ebp),%eax
8010209d:	89 04 24             	mov    %eax,(%esp)
801020a0:	e8 4f fb ff ff       	call   80101bf4 <bmap>
801020a5:	8b 55 08             	mov    0x8(%ebp),%edx
801020a8:	8b 12                	mov    (%edx),%edx
801020aa:	89 44 24 04          	mov    %eax,0x4(%esp)
801020ae:	89 14 24             	mov    %edx,(%esp)
801020b1:	e8 f0 e0 ff ff       	call   801001a6 <bread>
801020b6:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
801020b9:	8b 45 10             	mov    0x10(%ebp),%eax
801020bc:	25 ff 01 00 00       	and    $0x1ff,%eax
801020c1:	89 c2                	mov    %eax,%edx
801020c3:	b8 00 02 00 00       	mov    $0x200,%eax
801020c8:	29 d0                	sub    %edx,%eax
801020ca:	89 c2                	mov    %eax,%edx
801020cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801020cf:	8b 4d 14             	mov    0x14(%ebp),%ecx
801020d2:	29 c1                	sub    %eax,%ecx
801020d4:	89 c8                	mov    %ecx,%eax
801020d6:	39 c2                	cmp    %eax,%edx
801020d8:	0f 46 c2             	cmovbe %edx,%eax
801020db:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
801020de:	8b 45 10             	mov    0x10(%ebp),%eax
801020e1:	25 ff 01 00 00       	and    $0x1ff,%eax
801020e6:	8d 50 10             	lea    0x10(%eax),%edx
801020e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020ec:	01 d0                	add    %edx,%eax
801020ee:	8d 50 08             	lea    0x8(%eax),%edx
801020f1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020f4:	89 44 24 08          	mov    %eax,0x8(%esp)
801020f8:	8b 45 0c             	mov    0xc(%ebp),%eax
801020fb:	89 44 24 04          	mov    %eax,0x4(%esp)
801020ff:	89 14 24             	mov    %edx,(%esp)
80102102:	e8 78 3c 00 00       	call   80105d7f <memmove>
    log_write(bp);
80102107:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010210a:	89 04 24             	mov    %eax,(%esp)
8010210d:	e8 1b 17 00 00       	call   8010382d <log_write>
    brelse(bp);
80102112:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102115:	89 04 24             	mov    %eax,(%esp)
80102118:	e8 fa e0 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010211d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102120:	01 45 f4             	add    %eax,-0xc(%ebp)
80102123:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102126:	01 45 10             	add    %eax,0x10(%ebp)
80102129:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010212c:	01 45 0c             	add    %eax,0xc(%ebp)
8010212f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102132:	3b 45 14             	cmp    0x14(%ebp),%eax
80102135:	0f 82 55 ff ff ff    	jb     80102090 <writei+0xc0>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
8010213b:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010213f:	74 1f                	je     80102160 <writei+0x190>
80102141:	8b 45 08             	mov    0x8(%ebp),%eax
80102144:	8b 40 18             	mov    0x18(%eax),%eax
80102147:	3b 45 10             	cmp    0x10(%ebp),%eax
8010214a:	73 14                	jae    80102160 <writei+0x190>
    ip->size = off;
8010214c:	8b 45 08             	mov    0x8(%ebp),%eax
8010214f:	8b 55 10             	mov    0x10(%ebp),%edx
80102152:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
80102155:	8b 45 08             	mov    0x8(%ebp),%eax
80102158:	89 04 24             	mov    %eax,(%esp)
8010215b:	e8 36 f6 ff ff       	call   80101796 <iupdate>
  }
  return n;
80102160:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102163:	c9                   	leave  
80102164:	c3                   	ret    

80102165 <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
80102165:	55                   	push   %ebp
80102166:	89 e5                	mov    %esp,%ebp
80102168:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
8010216b:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102172:	00 
80102173:	8b 45 0c             	mov    0xc(%ebp),%eax
80102176:	89 44 24 04          	mov    %eax,0x4(%esp)
8010217a:	8b 45 08             	mov    0x8(%ebp),%eax
8010217d:	89 04 24             	mov    %eax,(%esp)
80102180:	e8 9d 3c 00 00       	call   80105e22 <strncmp>
}
80102185:	c9                   	leave  
80102186:	c3                   	ret    

80102187 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
80102187:	55                   	push   %ebp
80102188:	89 e5                	mov    %esp,%ebp
8010218a:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;
  struct inode *ip;

  if(dp->type != T_DIR && !IS_DEV_DIR(dp))
8010218d:	8b 45 08             	mov    0x8(%ebp),%eax
80102190:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102194:	66 83 f8 01          	cmp    $0x1,%ax
80102198:	74 4d                	je     801021e7 <dirlookup+0x60>
8010219a:	8b 45 08             	mov    0x8(%ebp),%eax
8010219d:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801021a1:	66 83 f8 03          	cmp    $0x3,%ax
801021a5:	75 34                	jne    801021db <dirlookup+0x54>
801021a7:	8b 45 08             	mov    0x8(%ebp),%eax
801021aa:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801021ae:	98                   	cwtl   
801021af:	c1 e0 04             	shl    $0x4,%eax
801021b2:	05 e0 21 11 80       	add    $0x801121e0,%eax
801021b7:	8b 00                	mov    (%eax),%eax
801021b9:	85 c0                	test   %eax,%eax
801021bb:	74 1e                	je     801021db <dirlookup+0x54>
801021bd:	8b 45 08             	mov    0x8(%ebp),%eax
801021c0:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801021c4:	98                   	cwtl   
801021c5:	c1 e0 04             	shl    $0x4,%eax
801021c8:	05 e0 21 11 80       	add    $0x801121e0,%eax
801021cd:	8b 00                	mov    (%eax),%eax
801021cf:	8b 55 08             	mov    0x8(%ebp),%edx
801021d2:	89 14 24             	mov    %edx,(%esp)
801021d5:	ff d0                	call   *%eax
801021d7:	85 c0                	test   %eax,%eax
801021d9:	75 0c                	jne    801021e7 <dirlookup+0x60>
    panic("dirlookup not DIR");
801021db:	c7 04 24 ad 91 10 80 	movl   $0x801091ad,(%esp)
801021e2:	e8 53 e3 ff ff       	call   8010053a <panic>

  for(off = 0; off < dp->size || dp->type == T_DEV; off += sizeof(de)){
801021e7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801021ee:	e9 fd 00 00 00       	jmp    801022f0 <dirlookup+0x169>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de)) {
801021f3:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801021fa:	00 
801021fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021fe:	89 44 24 08          	mov    %eax,0x8(%esp)
80102202:	8d 45 dc             	lea    -0x24(%ebp),%eax
80102205:	89 44 24 04          	mov    %eax,0x4(%esp)
80102209:	8b 45 08             	mov    0x8(%ebp),%eax
8010220c:	89 04 24             	mov    %eax,(%esp)
8010220f:	e8 4b fc ff ff       	call   80101e5f <readi>
80102214:	83 f8 10             	cmp    $0x10,%eax
80102217:	74 23                	je     8010223c <dirlookup+0xb5>
      if (dp->type == T_DEV)
80102219:	8b 45 08             	mov    0x8(%ebp),%eax
8010221c:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102220:	66 83 f8 03          	cmp    $0x3,%ax
80102224:	75 0a                	jne    80102230 <dirlookup+0xa9>
        return 0;
80102226:	b8 00 00 00 00       	mov    $0x0,%eax
8010222b:	e9 e5 00 00 00       	jmp    80102315 <dirlookup+0x18e>
      else
        panic("dirlink read");
80102230:	c7 04 24 bf 91 10 80 	movl   $0x801091bf,(%esp)
80102237:	e8 fe e2 ff ff       	call   8010053a <panic>
    }
    if(de.inum == 0)
8010223c:	0f b7 45 dc          	movzwl -0x24(%ebp),%eax
80102240:	66 85 c0             	test   %ax,%ax
80102243:	75 05                	jne    8010224a <dirlookup+0xc3>
      continue;
80102245:	e9 a2 00 00 00       	jmp    801022ec <dirlookup+0x165>
    if(namecmp(name, de.name) == 0){
8010224a:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010224d:	83 c0 02             	add    $0x2,%eax
80102250:	89 44 24 04          	mov    %eax,0x4(%esp)
80102254:	8b 45 0c             	mov    0xc(%ebp),%eax
80102257:	89 04 24             	mov    %eax,(%esp)
8010225a:	e8 06 ff ff ff       	call   80102165 <namecmp>
8010225f:	85 c0                	test   %eax,%eax
80102261:	0f 85 85 00 00 00    	jne    801022ec <dirlookup+0x165>
      // entry matches path element
      if(poff)
80102267:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010226b:	74 08                	je     80102275 <dirlookup+0xee>
        *poff = off;
8010226d:	8b 45 10             	mov    0x10(%ebp),%eax
80102270:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102273:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
80102275:	0f b7 45 dc          	movzwl -0x24(%ebp),%eax
80102279:	0f b7 c0             	movzwl %ax,%eax
8010227c:	89 45 f0             	mov    %eax,-0x10(%ebp)
      ip = iget(dp->dev, inum);
8010227f:	8b 45 08             	mov    0x8(%ebp),%eax
80102282:	8b 00                	mov    (%eax),%eax
80102284:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102287:	89 54 24 04          	mov    %edx,0x4(%esp)
8010228b:	89 04 24             	mov    %eax,(%esp)
8010228e:	e8 bb f5 ff ff       	call   8010184e <iget>
80102293:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if (!(ip->flags & I_VALID) && dp->type == T_DEV && devsw[dp->major].iread) {
80102296:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102299:	8b 40 0c             	mov    0xc(%eax),%eax
8010229c:	83 e0 02             	and    $0x2,%eax
8010229f:	85 c0                	test   %eax,%eax
801022a1:	75 44                	jne    801022e7 <dirlookup+0x160>
801022a3:	8b 45 08             	mov    0x8(%ebp),%eax
801022a6:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801022aa:	66 83 f8 03          	cmp    $0x3,%ax
801022ae:	75 37                	jne    801022e7 <dirlookup+0x160>
801022b0:	8b 45 08             	mov    0x8(%ebp),%eax
801022b3:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801022b7:	98                   	cwtl   
801022b8:	c1 e0 04             	shl    $0x4,%eax
801022bb:	05 e4 21 11 80       	add    $0x801121e4,%eax
801022c0:	8b 00                	mov    (%eax),%eax
801022c2:	85 c0                	test   %eax,%eax
801022c4:	74 21                	je     801022e7 <dirlookup+0x160>
        devsw[dp->major].iread(dp, ip);
801022c6:	8b 45 08             	mov    0x8(%ebp),%eax
801022c9:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801022cd:	98                   	cwtl   
801022ce:	c1 e0 04             	shl    $0x4,%eax
801022d1:	05 e4 21 11 80       	add    $0x801121e4,%eax
801022d6:	8b 00                	mov    (%eax),%eax
801022d8:	8b 55 ec             	mov    -0x14(%ebp),%edx
801022db:	89 54 24 04          	mov    %edx,0x4(%esp)
801022df:	8b 55 08             	mov    0x8(%ebp),%edx
801022e2:	89 14 24             	mov    %edx,(%esp)
801022e5:	ff d0                	call   *%eax
      }
      return ip;
801022e7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801022ea:	eb 29                	jmp    80102315 <dirlookup+0x18e>
  struct inode *ip;

  if(dp->type != T_DIR && !IS_DEV_DIR(dp))
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size || dp->type == T_DEV; off += sizeof(de)){
801022ec:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801022f0:	8b 45 08             	mov    0x8(%ebp),%eax
801022f3:	8b 40 18             	mov    0x18(%eax),%eax
801022f6:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801022f9:	0f 87 f4 fe ff ff    	ja     801021f3 <dirlookup+0x6c>
801022ff:	8b 45 08             	mov    0x8(%ebp),%eax
80102302:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102306:	66 83 f8 03          	cmp    $0x3,%ax
8010230a:	0f 84 e3 fe ff ff    	je     801021f3 <dirlookup+0x6c>
      }
      return ip;
    }
  }

  return 0;
80102310:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102315:	c9                   	leave  
80102316:	c3                   	ret    

80102317 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
80102317:	55                   	push   %ebp
80102318:	89 e5                	mov    %esp,%ebp
8010231a:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
8010231d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102324:	00 
80102325:	8b 45 0c             	mov    0xc(%ebp),%eax
80102328:	89 44 24 04          	mov    %eax,0x4(%esp)
8010232c:	8b 45 08             	mov    0x8(%ebp),%eax
8010232f:	89 04 24             	mov    %eax,(%esp)
80102332:	e8 50 fe ff ff       	call   80102187 <dirlookup>
80102337:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010233a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010233e:	74 15                	je     80102355 <dirlink+0x3e>
    iput(ip);
80102340:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102343:	89 04 24             	mov    %eax,(%esp)
80102346:	e8 ba f7 ff ff       	call   80101b05 <iput>
    return -1;
8010234b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102350:	e9 b7 00 00 00       	jmp    8010240c <dirlink+0xf5>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102355:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010235c:	eb 46                	jmp    801023a4 <dirlink+0x8d>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010235e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102361:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102368:	00 
80102369:	89 44 24 08          	mov    %eax,0x8(%esp)
8010236d:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102370:	89 44 24 04          	mov    %eax,0x4(%esp)
80102374:	8b 45 08             	mov    0x8(%ebp),%eax
80102377:	89 04 24             	mov    %eax,(%esp)
8010237a:	e8 e0 fa ff ff       	call   80101e5f <readi>
8010237f:	83 f8 10             	cmp    $0x10,%eax
80102382:	74 0c                	je     80102390 <dirlink+0x79>
      panic("dirlink read");
80102384:	c7 04 24 bf 91 10 80 	movl   $0x801091bf,(%esp)
8010238b:	e8 aa e1 ff ff       	call   8010053a <panic>
    if(de.inum == 0)
80102390:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102394:	66 85 c0             	test   %ax,%ax
80102397:	75 02                	jne    8010239b <dirlink+0x84>
      break;
80102399:	eb 16                	jmp    801023b1 <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
8010239b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010239e:	83 c0 10             	add    $0x10,%eax
801023a1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801023a4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801023a7:	8b 45 08             	mov    0x8(%ebp),%eax
801023aa:	8b 40 18             	mov    0x18(%eax),%eax
801023ad:	39 c2                	cmp    %eax,%edx
801023af:	72 ad                	jb     8010235e <dirlink+0x47>
      panic("dirlink read");
    if(de.inum == 0)
      break;
  }

  strncpy(de.name, name, DIRSIZ);
801023b1:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801023b8:	00 
801023b9:	8b 45 0c             	mov    0xc(%ebp),%eax
801023bc:	89 44 24 04          	mov    %eax,0x4(%esp)
801023c0:	8d 45 e0             	lea    -0x20(%ebp),%eax
801023c3:	83 c0 02             	add    $0x2,%eax
801023c6:	89 04 24             	mov    %eax,(%esp)
801023c9:	e8 aa 3a 00 00       	call   80105e78 <strncpy>
  de.inum = inum;
801023ce:	8b 45 10             	mov    0x10(%ebp),%eax
801023d1:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801023d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023d8:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801023df:	00 
801023e0:	89 44 24 08          	mov    %eax,0x8(%esp)
801023e4:	8d 45 e0             	lea    -0x20(%ebp),%eax
801023e7:	89 44 24 04          	mov    %eax,0x4(%esp)
801023eb:	8b 45 08             	mov    0x8(%ebp),%eax
801023ee:	89 04 24             	mov    %eax,(%esp)
801023f1:	e8 da fb ff ff       	call   80101fd0 <writei>
801023f6:	83 f8 10             	cmp    $0x10,%eax
801023f9:	74 0c                	je     80102407 <dirlink+0xf0>
    panic("dirlink");
801023fb:	c7 04 24 cc 91 10 80 	movl   $0x801091cc,(%esp)
80102402:	e8 33 e1 ff ff       	call   8010053a <panic>
  
  return 0;
80102407:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010240c:	c9                   	leave  
8010240d:	c3                   	ret    

8010240e <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
8010240e:	55                   	push   %ebp
8010240f:	89 e5                	mov    %esp,%ebp
80102411:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
80102414:	eb 04                	jmp    8010241a <skipelem+0xc>
    path++;
80102416:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
8010241a:	8b 45 08             	mov    0x8(%ebp),%eax
8010241d:	0f b6 00             	movzbl (%eax),%eax
80102420:	3c 2f                	cmp    $0x2f,%al
80102422:	74 f2                	je     80102416 <skipelem+0x8>
    path++;
  if(*path == 0)
80102424:	8b 45 08             	mov    0x8(%ebp),%eax
80102427:	0f b6 00             	movzbl (%eax),%eax
8010242a:	84 c0                	test   %al,%al
8010242c:	75 0a                	jne    80102438 <skipelem+0x2a>
    return 0;
8010242e:	b8 00 00 00 00       	mov    $0x0,%eax
80102433:	e9 86 00 00 00       	jmp    801024be <skipelem+0xb0>
  s = path;
80102438:	8b 45 08             	mov    0x8(%ebp),%eax
8010243b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
8010243e:	eb 04                	jmp    80102444 <skipelem+0x36>
    path++;
80102440:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
80102444:	8b 45 08             	mov    0x8(%ebp),%eax
80102447:	0f b6 00             	movzbl (%eax),%eax
8010244a:	3c 2f                	cmp    $0x2f,%al
8010244c:	74 0a                	je     80102458 <skipelem+0x4a>
8010244e:	8b 45 08             	mov    0x8(%ebp),%eax
80102451:	0f b6 00             	movzbl (%eax),%eax
80102454:	84 c0                	test   %al,%al
80102456:	75 e8                	jne    80102440 <skipelem+0x32>
    path++;
  len = path - s;
80102458:	8b 55 08             	mov    0x8(%ebp),%edx
8010245b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010245e:	29 c2                	sub    %eax,%edx
80102460:	89 d0                	mov    %edx,%eax
80102462:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
80102465:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
80102469:	7e 1c                	jle    80102487 <skipelem+0x79>
    memmove(name, s, DIRSIZ);
8010246b:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102472:	00 
80102473:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102476:	89 44 24 04          	mov    %eax,0x4(%esp)
8010247a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010247d:	89 04 24             	mov    %eax,(%esp)
80102480:	e8 fa 38 00 00       	call   80105d7f <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102485:	eb 2a                	jmp    801024b1 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
80102487:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010248a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010248e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102491:	89 44 24 04          	mov    %eax,0x4(%esp)
80102495:	8b 45 0c             	mov    0xc(%ebp),%eax
80102498:	89 04 24             	mov    %eax,(%esp)
8010249b:	e8 df 38 00 00       	call   80105d7f <memmove>
    name[len] = 0;
801024a0:	8b 55 f0             	mov    -0x10(%ebp),%edx
801024a3:	8b 45 0c             	mov    0xc(%ebp),%eax
801024a6:	01 d0                	add    %edx,%eax
801024a8:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
801024ab:	eb 04                	jmp    801024b1 <skipelem+0xa3>
    path++;
801024ad:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801024b1:	8b 45 08             	mov    0x8(%ebp),%eax
801024b4:	0f b6 00             	movzbl (%eax),%eax
801024b7:	3c 2f                	cmp    $0x2f,%al
801024b9:	74 f2                	je     801024ad <skipelem+0x9f>
    path++;
  return path;
801024bb:	8b 45 08             	mov    0x8(%ebp),%eax
}
801024be:	c9                   	leave  
801024bf:	c3                   	ret    

801024c0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
801024c0:	55                   	push   %ebp
801024c1:	89 e5                	mov    %esp,%ebp
801024c3:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
801024c6:	8b 45 08             	mov    0x8(%ebp),%eax
801024c9:	0f b6 00             	movzbl (%eax),%eax
801024cc:	3c 2f                	cmp    $0x2f,%al
801024ce:	75 1c                	jne    801024ec <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
801024d0:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801024d7:	00 
801024d8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801024df:	e8 6a f3 ff ff       	call   8010184e <iget>
801024e4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801024e7:	e9 f0 00 00 00       	jmp    801025dc <namex+0x11c>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
801024ec:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801024f2:	8b 40 78             	mov    0x78(%eax),%eax
801024f5:	89 04 24             	mov    %eax,(%esp)
801024f8:	e8 23 f4 ff ff       	call   80101920 <idup>
801024fd:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
80102500:	e9 d7 00 00 00       	jmp    801025dc <namex+0x11c>
    ilock(ip);
80102505:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102508:	89 04 24             	mov    %eax,(%esp)
8010250b:	e8 42 f4 ff ff       	call   80101952 <ilock>
    if(ip->type != T_DIR && !IS_DEV_DIR(ip)){
80102510:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102513:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102517:	66 83 f8 01          	cmp    $0x1,%ax
8010251b:	74 56                	je     80102573 <namex+0xb3>
8010251d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102520:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102524:	66 83 f8 03          	cmp    $0x3,%ax
80102528:	75 34                	jne    8010255e <namex+0x9e>
8010252a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010252d:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102531:	98                   	cwtl   
80102532:	c1 e0 04             	shl    $0x4,%eax
80102535:	05 e0 21 11 80       	add    $0x801121e0,%eax
8010253a:	8b 00                	mov    (%eax),%eax
8010253c:	85 c0                	test   %eax,%eax
8010253e:	74 1e                	je     8010255e <namex+0x9e>
80102540:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102543:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102547:	98                   	cwtl   
80102548:	c1 e0 04             	shl    $0x4,%eax
8010254b:	05 e0 21 11 80       	add    $0x801121e0,%eax
80102550:	8b 00                	mov    (%eax),%eax
80102552:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102555:	89 14 24             	mov    %edx,(%esp)
80102558:	ff d0                	call   *%eax
8010255a:	85 c0                	test   %eax,%eax
8010255c:	75 15                	jne    80102573 <namex+0xb3>
      iunlockput(ip);
8010255e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102561:	89 04 24             	mov    %eax,(%esp)
80102564:	e8 6d f6 ff ff       	call   80101bd6 <iunlockput>
      return 0;
80102569:	b8 00 00 00 00       	mov    $0x0,%eax
8010256e:	e9 a3 00 00 00       	jmp    80102616 <namex+0x156>
    }
    if(nameiparent && *path == '\0'){
80102573:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102577:	74 1d                	je     80102596 <namex+0xd6>
80102579:	8b 45 08             	mov    0x8(%ebp),%eax
8010257c:	0f b6 00             	movzbl (%eax),%eax
8010257f:	84 c0                	test   %al,%al
80102581:	75 13                	jne    80102596 <namex+0xd6>
      // Stop one level early.
      iunlock(ip);
80102583:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102586:	89 04 24             	mov    %eax,(%esp)
80102589:	e8 12 f5 ff ff       	call   80101aa0 <iunlock>
      return ip;
8010258e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102591:	e9 80 00 00 00       	jmp    80102616 <namex+0x156>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
80102596:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010259d:	00 
8010259e:	8b 45 10             	mov    0x10(%ebp),%eax
801025a1:	89 44 24 04          	mov    %eax,0x4(%esp)
801025a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025a8:	89 04 24             	mov    %eax,(%esp)
801025ab:	e8 d7 fb ff ff       	call   80102187 <dirlookup>
801025b0:	89 45 f0             	mov    %eax,-0x10(%ebp)
801025b3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801025b7:	75 12                	jne    801025cb <namex+0x10b>
      iunlockput(ip);
801025b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025bc:	89 04 24             	mov    %eax,(%esp)
801025bf:	e8 12 f6 ff ff       	call   80101bd6 <iunlockput>
      return 0;
801025c4:	b8 00 00 00 00       	mov    $0x0,%eax
801025c9:	eb 4b                	jmp    80102616 <namex+0x156>
    }
    iunlockput(ip);
801025cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025ce:	89 04 24             	mov    %eax,(%esp)
801025d1:	e8 00 f6 ff ff       	call   80101bd6 <iunlockput>
    ip = next;
801025d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801025d9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801025dc:	8b 45 10             	mov    0x10(%ebp),%eax
801025df:	89 44 24 04          	mov    %eax,0x4(%esp)
801025e3:	8b 45 08             	mov    0x8(%ebp),%eax
801025e6:	89 04 24             	mov    %eax,(%esp)
801025e9:	e8 20 fe ff ff       	call   8010240e <skipelem>
801025ee:	89 45 08             	mov    %eax,0x8(%ebp)
801025f1:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801025f5:	0f 85 0a ff ff ff    	jne    80102505 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
801025fb:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801025ff:	74 12                	je     80102613 <namex+0x153>
    iput(ip);
80102601:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102604:	89 04 24             	mov    %eax,(%esp)
80102607:	e8 f9 f4 ff ff       	call   80101b05 <iput>
    return 0;
8010260c:	b8 00 00 00 00       	mov    $0x0,%eax
80102611:	eb 03                	jmp    80102616 <namex+0x156>
  }
  return ip;
80102613:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102616:	c9                   	leave  
80102617:	c3                   	ret    

80102618 <namei>:

struct inode*
namei(char *path)
{
80102618:	55                   	push   %ebp
80102619:	89 e5                	mov    %esp,%ebp
8010261b:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
8010261e:	8d 45 ea             	lea    -0x16(%ebp),%eax
80102621:	89 44 24 08          	mov    %eax,0x8(%esp)
80102625:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010262c:	00 
8010262d:	8b 45 08             	mov    0x8(%ebp),%eax
80102630:	89 04 24             	mov    %eax,(%esp)
80102633:	e8 88 fe ff ff       	call   801024c0 <namex>
}
80102638:	c9                   	leave  
80102639:	c3                   	ret    

8010263a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
8010263a:	55                   	push   %ebp
8010263b:	89 e5                	mov    %esp,%ebp
8010263d:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
80102640:	8b 45 0c             	mov    0xc(%ebp),%eax
80102643:	89 44 24 08          	mov    %eax,0x8(%esp)
80102647:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010264e:	00 
8010264f:	8b 45 08             	mov    0x8(%ebp),%eax
80102652:	89 04 24             	mov    %eax,(%esp)
80102655:	e8 66 fe ff ff       	call   801024c0 <namex>
}
8010265a:	c9                   	leave  
8010265b:	c3                   	ret    

8010265c <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010265c:	55                   	push   %ebp
8010265d:	89 e5                	mov    %esp,%ebp
8010265f:	83 ec 14             	sub    $0x14,%esp
80102662:	8b 45 08             	mov    0x8(%ebp),%eax
80102665:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102669:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
8010266d:	89 c2                	mov    %eax,%edx
8010266f:	ec                   	in     (%dx),%al
80102670:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102673:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102677:	c9                   	leave  
80102678:	c3                   	ret    

80102679 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
80102679:	55                   	push   %ebp
8010267a:	89 e5                	mov    %esp,%ebp
8010267c:	57                   	push   %edi
8010267d:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
8010267e:	8b 55 08             	mov    0x8(%ebp),%edx
80102681:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102684:	8b 45 10             	mov    0x10(%ebp),%eax
80102687:	89 cb                	mov    %ecx,%ebx
80102689:	89 df                	mov    %ebx,%edi
8010268b:	89 c1                	mov    %eax,%ecx
8010268d:	fc                   	cld    
8010268e:	f3 6d                	rep insl (%dx),%es:(%edi)
80102690:	89 c8                	mov    %ecx,%eax
80102692:	89 fb                	mov    %edi,%ebx
80102694:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102697:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
8010269a:	5b                   	pop    %ebx
8010269b:	5f                   	pop    %edi
8010269c:	5d                   	pop    %ebp
8010269d:	c3                   	ret    

8010269e <outb>:

static inline void
outb(ushort port, uchar data)
{
8010269e:	55                   	push   %ebp
8010269f:	89 e5                	mov    %esp,%ebp
801026a1:	83 ec 08             	sub    $0x8,%esp
801026a4:	8b 55 08             	mov    0x8(%ebp),%edx
801026a7:	8b 45 0c             	mov    0xc(%ebp),%eax
801026aa:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801026ae:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801026b1:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801026b5:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801026b9:	ee                   	out    %al,(%dx)
}
801026ba:	c9                   	leave  
801026bb:	c3                   	ret    

801026bc <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
801026bc:	55                   	push   %ebp
801026bd:	89 e5                	mov    %esp,%ebp
801026bf:	56                   	push   %esi
801026c0:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
801026c1:	8b 55 08             	mov    0x8(%ebp),%edx
801026c4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801026c7:	8b 45 10             	mov    0x10(%ebp),%eax
801026ca:	89 cb                	mov    %ecx,%ebx
801026cc:	89 de                	mov    %ebx,%esi
801026ce:	89 c1                	mov    %eax,%ecx
801026d0:	fc                   	cld    
801026d1:	f3 6f                	rep outsl %ds:(%esi),(%dx)
801026d3:	89 c8                	mov    %ecx,%eax
801026d5:	89 f3                	mov    %esi,%ebx
801026d7:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801026da:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
801026dd:	5b                   	pop    %ebx
801026de:	5e                   	pop    %esi
801026df:	5d                   	pop    %ebp
801026e0:	c3                   	ret    

801026e1 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
801026e1:	55                   	push   %ebp
801026e2:	89 e5                	mov    %esp,%ebp
801026e4:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
801026e7:	90                   	nop
801026e8:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801026ef:	e8 68 ff ff ff       	call   8010265c <inb>
801026f4:	0f b6 c0             	movzbl %al,%eax
801026f7:	89 45 fc             	mov    %eax,-0x4(%ebp)
801026fa:	8b 45 fc             	mov    -0x4(%ebp),%eax
801026fd:	25 c0 00 00 00       	and    $0xc0,%eax
80102702:	83 f8 40             	cmp    $0x40,%eax
80102705:	75 e1                	jne    801026e8 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102707:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010270b:	74 11                	je     8010271e <idewait+0x3d>
8010270d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102710:	83 e0 21             	and    $0x21,%eax
80102713:	85 c0                	test   %eax,%eax
80102715:	74 07                	je     8010271e <idewait+0x3d>
    return -1;
80102717:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010271c:	eb 05                	jmp    80102723 <idewait+0x42>
  return 0;
8010271e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102723:	c9                   	leave  
80102724:	c3                   	ret    

80102725 <ideinit>:

void
ideinit(void)
{
80102725:	55                   	push   %ebp
80102726:	89 e5                	mov    %esp,%ebp
80102728:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
8010272b:	c7 44 24 04 d4 91 10 	movl   $0x801091d4,0x4(%esp)
80102732:	80 
80102733:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
8010273a:	e8 fc 32 00 00       	call   80105a3b <initlock>
  picenable(IRQ_IDE);
8010273f:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102746:	e8 80 18 00 00       	call   80103fcb <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
8010274b:	a1 80 39 11 80       	mov    0x80113980,%eax
80102750:	83 e8 01             	sub    $0x1,%eax
80102753:	89 44 24 04          	mov    %eax,0x4(%esp)
80102757:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
8010275e:	e8 0c 04 00 00       	call   80102b6f <ioapicenable>
  idewait(0);
80102763:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010276a:	e8 72 ff ff ff       	call   801026e1 <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
8010276f:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
80102776:	00 
80102777:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010277e:	e8 1b ff ff ff       	call   8010269e <outb>
  for(i=0; i<1000; i++){
80102783:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010278a:	eb 20                	jmp    801027ac <ideinit+0x87>
    if(inb(0x1f7) != 0){
8010278c:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102793:	e8 c4 fe ff ff       	call   8010265c <inb>
80102798:	84 c0                	test   %al,%al
8010279a:	74 0c                	je     801027a8 <ideinit+0x83>
      havedisk1 = 1;
8010279c:	c7 05 38 c6 10 80 01 	movl   $0x1,0x8010c638
801027a3:	00 00 00 
      break;
801027a6:	eb 0d                	jmp    801027b5 <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
801027a8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801027ac:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
801027b3:	7e d7                	jle    8010278c <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
801027b5:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
801027bc:	00 
801027bd:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801027c4:	e8 d5 fe ff ff       	call   8010269e <outb>
}
801027c9:	c9                   	leave  
801027ca:	c3                   	ret    

801027cb <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
801027cb:	55                   	push   %ebp
801027cc:	89 e5                	mov    %esp,%ebp
801027ce:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
801027d1:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801027d5:	75 0c                	jne    801027e3 <idestart+0x18>
    panic("idestart");
801027d7:	c7 04 24 d8 91 10 80 	movl   $0x801091d8,(%esp)
801027de:	e8 57 dd ff ff       	call   8010053a <panic>

  idewait(0);
801027e3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801027ea:	e8 f2 fe ff ff       	call   801026e1 <idewait>
  outb(0x3f6, 0);  // generate interrupt
801027ef:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801027f6:	00 
801027f7:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
801027fe:	e8 9b fe ff ff       	call   8010269e <outb>
  outb(0x1f2, 1);  // number of sectors
80102803:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010280a:	00 
8010280b:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
80102812:	e8 87 fe ff ff       	call   8010269e <outb>
  outb(0x1f3, b->sector & 0xff);
80102817:	8b 45 08             	mov    0x8(%ebp),%eax
8010281a:	8b 40 08             	mov    0x8(%eax),%eax
8010281d:	0f b6 c0             	movzbl %al,%eax
80102820:	89 44 24 04          	mov    %eax,0x4(%esp)
80102824:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
8010282b:	e8 6e fe ff ff       	call   8010269e <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
80102830:	8b 45 08             	mov    0x8(%ebp),%eax
80102833:	8b 40 08             	mov    0x8(%eax),%eax
80102836:	c1 e8 08             	shr    $0x8,%eax
80102839:	0f b6 c0             	movzbl %al,%eax
8010283c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102840:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102847:	e8 52 fe ff ff       	call   8010269e <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
8010284c:	8b 45 08             	mov    0x8(%ebp),%eax
8010284f:	8b 40 08             	mov    0x8(%eax),%eax
80102852:	c1 e8 10             	shr    $0x10,%eax
80102855:	0f b6 c0             	movzbl %al,%eax
80102858:	89 44 24 04          	mov    %eax,0x4(%esp)
8010285c:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
80102863:	e8 36 fe ff ff       	call   8010269e <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
80102868:	8b 45 08             	mov    0x8(%ebp),%eax
8010286b:	8b 40 04             	mov    0x4(%eax),%eax
8010286e:	83 e0 01             	and    $0x1,%eax
80102871:	c1 e0 04             	shl    $0x4,%eax
80102874:	89 c2                	mov    %eax,%edx
80102876:	8b 45 08             	mov    0x8(%ebp),%eax
80102879:	8b 40 08             	mov    0x8(%eax),%eax
8010287c:	c1 e8 18             	shr    $0x18,%eax
8010287f:	83 e0 0f             	and    $0xf,%eax
80102882:	09 d0                	or     %edx,%eax
80102884:	83 c8 e0             	or     $0xffffffe0,%eax
80102887:	0f b6 c0             	movzbl %al,%eax
8010288a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010288e:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102895:	e8 04 fe ff ff       	call   8010269e <outb>
  if(b->flags & B_DIRTY){
8010289a:	8b 45 08             	mov    0x8(%ebp),%eax
8010289d:	8b 00                	mov    (%eax),%eax
8010289f:	83 e0 04             	and    $0x4,%eax
801028a2:	85 c0                	test   %eax,%eax
801028a4:	74 34                	je     801028da <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
801028a6:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
801028ad:	00 
801028ae:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801028b5:	e8 e4 fd ff ff       	call   8010269e <outb>
    outsl(0x1f0, b->data, 512/4);
801028ba:	8b 45 08             	mov    0x8(%ebp),%eax
801028bd:	83 c0 18             	add    $0x18,%eax
801028c0:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801028c7:	00 
801028c8:	89 44 24 04          	mov    %eax,0x4(%esp)
801028cc:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
801028d3:	e8 e4 fd ff ff       	call   801026bc <outsl>
801028d8:	eb 14                	jmp    801028ee <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
801028da:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801028e1:	00 
801028e2:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801028e9:	e8 b0 fd ff ff       	call   8010269e <outb>
  }
}
801028ee:	c9                   	leave  
801028ef:	c3                   	ret    

801028f0 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
801028f0:	55                   	push   %ebp
801028f1:	89 e5                	mov    %esp,%ebp
801028f3:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
801028f6:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
801028fd:	e8 5a 31 00 00       	call   80105a5c <acquire>
  if((b = idequeue) == 0){
80102902:	a1 34 c6 10 80       	mov    0x8010c634,%eax
80102907:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010290a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010290e:	75 11                	jne    80102921 <ideintr+0x31>
    release(&idelock);
80102910:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102917:	e8 a2 31 00 00       	call   80105abe <release>
    // cprintf("spurious IDE interrupt\n");
    return;
8010291c:	e9 90 00 00 00       	jmp    801029b1 <ideintr+0xc1>
  }
  idequeue = b->qnext;
80102921:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102924:	8b 40 14             	mov    0x14(%eax),%eax
80102927:	a3 34 c6 10 80       	mov    %eax,0x8010c634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
8010292c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010292f:	8b 00                	mov    (%eax),%eax
80102931:	83 e0 04             	and    $0x4,%eax
80102934:	85 c0                	test   %eax,%eax
80102936:	75 2e                	jne    80102966 <ideintr+0x76>
80102938:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010293f:	e8 9d fd ff ff       	call   801026e1 <idewait>
80102944:	85 c0                	test   %eax,%eax
80102946:	78 1e                	js     80102966 <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
80102948:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010294b:	83 c0 18             	add    $0x18,%eax
8010294e:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102955:	00 
80102956:	89 44 24 04          	mov    %eax,0x4(%esp)
8010295a:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102961:	e8 13 fd ff ff       	call   80102679 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80102966:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102969:	8b 00                	mov    (%eax),%eax
8010296b:	83 c8 02             	or     $0x2,%eax
8010296e:	89 c2                	mov    %eax,%edx
80102970:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102973:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
80102975:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102978:	8b 00                	mov    (%eax),%eax
8010297a:	83 e0 fb             	and    $0xfffffffb,%eax
8010297d:	89 c2                	mov    %eax,%edx
8010297f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102982:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80102984:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102987:	89 04 24             	mov    %eax,(%esp)
8010298a:	e8 c0 25 00 00       	call   80104f4f <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
8010298f:	a1 34 c6 10 80       	mov    0x8010c634,%eax
80102994:	85 c0                	test   %eax,%eax
80102996:	74 0d                	je     801029a5 <ideintr+0xb5>
    idestart(idequeue);
80102998:	a1 34 c6 10 80       	mov    0x8010c634,%eax
8010299d:	89 04 24             	mov    %eax,(%esp)
801029a0:	e8 26 fe ff ff       	call   801027cb <idestart>

  release(&idelock);
801029a5:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
801029ac:	e8 0d 31 00 00       	call   80105abe <release>
}
801029b1:	c9                   	leave  
801029b2:	c3                   	ret    

801029b3 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
801029b3:	55                   	push   %ebp
801029b4:	89 e5                	mov    %esp,%ebp
801029b6:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
801029b9:	8b 45 08             	mov    0x8(%ebp),%eax
801029bc:	8b 00                	mov    (%eax),%eax
801029be:	83 e0 01             	and    $0x1,%eax
801029c1:	85 c0                	test   %eax,%eax
801029c3:	75 0c                	jne    801029d1 <iderw+0x1e>
    panic("iderw: buf not busy");
801029c5:	c7 04 24 e1 91 10 80 	movl   $0x801091e1,(%esp)
801029cc:	e8 69 db ff ff       	call   8010053a <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
801029d1:	8b 45 08             	mov    0x8(%ebp),%eax
801029d4:	8b 00                	mov    (%eax),%eax
801029d6:	83 e0 06             	and    $0x6,%eax
801029d9:	83 f8 02             	cmp    $0x2,%eax
801029dc:	75 0c                	jne    801029ea <iderw+0x37>
    panic("iderw: nothing to do");
801029de:	c7 04 24 f5 91 10 80 	movl   $0x801091f5,(%esp)
801029e5:	e8 50 db ff ff       	call   8010053a <panic>
  if(b->dev != 0 && !havedisk1)
801029ea:	8b 45 08             	mov    0x8(%ebp),%eax
801029ed:	8b 40 04             	mov    0x4(%eax),%eax
801029f0:	85 c0                	test   %eax,%eax
801029f2:	74 15                	je     80102a09 <iderw+0x56>
801029f4:	a1 38 c6 10 80       	mov    0x8010c638,%eax
801029f9:	85 c0                	test   %eax,%eax
801029fb:	75 0c                	jne    80102a09 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
801029fd:	c7 04 24 0a 92 10 80 	movl   $0x8010920a,(%esp)
80102a04:	e8 31 db ff ff       	call   8010053a <panic>

  acquire(&idelock);  //DOC:acquire-lock
80102a09:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102a10:	e8 47 30 00 00       	call   80105a5c <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80102a15:	8b 45 08             	mov    0x8(%ebp),%eax
80102a18:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80102a1f:	c7 45 f4 34 c6 10 80 	movl   $0x8010c634,-0xc(%ebp)
80102a26:	eb 0b                	jmp    80102a33 <iderw+0x80>
80102a28:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a2b:	8b 00                	mov    (%eax),%eax
80102a2d:	83 c0 14             	add    $0x14,%eax
80102a30:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102a33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a36:	8b 00                	mov    (%eax),%eax
80102a38:	85 c0                	test   %eax,%eax
80102a3a:	75 ec                	jne    80102a28 <iderw+0x75>
    ;
  *pp = b;
80102a3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a3f:	8b 55 08             	mov    0x8(%ebp),%edx
80102a42:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80102a44:	a1 34 c6 10 80       	mov    0x8010c634,%eax
80102a49:	3b 45 08             	cmp    0x8(%ebp),%eax
80102a4c:	75 0d                	jne    80102a5b <iderw+0xa8>
    idestart(b);
80102a4e:	8b 45 08             	mov    0x8(%ebp),%eax
80102a51:	89 04 24             	mov    %eax,(%esp)
80102a54:	e8 72 fd ff ff       	call   801027cb <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102a59:	eb 15                	jmp    80102a70 <iderw+0xbd>
80102a5b:	eb 13                	jmp    80102a70 <iderw+0xbd>
    sleep(b, &idelock);
80102a5d:	c7 44 24 04 00 c6 10 	movl   $0x8010c600,0x4(%esp)
80102a64:	80 
80102a65:	8b 45 08             	mov    0x8(%ebp),%eax
80102a68:	89 04 24             	mov    %eax,(%esp)
80102a6b:	e8 03 24 00 00       	call   80104e73 <sleep>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102a70:	8b 45 08             	mov    0x8(%ebp),%eax
80102a73:	8b 00                	mov    (%eax),%eax
80102a75:	83 e0 06             	and    $0x6,%eax
80102a78:	83 f8 02             	cmp    $0x2,%eax
80102a7b:	75 e0                	jne    80102a5d <iderw+0xaa>
    sleep(b, &idelock);
  }

  release(&idelock);
80102a7d:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102a84:	e8 35 30 00 00       	call   80105abe <release>
}
80102a89:	c9                   	leave  
80102a8a:	c3                   	ret    

80102a8b <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102a8b:	55                   	push   %ebp
80102a8c:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102a8e:	a1 54 32 11 80       	mov    0x80113254,%eax
80102a93:	8b 55 08             	mov    0x8(%ebp),%edx
80102a96:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80102a98:	a1 54 32 11 80       	mov    0x80113254,%eax
80102a9d:	8b 40 10             	mov    0x10(%eax),%eax
}
80102aa0:	5d                   	pop    %ebp
80102aa1:	c3                   	ret    

80102aa2 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80102aa2:	55                   	push   %ebp
80102aa3:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102aa5:	a1 54 32 11 80       	mov    0x80113254,%eax
80102aaa:	8b 55 08             	mov    0x8(%ebp),%edx
80102aad:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80102aaf:	a1 54 32 11 80       	mov    0x80113254,%eax
80102ab4:	8b 55 0c             	mov    0xc(%ebp),%edx
80102ab7:	89 50 10             	mov    %edx,0x10(%eax)
}
80102aba:	5d                   	pop    %ebp
80102abb:	c3                   	ret    

80102abc <ioapicinit>:

void
ioapicinit(void)
{
80102abc:	55                   	push   %ebp
80102abd:	89 e5                	mov    %esp,%ebp
80102abf:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80102ac2:	a1 84 33 11 80       	mov    0x80113384,%eax
80102ac7:	85 c0                	test   %eax,%eax
80102ac9:	75 05                	jne    80102ad0 <ioapicinit+0x14>
    return;
80102acb:	e9 9d 00 00 00       	jmp    80102b6d <ioapicinit+0xb1>

  ioapic = (volatile struct ioapic*)IOAPIC;
80102ad0:	c7 05 54 32 11 80 00 	movl   $0xfec00000,0x80113254
80102ad7:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80102ada:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102ae1:	e8 a5 ff ff ff       	call   80102a8b <ioapicread>
80102ae6:	c1 e8 10             	shr    $0x10,%eax
80102ae9:	25 ff 00 00 00       	and    $0xff,%eax
80102aee:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80102af1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102af8:	e8 8e ff ff ff       	call   80102a8b <ioapicread>
80102afd:	c1 e8 18             	shr    $0x18,%eax
80102b00:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80102b03:	0f b6 05 80 33 11 80 	movzbl 0x80113380,%eax
80102b0a:	0f b6 c0             	movzbl %al,%eax
80102b0d:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102b10:	74 0c                	je     80102b1e <ioapicinit+0x62>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102b12:	c7 04 24 28 92 10 80 	movl   $0x80109228,(%esp)
80102b19:	e8 82 d8 ff ff       	call   801003a0 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102b1e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102b25:	eb 3e                	jmp    80102b65 <ioapicinit+0xa9>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80102b27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b2a:	83 c0 20             	add    $0x20,%eax
80102b2d:	0d 00 00 01 00       	or     $0x10000,%eax
80102b32:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102b35:	83 c2 08             	add    $0x8,%edx
80102b38:	01 d2                	add    %edx,%edx
80102b3a:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b3e:	89 14 24             	mov    %edx,(%esp)
80102b41:	e8 5c ff ff ff       	call   80102aa2 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102b46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b49:	83 c0 08             	add    $0x8,%eax
80102b4c:	01 c0                	add    %eax,%eax
80102b4e:	83 c0 01             	add    $0x1,%eax
80102b51:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102b58:	00 
80102b59:	89 04 24             	mov    %eax,(%esp)
80102b5c:	e8 41 ff ff ff       	call   80102aa2 <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102b61:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102b65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b68:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80102b6b:	7e ba                	jle    80102b27 <ioapicinit+0x6b>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80102b6d:	c9                   	leave  
80102b6e:	c3                   	ret    

80102b6f <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102b6f:	55                   	push   %ebp
80102b70:	89 e5                	mov    %esp,%ebp
80102b72:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80102b75:	a1 84 33 11 80       	mov    0x80113384,%eax
80102b7a:	85 c0                	test   %eax,%eax
80102b7c:	75 02                	jne    80102b80 <ioapicenable+0x11>
    return;
80102b7e:	eb 37                	jmp    80102bb7 <ioapicenable+0x48>

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80102b80:	8b 45 08             	mov    0x8(%ebp),%eax
80102b83:	83 c0 20             	add    $0x20,%eax
80102b86:	8b 55 08             	mov    0x8(%ebp),%edx
80102b89:	83 c2 08             	add    $0x8,%edx
80102b8c:	01 d2                	add    %edx,%edx
80102b8e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b92:	89 14 24             	mov    %edx,(%esp)
80102b95:	e8 08 ff ff ff       	call   80102aa2 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80102b9a:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b9d:	c1 e0 18             	shl    $0x18,%eax
80102ba0:	8b 55 08             	mov    0x8(%ebp),%edx
80102ba3:	83 c2 08             	add    $0x8,%edx
80102ba6:	01 d2                	add    %edx,%edx
80102ba8:	83 c2 01             	add    $0x1,%edx
80102bab:	89 44 24 04          	mov    %eax,0x4(%esp)
80102baf:	89 14 24             	mov    %edx,(%esp)
80102bb2:	e8 eb fe ff ff       	call   80102aa2 <ioapicwrite>
}
80102bb7:	c9                   	leave  
80102bb8:	c3                   	ret    

80102bb9 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80102bb9:	55                   	push   %ebp
80102bba:	89 e5                	mov    %esp,%ebp
80102bbc:	8b 45 08             	mov    0x8(%ebp),%eax
80102bbf:	05 00 00 00 80       	add    $0x80000000,%eax
80102bc4:	5d                   	pop    %ebp
80102bc5:	c3                   	ret    

80102bc6 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80102bc6:	55                   	push   %ebp
80102bc7:	89 e5                	mov    %esp,%ebp
80102bc9:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80102bcc:	c7 44 24 04 5a 92 10 	movl   $0x8010925a,0x4(%esp)
80102bd3:	80 
80102bd4:	c7 04 24 60 32 11 80 	movl   $0x80113260,(%esp)
80102bdb:	e8 5b 2e 00 00       	call   80105a3b <initlock>
  kmem.use_lock = 0;
80102be0:	c7 05 94 32 11 80 00 	movl   $0x0,0x80113294
80102be7:	00 00 00 
  freerange(vstart, vend);
80102bea:	8b 45 0c             	mov    0xc(%ebp),%eax
80102bed:	89 44 24 04          	mov    %eax,0x4(%esp)
80102bf1:	8b 45 08             	mov    0x8(%ebp),%eax
80102bf4:	89 04 24             	mov    %eax,(%esp)
80102bf7:	e8 26 00 00 00       	call   80102c22 <freerange>
}
80102bfc:	c9                   	leave  
80102bfd:	c3                   	ret    

80102bfe <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102bfe:	55                   	push   %ebp
80102bff:	89 e5                	mov    %esp,%ebp
80102c01:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80102c04:	8b 45 0c             	mov    0xc(%ebp),%eax
80102c07:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c0b:	8b 45 08             	mov    0x8(%ebp),%eax
80102c0e:	89 04 24             	mov    %eax,(%esp)
80102c11:	e8 0c 00 00 00       	call   80102c22 <freerange>
  kmem.use_lock = 1;
80102c16:	c7 05 94 32 11 80 01 	movl   $0x1,0x80113294
80102c1d:	00 00 00 
}
80102c20:	c9                   	leave  
80102c21:	c3                   	ret    

80102c22 <freerange>:

void
freerange(void *vstart, void *vend)
{
80102c22:	55                   	push   %ebp
80102c23:	89 e5                	mov    %esp,%ebp
80102c25:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102c28:	8b 45 08             	mov    0x8(%ebp),%eax
80102c2b:	05 ff 0f 00 00       	add    $0xfff,%eax
80102c30:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102c35:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102c38:	eb 12                	jmp    80102c4c <freerange+0x2a>
    kfree(p);
80102c3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c3d:	89 04 24             	mov    %eax,(%esp)
80102c40:	e8 16 00 00 00       	call   80102c5b <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102c45:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102c4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c4f:	05 00 10 00 00       	add    $0x1000,%eax
80102c54:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102c57:	76 e1                	jbe    80102c3a <freerange+0x18>
    kfree(p);
}
80102c59:	c9                   	leave  
80102c5a:	c3                   	ret    

80102c5b <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102c5b:	55                   	push   %ebp
80102c5c:	89 e5                	mov    %esp,%ebp
80102c5e:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80102c61:	8b 45 08             	mov    0x8(%ebp),%eax
80102c64:	25 ff 0f 00 00       	and    $0xfff,%eax
80102c69:	85 c0                	test   %eax,%eax
80102c6b:	75 1b                	jne    80102c88 <kfree+0x2d>
80102c6d:	81 7d 08 7c 75 12 80 	cmpl   $0x8012757c,0x8(%ebp)
80102c74:	72 12                	jb     80102c88 <kfree+0x2d>
80102c76:	8b 45 08             	mov    0x8(%ebp),%eax
80102c79:	89 04 24             	mov    %eax,(%esp)
80102c7c:	e8 38 ff ff ff       	call   80102bb9 <v2p>
80102c81:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102c86:	76 0c                	jbe    80102c94 <kfree+0x39>
    panic("kfree");
80102c88:	c7 04 24 5f 92 10 80 	movl   $0x8010925f,(%esp)
80102c8f:	e8 a6 d8 ff ff       	call   8010053a <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102c94:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102c9b:	00 
80102c9c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102ca3:	00 
80102ca4:	8b 45 08             	mov    0x8(%ebp),%eax
80102ca7:	89 04 24             	mov    %eax,(%esp)
80102caa:	e8 01 30 00 00       	call   80105cb0 <memset>

  if(kmem.use_lock)
80102caf:	a1 94 32 11 80       	mov    0x80113294,%eax
80102cb4:	85 c0                	test   %eax,%eax
80102cb6:	74 0c                	je     80102cc4 <kfree+0x69>
    acquire(&kmem.lock);
80102cb8:	c7 04 24 60 32 11 80 	movl   $0x80113260,(%esp)
80102cbf:	e8 98 2d 00 00       	call   80105a5c <acquire>
  r = (struct run*)v;
80102cc4:	8b 45 08             	mov    0x8(%ebp),%eax
80102cc7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102cca:	8b 15 98 32 11 80    	mov    0x80113298,%edx
80102cd0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102cd3:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102cd5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102cd8:	a3 98 32 11 80       	mov    %eax,0x80113298
  if(kmem.use_lock)
80102cdd:	a1 94 32 11 80       	mov    0x80113294,%eax
80102ce2:	85 c0                	test   %eax,%eax
80102ce4:	74 0c                	je     80102cf2 <kfree+0x97>
    release(&kmem.lock);
80102ce6:	c7 04 24 60 32 11 80 	movl   $0x80113260,(%esp)
80102ced:	e8 cc 2d 00 00       	call   80105abe <release>
}
80102cf2:	c9                   	leave  
80102cf3:	c3                   	ret    

80102cf4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102cf4:	55                   	push   %ebp
80102cf5:	89 e5                	mov    %esp,%ebp
80102cf7:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80102cfa:	a1 94 32 11 80       	mov    0x80113294,%eax
80102cff:	85 c0                	test   %eax,%eax
80102d01:	74 0c                	je     80102d0f <kalloc+0x1b>
    acquire(&kmem.lock);
80102d03:	c7 04 24 60 32 11 80 	movl   $0x80113260,(%esp)
80102d0a:	e8 4d 2d 00 00       	call   80105a5c <acquire>
  r = kmem.freelist;
80102d0f:	a1 98 32 11 80       	mov    0x80113298,%eax
80102d14:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102d17:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102d1b:	74 0a                	je     80102d27 <kalloc+0x33>
    kmem.freelist = r->next;
80102d1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d20:	8b 00                	mov    (%eax),%eax
80102d22:	a3 98 32 11 80       	mov    %eax,0x80113298
  if(kmem.use_lock)
80102d27:	a1 94 32 11 80       	mov    0x80113294,%eax
80102d2c:	85 c0                	test   %eax,%eax
80102d2e:	74 0c                	je     80102d3c <kalloc+0x48>
    release(&kmem.lock);
80102d30:	c7 04 24 60 32 11 80 	movl   $0x80113260,(%esp)
80102d37:	e8 82 2d 00 00       	call   80105abe <release>
  return (char*)r;
80102d3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102d3f:	c9                   	leave  
80102d40:	c3                   	ret    

80102d41 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102d41:	55                   	push   %ebp
80102d42:	89 e5                	mov    %esp,%ebp
80102d44:	83 ec 14             	sub    $0x14,%esp
80102d47:	8b 45 08             	mov    0x8(%ebp),%eax
80102d4a:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102d4e:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102d52:	89 c2                	mov    %eax,%edx
80102d54:	ec                   	in     (%dx),%al
80102d55:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102d58:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102d5c:	c9                   	leave  
80102d5d:	c3                   	ret    

80102d5e <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102d5e:	55                   	push   %ebp
80102d5f:	89 e5                	mov    %esp,%ebp
80102d61:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102d64:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102d6b:	e8 d1 ff ff ff       	call   80102d41 <inb>
80102d70:	0f b6 c0             	movzbl %al,%eax
80102d73:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102d76:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d79:	83 e0 01             	and    $0x1,%eax
80102d7c:	85 c0                	test   %eax,%eax
80102d7e:	75 0a                	jne    80102d8a <kbdgetc+0x2c>
    return -1;
80102d80:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102d85:	e9 25 01 00 00       	jmp    80102eaf <kbdgetc+0x151>
  data = inb(KBDATAP);
80102d8a:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80102d91:	e8 ab ff ff ff       	call   80102d41 <inb>
80102d96:	0f b6 c0             	movzbl %al,%eax
80102d99:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102d9c:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102da3:	75 17                	jne    80102dbc <kbdgetc+0x5e>
    shift |= E0ESC;
80102da5:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102daa:	83 c8 40             	or     $0x40,%eax
80102dad:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
    return 0;
80102db2:	b8 00 00 00 00       	mov    $0x0,%eax
80102db7:	e9 f3 00 00 00       	jmp    80102eaf <kbdgetc+0x151>
  } else if(data & 0x80){
80102dbc:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102dbf:	25 80 00 00 00       	and    $0x80,%eax
80102dc4:	85 c0                	test   %eax,%eax
80102dc6:	74 45                	je     80102e0d <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102dc8:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102dcd:	83 e0 40             	and    $0x40,%eax
80102dd0:	85 c0                	test   %eax,%eax
80102dd2:	75 08                	jne    80102ddc <kbdgetc+0x7e>
80102dd4:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102dd7:	83 e0 7f             	and    $0x7f,%eax
80102dda:	eb 03                	jmp    80102ddf <kbdgetc+0x81>
80102ddc:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102ddf:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102de2:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102de5:	05 20 a0 10 80       	add    $0x8010a020,%eax
80102dea:	0f b6 00             	movzbl (%eax),%eax
80102ded:	83 c8 40             	or     $0x40,%eax
80102df0:	0f b6 c0             	movzbl %al,%eax
80102df3:	f7 d0                	not    %eax
80102df5:	89 c2                	mov    %eax,%edx
80102df7:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102dfc:	21 d0                	and    %edx,%eax
80102dfe:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
    return 0;
80102e03:	b8 00 00 00 00       	mov    $0x0,%eax
80102e08:	e9 a2 00 00 00       	jmp    80102eaf <kbdgetc+0x151>
  } else if(shift & E0ESC){
80102e0d:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102e12:	83 e0 40             	and    $0x40,%eax
80102e15:	85 c0                	test   %eax,%eax
80102e17:	74 14                	je     80102e2d <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102e19:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102e20:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102e25:	83 e0 bf             	and    $0xffffffbf,%eax
80102e28:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
  }

  shift |= shiftcode[data];
80102e2d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e30:	05 20 a0 10 80       	add    $0x8010a020,%eax
80102e35:	0f b6 00             	movzbl (%eax),%eax
80102e38:	0f b6 d0             	movzbl %al,%edx
80102e3b:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102e40:	09 d0                	or     %edx,%eax
80102e42:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
  shift ^= togglecode[data];
80102e47:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e4a:	05 20 a1 10 80       	add    $0x8010a120,%eax
80102e4f:	0f b6 00             	movzbl (%eax),%eax
80102e52:	0f b6 d0             	movzbl %al,%edx
80102e55:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102e5a:	31 d0                	xor    %edx,%eax
80102e5c:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
  c = charcode[shift & (CTL | SHIFT)][data];
80102e61:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102e66:	83 e0 03             	and    $0x3,%eax
80102e69:	8b 14 85 20 a5 10 80 	mov    -0x7fef5ae0(,%eax,4),%edx
80102e70:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e73:	01 d0                	add    %edx,%eax
80102e75:	0f b6 00             	movzbl (%eax),%eax
80102e78:	0f b6 c0             	movzbl %al,%eax
80102e7b:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102e7e:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102e83:	83 e0 08             	and    $0x8,%eax
80102e86:	85 c0                	test   %eax,%eax
80102e88:	74 22                	je     80102eac <kbdgetc+0x14e>
    if('a' <= c && c <= 'z')
80102e8a:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102e8e:	76 0c                	jbe    80102e9c <kbdgetc+0x13e>
80102e90:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102e94:	77 06                	ja     80102e9c <kbdgetc+0x13e>
      c += 'A' - 'a';
80102e96:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102e9a:	eb 10                	jmp    80102eac <kbdgetc+0x14e>
    else if('A' <= c && c <= 'Z')
80102e9c:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102ea0:	76 0a                	jbe    80102eac <kbdgetc+0x14e>
80102ea2:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102ea6:	77 04                	ja     80102eac <kbdgetc+0x14e>
      c += 'a' - 'A';
80102ea8:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102eac:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102eaf:	c9                   	leave  
80102eb0:	c3                   	ret    

80102eb1 <kbdintr>:

void
kbdintr(void)
{
80102eb1:	55                   	push   %ebp
80102eb2:	89 e5                	mov    %esp,%ebp
80102eb4:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80102eb7:	c7 04 24 5e 2d 10 80 	movl   $0x80102d5e,(%esp)
80102ebe:	e8 ea d8 ff ff       	call   801007ad <consoleintr>
}
80102ec3:	c9                   	leave  
80102ec4:	c3                   	ret    

80102ec5 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102ec5:	55                   	push   %ebp
80102ec6:	89 e5                	mov    %esp,%ebp
80102ec8:	83 ec 14             	sub    $0x14,%esp
80102ecb:	8b 45 08             	mov    0x8(%ebp),%eax
80102ece:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102ed2:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102ed6:	89 c2                	mov    %eax,%edx
80102ed8:	ec                   	in     (%dx),%al
80102ed9:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102edc:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102ee0:	c9                   	leave  
80102ee1:	c3                   	ret    

80102ee2 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80102ee2:	55                   	push   %ebp
80102ee3:	89 e5                	mov    %esp,%ebp
80102ee5:	83 ec 08             	sub    $0x8,%esp
80102ee8:	8b 55 08             	mov    0x8(%ebp),%edx
80102eeb:	8b 45 0c             	mov    0xc(%ebp),%eax
80102eee:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102ef2:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102ef5:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102ef9:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102efd:	ee                   	out    %al,(%dx)
}
80102efe:	c9                   	leave  
80102eff:	c3                   	ret    

80102f00 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80102f00:	55                   	push   %ebp
80102f01:	89 e5                	mov    %esp,%ebp
80102f03:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80102f06:	9c                   	pushf  
80102f07:	58                   	pop    %eax
80102f08:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80102f0b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80102f0e:	c9                   	leave  
80102f0f:	c3                   	ret    

80102f10 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102f10:	55                   	push   %ebp
80102f11:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102f13:	a1 9c 32 11 80       	mov    0x8011329c,%eax
80102f18:	8b 55 08             	mov    0x8(%ebp),%edx
80102f1b:	c1 e2 02             	shl    $0x2,%edx
80102f1e:	01 c2                	add    %eax,%edx
80102f20:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f23:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102f25:	a1 9c 32 11 80       	mov    0x8011329c,%eax
80102f2a:	83 c0 20             	add    $0x20,%eax
80102f2d:	8b 00                	mov    (%eax),%eax
}
80102f2f:	5d                   	pop    %ebp
80102f30:	c3                   	ret    

80102f31 <lapicinit>:
//PAGEBREAK!

void
lapicinit(void)
{
80102f31:	55                   	push   %ebp
80102f32:	89 e5                	mov    %esp,%ebp
80102f34:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80102f37:	a1 9c 32 11 80       	mov    0x8011329c,%eax
80102f3c:	85 c0                	test   %eax,%eax
80102f3e:	75 05                	jne    80102f45 <lapicinit+0x14>
    return;
80102f40:	e9 43 01 00 00       	jmp    80103088 <lapicinit+0x157>

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102f45:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80102f4c:	00 
80102f4d:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80102f54:	e8 b7 ff ff ff       	call   80102f10 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102f59:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80102f60:	00 
80102f61:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80102f68:	e8 a3 ff ff ff       	call   80102f10 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102f6d:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80102f74:	00 
80102f75:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102f7c:	e8 8f ff ff ff       	call   80102f10 <lapicw>
  lapicw(TICR, 10000000); 
80102f81:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80102f88:	00 
80102f89:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80102f90:	e8 7b ff ff ff       	call   80102f10 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102f95:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102f9c:	00 
80102f9d:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80102fa4:	e8 67 ff ff ff       	call   80102f10 <lapicw>
  lapicw(LINT1, MASKED);
80102fa9:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102fb0:	00 
80102fb1:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80102fb8:	e8 53 ff ff ff       	call   80102f10 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102fbd:	a1 9c 32 11 80       	mov    0x8011329c,%eax
80102fc2:	83 c0 30             	add    $0x30,%eax
80102fc5:	8b 00                	mov    (%eax),%eax
80102fc7:	c1 e8 10             	shr    $0x10,%eax
80102fca:	0f b6 c0             	movzbl %al,%eax
80102fcd:	83 f8 03             	cmp    $0x3,%eax
80102fd0:	76 14                	jbe    80102fe6 <lapicinit+0xb5>
    lapicw(PCINT, MASKED);
80102fd2:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102fd9:	00 
80102fda:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80102fe1:	e8 2a ff ff ff       	call   80102f10 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102fe6:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80102fed:	00 
80102fee:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80102ff5:	e8 16 ff ff ff       	call   80102f10 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80102ffa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103001:	00 
80103002:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103009:	e8 02 ff ff ff       	call   80102f10 <lapicw>
  lapicw(ESR, 0);
8010300e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103015:	00 
80103016:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010301d:	e8 ee fe ff ff       	call   80102f10 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80103022:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103029:	00 
8010302a:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103031:	e8 da fe ff ff       	call   80102f10 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80103036:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010303d:	00 
8010303e:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103045:	e8 c6 fe ff ff       	call   80102f10 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
8010304a:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80103051:	00 
80103052:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103059:	e8 b2 fe ff ff       	call   80102f10 <lapicw>
  while(lapic[ICRLO] & DELIVS)
8010305e:	90                   	nop
8010305f:	a1 9c 32 11 80       	mov    0x8011329c,%eax
80103064:	05 00 03 00 00       	add    $0x300,%eax
80103069:	8b 00                	mov    (%eax),%eax
8010306b:	25 00 10 00 00       	and    $0x1000,%eax
80103070:	85 c0                	test   %eax,%eax
80103072:	75 eb                	jne    8010305f <lapicinit+0x12e>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80103074:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010307b:	00 
8010307c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103083:	e8 88 fe ff ff       	call   80102f10 <lapicw>
}
80103088:	c9                   	leave  
80103089:	c3                   	ret    

8010308a <cpunum>:

int
cpunum(void)
{
8010308a:	55                   	push   %ebp
8010308b:	89 e5                	mov    %esp,%ebp
8010308d:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80103090:	e8 6b fe ff ff       	call   80102f00 <readeflags>
80103095:	25 00 02 00 00       	and    $0x200,%eax
8010309a:	85 c0                	test   %eax,%eax
8010309c:	74 25                	je     801030c3 <cpunum+0x39>
    static int n;
    if(n++ == 0)
8010309e:	a1 40 c6 10 80       	mov    0x8010c640,%eax
801030a3:	8d 50 01             	lea    0x1(%eax),%edx
801030a6:	89 15 40 c6 10 80    	mov    %edx,0x8010c640
801030ac:	85 c0                	test   %eax,%eax
801030ae:	75 13                	jne    801030c3 <cpunum+0x39>
      cprintf("cpu called from %x with interrupts enabled\n",
801030b0:	8b 45 04             	mov    0x4(%ebp),%eax
801030b3:	89 44 24 04          	mov    %eax,0x4(%esp)
801030b7:	c7 04 24 68 92 10 80 	movl   $0x80109268,(%esp)
801030be:	e8 dd d2 ff ff       	call   801003a0 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
801030c3:	a1 9c 32 11 80       	mov    0x8011329c,%eax
801030c8:	85 c0                	test   %eax,%eax
801030ca:	74 0f                	je     801030db <cpunum+0x51>
    return lapic[ID]>>24;
801030cc:	a1 9c 32 11 80       	mov    0x8011329c,%eax
801030d1:	83 c0 20             	add    $0x20,%eax
801030d4:	8b 00                	mov    (%eax),%eax
801030d6:	c1 e8 18             	shr    $0x18,%eax
801030d9:	eb 05                	jmp    801030e0 <cpunum+0x56>
  return 0;
801030db:	b8 00 00 00 00       	mov    $0x0,%eax
}
801030e0:	c9                   	leave  
801030e1:	c3                   	ret    

801030e2 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
801030e2:	55                   	push   %ebp
801030e3:	89 e5                	mov    %esp,%ebp
801030e5:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
801030e8:	a1 9c 32 11 80       	mov    0x8011329c,%eax
801030ed:	85 c0                	test   %eax,%eax
801030ef:	74 14                	je     80103105 <lapiceoi+0x23>
    lapicw(EOI, 0);
801030f1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801030f8:	00 
801030f9:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103100:	e8 0b fe ff ff       	call   80102f10 <lapicw>
}
80103105:	c9                   	leave  
80103106:	c3                   	ret    

80103107 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80103107:	55                   	push   %ebp
80103108:	89 e5                	mov    %esp,%ebp
}
8010310a:	5d                   	pop    %ebp
8010310b:	c3                   	ret    

8010310c <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
8010310c:	55                   	push   %ebp
8010310d:	89 e5                	mov    %esp,%ebp
8010310f:	83 ec 1c             	sub    $0x1c,%esp
80103112:	8b 45 08             	mov    0x8(%ebp),%eax
80103115:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
80103118:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
8010311f:	00 
80103120:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80103127:	e8 b6 fd ff ff       	call   80102ee2 <outb>
  outb(CMOS_PORT+1, 0x0A);
8010312c:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103133:	00 
80103134:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
8010313b:	e8 a2 fd ff ff       	call   80102ee2 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80103140:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80103147:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010314a:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
8010314f:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103152:	8d 50 02             	lea    0x2(%eax),%edx
80103155:	8b 45 0c             	mov    0xc(%ebp),%eax
80103158:	c1 e8 04             	shr    $0x4,%eax
8010315b:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
8010315e:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103162:	c1 e0 18             	shl    $0x18,%eax
80103165:	89 44 24 04          	mov    %eax,0x4(%esp)
80103169:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103170:	e8 9b fd ff ff       	call   80102f10 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80103175:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
8010317c:	00 
8010317d:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103184:	e8 87 fd ff ff       	call   80102f10 <lapicw>
  microdelay(200);
80103189:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103190:	e8 72 ff ff ff       	call   80103107 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80103195:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
8010319c:	00 
8010319d:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801031a4:	e8 67 fd ff ff       	call   80102f10 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
801031a9:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
801031b0:	e8 52 ff ff ff       	call   80103107 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801031b5:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801031bc:	eb 40                	jmp    801031fe <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
801031be:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801031c2:	c1 e0 18             	shl    $0x18,%eax
801031c5:	89 44 24 04          	mov    %eax,0x4(%esp)
801031c9:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801031d0:	e8 3b fd ff ff       	call   80102f10 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
801031d5:	8b 45 0c             	mov    0xc(%ebp),%eax
801031d8:	c1 e8 0c             	shr    $0xc,%eax
801031db:	80 cc 06             	or     $0x6,%ah
801031de:	89 44 24 04          	mov    %eax,0x4(%esp)
801031e2:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801031e9:	e8 22 fd ff ff       	call   80102f10 <lapicw>
    microdelay(200);
801031ee:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801031f5:	e8 0d ff ff ff       	call   80103107 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801031fa:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801031fe:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103202:	7e ba                	jle    801031be <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80103204:	c9                   	leave  
80103205:	c3                   	ret    

80103206 <cmos_read>:
#define DAY     0x07
#define MONTH   0x08
#define YEAR    0x09

static uint cmos_read(uint reg)
{
80103206:	55                   	push   %ebp
80103207:	89 e5                	mov    %esp,%ebp
80103209:	83 ec 08             	sub    $0x8,%esp
  outb(CMOS_PORT,  reg);
8010320c:	8b 45 08             	mov    0x8(%ebp),%eax
8010320f:	0f b6 c0             	movzbl %al,%eax
80103212:	89 44 24 04          	mov    %eax,0x4(%esp)
80103216:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
8010321d:	e8 c0 fc ff ff       	call   80102ee2 <outb>
  microdelay(200);
80103222:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103229:	e8 d9 fe ff ff       	call   80103107 <microdelay>

  return inb(CMOS_RETURN);
8010322e:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80103235:	e8 8b fc ff ff       	call   80102ec5 <inb>
8010323a:	0f b6 c0             	movzbl %al,%eax
}
8010323d:	c9                   	leave  
8010323e:	c3                   	ret    

8010323f <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
8010323f:	55                   	push   %ebp
80103240:	89 e5                	mov    %esp,%ebp
80103242:	83 ec 04             	sub    $0x4,%esp
  r->second = cmos_read(SECS);
80103245:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010324c:	e8 b5 ff ff ff       	call   80103206 <cmos_read>
80103251:	8b 55 08             	mov    0x8(%ebp),%edx
80103254:	89 02                	mov    %eax,(%edx)
  r->minute = cmos_read(MINS);
80103256:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010325d:	e8 a4 ff ff ff       	call   80103206 <cmos_read>
80103262:	8b 55 08             	mov    0x8(%ebp),%edx
80103265:	89 42 04             	mov    %eax,0x4(%edx)
  r->hour   = cmos_read(HOURS);
80103268:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
8010326f:	e8 92 ff ff ff       	call   80103206 <cmos_read>
80103274:	8b 55 08             	mov    0x8(%ebp),%edx
80103277:	89 42 08             	mov    %eax,0x8(%edx)
  r->day    = cmos_read(DAY);
8010327a:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
80103281:	e8 80 ff ff ff       	call   80103206 <cmos_read>
80103286:	8b 55 08             	mov    0x8(%ebp),%edx
80103289:	89 42 0c             	mov    %eax,0xc(%edx)
  r->month  = cmos_read(MONTH);
8010328c:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80103293:	e8 6e ff ff ff       	call   80103206 <cmos_read>
80103298:	8b 55 08             	mov    0x8(%ebp),%edx
8010329b:	89 42 10             	mov    %eax,0x10(%edx)
  r->year   = cmos_read(YEAR);
8010329e:	c7 04 24 09 00 00 00 	movl   $0x9,(%esp)
801032a5:	e8 5c ff ff ff       	call   80103206 <cmos_read>
801032aa:	8b 55 08             	mov    0x8(%ebp),%edx
801032ad:	89 42 14             	mov    %eax,0x14(%edx)
}
801032b0:	c9                   	leave  
801032b1:	c3                   	ret    

801032b2 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
801032b2:	55                   	push   %ebp
801032b3:	89 e5                	mov    %esp,%ebp
801032b5:	83 ec 58             	sub    $0x58,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
801032b8:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
801032bf:	e8 42 ff ff ff       	call   80103206 <cmos_read>
801032c4:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
801032c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032ca:	83 e0 04             	and    $0x4,%eax
801032cd:	85 c0                	test   %eax,%eax
801032cf:	0f 94 c0             	sete   %al
801032d2:	0f b6 c0             	movzbl %al,%eax
801032d5:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
801032d8:	8d 45 d8             	lea    -0x28(%ebp),%eax
801032db:	89 04 24             	mov    %eax,(%esp)
801032de:	e8 5c ff ff ff       	call   8010323f <fill_rtcdate>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
801032e3:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
801032ea:	e8 17 ff ff ff       	call   80103206 <cmos_read>
801032ef:	25 80 00 00 00       	and    $0x80,%eax
801032f4:	85 c0                	test   %eax,%eax
801032f6:	74 02                	je     801032fa <cmostime+0x48>
        continue;
801032f8:	eb 36                	jmp    80103330 <cmostime+0x7e>
    fill_rtcdate(&t2);
801032fa:	8d 45 c0             	lea    -0x40(%ebp),%eax
801032fd:	89 04 24             	mov    %eax,(%esp)
80103300:	e8 3a ff ff ff       	call   8010323f <fill_rtcdate>
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
80103305:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
8010330c:	00 
8010330d:	8d 45 c0             	lea    -0x40(%ebp),%eax
80103310:	89 44 24 04          	mov    %eax,0x4(%esp)
80103314:	8d 45 d8             	lea    -0x28(%ebp),%eax
80103317:	89 04 24             	mov    %eax,(%esp)
8010331a:	e8 08 2a 00 00       	call   80105d27 <memcmp>
8010331f:	85 c0                	test   %eax,%eax
80103321:	75 0d                	jne    80103330 <cmostime+0x7e>
      break;
80103323:	90                   	nop
  }

  // convert
  if (bcd) {
80103324:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103328:	0f 84 ac 00 00 00    	je     801033da <cmostime+0x128>
8010332e:	eb 02                	jmp    80103332 <cmostime+0x80>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
80103330:	eb a6                	jmp    801032d8 <cmostime+0x26>

  // convert
  if (bcd) {
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
80103332:	8b 45 d8             	mov    -0x28(%ebp),%eax
80103335:	c1 e8 04             	shr    $0x4,%eax
80103338:	89 c2                	mov    %eax,%edx
8010333a:	89 d0                	mov    %edx,%eax
8010333c:	c1 e0 02             	shl    $0x2,%eax
8010333f:	01 d0                	add    %edx,%eax
80103341:	01 c0                	add    %eax,%eax
80103343:	8b 55 d8             	mov    -0x28(%ebp),%edx
80103346:	83 e2 0f             	and    $0xf,%edx
80103349:	01 d0                	add    %edx,%eax
8010334b:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
8010334e:	8b 45 dc             	mov    -0x24(%ebp),%eax
80103351:	c1 e8 04             	shr    $0x4,%eax
80103354:	89 c2                	mov    %eax,%edx
80103356:	89 d0                	mov    %edx,%eax
80103358:	c1 e0 02             	shl    $0x2,%eax
8010335b:	01 d0                	add    %edx,%eax
8010335d:	01 c0                	add    %eax,%eax
8010335f:	8b 55 dc             	mov    -0x24(%ebp),%edx
80103362:	83 e2 0f             	and    $0xf,%edx
80103365:	01 d0                	add    %edx,%eax
80103367:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
8010336a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010336d:	c1 e8 04             	shr    $0x4,%eax
80103370:	89 c2                	mov    %eax,%edx
80103372:	89 d0                	mov    %edx,%eax
80103374:	c1 e0 02             	shl    $0x2,%eax
80103377:	01 d0                	add    %edx,%eax
80103379:	01 c0                	add    %eax,%eax
8010337b:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010337e:	83 e2 0f             	and    $0xf,%edx
80103381:	01 d0                	add    %edx,%eax
80103383:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
80103386:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103389:	c1 e8 04             	shr    $0x4,%eax
8010338c:	89 c2                	mov    %eax,%edx
8010338e:	89 d0                	mov    %edx,%eax
80103390:	c1 e0 02             	shl    $0x2,%eax
80103393:	01 d0                	add    %edx,%eax
80103395:	01 c0                	add    %eax,%eax
80103397:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010339a:	83 e2 0f             	and    $0xf,%edx
8010339d:	01 d0                	add    %edx,%eax
8010339f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
801033a2:	8b 45 e8             	mov    -0x18(%ebp),%eax
801033a5:	c1 e8 04             	shr    $0x4,%eax
801033a8:	89 c2                	mov    %eax,%edx
801033aa:	89 d0                	mov    %edx,%eax
801033ac:	c1 e0 02             	shl    $0x2,%eax
801033af:	01 d0                	add    %edx,%eax
801033b1:	01 c0                	add    %eax,%eax
801033b3:	8b 55 e8             	mov    -0x18(%ebp),%edx
801033b6:	83 e2 0f             	and    $0xf,%edx
801033b9:	01 d0                	add    %edx,%eax
801033bb:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
801033be:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033c1:	c1 e8 04             	shr    $0x4,%eax
801033c4:	89 c2                	mov    %eax,%edx
801033c6:	89 d0                	mov    %edx,%eax
801033c8:	c1 e0 02             	shl    $0x2,%eax
801033cb:	01 d0                	add    %edx,%eax
801033cd:	01 c0                	add    %eax,%eax
801033cf:	8b 55 ec             	mov    -0x14(%ebp),%edx
801033d2:	83 e2 0f             	and    $0xf,%edx
801033d5:	01 d0                	add    %edx,%eax
801033d7:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
801033da:	8b 45 08             	mov    0x8(%ebp),%eax
801033dd:	8b 55 d8             	mov    -0x28(%ebp),%edx
801033e0:	89 10                	mov    %edx,(%eax)
801033e2:	8b 55 dc             	mov    -0x24(%ebp),%edx
801033e5:	89 50 04             	mov    %edx,0x4(%eax)
801033e8:	8b 55 e0             	mov    -0x20(%ebp),%edx
801033eb:	89 50 08             	mov    %edx,0x8(%eax)
801033ee:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801033f1:	89 50 0c             	mov    %edx,0xc(%eax)
801033f4:	8b 55 e8             	mov    -0x18(%ebp),%edx
801033f7:	89 50 10             	mov    %edx,0x10(%eax)
801033fa:	8b 55 ec             	mov    -0x14(%ebp),%edx
801033fd:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
80103400:	8b 45 08             	mov    0x8(%ebp),%eax
80103403:	8b 40 14             	mov    0x14(%eax),%eax
80103406:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
8010340c:	8b 45 08             	mov    0x8(%ebp),%eax
8010340f:	89 50 14             	mov    %edx,0x14(%eax)
}
80103412:	c9                   	leave  
80103413:	c3                   	ret    

80103414 <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(void)
{
80103414:	55                   	push   %ebp
80103415:	89 e5                	mov    %esp,%ebp
80103417:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
8010341a:	c7 44 24 04 94 92 10 	movl   $0x80109294,0x4(%esp)
80103421:	80 
80103422:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
80103429:	e8 0d 26 00 00       	call   80105a3b <initlock>
  readsb(ROOTDEV, &sb);
8010342e:	8d 45 e8             	lea    -0x18(%ebp),%eax
80103431:	89 44 24 04          	mov    %eax,0x4(%esp)
80103435:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010343c:	e8 a7 df ff ff       	call   801013e8 <readsb>
  log.start = sb.size - sb.nlog;
80103441:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103444:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103447:	29 c2                	sub    %eax,%edx
80103449:	89 d0                	mov    %edx,%eax
8010344b:	a3 d4 32 11 80       	mov    %eax,0x801132d4
  log.size = sb.nlog;
80103450:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103453:	a3 d8 32 11 80       	mov    %eax,0x801132d8
  log.dev = ROOTDEV;
80103458:	c7 05 e4 32 11 80 01 	movl   $0x1,0x801132e4
8010345f:	00 00 00 
  recover_from_log();
80103462:	e8 9a 01 00 00       	call   80103601 <recover_from_log>
}
80103467:	c9                   	leave  
80103468:	c3                   	ret    

80103469 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
80103469:	55                   	push   %ebp
8010346a:	89 e5                	mov    %esp,%ebp
8010346c:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010346f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103476:	e9 8c 00 00 00       	jmp    80103507 <install_trans+0x9e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
8010347b:	8b 15 d4 32 11 80    	mov    0x801132d4,%edx
80103481:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103484:	01 d0                	add    %edx,%eax
80103486:	83 c0 01             	add    $0x1,%eax
80103489:	89 c2                	mov    %eax,%edx
8010348b:	a1 e4 32 11 80       	mov    0x801132e4,%eax
80103490:	89 54 24 04          	mov    %edx,0x4(%esp)
80103494:	89 04 24             	mov    %eax,(%esp)
80103497:	e8 0a cd ff ff       	call   801001a6 <bread>
8010349c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
8010349f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801034a2:	83 c0 10             	add    $0x10,%eax
801034a5:	8b 04 85 ac 32 11 80 	mov    -0x7feecd54(,%eax,4),%eax
801034ac:	89 c2                	mov    %eax,%edx
801034ae:	a1 e4 32 11 80       	mov    0x801132e4,%eax
801034b3:	89 54 24 04          	mov    %edx,0x4(%esp)
801034b7:	89 04 24             	mov    %eax,(%esp)
801034ba:	e8 e7 cc ff ff       	call   801001a6 <bread>
801034bf:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801034c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801034c5:	8d 50 18             	lea    0x18(%eax),%edx
801034c8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801034cb:	83 c0 18             	add    $0x18,%eax
801034ce:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801034d5:	00 
801034d6:	89 54 24 04          	mov    %edx,0x4(%esp)
801034da:	89 04 24             	mov    %eax,(%esp)
801034dd:	e8 9d 28 00 00       	call   80105d7f <memmove>
    bwrite(dbuf);  // write dst to disk
801034e2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801034e5:	89 04 24             	mov    %eax,(%esp)
801034e8:	e8 f0 cc ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
801034ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
801034f0:	89 04 24             	mov    %eax,(%esp)
801034f3:	e8 1f cd ff ff       	call   80100217 <brelse>
    brelse(dbuf);
801034f8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801034fb:	89 04 24             	mov    %eax,(%esp)
801034fe:	e8 14 cd ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103503:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103507:	a1 e8 32 11 80       	mov    0x801132e8,%eax
8010350c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010350f:	0f 8f 66 ff ff ff    	jg     8010347b <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103515:	c9                   	leave  
80103516:	c3                   	ret    

80103517 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103517:	55                   	push   %ebp
80103518:	89 e5                	mov    %esp,%ebp
8010351a:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
8010351d:	a1 d4 32 11 80       	mov    0x801132d4,%eax
80103522:	89 c2                	mov    %eax,%edx
80103524:	a1 e4 32 11 80       	mov    0x801132e4,%eax
80103529:	89 54 24 04          	mov    %edx,0x4(%esp)
8010352d:	89 04 24             	mov    %eax,(%esp)
80103530:	e8 71 cc ff ff       	call   801001a6 <bread>
80103535:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103538:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010353b:	83 c0 18             	add    $0x18,%eax
8010353e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103541:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103544:	8b 00                	mov    (%eax),%eax
80103546:	a3 e8 32 11 80       	mov    %eax,0x801132e8
  for (i = 0; i < log.lh.n; i++) {
8010354b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103552:	eb 1b                	jmp    8010356f <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
80103554:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103557:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010355a:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
8010355e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103561:	83 c2 10             	add    $0x10,%edx
80103564:	89 04 95 ac 32 11 80 	mov    %eax,-0x7feecd54(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
8010356b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010356f:	a1 e8 32 11 80       	mov    0x801132e8,%eax
80103574:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103577:	7f db                	jg     80103554 <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
80103579:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010357c:	89 04 24             	mov    %eax,(%esp)
8010357f:	e8 93 cc ff ff       	call   80100217 <brelse>
}
80103584:	c9                   	leave  
80103585:	c3                   	ret    

80103586 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103586:	55                   	push   %ebp
80103587:	89 e5                	mov    %esp,%ebp
80103589:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
8010358c:	a1 d4 32 11 80       	mov    0x801132d4,%eax
80103591:	89 c2                	mov    %eax,%edx
80103593:	a1 e4 32 11 80       	mov    0x801132e4,%eax
80103598:	89 54 24 04          	mov    %edx,0x4(%esp)
8010359c:	89 04 24             	mov    %eax,(%esp)
8010359f:	e8 02 cc ff ff       	call   801001a6 <bread>
801035a4:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
801035a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035aa:	83 c0 18             	add    $0x18,%eax
801035ad:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
801035b0:	8b 15 e8 32 11 80    	mov    0x801132e8,%edx
801035b6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801035b9:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
801035bb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801035c2:	eb 1b                	jmp    801035df <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
801035c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035c7:	83 c0 10             	add    $0x10,%eax
801035ca:	8b 0c 85 ac 32 11 80 	mov    -0x7feecd54(,%eax,4),%ecx
801035d1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801035d4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801035d7:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
801035db:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801035df:	a1 e8 32 11 80       	mov    0x801132e8,%eax
801035e4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801035e7:	7f db                	jg     801035c4 <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
801035e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035ec:	89 04 24             	mov    %eax,(%esp)
801035ef:	e8 e9 cb ff ff       	call   801001dd <bwrite>
  brelse(buf);
801035f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035f7:	89 04 24             	mov    %eax,(%esp)
801035fa:	e8 18 cc ff ff       	call   80100217 <brelse>
}
801035ff:	c9                   	leave  
80103600:	c3                   	ret    

80103601 <recover_from_log>:

static void
recover_from_log(void)
{
80103601:	55                   	push   %ebp
80103602:	89 e5                	mov    %esp,%ebp
80103604:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103607:	e8 0b ff ff ff       	call   80103517 <read_head>
  install_trans(); // if committed, copy from log to disk
8010360c:	e8 58 fe ff ff       	call   80103469 <install_trans>
  log.lh.n = 0;
80103611:	c7 05 e8 32 11 80 00 	movl   $0x0,0x801132e8
80103618:	00 00 00 
  write_head(); // clear the log
8010361b:	e8 66 ff ff ff       	call   80103586 <write_head>
}
80103620:	c9                   	leave  
80103621:	c3                   	ret    

80103622 <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
80103622:	55                   	push   %ebp
80103623:	89 e5                	mov    %esp,%ebp
80103625:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103628:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
8010362f:	e8 28 24 00 00       	call   80105a5c <acquire>
  while(1){
    if(log.committing){
80103634:	a1 e0 32 11 80       	mov    0x801132e0,%eax
80103639:	85 c0                	test   %eax,%eax
8010363b:	74 16                	je     80103653 <begin_op+0x31>
      sleep(&log, &log.lock);
8010363d:	c7 44 24 04 a0 32 11 	movl   $0x801132a0,0x4(%esp)
80103644:	80 
80103645:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
8010364c:	e8 22 18 00 00       	call   80104e73 <sleep>
80103651:	eb 4f                	jmp    801036a2 <begin_op+0x80>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80103653:	8b 0d e8 32 11 80    	mov    0x801132e8,%ecx
80103659:	a1 dc 32 11 80       	mov    0x801132dc,%eax
8010365e:	8d 50 01             	lea    0x1(%eax),%edx
80103661:	89 d0                	mov    %edx,%eax
80103663:	c1 e0 02             	shl    $0x2,%eax
80103666:	01 d0                	add    %edx,%eax
80103668:	01 c0                	add    %eax,%eax
8010366a:	01 c8                	add    %ecx,%eax
8010366c:	83 f8 1e             	cmp    $0x1e,%eax
8010366f:	7e 16                	jle    80103687 <begin_op+0x65>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
80103671:	c7 44 24 04 a0 32 11 	movl   $0x801132a0,0x4(%esp)
80103678:	80 
80103679:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
80103680:	e8 ee 17 00 00       	call   80104e73 <sleep>
80103685:	eb 1b                	jmp    801036a2 <begin_op+0x80>
    } else {
      log.outstanding += 1;
80103687:	a1 dc 32 11 80       	mov    0x801132dc,%eax
8010368c:	83 c0 01             	add    $0x1,%eax
8010368f:	a3 dc 32 11 80       	mov    %eax,0x801132dc
      release(&log.lock);
80103694:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
8010369b:	e8 1e 24 00 00       	call   80105abe <release>
      break;
801036a0:	eb 02                	jmp    801036a4 <begin_op+0x82>
    }
  }
801036a2:	eb 90                	jmp    80103634 <begin_op+0x12>
}
801036a4:	c9                   	leave  
801036a5:	c3                   	ret    

801036a6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
801036a6:	55                   	push   %ebp
801036a7:	89 e5                	mov    %esp,%ebp
801036a9:	83 ec 28             	sub    $0x28,%esp
  int do_commit = 0;
801036ac:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
801036b3:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
801036ba:	e8 9d 23 00 00       	call   80105a5c <acquire>
  log.outstanding -= 1;
801036bf:	a1 dc 32 11 80       	mov    0x801132dc,%eax
801036c4:	83 e8 01             	sub    $0x1,%eax
801036c7:	a3 dc 32 11 80       	mov    %eax,0x801132dc
  if(log.committing)
801036cc:	a1 e0 32 11 80       	mov    0x801132e0,%eax
801036d1:	85 c0                	test   %eax,%eax
801036d3:	74 0c                	je     801036e1 <end_op+0x3b>
    panic("log.committing");
801036d5:	c7 04 24 98 92 10 80 	movl   $0x80109298,(%esp)
801036dc:	e8 59 ce ff ff       	call   8010053a <panic>
  if(log.outstanding == 0){
801036e1:	a1 dc 32 11 80       	mov    0x801132dc,%eax
801036e6:	85 c0                	test   %eax,%eax
801036e8:	75 13                	jne    801036fd <end_op+0x57>
    do_commit = 1;
801036ea:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
801036f1:	c7 05 e0 32 11 80 01 	movl   $0x1,0x801132e0
801036f8:	00 00 00 
801036fb:	eb 0c                	jmp    80103709 <end_op+0x63>
  } else {
    // begin_op() may be waiting for log space.
    wakeup(&log);
801036fd:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
80103704:	e8 46 18 00 00       	call   80104f4f <wakeup>
  }
  release(&log.lock);
80103709:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
80103710:	e8 a9 23 00 00       	call   80105abe <release>

  if(do_commit){
80103715:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103719:	74 33                	je     8010374e <end_op+0xa8>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
8010371b:	e8 de 00 00 00       	call   801037fe <commit>
    acquire(&log.lock);
80103720:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
80103727:	e8 30 23 00 00       	call   80105a5c <acquire>
    log.committing = 0;
8010372c:	c7 05 e0 32 11 80 00 	movl   $0x0,0x801132e0
80103733:	00 00 00 
    wakeup(&log);
80103736:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
8010373d:	e8 0d 18 00 00       	call   80104f4f <wakeup>
    release(&log.lock);
80103742:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
80103749:	e8 70 23 00 00       	call   80105abe <release>
  }
}
8010374e:	c9                   	leave  
8010374f:	c3                   	ret    

80103750 <write_log>:

// Copy modified blocks from cache to log.
static void 
write_log(void)
{
80103750:	55                   	push   %ebp
80103751:	89 e5                	mov    %esp,%ebp
80103753:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103756:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010375d:	e9 8c 00 00 00       	jmp    801037ee <write_log+0x9e>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80103762:	8b 15 d4 32 11 80    	mov    0x801132d4,%edx
80103768:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010376b:	01 d0                	add    %edx,%eax
8010376d:	83 c0 01             	add    $0x1,%eax
80103770:	89 c2                	mov    %eax,%edx
80103772:	a1 e4 32 11 80       	mov    0x801132e4,%eax
80103777:	89 54 24 04          	mov    %edx,0x4(%esp)
8010377b:	89 04 24             	mov    %eax,(%esp)
8010377e:	e8 23 ca ff ff       	call   801001a6 <bread>
80103783:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.sector[tail]); // cache block
80103786:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103789:	83 c0 10             	add    $0x10,%eax
8010378c:	8b 04 85 ac 32 11 80 	mov    -0x7feecd54(,%eax,4),%eax
80103793:	89 c2                	mov    %eax,%edx
80103795:	a1 e4 32 11 80       	mov    0x801132e4,%eax
8010379a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010379e:	89 04 24             	mov    %eax,(%esp)
801037a1:	e8 00 ca ff ff       	call   801001a6 <bread>
801037a6:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
801037a9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801037ac:	8d 50 18             	lea    0x18(%eax),%edx
801037af:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037b2:	83 c0 18             	add    $0x18,%eax
801037b5:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801037bc:	00 
801037bd:	89 54 24 04          	mov    %edx,0x4(%esp)
801037c1:	89 04 24             	mov    %eax,(%esp)
801037c4:	e8 b6 25 00 00       	call   80105d7f <memmove>
    bwrite(to);  // write the log
801037c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037cc:	89 04 24             	mov    %eax,(%esp)
801037cf:	e8 09 ca ff ff       	call   801001dd <bwrite>
    brelse(from); 
801037d4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801037d7:	89 04 24             	mov    %eax,(%esp)
801037da:	e8 38 ca ff ff       	call   80100217 <brelse>
    brelse(to);
801037df:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037e2:	89 04 24             	mov    %eax,(%esp)
801037e5:	e8 2d ca ff ff       	call   80100217 <brelse>
static void 
write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801037ea:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801037ee:	a1 e8 32 11 80       	mov    0x801132e8,%eax
801037f3:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801037f6:	0f 8f 66 ff ff ff    	jg     80103762 <write_log+0x12>
    memmove(to->data, from->data, BSIZE);
    bwrite(to);  // write the log
    brelse(from); 
    brelse(to);
  }
}
801037fc:	c9                   	leave  
801037fd:	c3                   	ret    

801037fe <commit>:

static void
commit()
{
801037fe:	55                   	push   %ebp
801037ff:	89 e5                	mov    %esp,%ebp
80103801:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
80103804:	a1 e8 32 11 80       	mov    0x801132e8,%eax
80103809:	85 c0                	test   %eax,%eax
8010380b:	7e 1e                	jle    8010382b <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
8010380d:	e8 3e ff ff ff       	call   80103750 <write_log>
    write_head();    // Write header to disk -- the real commit
80103812:	e8 6f fd ff ff       	call   80103586 <write_head>
    install_trans(); // Now install writes to home locations
80103817:	e8 4d fc ff ff       	call   80103469 <install_trans>
    log.lh.n = 0; 
8010381c:	c7 05 e8 32 11 80 00 	movl   $0x0,0x801132e8
80103823:	00 00 00 
    write_head();    // Erase the transaction from the log
80103826:	e8 5b fd ff ff       	call   80103586 <write_head>
  }
}
8010382b:	c9                   	leave  
8010382c:	c3                   	ret    

8010382d <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
8010382d:	55                   	push   %ebp
8010382e:	89 e5                	mov    %esp,%ebp
80103830:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103833:	a1 e8 32 11 80       	mov    0x801132e8,%eax
80103838:	83 f8 1d             	cmp    $0x1d,%eax
8010383b:	7f 12                	jg     8010384f <log_write+0x22>
8010383d:	a1 e8 32 11 80       	mov    0x801132e8,%eax
80103842:	8b 15 d8 32 11 80    	mov    0x801132d8,%edx
80103848:	83 ea 01             	sub    $0x1,%edx
8010384b:	39 d0                	cmp    %edx,%eax
8010384d:	7c 0c                	jl     8010385b <log_write+0x2e>
    panic("too big a transaction");
8010384f:	c7 04 24 a7 92 10 80 	movl   $0x801092a7,(%esp)
80103856:	e8 df cc ff ff       	call   8010053a <panic>
  if (log.outstanding < 1)
8010385b:	a1 dc 32 11 80       	mov    0x801132dc,%eax
80103860:	85 c0                	test   %eax,%eax
80103862:	7f 0c                	jg     80103870 <log_write+0x43>
    panic("log_write outside of trans");
80103864:	c7 04 24 bd 92 10 80 	movl   $0x801092bd,(%esp)
8010386b:	e8 ca cc ff ff       	call   8010053a <panic>

  acquire(&log.lock);
80103870:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
80103877:	e8 e0 21 00 00       	call   80105a5c <acquire>
  for (i = 0; i < log.lh.n; i++) {
8010387c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103883:	eb 1f                	jmp    801038a4 <log_write+0x77>
    if (log.lh.sector[i] == b->sector)   // log absorbtion
80103885:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103888:	83 c0 10             	add    $0x10,%eax
8010388b:	8b 04 85 ac 32 11 80 	mov    -0x7feecd54(,%eax,4),%eax
80103892:	89 c2                	mov    %eax,%edx
80103894:	8b 45 08             	mov    0x8(%ebp),%eax
80103897:	8b 40 08             	mov    0x8(%eax),%eax
8010389a:	39 c2                	cmp    %eax,%edx
8010389c:	75 02                	jne    801038a0 <log_write+0x73>
      break;
8010389e:	eb 0e                	jmp    801038ae <log_write+0x81>
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
801038a0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801038a4:	a1 e8 32 11 80       	mov    0x801132e8,%eax
801038a9:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801038ac:	7f d7                	jg     80103885 <log_write+0x58>
    if (log.lh.sector[i] == b->sector)   // log absorbtion
      break;
  }
  log.lh.sector[i] = b->sector;
801038ae:	8b 45 08             	mov    0x8(%ebp),%eax
801038b1:	8b 40 08             	mov    0x8(%eax),%eax
801038b4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801038b7:	83 c2 10             	add    $0x10,%edx
801038ba:	89 04 95 ac 32 11 80 	mov    %eax,-0x7feecd54(,%edx,4)
  if (i == log.lh.n)
801038c1:	a1 e8 32 11 80       	mov    0x801132e8,%eax
801038c6:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801038c9:	75 0d                	jne    801038d8 <log_write+0xab>
    log.lh.n++;
801038cb:	a1 e8 32 11 80       	mov    0x801132e8,%eax
801038d0:	83 c0 01             	add    $0x1,%eax
801038d3:	a3 e8 32 11 80       	mov    %eax,0x801132e8
  b->flags |= B_DIRTY; // prevent eviction
801038d8:	8b 45 08             	mov    0x8(%ebp),%eax
801038db:	8b 00                	mov    (%eax),%eax
801038dd:	83 c8 04             	or     $0x4,%eax
801038e0:	89 c2                	mov    %eax,%edx
801038e2:	8b 45 08             	mov    0x8(%ebp),%eax
801038e5:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
801038e7:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
801038ee:	e8 cb 21 00 00       	call   80105abe <release>
}
801038f3:	c9                   	leave  
801038f4:	c3                   	ret    

801038f5 <v2p>:
801038f5:	55                   	push   %ebp
801038f6:	89 e5                	mov    %esp,%ebp
801038f8:	8b 45 08             	mov    0x8(%ebp),%eax
801038fb:	05 00 00 00 80       	add    $0x80000000,%eax
80103900:	5d                   	pop    %ebp
80103901:	c3                   	ret    

80103902 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103902:	55                   	push   %ebp
80103903:	89 e5                	mov    %esp,%ebp
80103905:	8b 45 08             	mov    0x8(%ebp),%eax
80103908:	05 00 00 00 80       	add    $0x80000000,%eax
8010390d:	5d                   	pop    %ebp
8010390e:	c3                   	ret    

8010390f <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
8010390f:	55                   	push   %ebp
80103910:	89 e5                	mov    %esp,%ebp
80103912:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103915:	8b 55 08             	mov    0x8(%ebp),%edx
80103918:	8b 45 0c             	mov    0xc(%ebp),%eax
8010391b:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010391e:	f0 87 02             	lock xchg %eax,(%edx)
80103921:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103924:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80103927:	c9                   	leave  
80103928:	c3                   	ret    

80103929 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103929:	55                   	push   %ebp
8010392a:	89 e5                	mov    %esp,%ebp
8010392c:	83 e4 f0             	and    $0xfffffff0,%esp
8010392f:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103932:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103939:	80 
8010393a:	c7 04 24 7c 75 12 80 	movl   $0x8012757c,(%esp)
80103941:	e8 80 f2 ff ff       	call   80102bc6 <kinit1>
  kvmalloc();      // kernel page table
80103946:	e8 90 4f 00 00       	call   801088db <kvmalloc>
  mpinit();        // collect info about this machine
8010394b:	e8 4b 04 00 00       	call   80103d9b <mpinit>
  lapicinit();
80103950:	e8 dc f5 ff ff       	call   80102f31 <lapicinit>
  seginit();       // set up segments
80103955:	e8 14 49 00 00       	call   8010826e <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
8010395a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103960:	0f b6 00             	movzbl (%eax),%eax
80103963:	0f b6 c0             	movzbl %al,%eax
80103966:	89 44 24 04          	mov    %eax,0x4(%esp)
8010396a:	c7 04 24 d8 92 10 80 	movl   $0x801092d8,(%esp)
80103971:	e8 2a ca ff ff       	call   801003a0 <cprintf>
  picinit();       // interrupt controller
80103976:	e8 7e 06 00 00       	call   80103ff9 <picinit>
  ioapicinit();    // another interrupt controller
8010397b:	e8 3c f1 ff ff       	call   80102abc <ioapicinit>
  procfsinit();
80103980:	e8 4b 1f 00 00       	call   801058d0 <procfsinit>
  consoleinit();   // I/O devices & their interrupts
80103985:	e8 f7 d0 ff ff       	call   80100a81 <consoleinit>
  uartinit();      // serial port
8010398a:	e8 2e 3c 00 00       	call   801075bd <uartinit>
  pinit();         // process table
8010398f:	e8 6f 0b 00 00       	call   80104503 <pinit>
  tvinit();        // trap vectors
80103994:	e8 d6 37 00 00       	call   8010716f <tvinit>
  binit();         // buffer cache
80103999:	e8 96 c6 ff ff       	call   80100034 <binit>
  fileinit();      // file table
8010399e:	e8 5e d6 ff ff       	call   80101001 <fileinit>
  iinit();         // inode cache
801039a3:	e8 f3 dc ff ff       	call   8010169b <iinit>
  ideinit();       // disk
801039a8:	e8 78 ed ff ff       	call   80102725 <ideinit>
  if(!ismp)
801039ad:	a1 84 33 11 80       	mov    0x80113384,%eax
801039b2:	85 c0                	test   %eax,%eax
801039b4:	75 05                	jne    801039bb <main+0x92>
    timerinit();   // uniprocessor timer
801039b6:	e8 ff 36 00 00       	call   801070ba <timerinit>
  startothers();   // start other processors
801039bb:	e8 7f 00 00 00       	call   80103a3f <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
801039c0:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
801039c7:	8e 
801039c8:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
801039cf:	e8 2a f2 ff ff       	call   80102bfe <kinit2>
  userinit();      // first user process
801039d4:	e8 48 0c 00 00       	call   80104621 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
801039d9:	e8 1a 00 00 00       	call   801039f8 <mpmain>

801039de <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
801039de:	55                   	push   %ebp
801039df:	89 e5                	mov    %esp,%ebp
801039e1:	83 ec 08             	sub    $0x8,%esp
  switchkvm(); 
801039e4:	e8 09 4f 00 00       	call   801088f2 <switchkvm>
  seginit();
801039e9:	e8 80 48 00 00       	call   8010826e <seginit>
  lapicinit();
801039ee:	e8 3e f5 ff ff       	call   80102f31 <lapicinit>
  mpmain();
801039f3:	e8 00 00 00 00       	call   801039f8 <mpmain>

801039f8 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
801039f8:	55                   	push   %ebp
801039f9:	89 e5                	mov    %esp,%ebp
801039fb:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
801039fe:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103a04:	0f b6 00             	movzbl (%eax),%eax
80103a07:	0f b6 c0             	movzbl %al,%eax
80103a0a:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a0e:	c7 04 24 ef 92 10 80 	movl   $0x801092ef,(%esp)
80103a15:	e8 86 c9 ff ff       	call   801003a0 <cprintf>
  idtinit();       // load idt register
80103a1a:	e8 c4 38 00 00       	call   801072e3 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103a1f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103a25:	05 a8 00 00 00       	add    $0xa8,%eax
80103a2a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103a31:	00 
80103a32:	89 04 24             	mov    %eax,(%esp)
80103a35:	e8 d5 fe ff ff       	call   8010390f <xchg>
  scheduler();     // start running processes
80103a3a:	e8 89 12 00 00       	call   80104cc8 <scheduler>

80103a3f <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103a3f:	55                   	push   %ebp
80103a40:	89 e5                	mov    %esp,%ebp
80103a42:	53                   	push   %ebx
80103a43:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103a46:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103a4d:	e8 b0 fe ff ff       	call   80103902 <p2v>
80103a52:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103a55:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103a5a:	89 44 24 08          	mov    %eax,0x8(%esp)
80103a5e:	c7 44 24 04 0c c5 10 	movl   $0x8010c50c,0x4(%esp)
80103a65:	80 
80103a66:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a69:	89 04 24             	mov    %eax,(%esp)
80103a6c:	e8 0e 23 00 00       	call   80105d7f <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103a71:	c7 45 f4 a0 33 11 80 	movl   $0x801133a0,-0xc(%ebp)
80103a78:	e9 85 00 00 00       	jmp    80103b02 <startothers+0xc3>
    if(c == cpus+cpunum())  // We've started already.
80103a7d:	e8 08 f6 ff ff       	call   8010308a <cpunum>
80103a82:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103a88:	05 a0 33 11 80       	add    $0x801133a0,%eax
80103a8d:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103a90:	75 02                	jne    80103a94 <startothers+0x55>
      continue;
80103a92:	eb 67                	jmp    80103afb <startothers+0xbc>

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80103a94:	e8 5b f2 ff ff       	call   80102cf4 <kalloc>
80103a99:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80103a9c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a9f:	83 e8 04             	sub    $0x4,%eax
80103aa2:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103aa5:	81 c2 00 10 00 00    	add    $0x1000,%edx
80103aab:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
80103aad:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ab0:	83 e8 08             	sub    $0x8,%eax
80103ab3:	c7 00 de 39 10 80    	movl   $0x801039de,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80103ab9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103abc:	8d 58 f4             	lea    -0xc(%eax),%ebx
80103abf:	c7 04 24 00 b0 10 80 	movl   $0x8010b000,(%esp)
80103ac6:	e8 2a fe ff ff       	call   801038f5 <v2p>
80103acb:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80103acd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ad0:	89 04 24             	mov    %eax,(%esp)
80103ad3:	e8 1d fe ff ff       	call   801038f5 <v2p>
80103ad8:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103adb:	0f b6 12             	movzbl (%edx),%edx
80103ade:	0f b6 d2             	movzbl %dl,%edx
80103ae1:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ae5:	89 14 24             	mov    %edx,(%esp)
80103ae8:	e8 1f f6 ff ff       	call   8010310c <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80103aed:	90                   	nop
80103aee:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103af1:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80103af7:	85 c0                	test   %eax,%eax
80103af9:	74 f3                	je     80103aee <startothers+0xaf>
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80103afb:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80103b02:	a1 80 39 11 80       	mov    0x80113980,%eax
80103b07:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103b0d:	05 a0 33 11 80       	add    $0x801133a0,%eax
80103b12:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103b15:	0f 87 62 ff ff ff    	ja     80103a7d <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103b1b:	83 c4 24             	add    $0x24,%esp
80103b1e:	5b                   	pop    %ebx
80103b1f:	5d                   	pop    %ebp
80103b20:	c3                   	ret    

80103b21 <p2v>:
80103b21:	55                   	push   %ebp
80103b22:	89 e5                	mov    %esp,%ebp
80103b24:	8b 45 08             	mov    0x8(%ebp),%eax
80103b27:	05 00 00 00 80       	add    $0x80000000,%eax
80103b2c:	5d                   	pop    %ebp
80103b2d:	c3                   	ret    

80103b2e <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103b2e:	55                   	push   %ebp
80103b2f:	89 e5                	mov    %esp,%ebp
80103b31:	83 ec 14             	sub    $0x14,%esp
80103b34:	8b 45 08             	mov    0x8(%ebp),%eax
80103b37:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103b3b:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80103b3f:	89 c2                	mov    %eax,%edx
80103b41:	ec                   	in     (%dx),%al
80103b42:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80103b45:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80103b49:	c9                   	leave  
80103b4a:	c3                   	ret    

80103b4b <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103b4b:	55                   	push   %ebp
80103b4c:	89 e5                	mov    %esp,%ebp
80103b4e:	83 ec 08             	sub    $0x8,%esp
80103b51:	8b 55 08             	mov    0x8(%ebp),%edx
80103b54:	8b 45 0c             	mov    0xc(%ebp),%eax
80103b57:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103b5b:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103b5e:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103b62:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103b66:	ee                   	out    %al,(%dx)
}
80103b67:	c9                   	leave  
80103b68:	c3                   	ret    

80103b69 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80103b69:	55                   	push   %ebp
80103b6a:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
80103b6c:	a1 44 c6 10 80       	mov    0x8010c644,%eax
80103b71:	89 c2                	mov    %eax,%edx
80103b73:	b8 a0 33 11 80       	mov    $0x801133a0,%eax
80103b78:	29 c2                	sub    %eax,%edx
80103b7a:	89 d0                	mov    %edx,%eax
80103b7c:	c1 f8 02             	sar    $0x2,%eax
80103b7f:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80103b85:	5d                   	pop    %ebp
80103b86:	c3                   	ret    

80103b87 <sum>:

static uchar
sum(uchar *addr, int len)
{
80103b87:	55                   	push   %ebp
80103b88:	89 e5                	mov    %esp,%ebp
80103b8a:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
80103b8d:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80103b94:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103b9b:	eb 15                	jmp    80103bb2 <sum+0x2b>
    sum += addr[i];
80103b9d:	8b 55 fc             	mov    -0x4(%ebp),%edx
80103ba0:	8b 45 08             	mov    0x8(%ebp),%eax
80103ba3:	01 d0                	add    %edx,%eax
80103ba5:	0f b6 00             	movzbl (%eax),%eax
80103ba8:	0f b6 c0             	movzbl %al,%eax
80103bab:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
80103bae:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103bb2:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103bb5:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103bb8:	7c e3                	jl     80103b9d <sum+0x16>
    sum += addr[i];
  return sum;
80103bba:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103bbd:	c9                   	leave  
80103bbe:	c3                   	ret    

80103bbf <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80103bbf:	55                   	push   %ebp
80103bc0:	89 e5                	mov    %esp,%ebp
80103bc2:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80103bc5:	8b 45 08             	mov    0x8(%ebp),%eax
80103bc8:	89 04 24             	mov    %eax,(%esp)
80103bcb:	e8 51 ff ff ff       	call   80103b21 <p2v>
80103bd0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80103bd3:	8b 55 0c             	mov    0xc(%ebp),%edx
80103bd6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bd9:	01 d0                	add    %edx,%eax
80103bdb:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80103bde:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103be1:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103be4:	eb 3f                	jmp    80103c25 <mpsearch1+0x66>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103be6:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103bed:	00 
80103bee:	c7 44 24 04 00 93 10 	movl   $0x80109300,0x4(%esp)
80103bf5:	80 
80103bf6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bf9:	89 04 24             	mov    %eax,(%esp)
80103bfc:	e8 26 21 00 00       	call   80105d27 <memcmp>
80103c01:	85 c0                	test   %eax,%eax
80103c03:	75 1c                	jne    80103c21 <mpsearch1+0x62>
80103c05:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80103c0c:	00 
80103c0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c10:	89 04 24             	mov    %eax,(%esp)
80103c13:	e8 6f ff ff ff       	call   80103b87 <sum>
80103c18:	84 c0                	test   %al,%al
80103c1a:	75 05                	jne    80103c21 <mpsearch1+0x62>
      return (struct mp*)p;
80103c1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c1f:	eb 11                	jmp    80103c32 <mpsearch1+0x73>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80103c21:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103c25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c28:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103c2b:	72 b9                	jb     80103be6 <mpsearch1+0x27>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
80103c2d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103c32:	c9                   	leave  
80103c33:	c3                   	ret    

80103c34 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103c34:	55                   	push   %ebp
80103c35:	89 e5                	mov    %esp,%ebp
80103c37:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103c3a:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80103c41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c44:	83 c0 0f             	add    $0xf,%eax
80103c47:	0f b6 00             	movzbl (%eax),%eax
80103c4a:	0f b6 c0             	movzbl %al,%eax
80103c4d:	c1 e0 08             	shl    $0x8,%eax
80103c50:	89 c2                	mov    %eax,%edx
80103c52:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c55:	83 c0 0e             	add    $0xe,%eax
80103c58:	0f b6 00             	movzbl (%eax),%eax
80103c5b:	0f b6 c0             	movzbl %al,%eax
80103c5e:	09 d0                	or     %edx,%eax
80103c60:	c1 e0 04             	shl    $0x4,%eax
80103c63:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103c66:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103c6a:	74 21                	je     80103c8d <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80103c6c:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103c73:	00 
80103c74:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c77:	89 04 24             	mov    %eax,(%esp)
80103c7a:	e8 40 ff ff ff       	call   80103bbf <mpsearch1>
80103c7f:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103c82:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103c86:	74 50                	je     80103cd8 <mpsearch+0xa4>
      return mp;
80103c88:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c8b:	eb 5f                	jmp    80103cec <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80103c8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c90:	83 c0 14             	add    $0x14,%eax
80103c93:	0f b6 00             	movzbl (%eax),%eax
80103c96:	0f b6 c0             	movzbl %al,%eax
80103c99:	c1 e0 08             	shl    $0x8,%eax
80103c9c:	89 c2                	mov    %eax,%edx
80103c9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ca1:	83 c0 13             	add    $0x13,%eax
80103ca4:	0f b6 00             	movzbl (%eax),%eax
80103ca7:	0f b6 c0             	movzbl %al,%eax
80103caa:	09 d0                	or     %edx,%eax
80103cac:	c1 e0 0a             	shl    $0xa,%eax
80103caf:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103cb2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103cb5:	2d 00 04 00 00       	sub    $0x400,%eax
80103cba:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103cc1:	00 
80103cc2:	89 04 24             	mov    %eax,(%esp)
80103cc5:	e8 f5 fe ff ff       	call   80103bbf <mpsearch1>
80103cca:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103ccd:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103cd1:	74 05                	je     80103cd8 <mpsearch+0xa4>
      return mp;
80103cd3:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103cd6:	eb 14                	jmp    80103cec <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80103cd8:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103cdf:	00 
80103ce0:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80103ce7:	e8 d3 fe ff ff       	call   80103bbf <mpsearch1>
}
80103cec:	c9                   	leave  
80103ced:	c3                   	ret    

80103cee <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80103cee:	55                   	push   %ebp
80103cef:	89 e5                	mov    %esp,%ebp
80103cf1:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80103cf4:	e8 3b ff ff ff       	call   80103c34 <mpsearch>
80103cf9:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103cfc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103d00:	74 0a                	je     80103d0c <mpconfig+0x1e>
80103d02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d05:	8b 40 04             	mov    0x4(%eax),%eax
80103d08:	85 c0                	test   %eax,%eax
80103d0a:	75 0a                	jne    80103d16 <mpconfig+0x28>
    return 0;
80103d0c:	b8 00 00 00 00       	mov    $0x0,%eax
80103d11:	e9 83 00 00 00       	jmp    80103d99 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80103d16:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d19:	8b 40 04             	mov    0x4(%eax),%eax
80103d1c:	89 04 24             	mov    %eax,(%esp)
80103d1f:	e8 fd fd ff ff       	call   80103b21 <p2v>
80103d24:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103d27:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103d2e:	00 
80103d2f:	c7 44 24 04 05 93 10 	movl   $0x80109305,0x4(%esp)
80103d36:	80 
80103d37:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d3a:	89 04 24             	mov    %eax,(%esp)
80103d3d:	e8 e5 1f 00 00       	call   80105d27 <memcmp>
80103d42:	85 c0                	test   %eax,%eax
80103d44:	74 07                	je     80103d4d <mpconfig+0x5f>
    return 0;
80103d46:	b8 00 00 00 00       	mov    $0x0,%eax
80103d4b:	eb 4c                	jmp    80103d99 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
80103d4d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d50:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103d54:	3c 01                	cmp    $0x1,%al
80103d56:	74 12                	je     80103d6a <mpconfig+0x7c>
80103d58:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d5b:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103d5f:	3c 04                	cmp    $0x4,%al
80103d61:	74 07                	je     80103d6a <mpconfig+0x7c>
    return 0;
80103d63:	b8 00 00 00 00       	mov    $0x0,%eax
80103d68:	eb 2f                	jmp    80103d99 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80103d6a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d6d:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103d71:	0f b7 c0             	movzwl %ax,%eax
80103d74:	89 44 24 04          	mov    %eax,0x4(%esp)
80103d78:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d7b:	89 04 24             	mov    %eax,(%esp)
80103d7e:	e8 04 fe ff ff       	call   80103b87 <sum>
80103d83:	84 c0                	test   %al,%al
80103d85:	74 07                	je     80103d8e <mpconfig+0xa0>
    return 0;
80103d87:	b8 00 00 00 00       	mov    $0x0,%eax
80103d8c:	eb 0b                	jmp    80103d99 <mpconfig+0xab>
  *pmp = mp;
80103d8e:	8b 45 08             	mov    0x8(%ebp),%eax
80103d91:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103d94:	89 10                	mov    %edx,(%eax)
  return conf;
80103d96:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80103d99:	c9                   	leave  
80103d9a:	c3                   	ret    

80103d9b <mpinit>:

void
mpinit(void)
{
80103d9b:	55                   	push   %ebp
80103d9c:	89 e5                	mov    %esp,%ebp
80103d9e:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80103da1:	c7 05 44 c6 10 80 a0 	movl   $0x801133a0,0x8010c644
80103da8:	33 11 80 
  if((conf = mpconfig(&mp)) == 0)
80103dab:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103dae:	89 04 24             	mov    %eax,(%esp)
80103db1:	e8 38 ff ff ff       	call   80103cee <mpconfig>
80103db6:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103db9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103dbd:	75 05                	jne    80103dc4 <mpinit+0x29>
    return;
80103dbf:	e9 9c 01 00 00       	jmp    80103f60 <mpinit+0x1c5>
  ismp = 1;
80103dc4:	c7 05 84 33 11 80 01 	movl   $0x1,0x80113384
80103dcb:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80103dce:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103dd1:	8b 40 24             	mov    0x24(%eax),%eax
80103dd4:	a3 9c 32 11 80       	mov    %eax,0x8011329c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103dd9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ddc:	83 c0 2c             	add    $0x2c,%eax
80103ddf:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103de2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103de5:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103de9:	0f b7 d0             	movzwl %ax,%edx
80103dec:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103def:	01 d0                	add    %edx,%eax
80103df1:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103df4:	e9 f4 00 00 00       	jmp    80103eed <mpinit+0x152>
    switch(*p){
80103df9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103dfc:	0f b6 00             	movzbl (%eax),%eax
80103dff:	0f b6 c0             	movzbl %al,%eax
80103e02:	83 f8 04             	cmp    $0x4,%eax
80103e05:	0f 87 bf 00 00 00    	ja     80103eca <mpinit+0x12f>
80103e0b:	8b 04 85 48 93 10 80 	mov    -0x7fef6cb8(,%eax,4),%eax
80103e12:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103e14:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e17:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80103e1a:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103e1d:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103e21:	0f b6 d0             	movzbl %al,%edx
80103e24:	a1 80 39 11 80       	mov    0x80113980,%eax
80103e29:	39 c2                	cmp    %eax,%edx
80103e2b:	74 2d                	je     80103e5a <mpinit+0xbf>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80103e2d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103e30:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103e34:	0f b6 d0             	movzbl %al,%edx
80103e37:	a1 80 39 11 80       	mov    0x80113980,%eax
80103e3c:	89 54 24 08          	mov    %edx,0x8(%esp)
80103e40:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e44:	c7 04 24 0a 93 10 80 	movl   $0x8010930a,(%esp)
80103e4b:	e8 50 c5 ff ff       	call   801003a0 <cprintf>
        ismp = 0;
80103e50:	c7 05 84 33 11 80 00 	movl   $0x0,0x80113384
80103e57:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80103e5a:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103e5d:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80103e61:	0f b6 c0             	movzbl %al,%eax
80103e64:	83 e0 02             	and    $0x2,%eax
80103e67:	85 c0                	test   %eax,%eax
80103e69:	74 15                	je     80103e80 <mpinit+0xe5>
        bcpu = &cpus[ncpu];
80103e6b:	a1 80 39 11 80       	mov    0x80113980,%eax
80103e70:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103e76:	05 a0 33 11 80       	add    $0x801133a0,%eax
80103e7b:	a3 44 c6 10 80       	mov    %eax,0x8010c644
      cpus[ncpu].id = ncpu;
80103e80:	8b 15 80 39 11 80    	mov    0x80113980,%edx
80103e86:	a1 80 39 11 80       	mov    0x80113980,%eax
80103e8b:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80103e91:	81 c2 a0 33 11 80    	add    $0x801133a0,%edx
80103e97:	88 02                	mov    %al,(%edx)
      ncpu++;
80103e99:	a1 80 39 11 80       	mov    0x80113980,%eax
80103e9e:	83 c0 01             	add    $0x1,%eax
80103ea1:	a3 80 39 11 80       	mov    %eax,0x80113980
      p += sizeof(struct mpproc);
80103ea6:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80103eaa:	eb 41                	jmp    80103eed <mpinit+0x152>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80103eac:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103eaf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80103eb2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103eb5:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103eb9:	a2 80 33 11 80       	mov    %al,0x80113380
      p += sizeof(struct mpioapic);
80103ebe:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103ec2:	eb 29                	jmp    80103eed <mpinit+0x152>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103ec4:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103ec8:	eb 23                	jmp    80103eed <mpinit+0x152>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80103eca:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ecd:	0f b6 00             	movzbl (%eax),%eax
80103ed0:	0f b6 c0             	movzbl %al,%eax
80103ed3:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ed7:	c7 04 24 28 93 10 80 	movl   $0x80109328,(%esp)
80103ede:	e8 bd c4 ff ff       	call   801003a0 <cprintf>
      ismp = 0;
80103ee3:	c7 05 84 33 11 80 00 	movl   $0x0,0x80113384
80103eea:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103eed:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ef0:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103ef3:	0f 82 00 ff ff ff    	jb     80103df9 <mpinit+0x5e>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80103ef9:	a1 84 33 11 80       	mov    0x80113384,%eax
80103efe:	85 c0                	test   %eax,%eax
80103f00:	75 1d                	jne    80103f1f <mpinit+0x184>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80103f02:	c7 05 80 39 11 80 01 	movl   $0x1,0x80113980
80103f09:	00 00 00 
    lapic = 0;
80103f0c:	c7 05 9c 32 11 80 00 	movl   $0x0,0x8011329c
80103f13:	00 00 00 
    ioapicid = 0;
80103f16:	c6 05 80 33 11 80 00 	movb   $0x0,0x80113380
    return;
80103f1d:	eb 41                	jmp    80103f60 <mpinit+0x1c5>
  }

  if(mp->imcrp){
80103f1f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103f22:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103f26:	84 c0                	test   %al,%al
80103f28:	74 36                	je     80103f60 <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103f2a:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80103f31:	00 
80103f32:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80103f39:	e8 0d fc ff ff       	call   80103b4b <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103f3e:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103f45:	e8 e4 fb ff ff       	call   80103b2e <inb>
80103f4a:	83 c8 01             	or     $0x1,%eax
80103f4d:	0f b6 c0             	movzbl %al,%eax
80103f50:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f54:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103f5b:	e8 eb fb ff ff       	call   80103b4b <outb>
  }
}
80103f60:	c9                   	leave  
80103f61:	c3                   	ret    

80103f62 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103f62:	55                   	push   %ebp
80103f63:	89 e5                	mov    %esp,%ebp
80103f65:	83 ec 08             	sub    $0x8,%esp
80103f68:	8b 55 08             	mov    0x8(%ebp),%edx
80103f6b:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f6e:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103f72:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103f75:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103f79:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103f7d:	ee                   	out    %al,(%dx)
}
80103f7e:	c9                   	leave  
80103f7f:	c3                   	ret    

80103f80 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80103f80:	55                   	push   %ebp
80103f81:	89 e5                	mov    %esp,%ebp
80103f83:	83 ec 0c             	sub    $0xc,%esp
80103f86:	8b 45 08             	mov    0x8(%ebp),%eax
80103f89:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80103f8d:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103f91:	66 a3 00 c0 10 80    	mov    %ax,0x8010c000
  outb(IO_PIC1+1, mask);
80103f97:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103f9b:	0f b6 c0             	movzbl %al,%eax
80103f9e:	89 44 24 04          	mov    %eax,0x4(%esp)
80103fa2:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103fa9:	e8 b4 ff ff ff       	call   80103f62 <outb>
  outb(IO_PIC2+1, mask >> 8);
80103fae:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103fb2:	66 c1 e8 08          	shr    $0x8,%ax
80103fb6:	0f b6 c0             	movzbl %al,%eax
80103fb9:	89 44 24 04          	mov    %eax,0x4(%esp)
80103fbd:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103fc4:	e8 99 ff ff ff       	call   80103f62 <outb>
}
80103fc9:	c9                   	leave  
80103fca:	c3                   	ret    

80103fcb <picenable>:

void
picenable(int irq)
{
80103fcb:	55                   	push   %ebp
80103fcc:	89 e5                	mov    %esp,%ebp
80103fce:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80103fd1:	8b 45 08             	mov    0x8(%ebp),%eax
80103fd4:	ba 01 00 00 00       	mov    $0x1,%edx
80103fd9:	89 c1                	mov    %eax,%ecx
80103fdb:	d3 e2                	shl    %cl,%edx
80103fdd:	89 d0                	mov    %edx,%eax
80103fdf:	f7 d0                	not    %eax
80103fe1:	89 c2                	mov    %eax,%edx
80103fe3:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80103fea:	21 d0                	and    %edx,%eax
80103fec:	0f b7 c0             	movzwl %ax,%eax
80103fef:	89 04 24             	mov    %eax,(%esp)
80103ff2:	e8 89 ff ff ff       	call   80103f80 <picsetmask>
}
80103ff7:	c9                   	leave  
80103ff8:	c3                   	ret    

80103ff9 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80103ff9:	55                   	push   %ebp
80103ffa:	89 e5                	mov    %esp,%ebp
80103ffc:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103fff:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104006:	00 
80104007:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010400e:	e8 4f ff ff ff       	call   80103f62 <outb>
  outb(IO_PIC2+1, 0xFF);
80104013:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
8010401a:	00 
8010401b:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104022:	e8 3b ff ff ff       	call   80103f62 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80104027:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
8010402e:	00 
8010402f:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104036:	e8 27 ff ff ff       	call   80103f62 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
8010403b:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80104042:	00 
80104043:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010404a:	e8 13 ff ff ff       	call   80103f62 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
8010404f:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80104056:	00 
80104057:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010405e:	e8 ff fe ff ff       	call   80103f62 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80104063:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
8010406a:	00 
8010406b:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104072:	e8 eb fe ff ff       	call   80103f62 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80104077:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
8010407e:	00 
8010407f:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104086:	e8 d7 fe ff ff       	call   80103f62 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
8010408b:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80104092:	00 
80104093:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010409a:	e8 c3 fe ff ff       	call   80103f62 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
8010409f:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
801040a6:	00 
801040a7:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801040ae:	e8 af fe ff ff       	call   80103f62 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
801040b3:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801040ba:	00 
801040bb:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801040c2:	e8 9b fe ff ff       	call   80103f62 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
801040c7:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
801040ce:	00 
801040cf:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801040d6:	e8 87 fe ff ff       	call   80103f62 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
801040db:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801040e2:	00 
801040e3:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801040ea:	e8 73 fe ff ff       	call   80103f62 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
801040ef:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
801040f6:	00 
801040f7:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801040fe:	e8 5f fe ff ff       	call   80103f62 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80104103:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
8010410a:	00 
8010410b:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104112:	e8 4b fe ff ff       	call   80103f62 <outb>

  if(irqmask != 0xFFFF)
80104117:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
8010411e:	66 83 f8 ff          	cmp    $0xffff,%ax
80104122:	74 12                	je     80104136 <picinit+0x13d>
    picsetmask(irqmask);
80104124:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
8010412b:	0f b7 c0             	movzwl %ax,%eax
8010412e:	89 04 24             	mov    %eax,(%esp)
80104131:	e8 4a fe ff ff       	call   80103f80 <picsetmask>
}
80104136:	c9                   	leave  
80104137:	c3                   	ret    

80104138 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80104138:	55                   	push   %ebp
80104139:	89 e5                	mov    %esp,%ebp
8010413b:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
8010413e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80104145:	8b 45 0c             	mov    0xc(%ebp),%eax
80104148:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
8010414e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104151:	8b 10                	mov    (%eax),%edx
80104153:	8b 45 08             	mov    0x8(%ebp),%eax
80104156:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80104158:	e8 c0 ce ff ff       	call   8010101d <filealloc>
8010415d:	8b 55 08             	mov    0x8(%ebp),%edx
80104160:	89 02                	mov    %eax,(%edx)
80104162:	8b 45 08             	mov    0x8(%ebp),%eax
80104165:	8b 00                	mov    (%eax),%eax
80104167:	85 c0                	test   %eax,%eax
80104169:	0f 84 c8 00 00 00    	je     80104237 <pipealloc+0xff>
8010416f:	e8 a9 ce ff ff       	call   8010101d <filealloc>
80104174:	8b 55 0c             	mov    0xc(%ebp),%edx
80104177:	89 02                	mov    %eax,(%edx)
80104179:	8b 45 0c             	mov    0xc(%ebp),%eax
8010417c:	8b 00                	mov    (%eax),%eax
8010417e:	85 c0                	test   %eax,%eax
80104180:	0f 84 b1 00 00 00    	je     80104237 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80104186:	e8 69 eb ff ff       	call   80102cf4 <kalloc>
8010418b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010418e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104192:	75 05                	jne    80104199 <pipealloc+0x61>
    goto bad;
80104194:	e9 9e 00 00 00       	jmp    80104237 <pipealloc+0xff>
  p->readopen = 1;
80104199:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010419c:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
801041a3:	00 00 00 
  p->writeopen = 1;
801041a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041a9:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
801041b0:	00 00 00 
  p->nwrite = 0;
801041b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041b6:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
801041bd:	00 00 00 
  p->nread = 0;
801041c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041c3:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
801041ca:	00 00 00 
  initlock(&p->lock, "pipe");
801041cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041d0:	c7 44 24 04 5c 93 10 	movl   $0x8010935c,0x4(%esp)
801041d7:	80 
801041d8:	89 04 24             	mov    %eax,(%esp)
801041db:	e8 5b 18 00 00       	call   80105a3b <initlock>
  (*f0)->type = FD_PIPE;
801041e0:	8b 45 08             	mov    0x8(%ebp),%eax
801041e3:	8b 00                	mov    (%eax),%eax
801041e5:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
801041eb:	8b 45 08             	mov    0x8(%ebp),%eax
801041ee:	8b 00                	mov    (%eax),%eax
801041f0:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
801041f4:	8b 45 08             	mov    0x8(%ebp),%eax
801041f7:	8b 00                	mov    (%eax),%eax
801041f9:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
801041fd:	8b 45 08             	mov    0x8(%ebp),%eax
80104200:	8b 00                	mov    (%eax),%eax
80104202:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104205:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80104208:	8b 45 0c             	mov    0xc(%ebp),%eax
8010420b:	8b 00                	mov    (%eax),%eax
8010420d:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80104213:	8b 45 0c             	mov    0xc(%ebp),%eax
80104216:	8b 00                	mov    (%eax),%eax
80104218:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
8010421c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010421f:	8b 00                	mov    (%eax),%eax
80104221:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80104225:	8b 45 0c             	mov    0xc(%ebp),%eax
80104228:	8b 00                	mov    (%eax),%eax
8010422a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010422d:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80104230:	b8 00 00 00 00       	mov    $0x0,%eax
80104235:	eb 42                	jmp    80104279 <pipealloc+0x141>

//PAGEBREAK: 20
 bad:
  if(p)
80104237:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010423b:	74 0b                	je     80104248 <pipealloc+0x110>
    kfree((char*)p);
8010423d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104240:	89 04 24             	mov    %eax,(%esp)
80104243:	e8 13 ea ff ff       	call   80102c5b <kfree>
  if(*f0)
80104248:	8b 45 08             	mov    0x8(%ebp),%eax
8010424b:	8b 00                	mov    (%eax),%eax
8010424d:	85 c0                	test   %eax,%eax
8010424f:	74 0d                	je     8010425e <pipealloc+0x126>
    fileclose(*f0);
80104251:	8b 45 08             	mov    0x8(%ebp),%eax
80104254:	8b 00                	mov    (%eax),%eax
80104256:	89 04 24             	mov    %eax,(%esp)
80104259:	e8 67 ce ff ff       	call   801010c5 <fileclose>
  if(*f1)
8010425e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104261:	8b 00                	mov    (%eax),%eax
80104263:	85 c0                	test   %eax,%eax
80104265:	74 0d                	je     80104274 <pipealloc+0x13c>
    fileclose(*f1);
80104267:	8b 45 0c             	mov    0xc(%ebp),%eax
8010426a:	8b 00                	mov    (%eax),%eax
8010426c:	89 04 24             	mov    %eax,(%esp)
8010426f:	e8 51 ce ff ff       	call   801010c5 <fileclose>
  return -1;
80104274:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104279:	c9                   	leave  
8010427a:	c3                   	ret    

8010427b <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
8010427b:	55                   	push   %ebp
8010427c:	89 e5                	mov    %esp,%ebp
8010427e:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80104281:	8b 45 08             	mov    0x8(%ebp),%eax
80104284:	89 04 24             	mov    %eax,(%esp)
80104287:	e8 d0 17 00 00       	call   80105a5c <acquire>
  if(writable){
8010428c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104290:	74 1f                	je     801042b1 <pipeclose+0x36>
    p->writeopen = 0;
80104292:	8b 45 08             	mov    0x8(%ebp),%eax
80104295:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
8010429c:	00 00 00 
    wakeup(&p->nread);
8010429f:	8b 45 08             	mov    0x8(%ebp),%eax
801042a2:	05 34 02 00 00       	add    $0x234,%eax
801042a7:	89 04 24             	mov    %eax,(%esp)
801042aa:	e8 a0 0c 00 00       	call   80104f4f <wakeup>
801042af:	eb 1d                	jmp    801042ce <pipeclose+0x53>
  } else {
    p->readopen = 0;
801042b1:	8b 45 08             	mov    0x8(%ebp),%eax
801042b4:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
801042bb:	00 00 00 
    wakeup(&p->nwrite);
801042be:	8b 45 08             	mov    0x8(%ebp),%eax
801042c1:	05 38 02 00 00       	add    $0x238,%eax
801042c6:	89 04 24             	mov    %eax,(%esp)
801042c9:	e8 81 0c 00 00       	call   80104f4f <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
801042ce:	8b 45 08             	mov    0x8(%ebp),%eax
801042d1:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801042d7:	85 c0                	test   %eax,%eax
801042d9:	75 25                	jne    80104300 <pipeclose+0x85>
801042db:	8b 45 08             	mov    0x8(%ebp),%eax
801042de:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801042e4:	85 c0                	test   %eax,%eax
801042e6:	75 18                	jne    80104300 <pipeclose+0x85>
    release(&p->lock);
801042e8:	8b 45 08             	mov    0x8(%ebp),%eax
801042eb:	89 04 24             	mov    %eax,(%esp)
801042ee:	e8 cb 17 00 00       	call   80105abe <release>
    kfree((char*)p);
801042f3:	8b 45 08             	mov    0x8(%ebp),%eax
801042f6:	89 04 24             	mov    %eax,(%esp)
801042f9:	e8 5d e9 ff ff       	call   80102c5b <kfree>
801042fe:	eb 0b                	jmp    8010430b <pipeclose+0x90>
  } else
    release(&p->lock);
80104300:	8b 45 08             	mov    0x8(%ebp),%eax
80104303:	89 04 24             	mov    %eax,(%esp)
80104306:	e8 b3 17 00 00       	call   80105abe <release>
}
8010430b:	c9                   	leave  
8010430c:	c3                   	ret    

8010430d <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
8010430d:	55                   	push   %ebp
8010430e:	89 e5                	mov    %esp,%ebp
80104310:	83 ec 28             	sub    $0x28,%esp
  int i;

  acquire(&p->lock);
80104313:	8b 45 08             	mov    0x8(%ebp),%eax
80104316:	89 04 24             	mov    %eax,(%esp)
80104319:	e8 3e 17 00 00       	call   80105a5c <acquire>
  for(i = 0; i < n; i++){
8010431e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104325:	e9 a6 00 00 00       	jmp    801043d0 <pipewrite+0xc3>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
8010432a:	eb 57                	jmp    80104383 <pipewrite+0x76>
      if(p->readopen == 0 || proc->killed){
8010432c:	8b 45 08             	mov    0x8(%ebp),%eax
8010432f:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104335:	85 c0                	test   %eax,%eax
80104337:	74 0d                	je     80104346 <pipewrite+0x39>
80104339:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010433f:	8b 40 24             	mov    0x24(%eax),%eax
80104342:	85 c0                	test   %eax,%eax
80104344:	74 15                	je     8010435b <pipewrite+0x4e>
        release(&p->lock);
80104346:	8b 45 08             	mov    0x8(%ebp),%eax
80104349:	89 04 24             	mov    %eax,(%esp)
8010434c:	e8 6d 17 00 00       	call   80105abe <release>
        return -1;
80104351:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104356:	e9 9f 00 00 00       	jmp    801043fa <pipewrite+0xed>
      }
      wakeup(&p->nread);
8010435b:	8b 45 08             	mov    0x8(%ebp),%eax
8010435e:	05 34 02 00 00       	add    $0x234,%eax
80104363:	89 04 24             	mov    %eax,(%esp)
80104366:	e8 e4 0b 00 00       	call   80104f4f <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
8010436b:	8b 45 08             	mov    0x8(%ebp),%eax
8010436e:	8b 55 08             	mov    0x8(%ebp),%edx
80104371:	81 c2 38 02 00 00    	add    $0x238,%edx
80104377:	89 44 24 04          	mov    %eax,0x4(%esp)
8010437b:	89 14 24             	mov    %edx,(%esp)
8010437e:	e8 f0 0a 00 00       	call   80104e73 <sleep>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104383:	8b 45 08             	mov    0x8(%ebp),%eax
80104386:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
8010438c:	8b 45 08             	mov    0x8(%ebp),%eax
8010438f:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104395:	05 00 02 00 00       	add    $0x200,%eax
8010439a:	39 c2                	cmp    %eax,%edx
8010439c:	74 8e                	je     8010432c <pipewrite+0x1f>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
8010439e:	8b 45 08             	mov    0x8(%ebp),%eax
801043a1:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801043a7:	8d 48 01             	lea    0x1(%eax),%ecx
801043aa:	8b 55 08             	mov    0x8(%ebp),%edx
801043ad:	89 8a 38 02 00 00    	mov    %ecx,0x238(%edx)
801043b3:	25 ff 01 00 00       	and    $0x1ff,%eax
801043b8:	89 c1                	mov    %eax,%ecx
801043ba:	8b 55 f4             	mov    -0xc(%ebp),%edx
801043bd:	8b 45 0c             	mov    0xc(%ebp),%eax
801043c0:	01 d0                	add    %edx,%eax
801043c2:	0f b6 10             	movzbl (%eax),%edx
801043c5:	8b 45 08             	mov    0x8(%ebp),%eax
801043c8:	88 54 08 34          	mov    %dl,0x34(%eax,%ecx,1)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
801043cc:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801043d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043d3:	3b 45 10             	cmp    0x10(%ebp),%eax
801043d6:	0f 8c 4e ff ff ff    	jl     8010432a <pipewrite+0x1d>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
801043dc:	8b 45 08             	mov    0x8(%ebp),%eax
801043df:	05 34 02 00 00       	add    $0x234,%eax
801043e4:	89 04 24             	mov    %eax,(%esp)
801043e7:	e8 63 0b 00 00       	call   80104f4f <wakeup>
  release(&p->lock);
801043ec:	8b 45 08             	mov    0x8(%ebp),%eax
801043ef:	89 04 24             	mov    %eax,(%esp)
801043f2:	e8 c7 16 00 00       	call   80105abe <release>
  return n;
801043f7:	8b 45 10             	mov    0x10(%ebp),%eax
}
801043fa:	c9                   	leave  
801043fb:	c3                   	ret    

801043fc <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
801043fc:	55                   	push   %ebp
801043fd:	89 e5                	mov    %esp,%ebp
801043ff:	53                   	push   %ebx
80104400:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104403:	8b 45 08             	mov    0x8(%ebp),%eax
80104406:	89 04 24             	mov    %eax,(%esp)
80104409:	e8 4e 16 00 00       	call   80105a5c <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010440e:	eb 3a                	jmp    8010444a <piperead+0x4e>
    if(proc->killed){
80104410:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104416:	8b 40 24             	mov    0x24(%eax),%eax
80104419:	85 c0                	test   %eax,%eax
8010441b:	74 15                	je     80104432 <piperead+0x36>
      release(&p->lock);
8010441d:	8b 45 08             	mov    0x8(%ebp),%eax
80104420:	89 04 24             	mov    %eax,(%esp)
80104423:	e8 96 16 00 00       	call   80105abe <release>
      return -1;
80104428:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010442d:	e9 b5 00 00 00       	jmp    801044e7 <piperead+0xeb>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80104432:	8b 45 08             	mov    0x8(%ebp),%eax
80104435:	8b 55 08             	mov    0x8(%ebp),%edx
80104438:	81 c2 34 02 00 00    	add    $0x234,%edx
8010443e:	89 44 24 04          	mov    %eax,0x4(%esp)
80104442:	89 14 24             	mov    %edx,(%esp)
80104445:	e8 29 0a 00 00       	call   80104e73 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010444a:	8b 45 08             	mov    0x8(%ebp),%eax
8010444d:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104453:	8b 45 08             	mov    0x8(%ebp),%eax
80104456:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
8010445c:	39 c2                	cmp    %eax,%edx
8010445e:	75 0d                	jne    8010446d <piperead+0x71>
80104460:	8b 45 08             	mov    0x8(%ebp),%eax
80104463:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104469:	85 c0                	test   %eax,%eax
8010446b:	75 a3                	jne    80104410 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010446d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104474:	eb 4b                	jmp    801044c1 <piperead+0xc5>
    if(p->nread == p->nwrite)
80104476:	8b 45 08             	mov    0x8(%ebp),%eax
80104479:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
8010447f:	8b 45 08             	mov    0x8(%ebp),%eax
80104482:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104488:	39 c2                	cmp    %eax,%edx
8010448a:	75 02                	jne    8010448e <piperead+0x92>
      break;
8010448c:	eb 3b                	jmp    801044c9 <piperead+0xcd>
    addr[i] = p->data[p->nread++ % PIPESIZE];
8010448e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104491:	8b 45 0c             	mov    0xc(%ebp),%eax
80104494:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80104497:	8b 45 08             	mov    0x8(%ebp),%eax
8010449a:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801044a0:	8d 48 01             	lea    0x1(%eax),%ecx
801044a3:	8b 55 08             	mov    0x8(%ebp),%edx
801044a6:	89 8a 34 02 00 00    	mov    %ecx,0x234(%edx)
801044ac:	25 ff 01 00 00       	and    $0x1ff,%eax
801044b1:	89 c2                	mov    %eax,%edx
801044b3:	8b 45 08             	mov    0x8(%ebp),%eax
801044b6:	0f b6 44 10 34       	movzbl 0x34(%eax,%edx,1),%eax
801044bb:	88 03                	mov    %al,(%ebx)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801044bd:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801044c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044c4:	3b 45 10             	cmp    0x10(%ebp),%eax
801044c7:	7c ad                	jl     80104476 <piperead+0x7a>
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
801044c9:	8b 45 08             	mov    0x8(%ebp),%eax
801044cc:	05 38 02 00 00       	add    $0x238,%eax
801044d1:	89 04 24             	mov    %eax,(%esp)
801044d4:	e8 76 0a 00 00       	call   80104f4f <wakeup>
  release(&p->lock);
801044d9:	8b 45 08             	mov    0x8(%ebp),%eax
801044dc:	89 04 24             	mov    %eax,(%esp)
801044df:	e8 da 15 00 00       	call   80105abe <release>
  return i;
801044e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801044e7:	83 c4 24             	add    $0x24,%esp
801044ea:	5b                   	pop    %ebx
801044eb:	5d                   	pop    %ebp
801044ec:	c3                   	ret    

801044ed <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801044ed:	55                   	push   %ebp
801044ee:	89 e5                	mov    %esp,%ebp
801044f0:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801044f3:	9c                   	pushf  
801044f4:	58                   	pop    %eax
801044f5:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
801044f8:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801044fb:	c9                   	leave  
801044fc:	c3                   	ret    

801044fd <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
801044fd:	55                   	push   %ebp
801044fe:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104500:	fb                   	sti    
}
80104501:	5d                   	pop    %ebp
80104502:	c3                   	ret    

80104503 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
80104503:	55                   	push   %ebp
80104504:	89 e5                	mov    %esp,%ebp
80104506:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104509:	c7 44 24 04 61 93 10 	movl   $0x80109361,0x4(%esp)
80104510:	80 
80104511:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104518:	e8 1e 15 00 00       	call   80105a3b <initlock>
}
8010451d:	c9                   	leave  
8010451e:	c3                   	ret    

8010451f <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
8010451f:	55                   	push   %ebp
80104520:	89 e5                	mov    %esp,%ebp
80104522:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104525:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
8010452c:	e8 2b 15 00 00       	call   80105a5c <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104531:	c7 45 f4 d4 39 11 80 	movl   $0x801139d4,-0xc(%ebp)
80104538:	eb 53                	jmp    8010458d <allocproc+0x6e>
    if(p->state == UNUSED)
8010453a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010453d:	8b 40 0c             	mov    0xc(%eax),%eax
80104540:	85 c0                	test   %eax,%eax
80104542:	75 42                	jne    80104586 <allocproc+0x67>
      goto found;
80104544:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
80104545:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104548:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
8010454f:	a1 04 c0 10 80       	mov    0x8010c004,%eax
80104554:	8d 50 01             	lea    0x1(%eax),%edx
80104557:	89 15 04 c0 10 80    	mov    %edx,0x8010c004
8010455d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104560:	89 42 10             	mov    %eax,0x10(%edx)
  release(&ptable.lock);
80104563:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
8010456a:	e8 4f 15 00 00       	call   80105abe <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
8010456f:	e8 80 e7 ff ff       	call   80102cf4 <kalloc>
80104574:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104577:	89 42 08             	mov    %eax,0x8(%edx)
8010457a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010457d:	8b 40 08             	mov    0x8(%eax),%eax
80104580:	85 c0                	test   %eax,%eax
80104582:	75 36                	jne    801045ba <allocproc+0x9b>
80104584:	eb 23                	jmp    801045a9 <allocproc+0x8a>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104586:	81 45 f4 cc 04 00 00 	addl   $0x4cc,-0xc(%ebp)
8010458d:	81 7d f4 d4 6c 12 80 	cmpl   $0x80126cd4,-0xc(%ebp)
80104594:	72 a4                	jb     8010453a <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
80104596:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
8010459d:	e8 1c 15 00 00       	call   80105abe <release>
  return 0;
801045a2:	b8 00 00 00 00       	mov    $0x0,%eax
801045a7:	eb 76                	jmp    8010461f <allocproc+0x100>
  p->pid = nextpid++;
  release(&ptable.lock);

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
    p->state = UNUSED;
801045a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045ac:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
801045b3:	b8 00 00 00 00       	mov    $0x0,%eax
801045b8:	eb 65                	jmp    8010461f <allocproc+0x100>
  }
  sp = p->kstack + KSTACKSIZE;
801045ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045bd:	8b 40 08             	mov    0x8(%eax),%eax
801045c0:	05 00 10 00 00       	add    $0x1000,%eax
801045c5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
801045c8:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
801045cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045cf:	8b 55 f0             	mov    -0x10(%ebp),%edx
801045d2:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
801045d5:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
801045d9:	ba 2a 71 10 80       	mov    $0x8010712a,%edx
801045de:	8b 45 f0             	mov    -0x10(%ebp),%eax
801045e1:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
801045e3:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
801045e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045ea:	8b 55 f0             	mov    -0x10(%ebp),%edx
801045ed:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
801045f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045f3:	8b 40 1c             	mov    0x1c(%eax),%eax
801045f6:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801045fd:	00 
801045fe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104605:	00 
80104606:	89 04 24             	mov    %eax,(%esp)
80104609:	e8 a2 16 00 00       	call   80105cb0 <memset>
  p->context->eip = (uint)forkret;
8010460e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104611:	8b 40 1c             	mov    0x1c(%eax),%eax
80104614:	ba 47 4e 10 80       	mov    $0x80104e47,%edx
80104619:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
8010461c:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010461f:	c9                   	leave  
80104620:	c3                   	ret    

80104621 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
80104621:	55                   	push   %ebp
80104622:	89 e5                	mov    %esp,%ebp
80104624:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int i;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104627:	e8 f3 fe ff ff       	call   8010451f <allocproc>
8010462c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  initproc = p;
8010462f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104632:	a3 48 c6 10 80       	mov    %eax,0x8010c648
  if((p->pgdir = setupkvm()) == 0)
80104637:	e8 e2 41 00 00       	call   8010881e <setupkvm>
8010463c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010463f:	89 42 04             	mov    %eax,0x4(%edx)
80104642:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104645:	8b 40 04             	mov    0x4(%eax),%eax
80104648:	85 c0                	test   %eax,%eax
8010464a:	75 0c                	jne    80104658 <userinit+0x37>
    panic("userinit: out of memory?");
8010464c:	c7 04 24 68 93 10 80 	movl   $0x80109368,(%esp)
80104653:	e8 e2 be ff ff       	call   8010053a <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104658:	ba 2c 00 00 00       	mov    $0x2c,%edx
8010465d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104660:	8b 40 04             	mov    0x4(%eax),%eax
80104663:	89 54 24 08          	mov    %edx,0x8(%esp)
80104667:	c7 44 24 04 e0 c4 10 	movl   $0x8010c4e0,0x4(%esp)
8010466e:	80 
8010466f:	89 04 24             	mov    %eax,(%esp)
80104672:	e8 ff 43 00 00       	call   80108a76 <inituvm>
  p->sz = PGSIZE;
80104677:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010467a:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80104680:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104683:	8b 40 18             	mov    0x18(%eax),%eax
80104686:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
8010468d:	00 
8010468e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104695:	00 
80104696:	89 04 24             	mov    %eax,(%esp)
80104699:	e8 12 16 00 00       	call   80105cb0 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
8010469e:	8b 45 f0             	mov    -0x10(%ebp),%eax
801046a1:	8b 40 18             	mov    0x18(%eax),%eax
801046a4:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801046aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801046ad:	8b 40 18             	mov    0x18(%eax),%eax
801046b0:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
801046b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801046b9:	8b 40 18             	mov    0x18(%eax),%eax
801046bc:	8b 55 f0             	mov    -0x10(%ebp),%edx
801046bf:	8b 52 18             	mov    0x18(%edx),%edx
801046c2:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801046c6:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801046ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
801046cd:	8b 40 18             	mov    0x18(%eax),%eax
801046d0:	8b 55 f0             	mov    -0x10(%ebp),%edx
801046d3:	8b 52 18             	mov    0x18(%edx),%edx
801046d6:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801046da:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801046de:	8b 45 f0             	mov    -0x10(%ebp),%eax
801046e1:	8b 40 18             	mov    0x18(%eax),%eax
801046e4:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801046eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801046ee:	8b 40 18             	mov    0x18(%eax),%eax
801046f1:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801046f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801046fb:	8b 40 18             	mov    0x18(%eax),%eax
801046fe:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104705:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104708:	83 c0 28             	add    $0x28,%eax
8010470b:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104712:	00 
80104713:	c7 44 24 04 81 93 10 	movl   $0x80109381,0x4(%esp)
8010471a:	80 
8010471b:	89 04 24             	mov    %eax,(%esp)
8010471e:	e8 ad 17 00 00       	call   80105ed0 <safestrcpy>
  p->cwd = namei("/");
80104723:	c7 04 24 8a 93 10 80 	movl   $0x8010938a,(%esp)
8010472a:	e8 e9 de ff ff       	call   80102618 <namei>
8010472f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104732:	89 42 78             	mov    %eax,0x78(%edx)
  p->exe=0;
80104735:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104738:	c7 40 7c 00 00 00 00 	movl   $0x0,0x7c(%eax)

  p->cmdline[0]= '\0';
8010473f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104742:	c6 80 80 00 00 00 00 	movb   $0x0,0x80(%eax)
  for (i=0; i < MAXARGS; i++)
80104749:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104750:	eb 18                	jmp    8010476a <userinit+0x149>
      p->args[i][0]='\0';
80104752:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104755:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104758:	6b c0 64             	imul   $0x64,%eax,%eax
8010475b:	01 d0                	add    %edx,%eax
8010475d:	05 e0 00 00 00       	add    $0xe0,%eax
80104762:	c6 40 04 00          	movb   $0x0,0x4(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");
  p->exe=0;

  p->cmdline[0]= '\0';
  for (i=0; i < MAXARGS; i++)
80104766:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010476a:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
8010476e:	7e e2                	jle    80104752 <userinit+0x131>
      p->args[i][0]='\0';

  p->state = RUNNABLE;
80104770:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104773:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
8010477a:	c9                   	leave  
8010477b:	c3                   	ret    

8010477c <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
8010477c:	55                   	push   %ebp
8010477d:	89 e5                	mov    %esp,%ebp
8010477f:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
80104782:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104788:	8b 00                	mov    (%eax),%eax
8010478a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
8010478d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104791:	7e 34                	jle    801047c7 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
80104793:	8b 55 08             	mov    0x8(%ebp),%edx
80104796:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104799:	01 c2                	add    %eax,%edx
8010479b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047a1:	8b 40 04             	mov    0x4(%eax),%eax
801047a4:	89 54 24 08          	mov    %edx,0x8(%esp)
801047a8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801047ab:	89 54 24 04          	mov    %edx,0x4(%esp)
801047af:	89 04 24             	mov    %eax,(%esp)
801047b2:	e8 35 44 00 00       	call   80108bec <allocuvm>
801047b7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801047ba:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801047be:	75 41                	jne    80104801 <growproc+0x85>
      return -1;
801047c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047c5:	eb 58                	jmp    8010481f <growproc+0xa3>
  } else if(n < 0){
801047c7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801047cb:	79 34                	jns    80104801 <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
801047cd:	8b 55 08             	mov    0x8(%ebp),%edx
801047d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047d3:	01 c2                	add    %eax,%edx
801047d5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047db:	8b 40 04             	mov    0x4(%eax),%eax
801047de:	89 54 24 08          	mov    %edx,0x8(%esp)
801047e2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801047e5:	89 54 24 04          	mov    %edx,0x4(%esp)
801047e9:	89 04 24             	mov    %eax,(%esp)
801047ec:	e8 d5 44 00 00       	call   80108cc6 <deallocuvm>
801047f1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801047f4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801047f8:	75 07                	jne    80104801 <growproc+0x85>
      return -1;
801047fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047ff:	eb 1e                	jmp    8010481f <growproc+0xa3>
  }
  proc->sz = sz;
80104801:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104807:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010480a:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
8010480c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104812:	89 04 24             	mov    %eax,(%esp)
80104815:	e8 f5 40 00 00       	call   8010890f <switchuvm>
  return 0;
8010481a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010481f:	c9                   	leave  
80104820:	c3                   	ret    

80104821 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80104821:	55                   	push   %ebp
80104822:	89 e5                	mov    %esp,%ebp
80104824:	57                   	push   %edi
80104825:	56                   	push   %esi
80104826:	53                   	push   %ebx
80104827:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
8010482a:	e8 f0 fc ff ff       	call   8010451f <allocproc>
8010482f:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104832:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104836:	75 0a                	jne    80104842 <fork+0x21>
    return -1;
80104838:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010483d:	e9 47 02 00 00       	jmp    80104a89 <fork+0x268>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
80104842:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104848:	8b 10                	mov    (%eax),%edx
8010484a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104850:	8b 40 04             	mov    0x4(%eax),%eax
80104853:	89 54 24 04          	mov    %edx,0x4(%esp)
80104857:	89 04 24             	mov    %eax,(%esp)
8010485a:	e8 03 46 00 00       	call   80108e62 <copyuvm>
8010485f:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104862:	89 42 04             	mov    %eax,0x4(%edx)
80104865:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104868:	8b 40 04             	mov    0x4(%eax),%eax
8010486b:	85 c0                	test   %eax,%eax
8010486d:	75 2c                	jne    8010489b <fork+0x7a>
    kfree(np->kstack);
8010486f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104872:	8b 40 08             	mov    0x8(%eax),%eax
80104875:	89 04 24             	mov    %eax,(%esp)
80104878:	e8 de e3 ff ff       	call   80102c5b <kfree>
    np->kstack = 0;
8010487d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104880:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104887:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010488a:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80104891:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104896:	e9 ee 01 00 00       	jmp    80104a89 <fork+0x268>
  }
  np->sz = proc->sz;
8010489b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048a1:	8b 10                	mov    (%eax),%edx
801048a3:	8b 45 e0             	mov    -0x20(%ebp),%eax
801048a6:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
801048a8:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801048af:	8b 45 e0             	mov    -0x20(%ebp),%eax
801048b2:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
801048b5:	8b 45 e0             	mov    -0x20(%ebp),%eax
801048b8:	8b 50 18             	mov    0x18(%eax),%edx
801048bb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048c1:	8b 40 18             	mov    0x18(%eax),%eax
801048c4:	89 c3                	mov    %eax,%ebx
801048c6:	b8 13 00 00 00       	mov    $0x13,%eax
801048cb:	89 d7                	mov    %edx,%edi
801048cd:	89 de                	mov    %ebx,%esi
801048cf:	89 c1                	mov    %eax,%ecx
801048d1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
801048d3:	8b 45 e0             	mov    -0x20(%ebp),%eax
801048d6:	8b 40 18             	mov    0x18(%eax),%eax
801048d9:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
801048e0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801048e7:	eb 3d                	jmp    80104926 <fork+0x105>
    if(proc->ofile[i])
801048e9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048ef:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801048f2:	83 c2 0c             	add    $0xc,%edx
801048f5:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801048f9:	85 c0                	test   %eax,%eax
801048fb:	74 25                	je     80104922 <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
801048fd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104903:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104906:	83 c2 0c             	add    $0xc,%edx
80104909:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010490d:	89 04 24             	mov    %eax,(%esp)
80104910:	e8 68 c7 ff ff       	call   8010107d <filedup>
80104915:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104918:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
8010491b:	83 c1 0c             	add    $0xc,%ecx
8010491e:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80104922:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104926:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
8010492a:	7e bd                	jle    801048e9 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
8010492c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104932:	8b 40 78             	mov    0x78(%eax),%eax
80104935:	89 04 24             	mov    %eax,(%esp)
80104938:	e8 e3 cf ff ff       	call   80101920 <idup>
8010493d:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104940:	89 42 78             	mov    %eax,0x78(%edx)

  safestrcpy(np->name, proc->name, sizeof(proc->name));
80104943:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104949:	8d 50 28             	lea    0x28(%eax),%edx
8010494c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010494f:	83 c0 28             	add    $0x28,%eax
80104952:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104959:	00 
8010495a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010495e:	89 04 24             	mov    %eax,(%esp)
80104961:	e8 6a 15 00 00       	call   80105ed0 <safestrcpy>
 
  pid = np->pid;
80104966:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104969:	8b 40 10             	mov    0x10(%eax),%eax
8010496c:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
8010496f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104972:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)

  np->exe = proc->exe;
80104979:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010497f:	8b 50 7c             	mov    0x7c(%eax),%edx
80104982:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104985:	89 50 7c             	mov    %edx,0x7c(%eax)

  safestrcpy(np->cmdline, proc->cmdline, strlen(proc->cmdline));
80104988:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010498e:	83 e8 80             	sub    $0xffffff80,%eax
80104991:	89 04 24             	mov    %eax,(%esp)
80104994:	e8 81 15 00 00       	call   80105f1a <strlen>
80104999:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801049a0:	8d 8a 80 00 00 00    	lea    0x80(%edx),%ecx
801049a6:	8b 55 e0             	mov    -0x20(%ebp),%edx
801049a9:	83 ea 80             	sub    $0xffffff80,%edx
801049ac:	89 44 24 08          	mov    %eax,0x8(%esp)
801049b0:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801049b4:	89 14 24             	mov    %edx,(%esp)
801049b7:	e8 14 15 00 00       	call   80105ed0 <safestrcpy>

  for (i=0; i < MAXARGS; i++)  {
801049bc:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801049c3:	e9 92 00 00 00       	jmp    80104a5a <fork+0x239>
  	  if (proc->args[i])
801049c8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049ce:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801049d1:	6b d2 64             	imul   $0x64,%edx,%edx
801049d4:	81 c2 e0 00 00 00    	add    $0xe0,%edx
801049da:	01 d0                	add    %edx,%eax
801049dc:	83 c0 04             	add    $0x4,%eax
801049df:	85 c0                	test   %eax,%eax
801049e1:	74 5f                	je     80104a42 <fork+0x221>
  		  safestrcpy(np->args[i], proc->args[i], strlen(proc->args[i])+1);
801049e3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049e9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801049ec:	6b d2 64             	imul   $0x64,%edx,%edx
801049ef:	81 c2 e0 00 00 00    	add    $0xe0,%edx
801049f5:	01 d0                	add    %edx,%eax
801049f7:	83 c0 04             	add    $0x4,%eax
801049fa:	89 04 24             	mov    %eax,(%esp)
801049fd:	e8 18 15 00 00       	call   80105f1a <strlen>
80104a02:	8d 48 01             	lea    0x1(%eax),%ecx
80104a05:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a0b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104a0e:	6b d2 64             	imul   $0x64,%edx,%edx
80104a11:	81 c2 e0 00 00 00    	add    $0xe0,%edx
80104a17:	01 d0                	add    %edx,%eax
80104a19:	8d 50 04             	lea    0x4(%eax),%edx
80104a1c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104a1f:	6b c0 64             	imul   $0x64,%eax,%eax
80104a22:	8d 98 e0 00 00 00    	lea    0xe0(%eax),%ebx
80104a28:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104a2b:	01 d8                	add    %ebx,%eax
80104a2d:	83 c0 04             	add    $0x4,%eax
80104a30:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80104a34:	89 54 24 04          	mov    %edx,0x4(%esp)
80104a38:	89 04 24             	mov    %eax,(%esp)
80104a3b:	e8 90 14 00 00       	call   80105ed0 <safestrcpy>
80104a40:	eb 14                	jmp    80104a56 <fork+0x235>
  	  else np->args[i][0]='\0';
80104a42:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104a45:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104a48:	6b c0 64             	imul   $0x64,%eax,%eax
80104a4b:	01 d0                	add    %edx,%eax
80104a4d:	05 e0 00 00 00       	add    $0xe0,%eax
80104a52:	c6 40 04 00          	movb   $0x0,0x4(%eax)

  np->exe = proc->exe;

  safestrcpy(np->cmdline, proc->cmdline, strlen(proc->cmdline));

  for (i=0; i < MAXARGS; i++)  {
80104a56:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104a5a:	83 7d e4 09          	cmpl   $0x9,-0x1c(%ebp)
80104a5e:	0f 8e 64 ff ff ff    	jle    801049c8 <fork+0x1a7>
  		  safestrcpy(np->args[i], proc->args[i], strlen(proc->args[i])+1);
  	  else np->args[i][0]='\0';
  }

  // lock to force the compiler to emit the np->state write last.
  acquire(&ptable.lock);
80104a64:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104a6b:	e8 ec 0f 00 00       	call   80105a5c <acquire>
  np->state = RUNNABLE;
80104a70:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104a73:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)

  release(&ptable.lock);
80104a7a:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104a81:	e8 38 10 00 00       	call   80105abe <release>
  
  return pid;
80104a86:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
80104a89:	83 c4 2c             	add    $0x2c,%esp
80104a8c:	5b                   	pop    %ebx
80104a8d:	5e                   	pop    %esi
80104a8e:	5f                   	pop    %edi
80104a8f:	5d                   	pop    %ebp
80104a90:	c3                   	ret    

80104a91 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80104a91:	55                   	push   %ebp
80104a92:	89 e5                	mov    %esp,%ebp
80104a94:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
80104a97:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104a9e:	a1 48 c6 10 80       	mov    0x8010c648,%eax
80104aa3:	39 c2                	cmp    %eax,%edx
80104aa5:	75 0c                	jne    80104ab3 <exit+0x22>
    panic("init exiting");
80104aa7:	c7 04 24 8c 93 10 80 	movl   $0x8010938c,(%esp)
80104aae:	e8 87 ba ff ff       	call   8010053a <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104ab3:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104aba:	eb 44                	jmp    80104b00 <exit+0x6f>
    if(proc->ofile[fd]){
80104abc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ac2:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104ac5:	83 c2 0c             	add    $0xc,%edx
80104ac8:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104acc:	85 c0                	test   %eax,%eax
80104ace:	74 2c                	je     80104afc <exit+0x6b>
      fileclose(proc->ofile[fd]);
80104ad0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ad6:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104ad9:	83 c2 0c             	add    $0xc,%edx
80104adc:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104ae0:	89 04 24             	mov    %eax,(%esp)
80104ae3:	e8 dd c5 ff ff       	call   801010c5 <fileclose>
      proc->ofile[fd] = 0;
80104ae8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104aee:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104af1:	83 c2 0c             	add    $0xc,%edx
80104af4:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104afb:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104afc:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104b00:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104b04:	7e b6                	jle    80104abc <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  begin_op();
80104b06:	e8 17 eb ff ff       	call   80103622 <begin_op>
  iput(proc->cwd);
80104b0b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b11:	8b 40 78             	mov    0x78(%eax),%eax
80104b14:	89 04 24             	mov    %eax,(%esp)
80104b17:	e8 e9 cf ff ff       	call   80101b05 <iput>
  end_op();
80104b1c:	e8 85 eb ff ff       	call   801036a6 <end_op>
  proc->cwd = 0;
80104b21:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b27:	c7 40 78 00 00 00 00 	movl   $0x0,0x78(%eax)

  acquire(&ptable.lock);
80104b2e:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104b35:	e8 22 0f 00 00       	call   80105a5c <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
80104b3a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b40:	8b 40 14             	mov    0x14(%eax),%eax
80104b43:	89 04 24             	mov    %eax,(%esp)
80104b46:	e8 c3 03 00 00       	call   80104f0e <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b4b:	c7 45 f4 d4 39 11 80 	movl   $0x801139d4,-0xc(%ebp)
80104b52:	eb 3b                	jmp    80104b8f <exit+0xfe>
    if(p->parent == proc){
80104b54:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b57:	8b 50 14             	mov    0x14(%eax),%edx
80104b5a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b60:	39 c2                	cmp    %eax,%edx
80104b62:	75 24                	jne    80104b88 <exit+0xf7>
      p->parent = initproc;
80104b64:	8b 15 48 c6 10 80    	mov    0x8010c648,%edx
80104b6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b6d:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
80104b70:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b73:	8b 40 0c             	mov    0xc(%eax),%eax
80104b76:	83 f8 05             	cmp    $0x5,%eax
80104b79:	75 0d                	jne    80104b88 <exit+0xf7>
        wakeup1(initproc);
80104b7b:	a1 48 c6 10 80       	mov    0x8010c648,%eax
80104b80:	89 04 24             	mov    %eax,(%esp)
80104b83:	e8 86 03 00 00       	call   80104f0e <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b88:	81 45 f4 cc 04 00 00 	addl   $0x4cc,-0xc(%ebp)
80104b8f:	81 7d f4 d4 6c 12 80 	cmpl   $0x80126cd4,-0xc(%ebp)
80104b96:	72 bc                	jb     80104b54 <exit+0xc3>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
80104b98:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b9e:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80104ba5:	e8 b9 01 00 00       	call   80104d63 <sched>
  panic("zombie exit");
80104baa:	c7 04 24 99 93 10 80 	movl   $0x80109399,(%esp)
80104bb1:	e8 84 b9 ff ff       	call   8010053a <panic>

80104bb6 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
80104bb6:	55                   	push   %ebp
80104bb7:	89 e5                	mov    %esp,%ebp
80104bb9:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
80104bbc:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104bc3:	e8 94 0e 00 00       	call   80105a5c <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
80104bc8:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104bcf:	c7 45 f4 d4 39 11 80 	movl   $0x801139d4,-0xc(%ebp)
80104bd6:	e9 9d 00 00 00       	jmp    80104c78 <wait+0xc2>
      if(p->parent != proc)
80104bdb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bde:	8b 50 14             	mov    0x14(%eax),%edx
80104be1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104be7:	39 c2                	cmp    %eax,%edx
80104be9:	74 05                	je     80104bf0 <wait+0x3a>
        continue;
80104beb:	e9 81 00 00 00       	jmp    80104c71 <wait+0xbb>
      havekids = 1;
80104bf0:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80104bf7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bfa:	8b 40 0c             	mov    0xc(%eax),%eax
80104bfd:	83 f8 05             	cmp    $0x5,%eax
80104c00:	75 6f                	jne    80104c71 <wait+0xbb>
        // Found one.
        pid = p->pid;
80104c02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c05:	8b 40 10             	mov    0x10(%eax),%eax
80104c08:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80104c0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c0e:	8b 40 08             	mov    0x8(%eax),%eax
80104c11:	89 04 24             	mov    %eax,(%esp)
80104c14:	e8 42 e0 ff ff       	call   80102c5b <kfree>
        p->kstack = 0;
80104c19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c1c:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80104c23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c26:	8b 40 04             	mov    0x4(%eax),%eax
80104c29:	89 04 24             	mov    %eax,(%esp)
80104c2c:	e8 51 41 00 00       	call   80108d82 <freevm>
        p->state = UNUSED;
80104c31:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c34:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80104c3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c3e:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80104c45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c48:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80104c4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c52:	c6 40 28 00          	movb   $0x0,0x28(%eax)
        p->killed = 0;
80104c56:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c59:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
80104c60:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104c67:	e8 52 0e 00 00       	call   80105abe <release>
        return pid;
80104c6c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104c6f:	eb 55                	jmp    80104cc6 <wait+0x110>

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104c71:	81 45 f4 cc 04 00 00 	addl   $0x4cc,-0xc(%ebp)
80104c78:	81 7d f4 d4 6c 12 80 	cmpl   $0x80126cd4,-0xc(%ebp)
80104c7f:	0f 82 56 ff ff ff    	jb     80104bdb <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80104c85:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104c89:	74 0d                	je     80104c98 <wait+0xe2>
80104c8b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c91:	8b 40 24             	mov    0x24(%eax),%eax
80104c94:	85 c0                	test   %eax,%eax
80104c96:	74 13                	je     80104cab <wait+0xf5>
      release(&ptable.lock);
80104c98:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104c9f:	e8 1a 0e 00 00       	call   80105abe <release>
      return -1;
80104ca4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ca9:	eb 1b                	jmp    80104cc6 <wait+0x110>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80104cab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cb1:	c7 44 24 04 a0 39 11 	movl   $0x801139a0,0x4(%esp)
80104cb8:	80 
80104cb9:	89 04 24             	mov    %eax,(%esp)
80104cbc:	e8 b2 01 00 00       	call   80104e73 <sleep>
  }
80104cc1:	e9 02 ff ff ff       	jmp    80104bc8 <wait+0x12>
}
80104cc6:	c9                   	leave  
80104cc7:	c3                   	ret    

80104cc8 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80104cc8:	55                   	push   %ebp
80104cc9:	89 e5                	mov    %esp,%ebp
80104ccb:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
80104cce:	e8 2a f8 ff ff       	call   801044fd <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80104cd3:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104cda:	e8 7d 0d 00 00       	call   80105a5c <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104cdf:	c7 45 f4 d4 39 11 80 	movl   $0x801139d4,-0xc(%ebp)
80104ce6:	eb 61                	jmp    80104d49 <scheduler+0x81>
      if(p->state != RUNNABLE)
80104ce8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ceb:	8b 40 0c             	mov    0xc(%eax),%eax
80104cee:	83 f8 03             	cmp    $0x3,%eax
80104cf1:	74 02                	je     80104cf5 <scheduler+0x2d>
        continue;
80104cf3:	eb 4d                	jmp    80104d42 <scheduler+0x7a>

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
80104cf5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cf8:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80104cfe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d01:	89 04 24             	mov    %eax,(%esp)
80104d04:	e8 06 3c 00 00       	call   8010890f <switchuvm>
      p->state = RUNNING;
80104d09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d0c:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80104d13:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d19:	8b 40 1c             	mov    0x1c(%eax),%eax
80104d1c:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104d23:	83 c2 04             	add    $0x4,%edx
80104d26:	89 44 24 04          	mov    %eax,0x4(%esp)
80104d2a:	89 14 24             	mov    %edx,(%esp)
80104d2d:	e8 0f 12 00 00       	call   80105f41 <swtch>
      switchkvm();
80104d32:	e8 bb 3b 00 00       	call   801088f2 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80104d37:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80104d3e:	00 00 00 00 
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104d42:	81 45 f4 cc 04 00 00 	addl   $0x4cc,-0xc(%ebp)
80104d49:	81 7d f4 d4 6c 12 80 	cmpl   $0x80126cd4,-0xc(%ebp)
80104d50:	72 96                	jb     80104ce8 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80104d52:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104d59:	e8 60 0d 00 00       	call   80105abe <release>

  }
80104d5e:	e9 6b ff ff ff       	jmp    80104cce <scheduler+0x6>

80104d63 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80104d63:	55                   	push   %ebp
80104d64:	89 e5                	mov    %esp,%ebp
80104d66:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80104d69:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104d70:	e8 11 0e 00 00       	call   80105b86 <holding>
80104d75:	85 c0                	test   %eax,%eax
80104d77:	75 0c                	jne    80104d85 <sched+0x22>
    panic("sched ptable.lock");
80104d79:	c7 04 24 a5 93 10 80 	movl   $0x801093a5,(%esp)
80104d80:	e8 b5 b7 ff ff       	call   8010053a <panic>
  if(cpu->ncli != 1)
80104d85:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104d8b:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104d91:	83 f8 01             	cmp    $0x1,%eax
80104d94:	74 0c                	je     80104da2 <sched+0x3f>
    panic("sched locks");
80104d96:	c7 04 24 b7 93 10 80 	movl   $0x801093b7,(%esp)
80104d9d:	e8 98 b7 ff ff       	call   8010053a <panic>
  if(proc->state == RUNNING)
80104da2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104da8:	8b 40 0c             	mov    0xc(%eax),%eax
80104dab:	83 f8 04             	cmp    $0x4,%eax
80104dae:	75 0c                	jne    80104dbc <sched+0x59>
    panic("sched running");
80104db0:	c7 04 24 c3 93 10 80 	movl   $0x801093c3,(%esp)
80104db7:	e8 7e b7 ff ff       	call   8010053a <panic>
  if(readeflags()&FL_IF)
80104dbc:	e8 2c f7 ff ff       	call   801044ed <readeflags>
80104dc1:	25 00 02 00 00       	and    $0x200,%eax
80104dc6:	85 c0                	test   %eax,%eax
80104dc8:	74 0c                	je     80104dd6 <sched+0x73>
    panic("sched interruptible");
80104dca:	c7 04 24 d1 93 10 80 	movl   $0x801093d1,(%esp)
80104dd1:	e8 64 b7 ff ff       	call   8010053a <panic>
  intena = cpu->intena;
80104dd6:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104ddc:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104de2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80104de5:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104deb:	8b 40 04             	mov    0x4(%eax),%eax
80104dee:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104df5:	83 c2 1c             	add    $0x1c,%edx
80104df8:	89 44 24 04          	mov    %eax,0x4(%esp)
80104dfc:	89 14 24             	mov    %edx,(%esp)
80104dff:	e8 3d 11 00 00       	call   80105f41 <swtch>
  cpu->intena = intena;
80104e04:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104e0a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e0d:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104e13:	c9                   	leave  
80104e14:	c3                   	ret    

80104e15 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80104e15:	55                   	push   %ebp
80104e16:	89 e5                	mov    %esp,%ebp
80104e18:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80104e1b:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104e22:	e8 35 0c 00 00       	call   80105a5c <acquire>
  proc->state = RUNNABLE;
80104e27:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e2d:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80104e34:	e8 2a ff ff ff       	call   80104d63 <sched>
  release(&ptable.lock);
80104e39:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104e40:	e8 79 0c 00 00       	call   80105abe <release>
}
80104e45:	c9                   	leave  
80104e46:	c3                   	ret    

80104e47 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80104e47:	55                   	push   %ebp
80104e48:	89 e5                	mov    %esp,%ebp
80104e4a:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80104e4d:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104e54:	e8 65 0c 00 00       	call   80105abe <release>

  if (first) {
80104e59:	a1 08 c0 10 80       	mov    0x8010c008,%eax
80104e5e:	85 c0                	test   %eax,%eax
80104e60:	74 0f                	je     80104e71 <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80104e62:	c7 05 08 c0 10 80 00 	movl   $0x0,0x8010c008
80104e69:	00 00 00 
    initlog();
80104e6c:	e8 a3 e5 ff ff       	call   80103414 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80104e71:	c9                   	leave  
80104e72:	c3                   	ret    

80104e73 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80104e73:	55                   	push   %ebp
80104e74:	89 e5                	mov    %esp,%ebp
80104e76:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80104e79:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e7f:	85 c0                	test   %eax,%eax
80104e81:	75 0c                	jne    80104e8f <sleep+0x1c>
    panic("sleep");
80104e83:	c7 04 24 e5 93 10 80 	movl   $0x801093e5,(%esp)
80104e8a:	e8 ab b6 ff ff       	call   8010053a <panic>

  if(lk == 0)
80104e8f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104e93:	75 0c                	jne    80104ea1 <sleep+0x2e>
    panic("sleep without lk");
80104e95:	c7 04 24 eb 93 10 80 	movl   $0x801093eb,(%esp)
80104e9c:	e8 99 b6 ff ff       	call   8010053a <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104ea1:	81 7d 0c a0 39 11 80 	cmpl   $0x801139a0,0xc(%ebp)
80104ea8:	74 17                	je     80104ec1 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80104eaa:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104eb1:	e8 a6 0b 00 00       	call   80105a5c <acquire>
    release(lk);
80104eb6:	8b 45 0c             	mov    0xc(%ebp),%eax
80104eb9:	89 04 24             	mov    %eax,(%esp)
80104ebc:	e8 fd 0b 00 00       	call   80105abe <release>
  }

  // Go to sleep.
  proc->chan = chan;
80104ec1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ec7:	8b 55 08             	mov    0x8(%ebp),%edx
80104eca:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80104ecd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ed3:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
80104eda:	e8 84 fe ff ff       	call   80104d63 <sched>

  // Tidy up.
  proc->chan = 0;
80104edf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ee5:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80104eec:	81 7d 0c a0 39 11 80 	cmpl   $0x801139a0,0xc(%ebp)
80104ef3:	74 17                	je     80104f0c <sleep+0x99>
    release(&ptable.lock);
80104ef5:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104efc:	e8 bd 0b 00 00       	call   80105abe <release>
    acquire(lk);
80104f01:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f04:	89 04 24             	mov    %eax,(%esp)
80104f07:	e8 50 0b 00 00       	call   80105a5c <acquire>
  }
}
80104f0c:	c9                   	leave  
80104f0d:	c3                   	ret    

80104f0e <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104f0e:	55                   	push   %ebp
80104f0f:	89 e5                	mov    %esp,%ebp
80104f11:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104f14:	c7 45 fc d4 39 11 80 	movl   $0x801139d4,-0x4(%ebp)
80104f1b:	eb 27                	jmp    80104f44 <wakeup1+0x36>
    if(p->state == SLEEPING && p->chan == chan)
80104f1d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f20:	8b 40 0c             	mov    0xc(%eax),%eax
80104f23:	83 f8 02             	cmp    $0x2,%eax
80104f26:	75 15                	jne    80104f3d <wakeup1+0x2f>
80104f28:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f2b:	8b 40 20             	mov    0x20(%eax),%eax
80104f2e:	3b 45 08             	cmp    0x8(%ebp),%eax
80104f31:	75 0a                	jne    80104f3d <wakeup1+0x2f>
      p->state = RUNNABLE;
80104f33:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f36:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104f3d:	81 45 fc cc 04 00 00 	addl   $0x4cc,-0x4(%ebp)
80104f44:	81 7d fc d4 6c 12 80 	cmpl   $0x80126cd4,-0x4(%ebp)
80104f4b:	72 d0                	jb     80104f1d <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80104f4d:	c9                   	leave  
80104f4e:	c3                   	ret    

80104f4f <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104f4f:	55                   	push   %ebp
80104f50:	89 e5                	mov    %esp,%ebp
80104f52:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80104f55:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104f5c:	e8 fb 0a 00 00       	call   80105a5c <acquire>
  wakeup1(chan);
80104f61:	8b 45 08             	mov    0x8(%ebp),%eax
80104f64:	89 04 24             	mov    %eax,(%esp)
80104f67:	e8 a2 ff ff ff       	call   80104f0e <wakeup1>
  release(&ptable.lock);
80104f6c:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104f73:	e8 46 0b 00 00       	call   80105abe <release>
}
80104f78:	c9                   	leave  
80104f79:	c3                   	ret    

80104f7a <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104f7a:	55                   	push   %ebp
80104f7b:	89 e5                	mov    %esp,%ebp
80104f7d:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104f80:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104f87:	e8 d0 0a 00 00       	call   80105a5c <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104f8c:	c7 45 f4 d4 39 11 80 	movl   $0x801139d4,-0xc(%ebp)
80104f93:	eb 44                	jmp    80104fd9 <kill+0x5f>
    if(p->pid == pid){
80104f95:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f98:	8b 40 10             	mov    0x10(%eax),%eax
80104f9b:	3b 45 08             	cmp    0x8(%ebp),%eax
80104f9e:	75 32                	jne    80104fd2 <kill+0x58>
      p->killed = 1;
80104fa0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fa3:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104faa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fad:	8b 40 0c             	mov    0xc(%eax),%eax
80104fb0:	83 f8 02             	cmp    $0x2,%eax
80104fb3:	75 0a                	jne    80104fbf <kill+0x45>
        p->state = RUNNABLE;
80104fb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fb8:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104fbf:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104fc6:	e8 f3 0a 00 00       	call   80105abe <release>
      return 0;
80104fcb:	b8 00 00 00 00       	mov    $0x0,%eax
80104fd0:	eb 21                	jmp    80104ff3 <kill+0x79>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104fd2:	81 45 f4 cc 04 00 00 	addl   $0x4cc,-0xc(%ebp)
80104fd9:	81 7d f4 d4 6c 12 80 	cmpl   $0x80126cd4,-0xc(%ebp)
80104fe0:	72 b3                	jb     80104f95 <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80104fe2:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104fe9:	e8 d0 0a 00 00       	call   80105abe <release>
  return -1;
80104fee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104ff3:	c9                   	leave  
80104ff4:	c3                   	ret    

80104ff5 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104ff5:	55                   	push   %ebp
80104ff6:	89 e5                	mov    %esp,%ebp
80104ff8:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104ffb:	c7 45 f0 d4 39 11 80 	movl   $0x801139d4,-0x10(%ebp)
80105002:	e9 d9 00 00 00       	jmp    801050e0 <procdump+0xeb>
    if(p->state == UNUSED)
80105007:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010500a:	8b 40 0c             	mov    0xc(%eax),%eax
8010500d:	85 c0                	test   %eax,%eax
8010500f:	75 05                	jne    80105016 <procdump+0x21>
      continue;
80105011:	e9 c3 00 00 00       	jmp    801050d9 <procdump+0xe4>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80105016:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105019:	8b 40 0c             	mov    0xc(%eax),%eax
8010501c:	83 f8 05             	cmp    $0x5,%eax
8010501f:	77 23                	ja     80105044 <procdump+0x4f>
80105021:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105024:	8b 40 0c             	mov    0xc(%eax),%eax
80105027:	8b 04 85 0c c0 10 80 	mov    -0x7fef3ff4(,%eax,4),%eax
8010502e:	85 c0                	test   %eax,%eax
80105030:	74 12                	je     80105044 <procdump+0x4f>
      state = states[p->state];
80105032:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105035:	8b 40 0c             	mov    0xc(%eax),%eax
80105038:	8b 04 85 0c c0 10 80 	mov    -0x7fef3ff4(,%eax,4),%eax
8010503f:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105042:	eb 07                	jmp    8010504b <procdump+0x56>
    else
      state = "???";
80105044:	c7 45 ec fc 93 10 80 	movl   $0x801093fc,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
8010504b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010504e:	8d 50 28             	lea    0x28(%eax),%edx
80105051:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105054:	8b 40 10             	mov    0x10(%eax),%eax
80105057:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010505b:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010505e:	89 54 24 08          	mov    %edx,0x8(%esp)
80105062:	89 44 24 04          	mov    %eax,0x4(%esp)
80105066:	c7 04 24 00 94 10 80 	movl   $0x80109400,(%esp)
8010506d:	e8 2e b3 ff ff       	call   801003a0 <cprintf>
    if(p->state == SLEEPING){
80105072:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105075:	8b 40 0c             	mov    0xc(%eax),%eax
80105078:	83 f8 02             	cmp    $0x2,%eax
8010507b:	75 50                	jne    801050cd <procdump+0xd8>
      getcallerpcs((uint*)p->context->ebp+2, pc);
8010507d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105080:	8b 40 1c             	mov    0x1c(%eax),%eax
80105083:	8b 40 0c             	mov    0xc(%eax),%eax
80105086:	83 c0 08             	add    $0x8,%eax
80105089:	8d 55 c4             	lea    -0x3c(%ebp),%edx
8010508c:	89 54 24 04          	mov    %edx,0x4(%esp)
80105090:	89 04 24             	mov    %eax,(%esp)
80105093:	e8 75 0a 00 00       	call   80105b0d <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80105098:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010509f:	eb 1b                	jmp    801050bc <procdump+0xc7>
        cprintf(" %p", pc[i]);
801050a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801050a4:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
801050a8:	89 44 24 04          	mov    %eax,0x4(%esp)
801050ac:	c7 04 24 09 94 10 80 	movl   $0x80109409,(%esp)
801050b3:	e8 e8 b2 ff ff       	call   801003a0 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
801050b8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801050bc:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801050c0:	7f 0b                	jg     801050cd <procdump+0xd8>
801050c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801050c5:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
801050c9:	85 c0                	test   %eax,%eax
801050cb:	75 d4                	jne    801050a1 <procdump+0xac>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
801050cd:	c7 04 24 0d 94 10 80 	movl   $0x8010940d,(%esp)
801050d4:	e8 c7 b2 ff ff       	call   801003a0 <cprintf>
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801050d9:	81 45 f0 cc 04 00 00 	addl   $0x4cc,-0x10(%ebp)
801050e0:	81 7d f0 d4 6c 12 80 	cmpl   $0x80126cd4,-0x10(%ebp)
801050e7:	0f 82 1a ff ff ff    	jb     80105007 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
801050ed:	c9                   	leave  
801050ee:	c3                   	ret    

801050ef <getProcPIDS>:

// set pids to contain all the current pids number 
// returns the number of elemets in pids
int getProcPIDS (int *pids){
801050ef:	55                   	push   %ebp
801050f0:	89 e5                	mov    %esp,%ebp
801050f2:	83 ec 28             	sub    $0x28,%esp

  struct proc *p;
  int count =0;
801050f5:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  acquire(& ptable.lock);
801050fc:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80105103:	e8 54 09 00 00       	call   80105a5c <acquire>
  for(p = ptable.proc; p< &ptable.proc[NPROC]; p++){
80105108:	c7 45 f4 d4 39 11 80 	movl   $0x801139d4,-0xc(%ebp)
8010510f:	eb 43                	jmp    80105154 <getProcPIDS+0x65>

      if  ((p->state==SLEEPING ||  p->state==RUNNABLE || p->state==RUNNING )){
80105111:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105114:	8b 40 0c             	mov    0xc(%eax),%eax
80105117:	83 f8 02             	cmp    $0x2,%eax
8010511a:	74 16                	je     80105132 <getProcPIDS+0x43>
8010511c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010511f:	8b 40 0c             	mov    0xc(%eax),%eax
80105122:	83 f8 03             	cmp    $0x3,%eax
80105125:	74 0b                	je     80105132 <getProcPIDS+0x43>
80105127:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010512a:	8b 40 0c             	mov    0xc(%eax),%eax
8010512d:	83 f8 04             	cmp    $0x4,%eax
80105130:	75 1b                	jne    8010514d <getProcPIDS+0x5e>
         pids[count]= p->pid;
80105132:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105135:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010513c:	8b 45 08             	mov    0x8(%ebp),%eax
8010513f:	01 c2                	add    %eax,%edx
80105141:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105144:	8b 40 10             	mov    0x10(%eax),%eax
80105147:	89 02                	mov    %eax,(%edx)
      	 //cprintf("%d   ", pids[count]);
         count++;
80105149:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
int getProcPIDS (int *pids){

  struct proc *p;
  int count =0;
  acquire(& ptable.lock);
  for(p = ptable.proc; p< &ptable.proc[NPROC]; p++){
8010514d:	81 45 f4 cc 04 00 00 	addl   $0x4cc,-0xc(%ebp)
80105154:	81 7d f4 d4 6c 12 80 	cmpl   $0x80126cd4,-0xc(%ebp)
8010515b:	72 b4                	jb     80105111 <getProcPIDS+0x22>
         count++;
      }

  }
  
  release(& ptable.lock);
8010515d:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80105164:	e8 55 09 00 00       	call   80105abe <release>
  return count;
80105169:	8b 45 f0             	mov    -0x10(%ebp),%eax

}
8010516c:	c9                   	leave  
8010516d:	c3                   	ret    

8010516e <procLock>:


// locks ptable
void procLock(){
8010516e:	55                   	push   %ebp
8010516f:	89 e5                	mov    %esp,%ebp
80105171:	83 ec 18             	sub    $0x18,%esp
	acquire(&ptable.lock);
80105174:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
8010517b:	e8 dc 08 00 00       	call   80105a5c <acquire>
}
80105180:	c9                   	leave  
80105181:	c3                   	ret    

80105182 <procRelease>:

// release ptable
void procRelease(){
80105182:	55                   	push   %ebp
80105183:	89 e5                	mov    %esp,%ebp
80105185:	83 ec 18             	sub    $0x18,%esp
	release(&ptable.lock);
80105188:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
8010518f:	e8 2a 09 00 00       	call   80105abe <release>
}
80105194:	c9                   	leave  
80105195:	c3                   	ret    

80105196 <getProc>:


// returns the process struct with the current pid number
// if process is not found, or not alive the function return null
struct proc* getProc (int pid){
80105196:	55                   	push   %ebp
80105197:	89 e5                	mov    %esp,%ebp
80105199:	83 ec 10             	sub    $0x10,%esp

  struct proc *p;

  for(p = ptable.proc; p< &ptable.proc[NPROC]; p++){
8010519c:	c7 45 fc d4 39 11 80 	movl   $0x801139d4,-0x4(%ebp)
801051a3:	eb 38                	jmp    801051dd <getProc+0x47>
      if  (p->pid==pid  && (p->state==SLEEPING ||  p->state==RUNNABLE || p->state==RUNNING )){
801051a5:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051a8:	8b 40 10             	mov    0x10(%eax),%eax
801051ab:	3b 45 08             	cmp    0x8(%ebp),%eax
801051ae:	75 26                	jne    801051d6 <getProc+0x40>
801051b0:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051b3:	8b 40 0c             	mov    0xc(%eax),%eax
801051b6:	83 f8 02             	cmp    $0x2,%eax
801051b9:	74 16                	je     801051d1 <getProc+0x3b>
801051bb:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051be:	8b 40 0c             	mov    0xc(%eax),%eax
801051c1:	83 f8 03             	cmp    $0x3,%eax
801051c4:	74 0b                	je     801051d1 <getProc+0x3b>
801051c6:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051c9:	8b 40 0c             	mov    0xc(%eax),%eax
801051cc:	83 f8 04             	cmp    $0x4,%eax
801051cf:	75 05                	jne    801051d6 <getProc+0x40>
    	  return p;
801051d1:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051d4:	eb 15                	jmp    801051eb <getProc+0x55>
// if process is not found, or not alive the function return null
struct proc* getProc (int pid){

  struct proc *p;

  for(p = ptable.proc; p< &ptable.proc[NPROC]; p++){
801051d6:	81 45 fc cc 04 00 00 	addl   $0x4cc,-0x4(%ebp)
801051dd:	81 7d fc d4 6c 12 80 	cmpl   $0x80126cd4,-0x4(%ebp)
801051e4:	72 bf                	jb     801051a5 <getProc+0xf>
      if  (p->pid==pid  && (p->state==SLEEPING ||  p->state==RUNNABLE || p->state==RUNNING )){
    	  return p;
      }

  }
  return 0;
801051e6:	b8 00 00 00 00       	mov    $0x0,%eax

}
801051eb:	c9                   	leave  
801051ec:	c3                   	ret    

801051ed <PID_PART>:
#define CWD_DNUM 3000
#define EXE_DNUM 4000
#define FDINFO_DNUM 5000
#define STATUS_DNUM 6000

static inline uint PID_PART(uint x) { return (x % 1000);}
801051ed:	55                   	push   %ebp
801051ee:	89 e5                	mov    %esp,%ebp
801051f0:	8b 4d 08             	mov    0x8(%ebp),%ecx
801051f3:	ba d3 4d 62 10       	mov    $0x10624dd3,%edx
801051f8:	89 c8                	mov    %ecx,%eax
801051fa:	f7 e2                	mul    %edx
801051fc:	89 d0                	mov    %edx,%eax
801051fe:	c1 e8 06             	shr    $0x6,%eax
80105201:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
80105207:	29 c1                	sub    %eax,%ecx
80105209:	89 c8                	mov    %ecx,%eax
8010520b:	5d                   	pop    %ebp
8010520c:	c3                   	ret    

8010520d <procfsisdir>:
int procfsInum;
int first=1;
 

int
procfsisdir(struct inode *ip) {
8010520d:	55                   	push   %ebp
8010520e:	89 e5                	mov    %esp,%ebp

 if (first){
80105210:	a1 24 c0 10 80       	mov    0x8010c024,%eax
80105215:	85 c0                	test   %eax,%eax
80105217:	74 1e                	je     80105237 <procfsisdir+0x2a>
    procfsInum= ip->inum;
80105219:	8b 45 08             	mov    0x8(%ebp),%eax
8010521c:	8b 40 04             	mov    0x4(%eax),%eax
8010521f:	a3 d4 6c 12 80       	mov    %eax,0x80126cd4
    ip->minor =0;
80105224:	8b 45 08             	mov    0x8(%ebp),%eax
80105227:	66 c7 40 14 00 00    	movw   $0x0,0x14(%eax)
    first= 0;
8010522d:	c7 05 24 c0 10 80 00 	movl   $0x0,0x8010c024
80105234:	00 00 00 
  }


  if (ip->inum == procfsInum)
80105237:	8b 45 08             	mov    0x8(%ebp),%eax
8010523a:	8b 50 04             	mov    0x4(%eax),%edx
8010523d:	a1 d4 6c 12 80       	mov    0x80126cd4,%eax
80105242:	39 c2                	cmp    %eax,%edx
80105244:	75 07                	jne    8010524d <procfsisdir+0x40>
	  return 1;
80105246:	b8 01 00 00 00       	mov    $0x1,%eax
8010524b:	eb 3f                	jmp    8010528c <procfsisdir+0x7f>

  if (ip->inum >= BASE_DIRENT_NUM && ip->inum <BASE_DNUM_LIM)
8010524d:	8b 45 08             	mov    0x8(%ebp),%eax
80105250:	8b 40 04             	mov    0x4(%eax),%eax
80105253:	3d e7 03 00 00       	cmp    $0x3e7,%eax
80105258:	76 14                	jbe    8010526e <procfsisdir+0x61>
8010525a:	8b 45 08             	mov    0x8(%ebp),%eax
8010525d:	8b 40 04             	mov    0x4(%eax),%eax
80105260:	3d 27 04 00 00       	cmp    $0x427,%eax
80105265:	77 07                	ja     8010526e <procfsisdir+0x61>
    return 1;
80105267:	b8 01 00 00 00       	mov    $0x1,%eax
8010526c:	eb 1e                	jmp    8010528c <procfsisdir+0x7f>

 /// cprintf(" ########## %d \n", ip->inum / CWD_DNUM);
  if (ip->inum / CWD_DNUM  == 1){
8010526e:	8b 45 08             	mov    0x8(%ebp),%eax
80105271:	8b 40 04             	mov    0x4(%eax),%eax
80105274:	2d b8 0b 00 00       	sub    $0xbb8,%eax
80105279:	3d b7 0b 00 00       	cmp    $0xbb7,%eax
8010527e:	77 07                	ja     80105287 <procfsisdir+0x7a>
    return 1;
80105280:	b8 01 00 00 00       	mov    $0x1,%eax
80105285:	eb 05                	jmp    8010528c <procfsisdir+0x7f>
  }
  
  else return 0;
80105287:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010528c:	5d                   	pop    %ebp
8010528d:	c3                   	ret    

8010528e <procfsiread>:

void 
procfsiread(struct inode* dp, struct inode *ip) 
{
8010528e:	55                   	push   %ebp
8010528f:	89 e5                	mov    %esp,%ebp
	// ip->flags = i_valid;
	// ip->major = 2;

 // cprintf("**** iread  inmu dp %d ip %d\n", dp->inum, ip->inum);
  //if (ip->inum >= BASE_DIRENT_NUM) {
    ip->type = T_DEV;
80105291:	8b 45 0c             	mov    0xc(%ebp),%eax
80105294:	66 c7 40 10 03 00    	movw   $0x3,0x10(%eax)
    ip->major = PROCFS;
8010529a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010529d:	66 c7 40 12 02 00    	movw   $0x2,0x12(%eax)
    ip->size = 0;
801052a3:	8b 45 0c             	mov    0xc(%ebp),%eax
801052a6:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
    ip->flags |= I_VALID;
801052ad:	8b 45 0c             	mov    0xc(%ebp),%eax
801052b0:	8b 40 0c             	mov    0xc(%eax),%eax
801052b3:	83 c8 02             	or     $0x2,%eax
801052b6:	89 c2                	mov    %eax,%edx
801052b8:	8b 45 0c             	mov    0xc(%ebp),%eax
801052bb:	89 50 0c             	mov    %edx,0xc(%eax)

  // cprintf("**** iread  type %d isdir %d  isdir(ip) %d\n",  ip->type, devsw[ip->major].isdir, devsw[ip->major].isdir(ip));
  // cprintf("**** iread  major dp %d ip %d\n", dp->major, ip->major);
  // cprintf("**** iread  minor dp %d ip %d\n", dp->minor, ip->minor);
    
}
801052be:	5d                   	pop    %ebp
801052bf:	c3                   	ret    

801052c0 <getProcList>:

int getProcList(char *buf, struct inode *pidIp) {
801052c0:	55                   	push   %ebp
801052c1:	89 e5                	mov    %esp,%ebp
801052c3:	81 ec 78 01 00 00    	sub    $0x178,%esp
  struct dirent de;
  int pidCount;
  int bufOff= 2;
801052c9:	c7 45 f4 02 00 00 00 	movl   $0x2,-0xc(%ebp)
  char stringNum[64];
  int  stringNumLength;


  //create "this dir" reference
  de.inum = procfsInum;
801052d0:	a1 d4 6c 12 80       	mov    0x80126cd4,%eax
801052d5:	66 89 45 d8          	mov    %ax,-0x28(%ebp)
  memmove(de.name, ".", 2);
801052d9:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
801052e0:	00 
801052e1:	c7 44 24 04 39 94 10 	movl   $0x80109439,0x4(%esp)
801052e8:	80 
801052e9:	8d 45 d8             	lea    -0x28(%ebp),%eax
801052ec:	83 c0 02             	add    $0x2,%eax
801052ef:	89 04 24             	mov    %eax,(%esp)
801052f2:	e8 88 0a 00 00       	call   80105d7f <memmove>
  memmove(buf, (char*)&de, sizeof(de));
801052f7:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801052fe:	00 
801052ff:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105302:	89 44 24 04          	mov    %eax,0x4(%esp)
80105306:	8b 45 08             	mov    0x8(%ebp),%eax
80105309:	89 04 24             	mov    %eax,(%esp)
8010530c:	e8 6e 0a 00 00       	call   80105d7f <memmove>

  //create "prev dir" reference -procfs Dir
  de.inum = ROOTINO;
80105311:	66 c7 45 d8 01 00    	movw   $0x1,-0x28(%ebp)
  memmove(de.name, "..", 3);
80105317:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
8010531e:	00 
8010531f:	c7 44 24 04 3b 94 10 	movl   $0x8010943b,0x4(%esp)
80105326:	80 
80105327:	8d 45 d8             	lea    -0x28(%ebp),%eax
8010532a:	83 c0 02             	add    $0x2,%eax
8010532d:	89 04 24             	mov    %eax,(%esp)
80105330:	e8 4a 0a 00 00       	call   80105d7f <memmove>
  memmove(buf + sizeof(de), (char*)&de, sizeof(de));
80105335:	8b 45 08             	mov    0x8(%ebp),%eax
80105338:	8d 50 10             	lea    0x10(%eax),%edx
8010533b:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105342:	00 
80105343:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105346:	89 44 24 04          	mov    %eax,0x4(%esp)
8010534a:	89 14 24             	mov    %edx,(%esp)
8010534d:	e8 2d 0a 00 00       	call   80105d7f <memmove>

  // return the current running processes pids
  pidCount = getProcPIDS(pids);
80105352:	8d 85 d8 fe ff ff    	lea    -0x128(%ebp),%eax
80105358:	89 04 24             	mov    %eax,(%esp)
8010535b:	e8 8f fd ff ff       	call   801050ef <getProcPIDS>
80105360:	89 45 ec             	mov    %eax,-0x14(%ebp)

  //push Pids as file entries
  for (pidIndex = 0; pidIndex< pidCount; pidIndex++){
80105363:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010536a:	eb 7f                	jmp    801053eb <getProcList+0x12b>

      de.inum = pids[pidIndex] + BASE_DIRENT_NUM ;
8010536c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010536f:	8b 84 85 d8 fe ff ff 	mov    -0x128(%ebp,%eax,4),%eax
80105376:	66 05 e8 03          	add    $0x3e8,%ax
8010537a:	66 89 45 d8          	mov    %ax,-0x28(%ebp)
      
      stringNumLength = itoa(  pids[pidIndex], stringNum );
8010537e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105381:	8b 84 85 d8 fe ff ff 	mov    -0x128(%ebp,%eax,4),%eax
80105388:	8d 95 98 fe ff ff    	lea    -0x168(%ebp),%edx
8010538e:	89 54 24 04          	mov    %edx,0x4(%esp)
80105392:	89 04 24             	mov    %eax,(%esp)
80105395:	e8 63 05 00 00       	call   801058fd <itoa>
8010539a:	89 45 e8             	mov    %eax,-0x18(%ebp)

      memmove(de.name, stringNum, stringNumLength+1);
8010539d:	8b 45 e8             	mov    -0x18(%ebp),%eax
801053a0:	83 c0 01             	add    $0x1,%eax
801053a3:	89 44 24 08          	mov    %eax,0x8(%esp)
801053a7:	8d 85 98 fe ff ff    	lea    -0x168(%ebp),%eax
801053ad:	89 44 24 04          	mov    %eax,0x4(%esp)
801053b1:	8d 45 d8             	lea    -0x28(%ebp),%eax
801053b4:	83 c0 02             	add    $0x2,%eax
801053b7:	89 04 24             	mov    %eax,(%esp)
801053ba:	e8 c0 09 00 00       	call   80105d7f <memmove>
      memmove(buf + bufOff * sizeof(de), (char*)&de, sizeof(de));
801053bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053c2:	c1 e0 04             	shl    $0x4,%eax
801053c5:	89 c2                	mov    %eax,%edx
801053c7:	8b 45 08             	mov    0x8(%ebp),%eax
801053ca:	01 c2                	add    %eax,%edx
801053cc:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801053d3:	00 
801053d4:	8d 45 d8             	lea    -0x28(%ebp),%eax
801053d7:	89 44 24 04          	mov    %eax,0x4(%esp)
801053db:	89 14 24             	mov    %edx,(%esp)
801053de:	e8 9c 09 00 00       	call   80105d7f <memmove>
      bufOff++;
801053e3:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

  // return the current running processes pids
  pidCount = getProcPIDS(pids);

  //push Pids as file entries
  for (pidIndex = 0; pidIndex< pidCount; pidIndex++){
801053e7:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801053eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801053ee:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801053f1:	0f 8c 75 ff ff ff    	jl     8010536c <getProcList+0xac>
      memmove(buf + bufOff * sizeof(de), (char*)&de, sizeof(de));
      bufOff++;

  }

  return (bufOff)* sizeof(de);
801053f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053fa:	c1 e0 04             	shl    $0x4,%eax
}
801053fd:	c9                   	leave  
801053fe:	c3                   	ret    

801053ff <getProcEntry>:



int getProcEntry(uint pid ,char *buf, struct inode *ip) {
801053ff:	55                   	push   %ebp
80105400:	89 e5                	mov    %esp,%ebp
80105402:	83 ec 38             	sub    $0x38,%esp

  struct dirent de;

  
  struct proc *p;
  procLock();
80105405:	e8 64 fd ff ff       	call   8010516e <procLock>

  p = getProc(pid);
8010540a:	8b 45 08             	mov    0x8(%ebp),%eax
8010540d:	89 04 24             	mov    %eax,(%esp)
80105410:	e8 81 fd ff ff       	call   80105196 <getProc>
80105415:	89 45 f4             	mov    %eax,-0xc(%ebp)
  
  procRelease();
80105418:	e8 65 fd ff ff       	call   80105182 <procRelease>
  if (!p){
8010541d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105421:	75 1d                	jne    80105440 <getProcEntry+0x41>
    cprintf ( " pid %d\n  ", pid );
80105423:	8b 45 08             	mov    0x8(%ebp),%eax
80105426:	89 44 24 04          	mov    %eax,0x4(%esp)
8010542a:	c7 04 24 3e 94 10 80 	movl   $0x8010943e,(%esp)
80105431:	e8 6a af ff ff       	call   801003a0 <cprintf>
	  return 0;
80105436:	b8 00 00 00 00       	mov    $0x0,%eax
8010543b:	e9 e9 01 00 00       	jmp    80105629 <getProcEntry+0x22a>
  }


  //create "this dir" reference
  de.inum = ip->inum;
80105440:	8b 45 10             	mov    0x10(%ebp),%eax
80105443:	8b 40 04             	mov    0x4(%eax),%eax
80105446:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)

  //cprintf(" ********* %d\n", ip->inum);
  memmove(de.name, ".", 2);
8010544a:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
80105451:	00 
80105452:	c7 44 24 04 39 94 10 	movl   $0x80109439,0x4(%esp)
80105459:	80 
8010545a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010545d:	83 c0 02             	add    $0x2,%eax
80105460:	89 04 24             	mov    %eax,(%esp)
80105463:	e8 17 09 00 00       	call   80105d7f <memmove>
  memmove(buf, (char*)&de, sizeof(de));
80105468:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010546f:	00 
80105470:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105473:	89 44 24 04          	mov    %eax,0x4(%esp)
80105477:	8b 45 0c             	mov    0xc(%ebp),%eax
8010547a:	89 04 24             	mov    %eax,(%esp)
8010547d:	e8 fd 08 00 00       	call   80105d7f <memmove>

  //create "prev dir" reference -root Dir
  de.inum = procfsInum;
80105482:	a1 d4 6c 12 80       	mov    0x80126cd4,%eax
80105487:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  memmove(de.name, "..", 3);
8010548b:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
80105492:	00 
80105493:	c7 44 24 04 3b 94 10 	movl   $0x8010943b,0x4(%esp)
8010549a:	80 
8010549b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010549e:	83 c0 02             	add    $0x2,%eax
801054a1:	89 04 24             	mov    %eax,(%esp)
801054a4:	e8 d6 08 00 00       	call   80105d7f <memmove>
  memmove(buf + sizeof(de), (char*)&de, sizeof(de));
801054a9:	8b 45 0c             	mov    0xc(%ebp),%eax
801054ac:	8d 50 10             	lea    0x10(%eax),%edx
801054af:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801054b6:	00 
801054b7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801054ba:	89 44 24 04          	mov    %eax,0x4(%esp)
801054be:	89 14 24             	mov    %edx,(%esp)
801054c1:	e8 b9 08 00 00       	call   80105d7f <memmove>

  //create "cmdline " reference
  
  de.inum = CMDLINE_DNUM+pid;
801054c6:	8b 45 08             	mov    0x8(%ebp),%eax
801054c9:	66 05 d0 07          	add    $0x7d0,%ax
801054cd:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  // cprintf("######### %d %p\n", de.inum, r);
  
  memmove(de.name, "cmdline", 8);
801054d1:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
801054d8:	00 
801054d9:	c7 44 24 04 49 94 10 	movl   $0x80109449,0x4(%esp)
801054e0:	80 
801054e1:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801054e4:	83 c0 02             	add    $0x2,%eax
801054e7:	89 04 24             	mov    %eax,(%esp)
801054ea:	e8 90 08 00 00       	call   80105d7f <memmove>
  memmove(buf + 2*sizeof(de), (char*)&de, sizeof(de));
801054ef:	8b 45 0c             	mov    0xc(%ebp),%eax
801054f2:	8d 50 20             	lea    0x20(%eax),%edx
801054f5:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801054fc:	00 
801054fd:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105500:	89 44 24 04          	mov    %eax,0x4(%esp)
80105504:	89 14 24             	mov    %edx,(%esp)
80105507:	e8 73 08 00 00       	call   80105d7f <memmove>

  //create "cwd " reference
  de.inum = CWD_DNUM + pid;
8010550c:	8b 45 08             	mov    0x8(%ebp),%eax
8010550f:	66 05 b8 0b          	add    $0xbb8,%ax
80105513:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  memmove(de.name, "cwd", 4);
80105517:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010551e:	00 
8010551f:	c7 44 24 04 51 94 10 	movl   $0x80109451,0x4(%esp)
80105526:	80 
80105527:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010552a:	83 c0 02             	add    $0x2,%eax
8010552d:	89 04 24             	mov    %eax,(%esp)
80105530:	e8 4a 08 00 00       	call   80105d7f <memmove>
  memmove(buf + 3*sizeof(de), (char*)&de, sizeof(de));
80105535:	8b 45 0c             	mov    0xc(%ebp),%eax
80105538:	8d 50 30             	lea    0x30(%eax),%edx
8010553b:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105542:	00 
80105543:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105546:	89 44 24 04          	mov    %eax,0x4(%esp)
8010554a:	89 14 24             	mov    %edx,(%esp)
8010554d:	e8 2d 08 00 00       	call   80105d7f <memmove>

  //create "exe " reference
  de.inum = EXE_DNUM + pid;
80105552:	8b 45 08             	mov    0x8(%ebp),%eax
80105555:	66 05 a0 0f          	add    $0xfa0,%ax
80105559:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  memmove(de.name, "exe", 4);
8010555d:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80105564:	00 
80105565:	c7 44 24 04 55 94 10 	movl   $0x80109455,0x4(%esp)
8010556c:	80 
8010556d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105570:	83 c0 02             	add    $0x2,%eax
80105573:	89 04 24             	mov    %eax,(%esp)
80105576:	e8 04 08 00 00       	call   80105d7f <memmove>
  memmove(buf + 4*sizeof(de), (char*)&de, sizeof(de));
8010557b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010557e:	8d 50 40             	lea    0x40(%eax),%edx
80105581:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105588:	00 
80105589:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010558c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105590:	89 14 24             	mov    %edx,(%esp)
80105593:	e8 e7 07 00 00       	call   80105d7f <memmove>

  //create "fdinfo " reference -root Dir
  de.inum = FDINFO_DNUM + pid;
80105598:	8b 45 08             	mov    0x8(%ebp),%eax
8010559b:	66 05 88 13          	add    $0x1388,%ax
8010559f:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  memmove(de.name, "fdinfo", 7);
801055a3:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
801055aa:	00 
801055ab:	c7 44 24 04 59 94 10 	movl   $0x80109459,0x4(%esp)
801055b2:	80 
801055b3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801055b6:	83 c0 02             	add    $0x2,%eax
801055b9:	89 04 24             	mov    %eax,(%esp)
801055bc:	e8 be 07 00 00       	call   80105d7f <memmove>
  memmove(buf + 5*sizeof(de), (char*)&de, sizeof(de));
801055c1:	8b 45 0c             	mov    0xc(%ebp),%eax
801055c4:	8d 50 50             	lea    0x50(%eax),%edx
801055c7:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801055ce:	00 
801055cf:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801055d2:	89 44 24 04          	mov    %eax,0x4(%esp)
801055d6:	89 14 24             	mov    %edx,(%esp)
801055d9:	e8 a1 07 00 00       	call   80105d7f <memmove>

  //create "status " reference -root Dir
  de.inum = STATUS_DNUM + pid;
801055de:	8b 45 08             	mov    0x8(%ebp),%eax
801055e1:	66 05 70 17          	add    $0x1770,%ax
801055e5:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  memmove(de.name, "status", 7);
801055e9:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
801055f0:	00 
801055f1:	c7 44 24 04 60 94 10 	movl   $0x80109460,0x4(%esp)
801055f8:	80 
801055f9:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801055fc:	83 c0 02             	add    $0x2,%eax
801055ff:	89 04 24             	mov    %eax,(%esp)
80105602:	e8 78 07 00 00       	call   80105d7f <memmove>
  memmove(buf + 6*sizeof(de), (char*)&de, sizeof(de));
80105607:	8b 45 0c             	mov    0xc(%ebp),%eax
8010560a:	8d 50 60             	lea    0x60(%eax),%edx
8010560d:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105614:	00 
80105615:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105618:	89 44 24 04          	mov    %eax,0x4(%esp)
8010561c:	89 14 24             	mov    %edx,(%esp)
8010561f:	e8 5b 07 00 00       	call   80105d7f <memmove>

  return 7 * sizeof(de);
80105624:	b8 70 00 00 00       	mov    $0x70,%eax
}
80105629:	c9                   	leave  
8010562a:	c3                   	ret    

8010562b <procfsread>:



int
procfsread(struct inode *ip, char *dst, int off, int n) {
8010562b:	55                   	push   %ebp
8010562c:	89 e5                	mov    %esp,%ebp
8010562e:	53                   	push   %ebx
8010562f:	81 ec 34 04 00 00    	sub    $0x434,%esp
  char buf[1024];
  int size ,i ;

    // cprintf("***********    %d \n", ip->inum);
    if (first){
80105635:	a1 24 c0 10 80       	mov    0x8010c024,%eax
8010563a:	85 c0                	test   %eax,%eax
8010563c:	74 1e                	je     8010565c <procfsread+0x31>
      procfsInum= ip->inum;
8010563e:	8b 45 08             	mov    0x8(%ebp),%eax
80105641:	8b 40 04             	mov    0x4(%eax),%eax
80105644:	a3 d4 6c 12 80       	mov    %eax,0x80126cd4
      ip->minor =0;
80105649:	8b 45 08             	mov    0x8(%ebp),%eax
8010564c:	66 c7 40 14 00 00    	movw   $0x0,0x14(%eax)
      first= 0;
80105652:	c7 05 24 c0 10 80 00 	movl   $0x0,0x8010c024
80105659:	00 00 00 
    }
    
	  if (ip->inum == procfsInum) {
8010565c:	8b 45 08             	mov    0x8(%ebp),%eax
8010565f:	8b 50 04             	mov    0x4(%eax),%edx
80105662:	a1 d4 6c 12 80       	mov    0x80126cd4,%eax
80105667:	39 c2                	cmp    %eax,%edx
80105669:	75 18                	jne    80105683 <procfsread+0x58>
		  size = getProcList(buf, ip);
8010566b:	8b 45 08             	mov    0x8(%ebp),%eax
8010566e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105672:	8d 85 e4 fb ff ff    	lea    -0x41c(%ebp),%eax
80105678:	89 04 24             	mov    %eax,(%esp)
8010567b:	e8 40 fc ff ff       	call   801052c0 <getProcList>
80105680:	89 45 f4             	mov    %eax,-0xc(%ebp)
          
    }

    uint pid = PID_PART(ip->inum);
80105683:	8b 45 08             	mov    0x8(%ebp),%eax
80105686:	8b 40 04             	mov    0x4(%eax),%eax
80105689:	89 04 24             	mov    %eax,(%esp)
8010568c:	e8 5c fb ff ff       	call   801051ed <PID_PART>
80105691:	89 45 ec             	mov    %eax,-0x14(%ebp)

    struct proc * p= getProc(pid);
80105694:	8b 45 ec             	mov    -0x14(%ebp),%eax
80105697:	89 04 24             	mov    %eax,(%esp)
8010569a:	e8 f7 fa ff ff       	call   80105196 <getProc>
8010569f:	89 45 e8             	mov    %eax,-0x18(%ebp)
    
    //cprintf ("p.pid %d *** num %d, pid %d *** %s \n", p->pid, ip->inum ,pid, p->cmdline);

    if (ip->inum >= BASE_DIRENT_NUM && ip->inum<=BASE_DNUM_LIM ){
801056a2:	8b 45 08             	mov    0x8(%ebp),%eax
801056a5:	8b 40 04             	mov    0x4(%eax),%eax
801056a8:	3d e7 03 00 00       	cmp    $0x3e7,%eax
801056ad:	76 2c                	jbe    801056db <procfsread+0xb0>
801056af:	8b 45 08             	mov    0x8(%ebp),%eax
801056b2:	8b 40 04             	mov    0x4(%eax),%eax
801056b5:	3d 28 04 00 00       	cmp    $0x428,%eax
801056ba:	77 1f                	ja     801056db <procfsread+0xb0>
		     
         size = getProcEntry(pid,buf, ip);
801056bc:	8b 45 08             	mov    0x8(%ebp),%eax
801056bf:	89 44 24 08          	mov    %eax,0x8(%esp)
801056c3:	8d 85 e4 fb ff ff    	lea    -0x41c(%ebp),%eax
801056c9:	89 44 24 04          	mov    %eax,0x4(%esp)
801056cd:	8b 45 ec             	mov    -0x14(%ebp),%eax
801056d0:	89 04 24             	mov    %eax,(%esp)
801056d3:	e8 27 fd ff ff       	call   801053ff <getProcEntry>
801056d8:	89 45 f4             	mov    %eax,-0xc(%ebp)
    }

    if ( ip-> inum >= CMDLINE_DNUM) {
801056db:	8b 45 08             	mov    0x8(%ebp),%eax
801056de:	8b 40 04             	mov    0x4(%eax),%eax
801056e1:	3d cf 07 00 00       	cmp    $0x7cf,%eax
801056e6:	0f 86 84 01 00 00    	jbe    80105870 <procfsread+0x245>


        if(!p)
801056ec:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801056f0:	75 0a                	jne    801056fc <procfsread+0xd1>
         return 0;
801056f2:	b8 00 00 00 00       	mov    $0x0,%eax
801056f7:	e9 c1 01 00 00       	jmp    801058bd <procfsread+0x292>


        switch (ip->inum-pid){
801056fc:	8b 45 08             	mov    0x8(%ebp),%eax
801056ff:	8b 40 04             	mov    0x4(%eax),%eax
80105702:	2b 45 ec             	sub    -0x14(%ebp),%eax
80105705:	3d d0 07 00 00       	cmp    $0x7d0,%eax
8010570a:	74 10                	je     8010571c <procfsread+0xf1>
8010570c:	3d b8 0b 00 00       	cmp    $0xbb8,%eax
80105711:	0f 84 25 01 00 00    	je     8010583c <procfsread+0x211>
80105717:	e9 54 01 00 00       	jmp    80105870 <procfsread+0x245>
         
              case CMDLINE_DNUM:
                            // cprintf("here p %d cmd %s\n", p->pid, p->cmdline);
                            size = strlen(p->cmdline);
8010571c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010571f:	83 e8 80             	sub    $0xffffff80,%eax
80105722:	89 04 24             	mov    %eax,(%esp)
80105725:	e8 f0 07 00 00       	call   80105f1a <strlen>
8010572a:	89 45 f4             	mov    %eax,-0xc(%ebp)

                            memmove(buf, p->cmdline, size);
8010572d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105730:	8b 55 e8             	mov    -0x18(%ebp),%edx
80105733:	83 ea 80             	sub    $0xffffff80,%edx
80105736:	89 44 24 08          	mov    %eax,0x8(%esp)
8010573a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010573e:	8d 85 e4 fb ff ff    	lea    -0x41c(%ebp),%eax
80105744:	89 04 24             	mov    %eax,(%esp)
80105747:	e8 33 06 00 00       	call   80105d7f <memmove>

                            for (i =1 ; i < MAXARGS; i++){
8010574c:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
80105753:	e9 b1 00 00 00       	jmp    80105809 <procfsread+0x1de>
                            	if (p->args[i]){
80105758:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010575b:	6b c0 64             	imul   $0x64,%eax,%eax
8010575e:	8d 90 e0 00 00 00    	lea    0xe0(%eax),%edx
80105764:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105767:	01 d0                	add    %edx,%eax
80105769:	83 c0 04             	add    $0x4,%eax
8010576c:	85 c0                	test   %eax,%eax
8010576e:	0f 84 91 00 00 00    	je     80105805 <procfsread+0x1da>

                            		memmove(buf+size, " ", 1);
80105774:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105777:	8d 95 e4 fb ff ff    	lea    -0x41c(%ebp),%edx
8010577d:	01 d0                	add    %edx,%eax
8010577f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80105786:	00 
80105787:	c7 44 24 04 67 94 10 	movl   $0x80109467,0x4(%esp)
8010578e:	80 
8010578f:	89 04 24             	mov    %eax,(%esp)
80105792:	e8 e8 05 00 00       	call   80105d7f <memmove>
                            		size++ ;
80105797:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
                            		memmove(buf+size, p->args[i], strlen(p->args[i]));
8010579b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010579e:	6b c0 64             	imul   $0x64,%eax,%eax
801057a1:	8d 90 e0 00 00 00    	lea    0xe0(%eax),%edx
801057a7:	8b 45 e8             	mov    -0x18(%ebp),%eax
801057aa:	01 d0                	add    %edx,%eax
801057ac:	83 c0 04             	add    $0x4,%eax
801057af:	89 04 24             	mov    %eax,(%esp)
801057b2:	e8 63 07 00 00       	call   80105f1a <strlen>
801057b7:	8b 55 f0             	mov    -0x10(%ebp),%edx
801057ba:	6b d2 64             	imul   $0x64,%edx,%edx
801057bd:	8d 8a e0 00 00 00    	lea    0xe0(%edx),%ecx
801057c3:	8b 55 e8             	mov    -0x18(%ebp),%edx
801057c6:	01 ca                	add    %ecx,%edx
801057c8:	8d 4a 04             	lea    0x4(%edx),%ecx
801057cb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801057ce:	8d 9d e4 fb ff ff    	lea    -0x41c(%ebp),%ebx
801057d4:	01 da                	add    %ebx,%edx
801057d6:	89 44 24 08          	mov    %eax,0x8(%esp)
801057da:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801057de:	89 14 24             	mov    %edx,(%esp)
801057e1:	e8 99 05 00 00       	call   80105d7f <memmove>
                            		//cprintf("here %s \n",p->args[i]);
                            		size+= strlen(p->args[i]);
801057e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057e9:	6b c0 64             	imul   $0x64,%eax,%eax
801057ec:	8d 90 e0 00 00 00    	lea    0xe0(%eax),%edx
801057f2:	8b 45 e8             	mov    -0x18(%ebp),%eax
801057f5:	01 d0                	add    %edx,%eax
801057f7:	83 c0 04             	add    $0x4,%eax
801057fa:	89 04 24             	mov    %eax,(%esp)
801057fd:	e8 18 07 00 00       	call   80105f1a <strlen>
80105802:	01 45 f4             	add    %eax,-0xc(%ebp)
                            // cprintf("here p %d cmd %s\n", p->pid, p->cmdline);
                            size = strlen(p->cmdline);

                            memmove(buf, p->cmdline, size);

                            for (i =1 ; i < MAXARGS; i++){
80105805:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80105809:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
8010580d:	0f 8e 45 ff ff ff    	jle    80105758 <procfsread+0x12d>
                            		size+= strlen(p->args[i]);
                            	}
                            }

//                            size++;
							memmove(buf+size, "\n",1);
80105813:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105816:	8d 95 e4 fb ff ff    	lea    -0x41c(%ebp),%edx
8010581c:	01 d0                	add    %edx,%eax
8010581e:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80105825:	00 
80105826:	c7 44 24 04 69 94 10 	movl   $0x80109469,0x4(%esp)
8010582d:	80 
8010582e:	89 04 24             	mov    %eax,(%esp)
80105831:	e8 49 05 00 00       	call   80105d7f <memmove>
							size++;
80105836:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
                            break;
8010583a:	eb 34                	jmp    80105870 <procfsread+0x245>
              case CWD_DNUM:
                            size= readi(p->exe, (char*)&dst, off, sizeof(struct dirent));
8010583c:	8b 55 10             	mov    0x10(%ebp),%edx
8010583f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105842:	8b 40 7c             	mov    0x7c(%eax),%eax
80105845:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010584c:	00 
8010584d:	89 54 24 08          	mov    %edx,0x8(%esp)
80105851:	8d 55 0c             	lea    0xc(%ebp),%edx
80105854:	89 54 24 04          	mov    %edx,0x4(%esp)
80105858:	89 04 24             	mov    %eax,(%esp)
8010585b:	e8 ff c5 ff ff       	call   80101e5f <readi>
80105860:	89 45 f4             	mov    %eax,-0xc(%ebp)
                            // memmove(buf, (char*)&p->exe, size);
                            cprintf("Here \n");
80105863:	c7 04 24 6b 94 10 80 	movl   $0x8010946b,(%esp)
8010586a:	e8 31 ab ff ff       	call   801003a0 <cprintf>
                            break;
8010586f:	90                   	nop
              //               break; 

        }
    }

  if (off < size) {
80105870:	8b 45 10             	mov    0x10(%ebp),%eax
80105873:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80105876:	7d 40                	jge    801058b8 <procfsread+0x28d>
    int rr = size - off;
80105878:	8b 45 10             	mov    0x10(%ebp),%eax
8010587b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010587e:	29 c2                	sub    %eax,%edx
80105880:	89 d0                	mov    %edx,%eax
80105882:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    rr = rr < n ? rr : n;
80105885:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105888:	39 45 14             	cmp    %eax,0x14(%ebp)
8010588b:	0f 4e 45 14          	cmovle 0x14(%ebp),%eax
8010588f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    memmove(dst, buf + off, rr);
80105892:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80105895:	8b 45 10             	mov    0x10(%ebp),%eax
80105898:	8d 8d e4 fb ff ff    	lea    -0x41c(%ebp),%ecx
8010589e:	01 c1                	add    %eax,%ecx
801058a0:	8b 45 0c             	mov    0xc(%ebp),%eax
801058a3:	89 54 24 08          	mov    %edx,0x8(%esp)
801058a7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801058ab:	89 04 24             	mov    %eax,(%esp)
801058ae:	e8 cc 04 00 00       	call   80105d7f <memmove>
    return rr;
801058b3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801058b6:	eb 05                	jmp    801058bd <procfsread+0x292>
  }

  return 0;
801058b8:	b8 00 00 00 00       	mov    $0x0,%eax
}
801058bd:	81 c4 34 04 00 00    	add    $0x434,%esp
801058c3:	5b                   	pop    %ebx
801058c4:	5d                   	pop    %ebp
801058c5:	c3                   	ret    

801058c6 <procfswrite>:

int
procfswrite(struct inode *ip, char *buf, int n)
{
801058c6:	55                   	push   %ebp
801058c7:	89 e5                	mov    %esp,%ebp
  return 0;
801058c9:	b8 00 00 00 00       	mov    $0x0,%eax
}
801058ce:	5d                   	pop    %ebp
801058cf:	c3                   	ret    

801058d0 <procfsinit>:

void
procfsinit(void)
{
801058d0:	55                   	push   %ebp
801058d1:	89 e5                	mov    %esp,%ebp
  devsw[PROCFS].isdir = procfsisdir;
801058d3:	c7 05 00 22 11 80 0d 	movl   $0x8010520d,0x80112200
801058da:	52 10 80 
  devsw[PROCFS].iread = procfsiread;
801058dd:	c7 05 04 22 11 80 8e 	movl   $0x8010528e,0x80112204
801058e4:	52 10 80 
  devsw[PROCFS].write = procfswrite;
801058e7:	c7 05 0c 22 11 80 c6 	movl   $0x801058c6,0x8011220c
801058ee:	58 10 80 
  devsw[PROCFS].read = procfsread;
801058f1:	c7 05 08 22 11 80 2b 	movl   $0x8010562b,0x80112208
801058f8:	56 10 80 
}
801058fb:	5d                   	pop    %ebp
801058fc:	c3                   	ret    

801058fd <itoa>:


//receives an integer and set stringNum to its string representation
// return the number of charachters in string num;

int  itoa(int num , char *stringNum ){
801058fd:	55                   	push   %ebp
801058fe:	89 e5                	mov    %esp,%ebp
80105900:	83 ec 10             	sub    $0x10,%esp

  int i, rem, len = 0, n;
80105903:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

    n = num;
8010590a:	8b 45 08             	mov    0x8(%ebp),%eax
8010590d:	89 45 f4             	mov    %eax,-0xc(%ebp)
    while (n != 0)
80105910:	eb 1f                	jmp    80105931 <itoa+0x34>
    {
        len++;
80105912:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
        n /= 10;
80105916:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80105919:	ba 67 66 66 66       	mov    $0x66666667,%edx
8010591e:	89 c8                	mov    %ecx,%eax
80105920:	f7 ea                	imul   %edx
80105922:	c1 fa 02             	sar    $0x2,%edx
80105925:	89 c8                	mov    %ecx,%eax
80105927:	c1 f8 1f             	sar    $0x1f,%eax
8010592a:	29 c2                	sub    %eax,%edx
8010592c:	89 d0                	mov    %edx,%eax
8010592e:	89 45 f4             	mov    %eax,-0xc(%ebp)
int  itoa(int num , char *stringNum ){

  int i, rem, len = 0, n;

    n = num;
    while (n != 0)
80105931:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105935:	75 db                	jne    80105912 <itoa+0x15>
    {
        len++;
        n /= 10;
    }
    for (i = 0; i < len; i++)
80105937:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010593e:	eb 60                	jmp    801059a0 <itoa+0xa3>
    {
        rem = num % 10;
80105940:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105943:	ba 67 66 66 66       	mov    $0x66666667,%edx
80105948:	89 c8                	mov    %ecx,%eax
8010594a:	f7 ea                	imul   %edx
8010594c:	c1 fa 02             	sar    $0x2,%edx
8010594f:	89 c8                	mov    %ecx,%eax
80105951:	c1 f8 1f             	sar    $0x1f,%eax
80105954:	29 c2                	sub    %eax,%edx
80105956:	89 d0                	mov    %edx,%eax
80105958:	c1 e0 02             	shl    $0x2,%eax
8010595b:	01 d0                	add    %edx,%eax
8010595d:	01 c0                	add    %eax,%eax
8010595f:	29 c1                	sub    %eax,%ecx
80105961:	89 c8                	mov    %ecx,%eax
80105963:	89 45 f0             	mov    %eax,-0x10(%ebp)
        num = num / 10;
80105966:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105969:	ba 67 66 66 66       	mov    $0x66666667,%edx
8010596e:	89 c8                	mov    %ecx,%eax
80105970:	f7 ea                	imul   %edx
80105972:	c1 fa 02             	sar    $0x2,%edx
80105975:	89 c8                	mov    %ecx,%eax
80105977:	c1 f8 1f             	sar    $0x1f,%eax
8010597a:	29 c2                	sub    %eax,%edx
8010597c:	89 d0                	mov    %edx,%eax
8010597e:	89 45 08             	mov    %eax,0x8(%ebp)
        stringNum[len - (i + 1)] = rem + '0';
80105981:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105984:	f7 d0                	not    %eax
80105986:	89 c2                	mov    %eax,%edx
80105988:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010598b:	01 d0                	add    %edx,%eax
8010598d:	89 c2                	mov    %eax,%edx
8010598f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105992:	01 c2                	add    %eax,%edx
80105994:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105997:	83 c0 30             	add    $0x30,%eax
8010599a:	88 02                	mov    %al,(%edx)
    while (n != 0)
    {
        len++;
        n /= 10;
    }
    for (i = 0; i < len; i++)
8010599c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801059a0:	8b 45 fc             	mov    -0x4(%ebp),%eax
801059a3:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801059a6:	7c 98                	jl     80105940 <itoa+0x43>
    {
        rem = num % 10;
        num = num / 10;
        stringNum[len - (i + 1)] = rem + '0';
    }
    stringNum[len] = '\0';
801059a8:	8b 55 f8             	mov    -0x8(%ebp),%edx
801059ab:	8b 45 0c             	mov    0xc(%ebp),%eax
801059ae:	01 d0                	add    %edx,%eax
801059b0:	c6 00 00             	movb   $0x0,(%eax)
//    cprintf("%s %d \n", stringNum ,len);
    return len;
801059b3:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801059b6:	c9                   	leave  
801059b7:	c3                   	ret    

801059b8 <atoi>:

int atoi(const char *s)
{
801059b8:	55                   	push   %ebp
801059b9:	89 e5                	mov    %esp,%ebp
801059bb:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
801059be:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
801059c5:	eb 25                	jmp    801059ec <atoi+0x34>
    n = n*10 + *s++ - '0';
801059c7:	8b 55 fc             	mov    -0x4(%ebp),%edx
801059ca:	89 d0                	mov    %edx,%eax
801059cc:	c1 e0 02             	shl    $0x2,%eax
801059cf:	01 d0                	add    %edx,%eax
801059d1:	01 c0                	add    %eax,%eax
801059d3:	89 c1                	mov    %eax,%ecx
801059d5:	8b 45 08             	mov    0x8(%ebp),%eax
801059d8:	8d 50 01             	lea    0x1(%eax),%edx
801059db:	89 55 08             	mov    %edx,0x8(%ebp)
801059de:	0f b6 00             	movzbl (%eax),%eax
801059e1:	0f be c0             	movsbl %al,%eax
801059e4:	01 c8                	add    %ecx,%eax
801059e6:	83 e8 30             	sub    $0x30,%eax
801059e9:	89 45 fc             	mov    %eax,-0x4(%ebp)
int atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
801059ec:	8b 45 08             	mov    0x8(%ebp),%eax
801059ef:	0f b6 00             	movzbl (%eax),%eax
801059f2:	3c 2f                	cmp    $0x2f,%al
801059f4:	7e 0a                	jle    80105a00 <atoi+0x48>
801059f6:	8b 45 08             	mov    0x8(%ebp),%eax
801059f9:	0f b6 00             	movzbl (%eax),%eax
801059fc:	3c 39                	cmp    $0x39,%al
801059fe:	7e c7                	jle    801059c7 <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
80105a00:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105a03:	c9                   	leave  
80105a04:	c3                   	ret    

80105a05 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80105a05:	55                   	push   %ebp
80105a06:	89 e5                	mov    %esp,%ebp
80105a08:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80105a0b:	9c                   	pushf  
80105a0c:	58                   	pop    %eax
80105a0d:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80105a10:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105a13:	c9                   	leave  
80105a14:	c3                   	ret    

80105a15 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80105a15:	55                   	push   %ebp
80105a16:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80105a18:	fa                   	cli    
}
80105a19:	5d                   	pop    %ebp
80105a1a:	c3                   	ret    

80105a1b <sti>:

static inline void
sti(void)
{
80105a1b:	55                   	push   %ebp
80105a1c:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105a1e:	fb                   	sti    
}
80105a1f:	5d                   	pop    %ebp
80105a20:	c3                   	ret    

80105a21 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105a21:	55                   	push   %ebp
80105a22:	89 e5                	mov    %esp,%ebp
80105a24:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105a27:	8b 55 08             	mov    0x8(%ebp),%edx
80105a2a:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a2d:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105a30:	f0 87 02             	lock xchg %eax,(%edx)
80105a33:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80105a36:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105a39:	c9                   	leave  
80105a3a:	c3                   	ret    

80105a3b <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105a3b:	55                   	push   %ebp
80105a3c:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105a3e:	8b 45 08             	mov    0x8(%ebp),%eax
80105a41:	8b 55 0c             	mov    0xc(%ebp),%edx
80105a44:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80105a47:	8b 45 08             	mov    0x8(%ebp),%eax
80105a4a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105a50:	8b 45 08             	mov    0x8(%ebp),%eax
80105a53:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80105a5a:	5d                   	pop    %ebp
80105a5b:	c3                   	ret    

80105a5c <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80105a5c:	55                   	push   %ebp
80105a5d:	89 e5                	mov    %esp,%ebp
80105a5f:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80105a62:	e8 49 01 00 00       	call   80105bb0 <pushcli>
  if(holding(lk))
80105a67:	8b 45 08             	mov    0x8(%ebp),%eax
80105a6a:	89 04 24             	mov    %eax,(%esp)
80105a6d:	e8 14 01 00 00       	call   80105b86 <holding>
80105a72:	85 c0                	test   %eax,%eax
80105a74:	74 0c                	je     80105a82 <acquire+0x26>
    panic("acquire");
80105a76:	c7 04 24 72 94 10 80 	movl   $0x80109472,(%esp)
80105a7d:	e8 b8 aa ff ff       	call   8010053a <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105a82:	90                   	nop
80105a83:	8b 45 08             	mov    0x8(%ebp),%eax
80105a86:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105a8d:	00 
80105a8e:	89 04 24             	mov    %eax,(%esp)
80105a91:	e8 8b ff ff ff       	call   80105a21 <xchg>
80105a96:	85 c0                	test   %eax,%eax
80105a98:	75 e9                	jne    80105a83 <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80105a9a:	8b 45 08             	mov    0x8(%ebp),%eax
80105a9d:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105aa4:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105aa7:	8b 45 08             	mov    0x8(%ebp),%eax
80105aaa:	83 c0 0c             	add    $0xc,%eax
80105aad:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ab1:	8d 45 08             	lea    0x8(%ebp),%eax
80105ab4:	89 04 24             	mov    %eax,(%esp)
80105ab7:	e8 51 00 00 00       	call   80105b0d <getcallerpcs>
}
80105abc:	c9                   	leave  
80105abd:	c3                   	ret    

80105abe <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105abe:	55                   	push   %ebp
80105abf:	89 e5                	mov    %esp,%ebp
80105ac1:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105ac4:	8b 45 08             	mov    0x8(%ebp),%eax
80105ac7:	89 04 24             	mov    %eax,(%esp)
80105aca:	e8 b7 00 00 00       	call   80105b86 <holding>
80105acf:	85 c0                	test   %eax,%eax
80105ad1:	75 0c                	jne    80105adf <release+0x21>
    panic("release");
80105ad3:	c7 04 24 7a 94 10 80 	movl   $0x8010947a,(%esp)
80105ada:	e8 5b aa ff ff       	call   8010053a <panic>

  lk->pcs[0] = 0;
80105adf:	8b 45 08             	mov    0x8(%ebp),%eax
80105ae2:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105ae9:	8b 45 08             	mov    0x8(%ebp),%eax
80105aec:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105af3:	8b 45 08             	mov    0x8(%ebp),%eax
80105af6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105afd:	00 
80105afe:	89 04 24             	mov    %eax,(%esp)
80105b01:	e8 1b ff ff ff       	call   80105a21 <xchg>

  popcli();
80105b06:	e8 e9 00 00 00       	call   80105bf4 <popcli>
}
80105b0b:	c9                   	leave  
80105b0c:	c3                   	ret    

80105b0d <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105b0d:	55                   	push   %ebp
80105b0e:	89 e5                	mov    %esp,%ebp
80105b10:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80105b13:	8b 45 08             	mov    0x8(%ebp),%eax
80105b16:	83 e8 08             	sub    $0x8,%eax
80105b19:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105b1c:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105b23:	eb 38                	jmp    80105b5d <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105b25:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105b29:	74 38                	je     80105b63 <getcallerpcs+0x56>
80105b2b:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105b32:	76 2f                	jbe    80105b63 <getcallerpcs+0x56>
80105b34:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105b38:	74 29                	je     80105b63 <getcallerpcs+0x56>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105b3a:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105b3d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105b44:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b47:	01 c2                	add    %eax,%edx
80105b49:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105b4c:	8b 40 04             	mov    0x4(%eax),%eax
80105b4f:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
80105b51:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105b54:	8b 00                	mov    (%eax),%eax
80105b56:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105b59:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105b5d:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105b61:	7e c2                	jle    80105b25 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105b63:	eb 19                	jmp    80105b7e <getcallerpcs+0x71>
    pcs[i] = 0;
80105b65:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105b68:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105b6f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b72:	01 d0                	add    %edx,%eax
80105b74:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105b7a:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105b7e:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105b82:	7e e1                	jle    80105b65 <getcallerpcs+0x58>
    pcs[i] = 0;
}
80105b84:	c9                   	leave  
80105b85:	c3                   	ret    

80105b86 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105b86:	55                   	push   %ebp
80105b87:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105b89:	8b 45 08             	mov    0x8(%ebp),%eax
80105b8c:	8b 00                	mov    (%eax),%eax
80105b8e:	85 c0                	test   %eax,%eax
80105b90:	74 17                	je     80105ba9 <holding+0x23>
80105b92:	8b 45 08             	mov    0x8(%ebp),%eax
80105b95:	8b 50 08             	mov    0x8(%eax),%edx
80105b98:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105b9e:	39 c2                	cmp    %eax,%edx
80105ba0:	75 07                	jne    80105ba9 <holding+0x23>
80105ba2:	b8 01 00 00 00       	mov    $0x1,%eax
80105ba7:	eb 05                	jmp    80105bae <holding+0x28>
80105ba9:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105bae:	5d                   	pop    %ebp
80105baf:	c3                   	ret    

80105bb0 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105bb0:	55                   	push   %ebp
80105bb1:	89 e5                	mov    %esp,%ebp
80105bb3:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80105bb6:	e8 4a fe ff ff       	call   80105a05 <readeflags>
80105bbb:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105bbe:	e8 52 fe ff ff       	call   80105a15 <cli>
  if(cpu->ncli++ == 0)
80105bc3:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105bca:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
80105bd0:	8d 48 01             	lea    0x1(%eax),%ecx
80105bd3:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
80105bd9:	85 c0                	test   %eax,%eax
80105bdb:	75 15                	jne    80105bf2 <pushcli+0x42>
    cpu->intena = eflags & FL_IF;
80105bdd:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105be3:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105be6:	81 e2 00 02 00 00    	and    $0x200,%edx
80105bec:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105bf2:	c9                   	leave  
80105bf3:	c3                   	ret    

80105bf4 <popcli>:

void
popcli(void)
{
80105bf4:	55                   	push   %ebp
80105bf5:	89 e5                	mov    %esp,%ebp
80105bf7:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105bfa:	e8 06 fe ff ff       	call   80105a05 <readeflags>
80105bff:	25 00 02 00 00       	and    $0x200,%eax
80105c04:	85 c0                	test   %eax,%eax
80105c06:	74 0c                	je     80105c14 <popcli+0x20>
    panic("popcli - interruptible");
80105c08:	c7 04 24 82 94 10 80 	movl   $0x80109482,(%esp)
80105c0f:	e8 26 a9 ff ff       	call   8010053a <panic>
  if(--cpu->ncli < 0)
80105c14:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105c1a:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105c20:	83 ea 01             	sub    $0x1,%edx
80105c23:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105c29:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105c2f:	85 c0                	test   %eax,%eax
80105c31:	79 0c                	jns    80105c3f <popcli+0x4b>
    panic("popcli");
80105c33:	c7 04 24 99 94 10 80 	movl   $0x80109499,(%esp)
80105c3a:	e8 fb a8 ff ff       	call   8010053a <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105c3f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105c45:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105c4b:	85 c0                	test   %eax,%eax
80105c4d:	75 15                	jne    80105c64 <popcli+0x70>
80105c4f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105c55:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105c5b:	85 c0                	test   %eax,%eax
80105c5d:	74 05                	je     80105c64 <popcli+0x70>
    sti();
80105c5f:	e8 b7 fd ff ff       	call   80105a1b <sti>
}
80105c64:	c9                   	leave  
80105c65:	c3                   	ret    

80105c66 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80105c66:	55                   	push   %ebp
80105c67:	89 e5                	mov    %esp,%ebp
80105c69:	57                   	push   %edi
80105c6a:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105c6b:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105c6e:	8b 55 10             	mov    0x10(%ebp),%edx
80105c71:	8b 45 0c             	mov    0xc(%ebp),%eax
80105c74:	89 cb                	mov    %ecx,%ebx
80105c76:	89 df                	mov    %ebx,%edi
80105c78:	89 d1                	mov    %edx,%ecx
80105c7a:	fc                   	cld    
80105c7b:	f3 aa                	rep stos %al,%es:(%edi)
80105c7d:	89 ca                	mov    %ecx,%edx
80105c7f:	89 fb                	mov    %edi,%ebx
80105c81:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105c84:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105c87:	5b                   	pop    %ebx
80105c88:	5f                   	pop    %edi
80105c89:	5d                   	pop    %ebp
80105c8a:	c3                   	ret    

80105c8b <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105c8b:	55                   	push   %ebp
80105c8c:	89 e5                	mov    %esp,%ebp
80105c8e:	57                   	push   %edi
80105c8f:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80105c90:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105c93:	8b 55 10             	mov    0x10(%ebp),%edx
80105c96:	8b 45 0c             	mov    0xc(%ebp),%eax
80105c99:	89 cb                	mov    %ecx,%ebx
80105c9b:	89 df                	mov    %ebx,%edi
80105c9d:	89 d1                	mov    %edx,%ecx
80105c9f:	fc                   	cld    
80105ca0:	f3 ab                	rep stos %eax,%es:(%edi)
80105ca2:	89 ca                	mov    %ecx,%edx
80105ca4:	89 fb                	mov    %edi,%ebx
80105ca6:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105ca9:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105cac:	5b                   	pop    %ebx
80105cad:	5f                   	pop    %edi
80105cae:	5d                   	pop    %ebp
80105caf:	c3                   	ret    

80105cb0 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105cb0:	55                   	push   %ebp
80105cb1:	89 e5                	mov    %esp,%ebp
80105cb3:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105cb6:	8b 45 08             	mov    0x8(%ebp),%eax
80105cb9:	83 e0 03             	and    $0x3,%eax
80105cbc:	85 c0                	test   %eax,%eax
80105cbe:	75 49                	jne    80105d09 <memset+0x59>
80105cc0:	8b 45 10             	mov    0x10(%ebp),%eax
80105cc3:	83 e0 03             	and    $0x3,%eax
80105cc6:	85 c0                	test   %eax,%eax
80105cc8:	75 3f                	jne    80105d09 <memset+0x59>
    c &= 0xFF;
80105cca:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80105cd1:	8b 45 10             	mov    0x10(%ebp),%eax
80105cd4:	c1 e8 02             	shr    $0x2,%eax
80105cd7:	89 c2                	mov    %eax,%edx
80105cd9:	8b 45 0c             	mov    0xc(%ebp),%eax
80105cdc:	c1 e0 18             	shl    $0x18,%eax
80105cdf:	89 c1                	mov    %eax,%ecx
80105ce1:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ce4:	c1 e0 10             	shl    $0x10,%eax
80105ce7:	09 c1                	or     %eax,%ecx
80105ce9:	8b 45 0c             	mov    0xc(%ebp),%eax
80105cec:	c1 e0 08             	shl    $0x8,%eax
80105cef:	09 c8                	or     %ecx,%eax
80105cf1:	0b 45 0c             	or     0xc(%ebp),%eax
80105cf4:	89 54 24 08          	mov    %edx,0x8(%esp)
80105cf8:	89 44 24 04          	mov    %eax,0x4(%esp)
80105cfc:	8b 45 08             	mov    0x8(%ebp),%eax
80105cff:	89 04 24             	mov    %eax,(%esp)
80105d02:	e8 84 ff ff ff       	call   80105c8b <stosl>
80105d07:	eb 19                	jmp    80105d22 <memset+0x72>
  } else
    stosb(dst, c, n);
80105d09:	8b 45 10             	mov    0x10(%ebp),%eax
80105d0c:	89 44 24 08          	mov    %eax,0x8(%esp)
80105d10:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d13:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d17:	8b 45 08             	mov    0x8(%ebp),%eax
80105d1a:	89 04 24             	mov    %eax,(%esp)
80105d1d:	e8 44 ff ff ff       	call   80105c66 <stosb>
  return dst;
80105d22:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105d25:	c9                   	leave  
80105d26:	c3                   	ret    

80105d27 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105d27:	55                   	push   %ebp
80105d28:	89 e5                	mov    %esp,%ebp
80105d2a:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105d2d:	8b 45 08             	mov    0x8(%ebp),%eax
80105d30:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105d33:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d36:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105d39:	eb 30                	jmp    80105d6b <memcmp+0x44>
    if(*s1 != *s2)
80105d3b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d3e:	0f b6 10             	movzbl (%eax),%edx
80105d41:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105d44:	0f b6 00             	movzbl (%eax),%eax
80105d47:	38 c2                	cmp    %al,%dl
80105d49:	74 18                	je     80105d63 <memcmp+0x3c>
      return *s1 - *s2;
80105d4b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d4e:	0f b6 00             	movzbl (%eax),%eax
80105d51:	0f b6 d0             	movzbl %al,%edx
80105d54:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105d57:	0f b6 00             	movzbl (%eax),%eax
80105d5a:	0f b6 c0             	movzbl %al,%eax
80105d5d:	29 c2                	sub    %eax,%edx
80105d5f:	89 d0                	mov    %edx,%eax
80105d61:	eb 1a                	jmp    80105d7d <memcmp+0x56>
    s1++, s2++;
80105d63:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105d67:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105d6b:	8b 45 10             	mov    0x10(%ebp),%eax
80105d6e:	8d 50 ff             	lea    -0x1(%eax),%edx
80105d71:	89 55 10             	mov    %edx,0x10(%ebp)
80105d74:	85 c0                	test   %eax,%eax
80105d76:	75 c3                	jne    80105d3b <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105d78:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105d7d:	c9                   	leave  
80105d7e:	c3                   	ret    

80105d7f <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105d7f:	55                   	push   %ebp
80105d80:	89 e5                	mov    %esp,%ebp
80105d82:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105d85:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d88:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105d8b:	8b 45 08             	mov    0x8(%ebp),%eax
80105d8e:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105d91:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d94:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105d97:	73 3d                	jae    80105dd6 <memmove+0x57>
80105d99:	8b 45 10             	mov    0x10(%ebp),%eax
80105d9c:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105d9f:	01 d0                	add    %edx,%eax
80105da1:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105da4:	76 30                	jbe    80105dd6 <memmove+0x57>
    s += n;
80105da6:	8b 45 10             	mov    0x10(%ebp),%eax
80105da9:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80105dac:	8b 45 10             	mov    0x10(%ebp),%eax
80105daf:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105db2:	eb 13                	jmp    80105dc7 <memmove+0x48>
      *--d = *--s;
80105db4:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105db8:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80105dbc:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105dbf:	0f b6 10             	movzbl (%eax),%edx
80105dc2:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105dc5:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105dc7:	8b 45 10             	mov    0x10(%ebp),%eax
80105dca:	8d 50 ff             	lea    -0x1(%eax),%edx
80105dcd:	89 55 10             	mov    %edx,0x10(%ebp)
80105dd0:	85 c0                	test   %eax,%eax
80105dd2:	75 e0                	jne    80105db4 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105dd4:	eb 26                	jmp    80105dfc <memmove+0x7d>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105dd6:	eb 17                	jmp    80105def <memmove+0x70>
      *d++ = *s++;
80105dd8:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105ddb:	8d 50 01             	lea    0x1(%eax),%edx
80105dde:	89 55 f8             	mov    %edx,-0x8(%ebp)
80105de1:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105de4:	8d 4a 01             	lea    0x1(%edx),%ecx
80105de7:	89 4d fc             	mov    %ecx,-0x4(%ebp)
80105dea:	0f b6 12             	movzbl (%edx),%edx
80105ded:	88 10                	mov    %dl,(%eax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105def:	8b 45 10             	mov    0x10(%ebp),%eax
80105df2:	8d 50 ff             	lea    -0x1(%eax),%edx
80105df5:	89 55 10             	mov    %edx,0x10(%ebp)
80105df8:	85 c0                	test   %eax,%eax
80105dfa:	75 dc                	jne    80105dd8 <memmove+0x59>
      *d++ = *s++;

  return dst;
80105dfc:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105dff:	c9                   	leave  
80105e00:	c3                   	ret    

80105e01 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105e01:	55                   	push   %ebp
80105e02:	89 e5                	mov    %esp,%ebp
80105e04:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105e07:	8b 45 10             	mov    0x10(%ebp),%eax
80105e0a:	89 44 24 08          	mov    %eax,0x8(%esp)
80105e0e:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e11:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e15:	8b 45 08             	mov    0x8(%ebp),%eax
80105e18:	89 04 24             	mov    %eax,(%esp)
80105e1b:	e8 5f ff ff ff       	call   80105d7f <memmove>
}
80105e20:	c9                   	leave  
80105e21:	c3                   	ret    

80105e22 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105e22:	55                   	push   %ebp
80105e23:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105e25:	eb 0c                	jmp    80105e33 <strncmp+0x11>
    n--, p++, q++;
80105e27:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105e2b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105e2f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105e33:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105e37:	74 1a                	je     80105e53 <strncmp+0x31>
80105e39:	8b 45 08             	mov    0x8(%ebp),%eax
80105e3c:	0f b6 00             	movzbl (%eax),%eax
80105e3f:	84 c0                	test   %al,%al
80105e41:	74 10                	je     80105e53 <strncmp+0x31>
80105e43:	8b 45 08             	mov    0x8(%ebp),%eax
80105e46:	0f b6 10             	movzbl (%eax),%edx
80105e49:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e4c:	0f b6 00             	movzbl (%eax),%eax
80105e4f:	38 c2                	cmp    %al,%dl
80105e51:	74 d4                	je     80105e27 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105e53:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105e57:	75 07                	jne    80105e60 <strncmp+0x3e>
    return 0;
80105e59:	b8 00 00 00 00       	mov    $0x0,%eax
80105e5e:	eb 16                	jmp    80105e76 <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
80105e60:	8b 45 08             	mov    0x8(%ebp),%eax
80105e63:	0f b6 00             	movzbl (%eax),%eax
80105e66:	0f b6 d0             	movzbl %al,%edx
80105e69:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e6c:	0f b6 00             	movzbl (%eax),%eax
80105e6f:	0f b6 c0             	movzbl %al,%eax
80105e72:	29 c2                	sub    %eax,%edx
80105e74:	89 d0                	mov    %edx,%eax
}
80105e76:	5d                   	pop    %ebp
80105e77:	c3                   	ret    

80105e78 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105e78:	55                   	push   %ebp
80105e79:	89 e5                	mov    %esp,%ebp
80105e7b:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105e7e:	8b 45 08             	mov    0x8(%ebp),%eax
80105e81:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105e84:	90                   	nop
80105e85:	8b 45 10             	mov    0x10(%ebp),%eax
80105e88:	8d 50 ff             	lea    -0x1(%eax),%edx
80105e8b:	89 55 10             	mov    %edx,0x10(%ebp)
80105e8e:	85 c0                	test   %eax,%eax
80105e90:	7e 1e                	jle    80105eb0 <strncpy+0x38>
80105e92:	8b 45 08             	mov    0x8(%ebp),%eax
80105e95:	8d 50 01             	lea    0x1(%eax),%edx
80105e98:	89 55 08             	mov    %edx,0x8(%ebp)
80105e9b:	8b 55 0c             	mov    0xc(%ebp),%edx
80105e9e:	8d 4a 01             	lea    0x1(%edx),%ecx
80105ea1:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105ea4:	0f b6 12             	movzbl (%edx),%edx
80105ea7:	88 10                	mov    %dl,(%eax)
80105ea9:	0f b6 00             	movzbl (%eax),%eax
80105eac:	84 c0                	test   %al,%al
80105eae:	75 d5                	jne    80105e85 <strncpy+0xd>
    ;
  while(n-- > 0)
80105eb0:	eb 0c                	jmp    80105ebe <strncpy+0x46>
    *s++ = 0;
80105eb2:	8b 45 08             	mov    0x8(%ebp),%eax
80105eb5:	8d 50 01             	lea    0x1(%eax),%edx
80105eb8:	89 55 08             	mov    %edx,0x8(%ebp)
80105ebb:	c6 00 00             	movb   $0x0,(%eax)
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105ebe:	8b 45 10             	mov    0x10(%ebp),%eax
80105ec1:	8d 50 ff             	lea    -0x1(%eax),%edx
80105ec4:	89 55 10             	mov    %edx,0x10(%ebp)
80105ec7:	85 c0                	test   %eax,%eax
80105ec9:	7f e7                	jg     80105eb2 <strncpy+0x3a>
    *s++ = 0;
  return os;
80105ecb:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105ece:	c9                   	leave  
80105ecf:	c3                   	ret    

80105ed0 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80105ed0:	55                   	push   %ebp
80105ed1:	89 e5                	mov    %esp,%ebp
80105ed3:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105ed6:	8b 45 08             	mov    0x8(%ebp),%eax
80105ed9:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105edc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105ee0:	7f 05                	jg     80105ee7 <safestrcpy+0x17>
    return os;
80105ee2:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105ee5:	eb 31                	jmp    80105f18 <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
80105ee7:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105eeb:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105eef:	7e 1e                	jle    80105f0f <safestrcpy+0x3f>
80105ef1:	8b 45 08             	mov    0x8(%ebp),%eax
80105ef4:	8d 50 01             	lea    0x1(%eax),%edx
80105ef7:	89 55 08             	mov    %edx,0x8(%ebp)
80105efa:	8b 55 0c             	mov    0xc(%ebp),%edx
80105efd:	8d 4a 01             	lea    0x1(%edx),%ecx
80105f00:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105f03:	0f b6 12             	movzbl (%edx),%edx
80105f06:	88 10                	mov    %dl,(%eax)
80105f08:	0f b6 00             	movzbl (%eax),%eax
80105f0b:	84 c0                	test   %al,%al
80105f0d:	75 d8                	jne    80105ee7 <safestrcpy+0x17>
    ;
  *s = 0;
80105f0f:	8b 45 08             	mov    0x8(%ebp),%eax
80105f12:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105f15:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105f18:	c9                   	leave  
80105f19:	c3                   	ret    

80105f1a <strlen>:

int
strlen(const char *s)
{
80105f1a:	55                   	push   %ebp
80105f1b:	89 e5                	mov    %esp,%ebp
80105f1d:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105f20:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105f27:	eb 04                	jmp    80105f2d <strlen+0x13>
80105f29:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105f2d:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105f30:	8b 45 08             	mov    0x8(%ebp),%eax
80105f33:	01 d0                	add    %edx,%eax
80105f35:	0f b6 00             	movzbl (%eax),%eax
80105f38:	84 c0                	test   %al,%al
80105f3a:	75 ed                	jne    80105f29 <strlen+0xf>
    ;
  return n;
80105f3c:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105f3f:	c9                   	leave  
80105f40:	c3                   	ret    

80105f41 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105f41:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105f45:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105f49:	55                   	push   %ebp
  pushl %ebx
80105f4a:	53                   	push   %ebx
  pushl %esi
80105f4b:	56                   	push   %esi
  pushl %edi
80105f4c:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105f4d:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105f4f:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105f51:	5f                   	pop    %edi
  popl %esi
80105f52:	5e                   	pop    %esi
  popl %ebx
80105f53:	5b                   	pop    %ebx
  popl %ebp
80105f54:	5d                   	pop    %ebp
  ret
80105f55:	c3                   	ret    

80105f56 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80105f56:	55                   	push   %ebp
80105f57:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
80105f59:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f5f:	8b 00                	mov    (%eax),%eax
80105f61:	3b 45 08             	cmp    0x8(%ebp),%eax
80105f64:	76 12                	jbe    80105f78 <fetchint+0x22>
80105f66:	8b 45 08             	mov    0x8(%ebp),%eax
80105f69:	8d 50 04             	lea    0x4(%eax),%edx
80105f6c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f72:	8b 00                	mov    (%eax),%eax
80105f74:	39 c2                	cmp    %eax,%edx
80105f76:	76 07                	jbe    80105f7f <fetchint+0x29>
    return -1;
80105f78:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f7d:	eb 0f                	jmp    80105f8e <fetchint+0x38>
  *ip = *(int*)(addr);
80105f7f:	8b 45 08             	mov    0x8(%ebp),%eax
80105f82:	8b 10                	mov    (%eax),%edx
80105f84:	8b 45 0c             	mov    0xc(%ebp),%eax
80105f87:	89 10                	mov    %edx,(%eax)
  return 0;
80105f89:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105f8e:	5d                   	pop    %ebp
80105f8f:	c3                   	ret    

80105f90 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80105f90:	55                   	push   %ebp
80105f91:	89 e5                	mov    %esp,%ebp
80105f93:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
80105f96:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f9c:	8b 00                	mov    (%eax),%eax
80105f9e:	3b 45 08             	cmp    0x8(%ebp),%eax
80105fa1:	77 07                	ja     80105faa <fetchstr+0x1a>
    return -1;
80105fa3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fa8:	eb 46                	jmp    80105ff0 <fetchstr+0x60>
  *pp = (char*)addr;
80105faa:	8b 55 08             	mov    0x8(%ebp),%edx
80105fad:	8b 45 0c             	mov    0xc(%ebp),%eax
80105fb0:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
80105fb2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105fb8:	8b 00                	mov    (%eax),%eax
80105fba:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105fbd:	8b 45 0c             	mov    0xc(%ebp),%eax
80105fc0:	8b 00                	mov    (%eax),%eax
80105fc2:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105fc5:	eb 1c                	jmp    80105fe3 <fetchstr+0x53>
    if(*s == 0)
80105fc7:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105fca:	0f b6 00             	movzbl (%eax),%eax
80105fcd:	84 c0                	test   %al,%al
80105fcf:	75 0e                	jne    80105fdf <fetchstr+0x4f>
      return s - *pp;
80105fd1:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105fd4:	8b 45 0c             	mov    0xc(%ebp),%eax
80105fd7:	8b 00                	mov    (%eax),%eax
80105fd9:	29 c2                	sub    %eax,%edx
80105fdb:	89 d0                	mov    %edx,%eax
80105fdd:	eb 11                	jmp    80105ff0 <fetchstr+0x60>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
80105fdf:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105fe3:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105fe6:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105fe9:	72 dc                	jb     80105fc7 <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
80105feb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105ff0:	c9                   	leave  
80105ff1:	c3                   	ret    

80105ff2 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80105ff2:	55                   	push   %ebp
80105ff3:	89 e5                	mov    %esp,%ebp
80105ff5:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->tf->esp + 4 + 4*n, ip);
80105ff8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ffe:	8b 40 18             	mov    0x18(%eax),%eax
80106001:	8b 50 44             	mov    0x44(%eax),%edx
80106004:	8b 45 08             	mov    0x8(%ebp),%eax
80106007:	c1 e0 02             	shl    $0x2,%eax
8010600a:	01 d0                	add    %edx,%eax
8010600c:	8d 50 04             	lea    0x4(%eax),%edx
8010600f:	8b 45 0c             	mov    0xc(%ebp),%eax
80106012:	89 44 24 04          	mov    %eax,0x4(%esp)
80106016:	89 14 24             	mov    %edx,(%esp)
80106019:	e8 38 ff ff ff       	call   80105f56 <fetchint>
}
8010601e:	c9                   	leave  
8010601f:	c3                   	ret    

80106020 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80106020:	55                   	push   %ebp
80106021:	89 e5                	mov    %esp,%ebp
80106023:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80106026:	8d 45 fc             	lea    -0x4(%ebp),%eax
80106029:	89 44 24 04          	mov    %eax,0x4(%esp)
8010602d:	8b 45 08             	mov    0x8(%ebp),%eax
80106030:	89 04 24             	mov    %eax,(%esp)
80106033:	e8 ba ff ff ff       	call   80105ff2 <argint>
80106038:	85 c0                	test   %eax,%eax
8010603a:	79 07                	jns    80106043 <argptr+0x23>
    return -1;
8010603c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106041:	eb 3d                	jmp    80106080 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80106043:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106046:	89 c2                	mov    %eax,%edx
80106048:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010604e:	8b 00                	mov    (%eax),%eax
80106050:	39 c2                	cmp    %eax,%edx
80106052:	73 16                	jae    8010606a <argptr+0x4a>
80106054:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106057:	89 c2                	mov    %eax,%edx
80106059:	8b 45 10             	mov    0x10(%ebp),%eax
8010605c:	01 c2                	add    %eax,%edx
8010605e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106064:	8b 00                	mov    (%eax),%eax
80106066:	39 c2                	cmp    %eax,%edx
80106068:	76 07                	jbe    80106071 <argptr+0x51>
    return -1;
8010606a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010606f:	eb 0f                	jmp    80106080 <argptr+0x60>
  *pp = (char*)i;
80106071:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106074:	89 c2                	mov    %eax,%edx
80106076:	8b 45 0c             	mov    0xc(%ebp),%eax
80106079:	89 10                	mov    %edx,(%eax)
  return 0;
8010607b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106080:	c9                   	leave  
80106081:	c3                   	ret    

80106082 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80106082:	55                   	push   %ebp
80106083:	89 e5                	mov    %esp,%ebp
80106085:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
80106088:	8d 45 fc             	lea    -0x4(%ebp),%eax
8010608b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010608f:	8b 45 08             	mov    0x8(%ebp),%eax
80106092:	89 04 24             	mov    %eax,(%esp)
80106095:	e8 58 ff ff ff       	call   80105ff2 <argint>
8010609a:	85 c0                	test   %eax,%eax
8010609c:	79 07                	jns    801060a5 <argstr+0x23>
    return -1;
8010609e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060a3:	eb 12                	jmp    801060b7 <argstr+0x35>
  return fetchstr(addr, pp);
801060a5:	8b 45 fc             	mov    -0x4(%ebp),%eax
801060a8:	8b 55 0c             	mov    0xc(%ebp),%edx
801060ab:	89 54 24 04          	mov    %edx,0x4(%esp)
801060af:	89 04 24             	mov    %eax,(%esp)
801060b2:	e8 d9 fe ff ff       	call   80105f90 <fetchstr>
}
801060b7:	c9                   	leave  
801060b8:	c3                   	ret    

801060b9 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
801060b9:	55                   	push   %ebp
801060ba:	89 e5                	mov    %esp,%ebp
801060bc:	53                   	push   %ebx
801060bd:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
801060c0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801060c6:	8b 40 18             	mov    0x18(%eax),%eax
801060c9:	8b 40 1c             	mov    0x1c(%eax),%eax
801060cc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
801060cf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801060d3:	7e 30                	jle    80106105 <syscall+0x4c>
801060d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060d8:	83 f8 15             	cmp    $0x15,%eax
801060db:	77 28                	ja     80106105 <syscall+0x4c>
801060dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060e0:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
801060e7:	85 c0                	test   %eax,%eax
801060e9:	74 1a                	je     80106105 <syscall+0x4c>
    proc->tf->eax = syscalls[num]();
801060eb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801060f1:	8b 58 18             	mov    0x18(%eax),%ebx
801060f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060f7:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
801060fe:	ff d0                	call   *%eax
80106100:	89 43 1c             	mov    %eax,0x1c(%ebx)
80106103:	eb 3d                	jmp    80106142 <syscall+0x89>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80106105:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010610b:	8d 48 28             	lea    0x28(%eax),%ecx
8010610e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80106114:	8b 40 10             	mov    0x10(%eax),%eax
80106117:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010611a:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010611e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106122:	89 44 24 04          	mov    %eax,0x4(%esp)
80106126:	c7 04 24 a0 94 10 80 	movl   $0x801094a0,(%esp)
8010612d:	e8 6e a2 ff ff       	call   801003a0 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80106132:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106138:	8b 40 18             	mov    0x18(%eax),%eax
8010613b:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80106142:	83 c4 24             	add    $0x24,%esp
80106145:	5b                   	pop    %ebx
80106146:	5d                   	pop    %ebp
80106147:	c3                   	ret    

80106148 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80106148:	55                   	push   %ebp
80106149:	89 e5                	mov    %esp,%ebp
8010614b:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
8010614e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106151:	89 44 24 04          	mov    %eax,0x4(%esp)
80106155:	8b 45 08             	mov    0x8(%ebp),%eax
80106158:	89 04 24             	mov    %eax,(%esp)
8010615b:	e8 92 fe ff ff       	call   80105ff2 <argint>
80106160:	85 c0                	test   %eax,%eax
80106162:	79 07                	jns    8010616b <argfd+0x23>
    return -1;
80106164:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106169:	eb 50                	jmp    801061bb <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
8010616b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010616e:	85 c0                	test   %eax,%eax
80106170:	78 21                	js     80106193 <argfd+0x4b>
80106172:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106175:	83 f8 0f             	cmp    $0xf,%eax
80106178:	7f 19                	jg     80106193 <argfd+0x4b>
8010617a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106180:	8b 55 f0             	mov    -0x10(%ebp),%edx
80106183:	83 c2 0c             	add    $0xc,%edx
80106186:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010618a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010618d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106191:	75 07                	jne    8010619a <argfd+0x52>
    return -1;
80106193:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106198:	eb 21                	jmp    801061bb <argfd+0x73>
  if(pfd)
8010619a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010619e:	74 08                	je     801061a8 <argfd+0x60>
    *pfd = fd;
801061a0:	8b 55 f0             	mov    -0x10(%ebp),%edx
801061a3:	8b 45 0c             	mov    0xc(%ebp),%eax
801061a6:	89 10                	mov    %edx,(%eax)
  if(pf)
801061a8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801061ac:	74 08                	je     801061b6 <argfd+0x6e>
    *pf = f;
801061ae:	8b 45 10             	mov    0x10(%ebp),%eax
801061b1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801061b4:	89 10                	mov    %edx,(%eax)
  return 0;
801061b6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801061bb:	c9                   	leave  
801061bc:	c3                   	ret    

801061bd <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801061bd:	55                   	push   %ebp
801061be:	89 e5                	mov    %esp,%ebp
801061c0:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801061c3:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801061ca:	eb 30                	jmp    801061fc <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
801061cc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801061d2:	8b 55 fc             	mov    -0x4(%ebp),%edx
801061d5:	83 c2 0c             	add    $0xc,%edx
801061d8:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801061dc:	85 c0                	test   %eax,%eax
801061de:	75 18                	jne    801061f8 <fdalloc+0x3b>
      proc->ofile[fd] = f;
801061e0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801061e6:	8b 55 fc             	mov    -0x4(%ebp),%edx
801061e9:	8d 4a 0c             	lea    0xc(%edx),%ecx
801061ec:	8b 55 08             	mov    0x8(%ebp),%edx
801061ef:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
801061f3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801061f6:	eb 0f                	jmp    80106207 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801061f8:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801061fc:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80106200:	7e ca                	jle    801061cc <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80106202:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106207:	c9                   	leave  
80106208:	c3                   	ret    

80106209 <sys_dup>:

int
sys_dup(void)
{
80106209:	55                   	push   %ebp
8010620a:	89 e5                	mov    %esp,%ebp
8010620c:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
8010620f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106212:	89 44 24 08          	mov    %eax,0x8(%esp)
80106216:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010621d:	00 
8010621e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106225:	e8 1e ff ff ff       	call   80106148 <argfd>
8010622a:	85 c0                	test   %eax,%eax
8010622c:	79 07                	jns    80106235 <sys_dup+0x2c>
    return -1;
8010622e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106233:	eb 29                	jmp    8010625e <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80106235:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106238:	89 04 24             	mov    %eax,(%esp)
8010623b:	e8 7d ff ff ff       	call   801061bd <fdalloc>
80106240:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106243:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106247:	79 07                	jns    80106250 <sys_dup+0x47>
    return -1;
80106249:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010624e:	eb 0e                	jmp    8010625e <sys_dup+0x55>
  filedup(f);
80106250:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106253:	89 04 24             	mov    %eax,(%esp)
80106256:	e8 22 ae ff ff       	call   8010107d <filedup>
  return fd;
8010625b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010625e:	c9                   	leave  
8010625f:	c3                   	ret    

80106260 <sys_read>:

int
sys_read(void)
{
80106260:	55                   	push   %ebp
80106261:	89 e5                	mov    %esp,%ebp
80106263:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80106266:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106269:	89 44 24 08          	mov    %eax,0x8(%esp)
8010626d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106274:	00 
80106275:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010627c:	e8 c7 fe ff ff       	call   80106148 <argfd>
80106281:	85 c0                	test   %eax,%eax
80106283:	78 35                	js     801062ba <sys_read+0x5a>
80106285:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106288:	89 44 24 04          	mov    %eax,0x4(%esp)
8010628c:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106293:	e8 5a fd ff ff       	call   80105ff2 <argint>
80106298:	85 c0                	test   %eax,%eax
8010629a:	78 1e                	js     801062ba <sys_read+0x5a>
8010629c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010629f:	89 44 24 08          	mov    %eax,0x8(%esp)
801062a3:	8d 45 ec             	lea    -0x14(%ebp),%eax
801062a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801062aa:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801062b1:	e8 6a fd ff ff       	call   80106020 <argptr>
801062b6:	85 c0                	test   %eax,%eax
801062b8:	79 07                	jns    801062c1 <sys_read+0x61>
    return -1;
801062ba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062bf:	eb 19                	jmp    801062da <sys_read+0x7a>
  return fileread(f, p, n);
801062c1:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801062c4:	8b 55 ec             	mov    -0x14(%ebp),%edx
801062c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062ca:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801062ce:	89 54 24 04          	mov    %edx,0x4(%esp)
801062d2:	89 04 24             	mov    %eax,(%esp)
801062d5:	e8 10 af ff ff       	call   801011ea <fileread>
}
801062da:	c9                   	leave  
801062db:	c3                   	ret    

801062dc <sys_write>:

int
sys_write(void)
{
801062dc:	55                   	push   %ebp
801062dd:	89 e5                	mov    %esp,%ebp
801062df:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801062e2:	8d 45 f4             	lea    -0xc(%ebp),%eax
801062e5:	89 44 24 08          	mov    %eax,0x8(%esp)
801062e9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801062f0:	00 
801062f1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801062f8:	e8 4b fe ff ff       	call   80106148 <argfd>
801062fd:	85 c0                	test   %eax,%eax
801062ff:	78 35                	js     80106336 <sys_write+0x5a>
80106301:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106304:	89 44 24 04          	mov    %eax,0x4(%esp)
80106308:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010630f:	e8 de fc ff ff       	call   80105ff2 <argint>
80106314:	85 c0                	test   %eax,%eax
80106316:	78 1e                	js     80106336 <sys_write+0x5a>
80106318:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010631b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010631f:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106322:	89 44 24 04          	mov    %eax,0x4(%esp)
80106326:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010632d:	e8 ee fc ff ff       	call   80106020 <argptr>
80106332:	85 c0                	test   %eax,%eax
80106334:	79 07                	jns    8010633d <sys_write+0x61>
    return -1;
80106336:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010633b:	eb 19                	jmp    80106356 <sys_write+0x7a>
  return filewrite(f, p, n);
8010633d:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106340:	8b 55 ec             	mov    -0x14(%ebp),%edx
80106343:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106346:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010634a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010634e:	89 04 24             	mov    %eax,(%esp)
80106351:	e8 50 af ff ff       	call   801012a6 <filewrite>
}
80106356:	c9                   	leave  
80106357:	c3                   	ret    

80106358 <sys_close>:

int
sys_close(void)
{
80106358:	55                   	push   %ebp
80106359:	89 e5                	mov    %esp,%ebp
8010635b:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
8010635e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106361:	89 44 24 08          	mov    %eax,0x8(%esp)
80106365:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106368:	89 44 24 04          	mov    %eax,0x4(%esp)
8010636c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106373:	e8 d0 fd ff ff       	call   80106148 <argfd>
80106378:	85 c0                	test   %eax,%eax
8010637a:	79 07                	jns    80106383 <sys_close+0x2b>
    return -1;
8010637c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106381:	eb 24                	jmp    801063a7 <sys_close+0x4f>
  proc->ofile[fd] = 0;
80106383:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106389:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010638c:	83 c2 0c             	add    $0xc,%edx
8010638f:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106396:	00 
  fileclose(f);
80106397:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010639a:	89 04 24             	mov    %eax,(%esp)
8010639d:	e8 23 ad ff ff       	call   801010c5 <fileclose>
  return 0;
801063a2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801063a7:	c9                   	leave  
801063a8:	c3                   	ret    

801063a9 <sys_fstat>:

int
sys_fstat(void)
{
801063a9:	55                   	push   %ebp
801063aa:	89 e5                	mov    %esp,%ebp
801063ac:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801063af:	8d 45 f4             	lea    -0xc(%ebp),%eax
801063b2:	89 44 24 08          	mov    %eax,0x8(%esp)
801063b6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801063bd:	00 
801063be:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801063c5:	e8 7e fd ff ff       	call   80106148 <argfd>
801063ca:	85 c0                	test   %eax,%eax
801063cc:	78 1f                	js     801063ed <sys_fstat+0x44>
801063ce:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801063d5:	00 
801063d6:	8d 45 f0             	lea    -0x10(%ebp),%eax
801063d9:	89 44 24 04          	mov    %eax,0x4(%esp)
801063dd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801063e4:	e8 37 fc ff ff       	call   80106020 <argptr>
801063e9:	85 c0                	test   %eax,%eax
801063eb:	79 07                	jns    801063f4 <sys_fstat+0x4b>
    return -1;
801063ed:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063f2:	eb 12                	jmp    80106406 <sys_fstat+0x5d>
  return filestat(f, st);
801063f4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801063f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063fa:	89 54 24 04          	mov    %edx,0x4(%esp)
801063fe:	89 04 24             	mov    %eax,(%esp)
80106401:	e8 95 ad ff ff       	call   8010119b <filestat>
}
80106406:	c9                   	leave  
80106407:	c3                   	ret    

80106408 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80106408:	55                   	push   %ebp
80106409:	89 e5                	mov    %esp,%ebp
8010640b:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
8010640e:	8d 45 d8             	lea    -0x28(%ebp),%eax
80106411:	89 44 24 04          	mov    %eax,0x4(%esp)
80106415:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010641c:	e8 61 fc ff ff       	call   80106082 <argstr>
80106421:	85 c0                	test   %eax,%eax
80106423:	78 17                	js     8010643c <sys_link+0x34>
80106425:	8d 45 dc             	lea    -0x24(%ebp),%eax
80106428:	89 44 24 04          	mov    %eax,0x4(%esp)
8010642c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106433:	e8 4a fc ff ff       	call   80106082 <argstr>
80106438:	85 c0                	test   %eax,%eax
8010643a:	79 0a                	jns    80106446 <sys_link+0x3e>
    return -1;
8010643c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106441:	e9 42 01 00 00       	jmp    80106588 <sys_link+0x180>

  begin_op();
80106446:	e8 d7 d1 ff ff       	call   80103622 <begin_op>
  if((ip = namei(old)) == 0){
8010644b:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010644e:	89 04 24             	mov    %eax,(%esp)
80106451:	e8 c2 c1 ff ff       	call   80102618 <namei>
80106456:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106459:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010645d:	75 0f                	jne    8010646e <sys_link+0x66>
    end_op();
8010645f:	e8 42 d2 ff ff       	call   801036a6 <end_op>
    return -1;
80106464:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106469:	e9 1a 01 00 00       	jmp    80106588 <sys_link+0x180>
  }

  ilock(ip);
8010646e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106471:	89 04 24             	mov    %eax,(%esp)
80106474:	e8 d9 b4 ff ff       	call   80101952 <ilock>
  if(ip->type == T_DIR){
80106479:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010647c:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106480:	66 83 f8 01          	cmp    $0x1,%ax
80106484:	75 1a                	jne    801064a0 <sys_link+0x98>
    iunlockput(ip);
80106486:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106489:	89 04 24             	mov    %eax,(%esp)
8010648c:	e8 45 b7 ff ff       	call   80101bd6 <iunlockput>
    end_op();
80106491:	e8 10 d2 ff ff       	call   801036a6 <end_op>
    return -1;
80106496:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010649b:	e9 e8 00 00 00       	jmp    80106588 <sys_link+0x180>
  }

  ip->nlink++;
801064a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064a3:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801064a7:	8d 50 01             	lea    0x1(%eax),%edx
801064aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064ad:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801064b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064b4:	89 04 24             	mov    %eax,(%esp)
801064b7:	e8 da b2 ff ff       	call   80101796 <iupdate>
  iunlock(ip);
801064bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064bf:	89 04 24             	mov    %eax,(%esp)
801064c2:	e8 d9 b5 ff ff       	call   80101aa0 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
801064c7:	8b 45 dc             	mov    -0x24(%ebp),%eax
801064ca:	8d 55 e2             	lea    -0x1e(%ebp),%edx
801064cd:	89 54 24 04          	mov    %edx,0x4(%esp)
801064d1:	89 04 24             	mov    %eax,(%esp)
801064d4:	e8 61 c1 ff ff       	call   8010263a <nameiparent>
801064d9:	89 45 f0             	mov    %eax,-0x10(%ebp)
801064dc:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801064e0:	75 02                	jne    801064e4 <sys_link+0xdc>
    goto bad;
801064e2:	eb 68                	jmp    8010654c <sys_link+0x144>
  ilock(dp);
801064e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064e7:	89 04 24             	mov    %eax,(%esp)
801064ea:	e8 63 b4 ff ff       	call   80101952 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801064ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064f2:	8b 10                	mov    (%eax),%edx
801064f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064f7:	8b 00                	mov    (%eax),%eax
801064f9:	39 c2                	cmp    %eax,%edx
801064fb:	75 20                	jne    8010651d <sys_link+0x115>
801064fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106500:	8b 40 04             	mov    0x4(%eax),%eax
80106503:	89 44 24 08          	mov    %eax,0x8(%esp)
80106507:	8d 45 e2             	lea    -0x1e(%ebp),%eax
8010650a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010650e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106511:	89 04 24             	mov    %eax,(%esp)
80106514:	e8 fe bd ff ff       	call   80102317 <dirlink>
80106519:	85 c0                	test   %eax,%eax
8010651b:	79 0d                	jns    8010652a <sys_link+0x122>
    iunlockput(dp);
8010651d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106520:	89 04 24             	mov    %eax,(%esp)
80106523:	e8 ae b6 ff ff       	call   80101bd6 <iunlockput>
    goto bad;
80106528:	eb 22                	jmp    8010654c <sys_link+0x144>
  }
  iunlockput(dp);
8010652a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010652d:	89 04 24             	mov    %eax,(%esp)
80106530:	e8 a1 b6 ff ff       	call   80101bd6 <iunlockput>
  iput(ip);
80106535:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106538:	89 04 24             	mov    %eax,(%esp)
8010653b:	e8 c5 b5 ff ff       	call   80101b05 <iput>

  end_op();
80106540:	e8 61 d1 ff ff       	call   801036a6 <end_op>

  return 0;
80106545:	b8 00 00 00 00       	mov    $0x0,%eax
8010654a:	eb 3c                	jmp    80106588 <sys_link+0x180>

bad:
  ilock(ip);
8010654c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010654f:	89 04 24             	mov    %eax,(%esp)
80106552:	e8 fb b3 ff ff       	call   80101952 <ilock>
  ip->nlink--;
80106557:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010655a:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010655e:	8d 50 ff             	lea    -0x1(%eax),%edx
80106561:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106564:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106568:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010656b:	89 04 24             	mov    %eax,(%esp)
8010656e:	e8 23 b2 ff ff       	call   80101796 <iupdate>
  iunlockput(ip);
80106573:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106576:	89 04 24             	mov    %eax,(%esp)
80106579:	e8 58 b6 ff ff       	call   80101bd6 <iunlockput>
  end_op();
8010657e:	e8 23 d1 ff ff       	call   801036a6 <end_op>
  return -1;
80106583:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106588:	c9                   	leave  
80106589:	c3                   	ret    

8010658a <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
8010658a:	55                   	push   %ebp
8010658b:	89 e5                	mov    %esp,%ebp
8010658d:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106590:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80106597:	eb 4b                	jmp    801065e4 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106599:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010659c:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801065a3:	00 
801065a4:	89 44 24 08          	mov    %eax,0x8(%esp)
801065a8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801065ab:	89 44 24 04          	mov    %eax,0x4(%esp)
801065af:	8b 45 08             	mov    0x8(%ebp),%eax
801065b2:	89 04 24             	mov    %eax,(%esp)
801065b5:	e8 a5 b8 ff ff       	call   80101e5f <readi>
801065ba:	83 f8 10             	cmp    $0x10,%eax
801065bd:	74 0c                	je     801065cb <isdirempty+0x41>
      panic("isdirempty: readi");
801065bf:	c7 04 24 bc 94 10 80 	movl   $0x801094bc,(%esp)
801065c6:	e8 6f 9f ff ff       	call   8010053a <panic>
    if(de.inum != 0)
801065cb:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
801065cf:	66 85 c0             	test   %ax,%ax
801065d2:	74 07                	je     801065db <isdirempty+0x51>
      return 0;
801065d4:	b8 00 00 00 00       	mov    $0x0,%eax
801065d9:	eb 1b                	jmp    801065f6 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801065db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065de:	83 c0 10             	add    $0x10,%eax
801065e1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801065e4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801065e7:	8b 45 08             	mov    0x8(%ebp),%eax
801065ea:	8b 40 18             	mov    0x18(%eax),%eax
801065ed:	39 c2                	cmp    %eax,%edx
801065ef:	72 a8                	jb     80106599 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
801065f1:	b8 01 00 00 00       	mov    $0x1,%eax
}
801065f6:	c9                   	leave  
801065f7:	c3                   	ret    

801065f8 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
801065f8:	55                   	push   %ebp
801065f9:	89 e5                	mov    %esp,%ebp
801065fb:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
801065fe:	8d 45 cc             	lea    -0x34(%ebp),%eax
80106601:	89 44 24 04          	mov    %eax,0x4(%esp)
80106605:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010660c:	e8 71 fa ff ff       	call   80106082 <argstr>
80106611:	85 c0                	test   %eax,%eax
80106613:	79 0a                	jns    8010661f <sys_unlink+0x27>
    return -1;
80106615:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010661a:	e9 af 01 00 00       	jmp    801067ce <sys_unlink+0x1d6>

  begin_op();
8010661f:	e8 fe cf ff ff       	call   80103622 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80106624:	8b 45 cc             	mov    -0x34(%ebp),%eax
80106627:	8d 55 d2             	lea    -0x2e(%ebp),%edx
8010662a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010662e:	89 04 24             	mov    %eax,(%esp)
80106631:	e8 04 c0 ff ff       	call   8010263a <nameiparent>
80106636:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106639:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010663d:	75 0f                	jne    8010664e <sys_unlink+0x56>
    end_op();
8010663f:	e8 62 d0 ff ff       	call   801036a6 <end_op>
    return -1;
80106644:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106649:	e9 80 01 00 00       	jmp    801067ce <sys_unlink+0x1d6>
  }

  ilock(dp);
8010664e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106651:	89 04 24             	mov    %eax,(%esp)
80106654:	e8 f9 b2 ff ff       	call   80101952 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80106659:	c7 44 24 04 ce 94 10 	movl   $0x801094ce,0x4(%esp)
80106660:	80 
80106661:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106664:	89 04 24             	mov    %eax,(%esp)
80106667:	e8 f9 ba ff ff       	call   80102165 <namecmp>
8010666c:	85 c0                	test   %eax,%eax
8010666e:	0f 84 45 01 00 00    	je     801067b9 <sys_unlink+0x1c1>
80106674:	c7 44 24 04 d0 94 10 	movl   $0x801094d0,0x4(%esp)
8010667b:	80 
8010667c:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010667f:	89 04 24             	mov    %eax,(%esp)
80106682:	e8 de ba ff ff       	call   80102165 <namecmp>
80106687:	85 c0                	test   %eax,%eax
80106689:	0f 84 2a 01 00 00    	je     801067b9 <sys_unlink+0x1c1>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
8010668f:	8d 45 c8             	lea    -0x38(%ebp),%eax
80106692:	89 44 24 08          	mov    %eax,0x8(%esp)
80106696:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106699:	89 44 24 04          	mov    %eax,0x4(%esp)
8010669d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066a0:	89 04 24             	mov    %eax,(%esp)
801066a3:	e8 df ba ff ff       	call   80102187 <dirlookup>
801066a8:	89 45 f0             	mov    %eax,-0x10(%ebp)
801066ab:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801066af:	75 05                	jne    801066b6 <sys_unlink+0xbe>
    goto bad;
801066b1:	e9 03 01 00 00       	jmp    801067b9 <sys_unlink+0x1c1>
  ilock(ip);
801066b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066b9:	89 04 24             	mov    %eax,(%esp)
801066bc:	e8 91 b2 ff ff       	call   80101952 <ilock>

  if(ip->nlink < 1)
801066c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066c4:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801066c8:	66 85 c0             	test   %ax,%ax
801066cb:	7f 0c                	jg     801066d9 <sys_unlink+0xe1>
    panic("unlink: nlink < 1");
801066cd:	c7 04 24 d3 94 10 80 	movl   $0x801094d3,(%esp)
801066d4:	e8 61 9e ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
801066d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066dc:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801066e0:	66 83 f8 01          	cmp    $0x1,%ax
801066e4:	75 1f                	jne    80106705 <sys_unlink+0x10d>
801066e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066e9:	89 04 24             	mov    %eax,(%esp)
801066ec:	e8 99 fe ff ff       	call   8010658a <isdirempty>
801066f1:	85 c0                	test   %eax,%eax
801066f3:	75 10                	jne    80106705 <sys_unlink+0x10d>
    iunlockput(ip);
801066f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066f8:	89 04 24             	mov    %eax,(%esp)
801066fb:	e8 d6 b4 ff ff       	call   80101bd6 <iunlockput>
    goto bad;
80106700:	e9 b4 00 00 00       	jmp    801067b9 <sys_unlink+0x1c1>
  }

  memset(&de, 0, sizeof(de));
80106705:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010670c:	00 
8010670d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106714:	00 
80106715:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106718:	89 04 24             	mov    %eax,(%esp)
8010671b:	e8 90 f5 ff ff       	call   80105cb0 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106720:	8b 45 c8             	mov    -0x38(%ebp),%eax
80106723:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010672a:	00 
8010672b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010672f:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106732:	89 44 24 04          	mov    %eax,0x4(%esp)
80106736:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106739:	89 04 24             	mov    %eax,(%esp)
8010673c:	e8 8f b8 ff ff       	call   80101fd0 <writei>
80106741:	83 f8 10             	cmp    $0x10,%eax
80106744:	74 0c                	je     80106752 <sys_unlink+0x15a>
    panic("unlink: writei");
80106746:	c7 04 24 e5 94 10 80 	movl   $0x801094e5,(%esp)
8010674d:	e8 e8 9d ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR){
80106752:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106755:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106759:	66 83 f8 01          	cmp    $0x1,%ax
8010675d:	75 1c                	jne    8010677b <sys_unlink+0x183>
    dp->nlink--;
8010675f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106762:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106766:	8d 50 ff             	lea    -0x1(%eax),%edx
80106769:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010676c:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106770:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106773:	89 04 24             	mov    %eax,(%esp)
80106776:	e8 1b b0 ff ff       	call   80101796 <iupdate>
  }
  iunlockput(dp);
8010677b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010677e:	89 04 24             	mov    %eax,(%esp)
80106781:	e8 50 b4 ff ff       	call   80101bd6 <iunlockput>

  ip->nlink--;
80106786:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106789:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010678d:	8d 50 ff             	lea    -0x1(%eax),%edx
80106790:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106793:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106797:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010679a:	89 04 24             	mov    %eax,(%esp)
8010679d:	e8 f4 af ff ff       	call   80101796 <iupdate>
  iunlockput(ip);
801067a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067a5:	89 04 24             	mov    %eax,(%esp)
801067a8:	e8 29 b4 ff ff       	call   80101bd6 <iunlockput>

  end_op();
801067ad:	e8 f4 ce ff ff       	call   801036a6 <end_op>

  return 0;
801067b2:	b8 00 00 00 00       	mov    $0x0,%eax
801067b7:	eb 15                	jmp    801067ce <sys_unlink+0x1d6>

bad:
  iunlockput(dp);
801067b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067bc:	89 04 24             	mov    %eax,(%esp)
801067bf:	e8 12 b4 ff ff       	call   80101bd6 <iunlockput>
  end_op();
801067c4:	e8 dd ce ff ff       	call   801036a6 <end_op>
  return -1;
801067c9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801067ce:	c9                   	leave  
801067cf:	c3                   	ret    

801067d0 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
801067d0:	55                   	push   %ebp
801067d1:	89 e5                	mov    %esp,%ebp
801067d3:	83 ec 48             	sub    $0x48,%esp
801067d6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801067d9:	8b 55 10             	mov    0x10(%ebp),%edx
801067dc:	8b 45 14             	mov    0x14(%ebp),%eax
801067df:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
801067e3:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
801067e7:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
801067eb:	8d 45 de             	lea    -0x22(%ebp),%eax
801067ee:	89 44 24 04          	mov    %eax,0x4(%esp)
801067f2:	8b 45 08             	mov    0x8(%ebp),%eax
801067f5:	89 04 24             	mov    %eax,(%esp)
801067f8:	e8 3d be ff ff       	call   8010263a <nameiparent>
801067fd:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106800:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106804:	75 0a                	jne    80106810 <create+0x40>
    return 0;
80106806:	b8 00 00 00 00       	mov    $0x0,%eax
8010680b:	e9 a0 01 00 00       	jmp    801069b0 <create+0x1e0>
  ilock(dp);
80106810:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106813:	89 04 24             	mov    %eax,(%esp)
80106816:	e8 37 b1 ff ff       	call   80101952 <ilock>

  if (dp->type == T_DEV) {
8010681b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010681e:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106822:	66 83 f8 03          	cmp    $0x3,%ax
80106826:	75 15                	jne    8010683d <create+0x6d>
    iunlockput(dp);
80106828:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010682b:	89 04 24             	mov    %eax,(%esp)
8010682e:	e8 a3 b3 ff ff       	call   80101bd6 <iunlockput>
    return 0;
80106833:	b8 00 00 00 00       	mov    $0x0,%eax
80106838:	e9 73 01 00 00       	jmp    801069b0 <create+0x1e0>
  }

  if((ip = dirlookup(dp, name, &off)) != 0){
8010683d:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106840:	89 44 24 08          	mov    %eax,0x8(%esp)
80106844:	8d 45 de             	lea    -0x22(%ebp),%eax
80106847:	89 44 24 04          	mov    %eax,0x4(%esp)
8010684b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010684e:	89 04 24             	mov    %eax,(%esp)
80106851:	e8 31 b9 ff ff       	call   80102187 <dirlookup>
80106856:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106859:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010685d:	74 47                	je     801068a6 <create+0xd6>
    iunlockput(dp);
8010685f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106862:	89 04 24             	mov    %eax,(%esp)
80106865:	e8 6c b3 ff ff       	call   80101bd6 <iunlockput>
    ilock(ip);
8010686a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010686d:	89 04 24             	mov    %eax,(%esp)
80106870:	e8 dd b0 ff ff       	call   80101952 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80106875:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
8010687a:	75 15                	jne    80106891 <create+0xc1>
8010687c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010687f:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106883:	66 83 f8 02          	cmp    $0x2,%ax
80106887:	75 08                	jne    80106891 <create+0xc1>
      return ip;
80106889:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010688c:	e9 1f 01 00 00       	jmp    801069b0 <create+0x1e0>
    iunlockput(ip);
80106891:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106894:	89 04 24             	mov    %eax,(%esp)
80106897:	e8 3a b3 ff ff       	call   80101bd6 <iunlockput>
    return 0;
8010689c:	b8 00 00 00 00       	mov    $0x0,%eax
801068a1:	e9 0a 01 00 00       	jmp    801069b0 <create+0x1e0>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
801068a6:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
801068aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068ad:	8b 00                	mov    (%eax),%eax
801068af:	89 54 24 04          	mov    %edx,0x4(%esp)
801068b3:	89 04 24             	mov    %eax,(%esp)
801068b6:	e8 fc ad ff ff       	call   801016b7 <ialloc>
801068bb:	89 45 f0             	mov    %eax,-0x10(%ebp)
801068be:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801068c2:	75 0c                	jne    801068d0 <create+0x100>
    panic("create: ialloc");
801068c4:	c7 04 24 f4 94 10 80 	movl   $0x801094f4,(%esp)
801068cb:	e8 6a 9c ff ff       	call   8010053a <panic>

  ilock(ip);
801068d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068d3:	89 04 24             	mov    %eax,(%esp)
801068d6:	e8 77 b0 ff ff       	call   80101952 <ilock>
  ip->major = major;
801068db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068de:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
801068e2:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
801068e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068e9:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
801068ed:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
801068f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068f4:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
801068fa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068fd:	89 04 24             	mov    %eax,(%esp)
80106900:	e8 91 ae ff ff       	call   80101796 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80106905:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
8010690a:	75 6a                	jne    80106976 <create+0x1a6>
    dp->nlink++;  // for ".."
8010690c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010690f:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106913:	8d 50 01             	lea    0x1(%eax),%edx
80106916:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106919:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
8010691d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106920:	89 04 24             	mov    %eax,(%esp)
80106923:	e8 6e ae ff ff       	call   80101796 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80106928:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010692b:	8b 40 04             	mov    0x4(%eax),%eax
8010692e:	89 44 24 08          	mov    %eax,0x8(%esp)
80106932:	c7 44 24 04 ce 94 10 	movl   $0x801094ce,0x4(%esp)
80106939:	80 
8010693a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010693d:	89 04 24             	mov    %eax,(%esp)
80106940:	e8 d2 b9 ff ff       	call   80102317 <dirlink>
80106945:	85 c0                	test   %eax,%eax
80106947:	78 21                	js     8010696a <create+0x19a>
80106949:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010694c:	8b 40 04             	mov    0x4(%eax),%eax
8010694f:	89 44 24 08          	mov    %eax,0x8(%esp)
80106953:	c7 44 24 04 d0 94 10 	movl   $0x801094d0,0x4(%esp)
8010695a:	80 
8010695b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010695e:	89 04 24             	mov    %eax,(%esp)
80106961:	e8 b1 b9 ff ff       	call   80102317 <dirlink>
80106966:	85 c0                	test   %eax,%eax
80106968:	79 0c                	jns    80106976 <create+0x1a6>
      panic("create dots");
8010696a:	c7 04 24 03 95 10 80 	movl   $0x80109503,(%esp)
80106971:	e8 c4 9b ff ff       	call   8010053a <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80106976:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106979:	8b 40 04             	mov    0x4(%eax),%eax
8010697c:	89 44 24 08          	mov    %eax,0x8(%esp)
80106980:	8d 45 de             	lea    -0x22(%ebp),%eax
80106983:	89 44 24 04          	mov    %eax,0x4(%esp)
80106987:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010698a:	89 04 24             	mov    %eax,(%esp)
8010698d:	e8 85 b9 ff ff       	call   80102317 <dirlink>
80106992:	85 c0                	test   %eax,%eax
80106994:	79 0c                	jns    801069a2 <create+0x1d2>
    panic("create: dirlink");
80106996:	c7 04 24 0f 95 10 80 	movl   $0x8010950f,(%esp)
8010699d:	e8 98 9b ff ff       	call   8010053a <panic>

  iunlockput(dp);
801069a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069a5:	89 04 24             	mov    %eax,(%esp)
801069a8:	e8 29 b2 ff ff       	call   80101bd6 <iunlockput>

  return ip;
801069ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801069b0:	c9                   	leave  
801069b1:	c3                   	ret    

801069b2 <sys_open>:

int
sys_open(void)
{
801069b2:	55                   	push   %ebp
801069b3:	89 e5                	mov    %esp,%ebp
801069b5:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
801069b8:	8d 45 e8             	lea    -0x18(%ebp),%eax
801069bb:	89 44 24 04          	mov    %eax,0x4(%esp)
801069bf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801069c6:	e8 b7 f6 ff ff       	call   80106082 <argstr>
801069cb:	85 c0                	test   %eax,%eax
801069cd:	78 17                	js     801069e6 <sys_open+0x34>
801069cf:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801069d2:	89 44 24 04          	mov    %eax,0x4(%esp)
801069d6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801069dd:	e8 10 f6 ff ff       	call   80105ff2 <argint>
801069e2:	85 c0                	test   %eax,%eax
801069e4:	79 0a                	jns    801069f0 <sys_open+0x3e>
    return -1;
801069e6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069eb:	e9 5c 01 00 00       	jmp    80106b4c <sys_open+0x19a>

  begin_op();
801069f0:	e8 2d cc ff ff       	call   80103622 <begin_op>

  if(omode & O_CREATE){
801069f5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801069f8:	25 00 02 00 00       	and    $0x200,%eax
801069fd:	85 c0                	test   %eax,%eax
801069ff:	74 3b                	je     80106a3c <sys_open+0x8a>
    ip = create(path, T_FILE, 0, 0);
80106a01:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106a04:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106a0b:	00 
80106a0c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106a13:	00 
80106a14:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106a1b:	00 
80106a1c:	89 04 24             	mov    %eax,(%esp)
80106a1f:	e8 ac fd ff ff       	call   801067d0 <create>
80106a24:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
80106a27:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106a2b:	75 6b                	jne    80106a98 <sys_open+0xe6>
      end_op();
80106a2d:	e8 74 cc ff ff       	call   801036a6 <end_op>
      return -1;
80106a32:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a37:	e9 10 01 00 00       	jmp    80106b4c <sys_open+0x19a>
    }
  } else {
    if((ip = namei(path)) == 0){
80106a3c:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106a3f:	89 04 24             	mov    %eax,(%esp)
80106a42:	e8 d1 bb ff ff       	call   80102618 <namei>
80106a47:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106a4a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106a4e:	75 0f                	jne    80106a5f <sys_open+0xad>
      end_op();
80106a50:	e8 51 cc ff ff       	call   801036a6 <end_op>
      return -1;
80106a55:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a5a:	e9 ed 00 00 00       	jmp    80106b4c <sys_open+0x19a>
    }
    ilock(ip);
80106a5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a62:	89 04 24             	mov    %eax,(%esp)
80106a65:	e8 e8 ae ff ff       	call   80101952 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106a6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a6d:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106a71:	66 83 f8 01          	cmp    $0x1,%ax
80106a75:	75 21                	jne    80106a98 <sys_open+0xe6>
80106a77:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106a7a:	85 c0                	test   %eax,%eax
80106a7c:	74 1a                	je     80106a98 <sys_open+0xe6>
      iunlockput(ip);
80106a7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a81:	89 04 24             	mov    %eax,(%esp)
80106a84:	e8 4d b1 ff ff       	call   80101bd6 <iunlockput>
      end_op();
80106a89:	e8 18 cc ff ff       	call   801036a6 <end_op>
      return -1;
80106a8e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a93:	e9 b4 00 00 00       	jmp    80106b4c <sys_open+0x19a>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106a98:	e8 80 a5 ff ff       	call   8010101d <filealloc>
80106a9d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106aa0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106aa4:	74 14                	je     80106aba <sys_open+0x108>
80106aa6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106aa9:	89 04 24             	mov    %eax,(%esp)
80106aac:	e8 0c f7 ff ff       	call   801061bd <fdalloc>
80106ab1:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106ab4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106ab8:	79 28                	jns    80106ae2 <sys_open+0x130>
    if(f)
80106aba:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106abe:	74 0b                	je     80106acb <sys_open+0x119>
      fileclose(f);
80106ac0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ac3:	89 04 24             	mov    %eax,(%esp)
80106ac6:	e8 fa a5 ff ff       	call   801010c5 <fileclose>
    iunlockput(ip);
80106acb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ace:	89 04 24             	mov    %eax,(%esp)
80106ad1:	e8 00 b1 ff ff       	call   80101bd6 <iunlockput>
    end_op();
80106ad6:	e8 cb cb ff ff       	call   801036a6 <end_op>
    return -1;
80106adb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ae0:	eb 6a                	jmp    80106b4c <sys_open+0x19a>
  }
  iunlock(ip);
80106ae2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ae5:	89 04 24             	mov    %eax,(%esp)
80106ae8:	e8 b3 af ff ff       	call   80101aa0 <iunlock>
  end_op();
80106aed:	e8 b4 cb ff ff       	call   801036a6 <end_op>

  f->type = FD_INODE;
80106af2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106af5:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106afb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106afe:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106b01:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106b04:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b07:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106b0e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106b11:	83 e0 01             	and    $0x1,%eax
80106b14:	85 c0                	test   %eax,%eax
80106b16:	0f 94 c0             	sete   %al
80106b19:	89 c2                	mov    %eax,%edx
80106b1b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b1e:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106b21:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106b24:	83 e0 01             	and    $0x1,%eax
80106b27:	85 c0                	test   %eax,%eax
80106b29:	75 0a                	jne    80106b35 <sys_open+0x183>
80106b2b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106b2e:	83 e0 02             	and    $0x2,%eax
80106b31:	85 c0                	test   %eax,%eax
80106b33:	74 07                	je     80106b3c <sys_open+0x18a>
80106b35:	b8 01 00 00 00       	mov    $0x1,%eax
80106b3a:	eb 05                	jmp    80106b41 <sys_open+0x18f>
80106b3c:	b8 00 00 00 00       	mov    $0x0,%eax
80106b41:	89 c2                	mov    %eax,%edx
80106b43:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b46:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80106b49:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80106b4c:	c9                   	leave  
80106b4d:	c3                   	ret    

80106b4e <sys_mkdir>:

int
sys_mkdir(void)
{
80106b4e:	55                   	push   %ebp
80106b4f:	89 e5                	mov    %esp,%ebp
80106b51:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80106b54:	e8 c9 ca ff ff       	call   80103622 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80106b59:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106b5c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b60:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106b67:	e8 16 f5 ff ff       	call   80106082 <argstr>
80106b6c:	85 c0                	test   %eax,%eax
80106b6e:	78 2c                	js     80106b9c <sys_mkdir+0x4e>
80106b70:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b73:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106b7a:	00 
80106b7b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106b82:	00 
80106b83:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106b8a:	00 
80106b8b:	89 04 24             	mov    %eax,(%esp)
80106b8e:	e8 3d fc ff ff       	call   801067d0 <create>
80106b93:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106b96:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106b9a:	75 0c                	jne    80106ba8 <sys_mkdir+0x5a>
    end_op();
80106b9c:	e8 05 cb ff ff       	call   801036a6 <end_op>
    return -1;
80106ba1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ba6:	eb 15                	jmp    80106bbd <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80106ba8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bab:	89 04 24             	mov    %eax,(%esp)
80106bae:	e8 23 b0 ff ff       	call   80101bd6 <iunlockput>
  end_op();
80106bb3:	e8 ee ca ff ff       	call   801036a6 <end_op>
  return 0;
80106bb8:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106bbd:	c9                   	leave  
80106bbe:	c3                   	ret    

80106bbf <sys_mknod>:

int
sys_mknod(void)
{
80106bbf:	55                   	push   %ebp
80106bc0:	89 e5                	mov    %esp,%ebp
80106bc2:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_op();
80106bc5:	e8 58 ca ff ff       	call   80103622 <begin_op>
  if((len=argstr(0, &path)) < 0 ||
80106bca:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106bcd:	89 44 24 04          	mov    %eax,0x4(%esp)
80106bd1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106bd8:	e8 a5 f4 ff ff       	call   80106082 <argstr>
80106bdd:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106be0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106be4:	78 5e                	js     80106c44 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80106be6:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106be9:	89 44 24 04          	mov    %eax,0x4(%esp)
80106bed:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106bf4:	e8 f9 f3 ff ff       	call   80105ff2 <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
80106bf9:	85 c0                	test   %eax,%eax
80106bfb:	78 47                	js     80106c44 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106bfd:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106c00:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c04:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106c0b:	e8 e2 f3 ff ff       	call   80105ff2 <argint>
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80106c10:	85 c0                	test   %eax,%eax
80106c12:	78 30                	js     80106c44 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80106c14:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106c17:	0f bf c8             	movswl %ax,%ecx
80106c1a:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106c1d:	0f bf d0             	movswl %ax,%edx
80106c20:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106c23:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106c27:	89 54 24 08          	mov    %edx,0x8(%esp)
80106c2b:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106c32:	00 
80106c33:	89 04 24             	mov    %eax,(%esp)
80106c36:	e8 95 fb ff ff       	call   801067d0 <create>
80106c3b:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106c3e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106c42:	75 0c                	jne    80106c50 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
80106c44:	e8 5d ca ff ff       	call   801036a6 <end_op>
    return -1;
80106c49:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c4e:	eb 15                	jmp    80106c65 <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106c50:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c53:	89 04 24             	mov    %eax,(%esp)
80106c56:	e8 7b af ff ff       	call   80101bd6 <iunlockput>
  end_op();
80106c5b:	e8 46 ca ff ff       	call   801036a6 <end_op>
  return 0;
80106c60:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106c65:	c9                   	leave  
80106c66:	c3                   	ret    

80106c67 <sys_chdir>:

int
sys_chdir(void)
{
80106c67:	55                   	push   %ebp
80106c68:	89 e5                	mov    %esp,%ebp
80106c6a:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80106c6d:	e8 b0 c9 ff ff       	call   80103622 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80106c72:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106c75:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c79:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106c80:	e8 fd f3 ff ff       	call   80106082 <argstr>
80106c85:	85 c0                	test   %eax,%eax
80106c87:	78 14                	js     80106c9d <sys_chdir+0x36>
80106c89:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c8c:	89 04 24             	mov    %eax,(%esp)
80106c8f:	e8 84 b9 ff ff       	call   80102618 <namei>
80106c94:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106c97:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106c9b:	75 0f                	jne    80106cac <sys_chdir+0x45>
    end_op();
80106c9d:	e8 04 ca ff ff       	call   801036a6 <end_op>
    return -1;
80106ca2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ca7:	e9 a2 00 00 00       	jmp    80106d4e <sys_chdir+0xe7>
  }
  ilock(ip);
80106cac:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106caf:	89 04 24             	mov    %eax,(%esp)
80106cb2:	e8 9b ac ff ff       	call   80101952 <ilock>

  if(ip->type != T_DIR && !IS_DEV_DIR(ip)) {
80106cb7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106cba:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106cbe:	66 83 f8 01          	cmp    $0x1,%ax
80106cc2:	74 58                	je     80106d1c <sys_chdir+0xb5>
80106cc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106cc7:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106ccb:	66 83 f8 03          	cmp    $0x3,%ax
80106ccf:	75 34                	jne    80106d05 <sys_chdir+0x9e>
80106cd1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106cd4:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80106cd8:	98                   	cwtl   
80106cd9:	c1 e0 04             	shl    $0x4,%eax
80106cdc:	05 e0 21 11 80       	add    $0x801121e0,%eax
80106ce1:	8b 00                	mov    (%eax),%eax
80106ce3:	85 c0                	test   %eax,%eax
80106ce5:	74 1e                	je     80106d05 <sys_chdir+0x9e>
80106ce7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106cea:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80106cee:	98                   	cwtl   
80106cef:	c1 e0 04             	shl    $0x4,%eax
80106cf2:	05 e0 21 11 80       	add    $0x801121e0,%eax
80106cf7:	8b 00                	mov    (%eax),%eax
80106cf9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106cfc:	89 14 24             	mov    %edx,(%esp)
80106cff:	ff d0                	call   *%eax
80106d01:	85 c0                	test   %eax,%eax
80106d03:	75 17                	jne    80106d1c <sys_chdir+0xb5>
    iunlockput(ip);
80106d05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d08:	89 04 24             	mov    %eax,(%esp)
80106d0b:	e8 c6 ae ff ff       	call   80101bd6 <iunlockput>
    end_op();
80106d10:	e8 91 c9 ff ff       	call   801036a6 <end_op>
    return -1;
80106d15:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d1a:	eb 32                	jmp    80106d4e <sys_chdir+0xe7>
  }
  
  iunlock(ip);
80106d1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d1f:	89 04 24             	mov    %eax,(%esp)
80106d22:	e8 79 ad ff ff       	call   80101aa0 <iunlock>
  iput(proc->cwd);
80106d27:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d2d:	8b 40 78             	mov    0x78(%eax),%eax
80106d30:	89 04 24             	mov    %eax,(%esp)
80106d33:	e8 cd ad ff ff       	call   80101b05 <iput>
  end_op();
80106d38:	e8 69 c9 ff ff       	call   801036a6 <end_op>
  proc->cwd = ip;
80106d3d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d43:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106d46:	89 50 78             	mov    %edx,0x78(%eax)
  return 0;
80106d49:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106d4e:	c9                   	leave  
80106d4f:	c3                   	ret    

80106d50 <sys_exec>:

int
sys_exec(void)
{
80106d50:	55                   	push   %ebp
80106d51:	89 e5                	mov    %esp,%ebp
80106d53:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106d59:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106d5c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d60:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106d67:	e8 16 f3 ff ff       	call   80106082 <argstr>
80106d6c:	85 c0                	test   %eax,%eax
80106d6e:	78 1a                	js     80106d8a <sys_exec+0x3a>
80106d70:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80106d76:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d7a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106d81:	e8 6c f2 ff ff       	call   80105ff2 <argint>
80106d86:	85 c0                	test   %eax,%eax
80106d88:	79 0a                	jns    80106d94 <sys_exec+0x44>
    return -1;
80106d8a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d8f:	e9 c8 00 00 00       	jmp    80106e5c <sys_exec+0x10c>
  }
  memset(argv, 0, sizeof(argv));
80106d94:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106d9b:	00 
80106d9c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106da3:	00 
80106da4:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106daa:	89 04 24             	mov    %eax,(%esp)
80106dad:	e8 fe ee ff ff       	call   80105cb0 <memset>
  for(i=0;; i++){
80106db2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106db9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106dbc:	83 f8 1f             	cmp    $0x1f,%eax
80106dbf:	76 0a                	jbe    80106dcb <sys_exec+0x7b>
      return -1;
80106dc1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106dc6:	e9 91 00 00 00       	jmp    80106e5c <sys_exec+0x10c>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80106dcb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106dce:	c1 e0 02             	shl    $0x2,%eax
80106dd1:	89 c2                	mov    %eax,%edx
80106dd3:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106dd9:	01 c2                	add    %eax,%edx
80106ddb:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
80106de1:	89 44 24 04          	mov    %eax,0x4(%esp)
80106de5:	89 14 24             	mov    %edx,(%esp)
80106de8:	e8 69 f1 ff ff       	call   80105f56 <fetchint>
80106ded:	85 c0                	test   %eax,%eax
80106def:	79 07                	jns    80106df8 <sys_exec+0xa8>
      return -1;
80106df1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106df6:	eb 64                	jmp    80106e5c <sys_exec+0x10c>
    if(uarg == 0){
80106df8:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106dfe:	85 c0                	test   %eax,%eax
80106e00:	75 26                	jne    80106e28 <sys_exec+0xd8>
      argv[i] = 0;
80106e02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e05:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106e0c:	00 00 00 00 
      break;
80106e10:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106e11:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e14:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80106e1a:	89 54 24 04          	mov    %edx,0x4(%esp)
80106e1e:	89 04 24             	mov    %eax,(%esp)
80106e21:	e8 c9 9c ff ff       	call   80100aef <exec>
80106e26:	eb 34                	jmp    80106e5c <sys_exec+0x10c>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80106e28:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106e2e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106e31:	c1 e2 02             	shl    $0x2,%edx
80106e34:	01 c2                	add    %eax,%edx
80106e36:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106e3c:	89 54 24 04          	mov    %edx,0x4(%esp)
80106e40:	89 04 24             	mov    %eax,(%esp)
80106e43:	e8 48 f1 ff ff       	call   80105f90 <fetchstr>
80106e48:	85 c0                	test   %eax,%eax
80106e4a:	79 07                	jns    80106e53 <sys_exec+0x103>
      return -1;
80106e4c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106e51:	eb 09                	jmp    80106e5c <sys_exec+0x10c>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106e53:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
80106e57:	e9 5d ff ff ff       	jmp    80106db9 <sys_exec+0x69>
  return exec(path, argv);
}
80106e5c:	c9                   	leave  
80106e5d:	c3                   	ret    

80106e5e <sys_pipe>:

int
sys_pipe(void)
{
80106e5e:	55                   	push   %ebp
80106e5f:	89 e5                	mov    %esp,%ebp
80106e61:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106e64:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106e6b:	00 
80106e6c:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106e6f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106e73:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106e7a:	e8 a1 f1 ff ff       	call   80106020 <argptr>
80106e7f:	85 c0                	test   %eax,%eax
80106e81:	79 0a                	jns    80106e8d <sys_pipe+0x2f>
    return -1;
80106e83:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106e88:	e9 9b 00 00 00       	jmp    80106f28 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106e8d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106e90:	89 44 24 04          	mov    %eax,0x4(%esp)
80106e94:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106e97:	89 04 24             	mov    %eax,(%esp)
80106e9a:	e8 99 d2 ff ff       	call   80104138 <pipealloc>
80106e9f:	85 c0                	test   %eax,%eax
80106ea1:	79 07                	jns    80106eaa <sys_pipe+0x4c>
    return -1;
80106ea3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ea8:	eb 7e                	jmp    80106f28 <sys_pipe+0xca>
  fd0 = -1;
80106eaa:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106eb1:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106eb4:	89 04 24             	mov    %eax,(%esp)
80106eb7:	e8 01 f3 ff ff       	call   801061bd <fdalloc>
80106ebc:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106ebf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106ec3:	78 14                	js     80106ed9 <sys_pipe+0x7b>
80106ec5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106ec8:	89 04 24             	mov    %eax,(%esp)
80106ecb:	e8 ed f2 ff ff       	call   801061bd <fdalloc>
80106ed0:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106ed3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106ed7:	79 37                	jns    80106f10 <sys_pipe+0xb2>
    if(fd0 >= 0)
80106ed9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106edd:	78 14                	js     80106ef3 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106edf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106ee5:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106ee8:	83 c2 0c             	add    $0xc,%edx
80106eeb:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106ef2:	00 
    fileclose(rf);
80106ef3:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106ef6:	89 04 24             	mov    %eax,(%esp)
80106ef9:	e8 c7 a1 ff ff       	call   801010c5 <fileclose>
    fileclose(wf);
80106efe:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106f01:	89 04 24             	mov    %eax,(%esp)
80106f04:	e8 bc a1 ff ff       	call   801010c5 <fileclose>
    return -1;
80106f09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f0e:	eb 18                	jmp    80106f28 <sys_pipe+0xca>
  }
  fd[0] = fd0;
80106f10:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106f13:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106f16:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80106f18:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106f1b:	8d 50 04             	lea    0x4(%eax),%edx
80106f1e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f21:	89 02                	mov    %eax,(%edx)
  return 0;
80106f23:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106f28:	c9                   	leave  
80106f29:	c3                   	ret    

80106f2a <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80106f2a:	55                   	push   %ebp
80106f2b:	89 e5                	mov    %esp,%ebp
80106f2d:	83 ec 08             	sub    $0x8,%esp
  return fork();
80106f30:	e8 ec d8 ff ff       	call   80104821 <fork>
}
80106f35:	c9                   	leave  
80106f36:	c3                   	ret    

80106f37 <sys_exit>:

int
sys_exit(void)
{
80106f37:	55                   	push   %ebp
80106f38:	89 e5                	mov    %esp,%ebp
80106f3a:	83 ec 08             	sub    $0x8,%esp
  exit();
80106f3d:	e8 4f db ff ff       	call   80104a91 <exit>
  return 0;  // not reached
80106f42:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106f47:	c9                   	leave  
80106f48:	c3                   	ret    

80106f49 <sys_wait>:

int
sys_wait(void)
{
80106f49:	55                   	push   %ebp
80106f4a:	89 e5                	mov    %esp,%ebp
80106f4c:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106f4f:	e8 62 dc ff ff       	call   80104bb6 <wait>
}
80106f54:	c9                   	leave  
80106f55:	c3                   	ret    

80106f56 <sys_kill>:

int
sys_kill(void)
{
80106f56:	55                   	push   %ebp
80106f57:	89 e5                	mov    %esp,%ebp
80106f59:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80106f5c:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106f5f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f63:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106f6a:	e8 83 f0 ff ff       	call   80105ff2 <argint>
80106f6f:	85 c0                	test   %eax,%eax
80106f71:	79 07                	jns    80106f7a <sys_kill+0x24>
    return -1;
80106f73:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f78:	eb 0b                	jmp    80106f85 <sys_kill+0x2f>
  return kill(pid);
80106f7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f7d:	89 04 24             	mov    %eax,(%esp)
80106f80:	e8 f5 df ff ff       	call   80104f7a <kill>
}
80106f85:	c9                   	leave  
80106f86:	c3                   	ret    

80106f87 <sys_getpid>:

int
sys_getpid(void)
{
80106f87:	55                   	push   %ebp
80106f88:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80106f8a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106f90:	8b 40 10             	mov    0x10(%eax),%eax
}
80106f93:	5d                   	pop    %ebp
80106f94:	c3                   	ret    

80106f95 <sys_sbrk>:

int
sys_sbrk(void)
{
80106f95:	55                   	push   %ebp
80106f96:	89 e5                	mov    %esp,%ebp
80106f98:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80106f9b:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106f9e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106fa2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106fa9:	e8 44 f0 ff ff       	call   80105ff2 <argint>
80106fae:	85 c0                	test   %eax,%eax
80106fb0:	79 07                	jns    80106fb9 <sys_sbrk+0x24>
    return -1;
80106fb2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106fb7:	eb 24                	jmp    80106fdd <sys_sbrk+0x48>
  addr = proc->sz;
80106fb9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106fbf:	8b 00                	mov    (%eax),%eax
80106fc1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80106fc4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106fc7:	89 04 24             	mov    %eax,(%esp)
80106fca:	e8 ad d7 ff ff       	call   8010477c <growproc>
80106fcf:	85 c0                	test   %eax,%eax
80106fd1:	79 07                	jns    80106fda <sys_sbrk+0x45>
    return -1;
80106fd3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106fd8:	eb 03                	jmp    80106fdd <sys_sbrk+0x48>
  return addr;
80106fda:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106fdd:	c9                   	leave  
80106fde:	c3                   	ret    

80106fdf <sys_sleep>:

int
sys_sleep(void)
{
80106fdf:	55                   	push   %ebp
80106fe0:	89 e5                	mov    %esp,%ebp
80106fe2:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
80106fe5:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106fe8:	89 44 24 04          	mov    %eax,0x4(%esp)
80106fec:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106ff3:	e8 fa ef ff ff       	call   80105ff2 <argint>
80106ff8:	85 c0                	test   %eax,%eax
80106ffa:	79 07                	jns    80107003 <sys_sleep+0x24>
    return -1;
80106ffc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107001:	eb 6c                	jmp    8010706f <sys_sleep+0x90>
  acquire(&tickslock);
80107003:	c7 04 24 e0 6c 12 80 	movl   $0x80126ce0,(%esp)
8010700a:	e8 4d ea ff ff       	call   80105a5c <acquire>
  ticks0 = ticks;
8010700f:	a1 20 75 12 80       	mov    0x80127520,%eax
80107014:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80107017:	eb 34                	jmp    8010704d <sys_sleep+0x6e>
    if(proc->killed){
80107019:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010701f:	8b 40 24             	mov    0x24(%eax),%eax
80107022:	85 c0                	test   %eax,%eax
80107024:	74 13                	je     80107039 <sys_sleep+0x5a>
      release(&tickslock);
80107026:	c7 04 24 e0 6c 12 80 	movl   $0x80126ce0,(%esp)
8010702d:	e8 8c ea ff ff       	call   80105abe <release>
      return -1;
80107032:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107037:	eb 36                	jmp    8010706f <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80107039:	c7 44 24 04 e0 6c 12 	movl   $0x80126ce0,0x4(%esp)
80107040:	80 
80107041:	c7 04 24 20 75 12 80 	movl   $0x80127520,(%esp)
80107048:	e8 26 de ff ff       	call   80104e73 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
8010704d:	a1 20 75 12 80       	mov    0x80127520,%eax
80107052:	2b 45 f4             	sub    -0xc(%ebp),%eax
80107055:	89 c2                	mov    %eax,%edx
80107057:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010705a:	39 c2                	cmp    %eax,%edx
8010705c:	72 bb                	jb     80107019 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
8010705e:	c7 04 24 e0 6c 12 80 	movl   $0x80126ce0,(%esp)
80107065:	e8 54 ea ff ff       	call   80105abe <release>
  return 0;
8010706a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010706f:	c9                   	leave  
80107070:	c3                   	ret    

80107071 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80107071:	55                   	push   %ebp
80107072:	89 e5                	mov    %esp,%ebp
80107074:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80107077:	c7 04 24 e0 6c 12 80 	movl   $0x80126ce0,(%esp)
8010707e:	e8 d9 e9 ff ff       	call   80105a5c <acquire>
  xticks = ticks;
80107083:	a1 20 75 12 80       	mov    0x80127520,%eax
80107088:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
8010708b:	c7 04 24 e0 6c 12 80 	movl   $0x80126ce0,(%esp)
80107092:	e8 27 ea ff ff       	call   80105abe <release>
  return xticks;
80107097:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010709a:	c9                   	leave  
8010709b:	c3                   	ret    

8010709c <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010709c:	55                   	push   %ebp
8010709d:	89 e5                	mov    %esp,%ebp
8010709f:	83 ec 08             	sub    $0x8,%esp
801070a2:	8b 55 08             	mov    0x8(%ebp),%edx
801070a5:	8b 45 0c             	mov    0xc(%ebp),%eax
801070a8:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801070ac:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801070af:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801070b3:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801070b7:	ee                   	out    %al,(%dx)
}
801070b8:	c9                   	leave  
801070b9:	c3                   	ret    

801070ba <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
801070ba:	55                   	push   %ebp
801070bb:	89 e5                	mov    %esp,%ebp
801070bd:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
801070c0:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
801070c7:	00 
801070c8:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
801070cf:	e8 c8 ff ff ff       	call   8010709c <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
801070d4:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
801070db:	00 
801070dc:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801070e3:	e8 b4 ff ff ff       	call   8010709c <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
801070e8:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
801070ef:	00 
801070f0:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801070f7:	e8 a0 ff ff ff       	call   8010709c <outb>
  picenable(IRQ_TIMER);
801070fc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107103:	e8 c3 ce ff ff       	call   80103fcb <picenable>
}
80107108:	c9                   	leave  
80107109:	c3                   	ret    

8010710a <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
8010710a:	1e                   	push   %ds
  pushl %es
8010710b:	06                   	push   %es
  pushl %fs
8010710c:	0f a0                	push   %fs
  pushl %gs
8010710e:	0f a8                	push   %gs
  pushal
80107110:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80107111:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80107115:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80107117:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80107119:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
8010711d:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
8010711f:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80107121:	54                   	push   %esp
  call trap
80107122:	e8 d8 01 00 00       	call   801072ff <trap>
  addl $4, %esp
80107127:	83 c4 04             	add    $0x4,%esp

8010712a <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
8010712a:	61                   	popa   
  popl %gs
8010712b:	0f a9                	pop    %gs
  popl %fs
8010712d:	0f a1                	pop    %fs
  popl %es
8010712f:	07                   	pop    %es
  popl %ds
80107130:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80107131:	83 c4 08             	add    $0x8,%esp
  iret
80107134:	cf                   	iret   

80107135 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80107135:	55                   	push   %ebp
80107136:	89 e5                	mov    %esp,%ebp
80107138:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
8010713b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010713e:	83 e8 01             	sub    $0x1,%eax
80107141:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107145:	8b 45 08             	mov    0x8(%ebp),%eax
80107148:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010714c:	8b 45 08             	mov    0x8(%ebp),%eax
8010714f:	c1 e8 10             	shr    $0x10,%eax
80107152:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80107156:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107159:	0f 01 18             	lidtl  (%eax)
}
8010715c:	c9                   	leave  
8010715d:	c3                   	ret    

8010715e <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
8010715e:	55                   	push   %ebp
8010715f:	89 e5                	mov    %esp,%ebp
80107161:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80107164:	0f 20 d0             	mov    %cr2,%eax
80107167:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
8010716a:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010716d:	c9                   	leave  
8010716e:	c3                   	ret    

8010716f <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
8010716f:	55                   	push   %ebp
80107170:	89 e5                	mov    %esp,%ebp
80107172:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80107175:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010717c:	e9 c3 00 00 00       	jmp    80107244 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80107181:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107184:	8b 04 85 98 c0 10 80 	mov    -0x7fef3f68(,%eax,4),%eax
8010718b:	89 c2                	mov    %eax,%edx
8010718d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107190:	66 89 14 c5 20 6d 12 	mov    %dx,-0x7fed92e0(,%eax,8)
80107197:	80 
80107198:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010719b:	66 c7 04 c5 22 6d 12 	movw   $0x8,-0x7fed92de(,%eax,8)
801071a2:	80 08 00 
801071a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801071a8:	0f b6 14 c5 24 6d 12 	movzbl -0x7fed92dc(,%eax,8),%edx
801071af:	80 
801071b0:	83 e2 e0             	and    $0xffffffe0,%edx
801071b3:	88 14 c5 24 6d 12 80 	mov    %dl,-0x7fed92dc(,%eax,8)
801071ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801071bd:	0f b6 14 c5 24 6d 12 	movzbl -0x7fed92dc(,%eax,8),%edx
801071c4:	80 
801071c5:	83 e2 1f             	and    $0x1f,%edx
801071c8:	88 14 c5 24 6d 12 80 	mov    %dl,-0x7fed92dc(,%eax,8)
801071cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801071d2:	0f b6 14 c5 25 6d 12 	movzbl -0x7fed92db(,%eax,8),%edx
801071d9:	80 
801071da:	83 e2 f0             	and    $0xfffffff0,%edx
801071dd:	83 ca 0e             	or     $0xe,%edx
801071e0:	88 14 c5 25 6d 12 80 	mov    %dl,-0x7fed92db(,%eax,8)
801071e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801071ea:	0f b6 14 c5 25 6d 12 	movzbl -0x7fed92db(,%eax,8),%edx
801071f1:	80 
801071f2:	83 e2 ef             	and    $0xffffffef,%edx
801071f5:	88 14 c5 25 6d 12 80 	mov    %dl,-0x7fed92db(,%eax,8)
801071fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801071ff:	0f b6 14 c5 25 6d 12 	movzbl -0x7fed92db(,%eax,8),%edx
80107206:	80 
80107207:	83 e2 9f             	and    $0xffffff9f,%edx
8010720a:	88 14 c5 25 6d 12 80 	mov    %dl,-0x7fed92db(,%eax,8)
80107211:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107214:	0f b6 14 c5 25 6d 12 	movzbl -0x7fed92db(,%eax,8),%edx
8010721b:	80 
8010721c:	83 ca 80             	or     $0xffffff80,%edx
8010721f:	88 14 c5 25 6d 12 80 	mov    %dl,-0x7fed92db(,%eax,8)
80107226:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107229:	8b 04 85 98 c0 10 80 	mov    -0x7fef3f68(,%eax,4),%eax
80107230:	c1 e8 10             	shr    $0x10,%eax
80107233:	89 c2                	mov    %eax,%edx
80107235:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107238:	66 89 14 c5 26 6d 12 	mov    %dx,-0x7fed92da(,%eax,8)
8010723f:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80107240:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107244:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
8010724b:	0f 8e 30 ff ff ff    	jle    80107181 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80107251:	a1 98 c1 10 80       	mov    0x8010c198,%eax
80107256:	66 a3 20 6f 12 80    	mov    %ax,0x80126f20
8010725c:	66 c7 05 22 6f 12 80 	movw   $0x8,0x80126f22
80107263:	08 00 
80107265:	0f b6 05 24 6f 12 80 	movzbl 0x80126f24,%eax
8010726c:	83 e0 e0             	and    $0xffffffe0,%eax
8010726f:	a2 24 6f 12 80       	mov    %al,0x80126f24
80107274:	0f b6 05 24 6f 12 80 	movzbl 0x80126f24,%eax
8010727b:	83 e0 1f             	and    $0x1f,%eax
8010727e:	a2 24 6f 12 80       	mov    %al,0x80126f24
80107283:	0f b6 05 25 6f 12 80 	movzbl 0x80126f25,%eax
8010728a:	83 c8 0f             	or     $0xf,%eax
8010728d:	a2 25 6f 12 80       	mov    %al,0x80126f25
80107292:	0f b6 05 25 6f 12 80 	movzbl 0x80126f25,%eax
80107299:	83 e0 ef             	and    $0xffffffef,%eax
8010729c:	a2 25 6f 12 80       	mov    %al,0x80126f25
801072a1:	0f b6 05 25 6f 12 80 	movzbl 0x80126f25,%eax
801072a8:	83 c8 60             	or     $0x60,%eax
801072ab:	a2 25 6f 12 80       	mov    %al,0x80126f25
801072b0:	0f b6 05 25 6f 12 80 	movzbl 0x80126f25,%eax
801072b7:	83 c8 80             	or     $0xffffff80,%eax
801072ba:	a2 25 6f 12 80       	mov    %al,0x80126f25
801072bf:	a1 98 c1 10 80       	mov    0x8010c198,%eax
801072c4:	c1 e8 10             	shr    $0x10,%eax
801072c7:	66 a3 26 6f 12 80    	mov    %ax,0x80126f26
  
  initlock(&tickslock, "time");
801072cd:	c7 44 24 04 20 95 10 	movl   $0x80109520,0x4(%esp)
801072d4:	80 
801072d5:	c7 04 24 e0 6c 12 80 	movl   $0x80126ce0,(%esp)
801072dc:	e8 5a e7 ff ff       	call   80105a3b <initlock>
}
801072e1:	c9                   	leave  
801072e2:	c3                   	ret    

801072e3 <idtinit>:

void
idtinit(void)
{
801072e3:	55                   	push   %ebp
801072e4:	89 e5                	mov    %esp,%ebp
801072e6:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
801072e9:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
801072f0:	00 
801072f1:	c7 04 24 20 6d 12 80 	movl   $0x80126d20,(%esp)
801072f8:	e8 38 fe ff ff       	call   80107135 <lidt>
}
801072fd:	c9                   	leave  
801072fe:	c3                   	ret    

801072ff <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
801072ff:	55                   	push   %ebp
80107300:	89 e5                	mov    %esp,%ebp
80107302:	57                   	push   %edi
80107303:	56                   	push   %esi
80107304:	53                   	push   %ebx
80107305:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80107308:	8b 45 08             	mov    0x8(%ebp),%eax
8010730b:	8b 40 30             	mov    0x30(%eax),%eax
8010730e:	83 f8 40             	cmp    $0x40,%eax
80107311:	75 3f                	jne    80107352 <trap+0x53>
    if(proc->killed)
80107313:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107319:	8b 40 24             	mov    0x24(%eax),%eax
8010731c:	85 c0                	test   %eax,%eax
8010731e:	74 05                	je     80107325 <trap+0x26>
      exit();
80107320:	e8 6c d7 ff ff       	call   80104a91 <exit>
    proc->tf = tf;
80107325:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010732b:	8b 55 08             	mov    0x8(%ebp),%edx
8010732e:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80107331:	e8 83 ed ff ff       	call   801060b9 <syscall>
    if(proc->killed)
80107336:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010733c:	8b 40 24             	mov    0x24(%eax),%eax
8010733f:	85 c0                	test   %eax,%eax
80107341:	74 0a                	je     8010734d <trap+0x4e>
      exit();
80107343:	e8 49 d7 ff ff       	call   80104a91 <exit>
    return;
80107348:	e9 2d 02 00 00       	jmp    8010757a <trap+0x27b>
8010734d:	e9 28 02 00 00       	jmp    8010757a <trap+0x27b>
  }

  switch(tf->trapno){
80107352:	8b 45 08             	mov    0x8(%ebp),%eax
80107355:	8b 40 30             	mov    0x30(%eax),%eax
80107358:	83 e8 20             	sub    $0x20,%eax
8010735b:	83 f8 1f             	cmp    $0x1f,%eax
8010735e:	0f 87 bc 00 00 00    	ja     80107420 <trap+0x121>
80107364:	8b 04 85 c8 95 10 80 	mov    -0x7fef6a38(,%eax,4),%eax
8010736b:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
8010736d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107373:	0f b6 00             	movzbl (%eax),%eax
80107376:	84 c0                	test   %al,%al
80107378:	75 31                	jne    801073ab <trap+0xac>
      acquire(&tickslock);
8010737a:	c7 04 24 e0 6c 12 80 	movl   $0x80126ce0,(%esp)
80107381:	e8 d6 e6 ff ff       	call   80105a5c <acquire>
      ticks++;
80107386:	a1 20 75 12 80       	mov    0x80127520,%eax
8010738b:	83 c0 01             	add    $0x1,%eax
8010738e:	a3 20 75 12 80       	mov    %eax,0x80127520
      wakeup(&ticks);
80107393:	c7 04 24 20 75 12 80 	movl   $0x80127520,(%esp)
8010739a:	e8 b0 db ff ff       	call   80104f4f <wakeup>
      release(&tickslock);
8010739f:	c7 04 24 e0 6c 12 80 	movl   $0x80126ce0,(%esp)
801073a6:	e8 13 e7 ff ff       	call   80105abe <release>
    }
    lapiceoi();
801073ab:	e8 32 bd ff ff       	call   801030e2 <lapiceoi>
    break;
801073b0:	e9 41 01 00 00       	jmp    801074f6 <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
801073b5:	e8 36 b5 ff ff       	call   801028f0 <ideintr>
    lapiceoi();
801073ba:	e8 23 bd ff ff       	call   801030e2 <lapiceoi>
    break;
801073bf:	e9 32 01 00 00       	jmp    801074f6 <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
801073c4:	e8 e8 ba ff ff       	call   80102eb1 <kbdintr>
    lapiceoi();
801073c9:	e8 14 bd ff ff       	call   801030e2 <lapiceoi>
    break;
801073ce:	e9 23 01 00 00       	jmp    801074f6 <trap+0x1f7>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
801073d3:	e8 97 03 00 00       	call   8010776f <uartintr>
    lapiceoi();
801073d8:	e8 05 bd ff ff       	call   801030e2 <lapiceoi>
    break;
801073dd:	e9 14 01 00 00       	jmp    801074f6 <trap+0x1f7>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801073e2:	8b 45 08             	mov    0x8(%ebp),%eax
801073e5:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
801073e8:	8b 45 08             	mov    0x8(%ebp),%eax
801073eb:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801073ef:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
801073f2:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801073f8:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801073fb:	0f b6 c0             	movzbl %al,%eax
801073fe:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107402:	89 54 24 08          	mov    %edx,0x8(%esp)
80107406:	89 44 24 04          	mov    %eax,0x4(%esp)
8010740a:	c7 04 24 28 95 10 80 	movl   $0x80109528,(%esp)
80107411:	e8 8a 8f ff ff       	call   801003a0 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80107416:	e8 c7 bc ff ff       	call   801030e2 <lapiceoi>
    break;
8010741b:	e9 d6 00 00 00       	jmp    801074f6 <trap+0x1f7>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80107420:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107426:	85 c0                	test   %eax,%eax
80107428:	74 11                	je     8010743b <trap+0x13c>
8010742a:	8b 45 08             	mov    0x8(%ebp),%eax
8010742d:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107431:	0f b7 c0             	movzwl %ax,%eax
80107434:	83 e0 03             	and    $0x3,%eax
80107437:	85 c0                	test   %eax,%eax
80107439:	75 46                	jne    80107481 <trap+0x182>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010743b:	e8 1e fd ff ff       	call   8010715e <rcr2>
80107440:	8b 55 08             	mov    0x8(%ebp),%edx
80107443:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80107446:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010744d:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107450:	0f b6 ca             	movzbl %dl,%ecx
80107453:	8b 55 08             	mov    0x8(%ebp),%edx
80107456:	8b 52 30             	mov    0x30(%edx),%edx
80107459:	89 44 24 10          	mov    %eax,0x10(%esp)
8010745d:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80107461:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80107465:	89 54 24 04          	mov    %edx,0x4(%esp)
80107469:	c7 04 24 4c 95 10 80 	movl   $0x8010954c,(%esp)
80107470:	e8 2b 8f ff ff       	call   801003a0 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80107475:	c7 04 24 7e 95 10 80 	movl   $0x8010957e,(%esp)
8010747c:	e8 b9 90 ff ff       	call   8010053a <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107481:	e8 d8 fc ff ff       	call   8010715e <rcr2>
80107486:	89 c2                	mov    %eax,%edx
80107488:	8b 45 08             	mov    0x8(%ebp),%eax
8010748b:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010748e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107494:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107497:	0f b6 f0             	movzbl %al,%esi
8010749a:	8b 45 08             	mov    0x8(%ebp),%eax
8010749d:	8b 58 34             	mov    0x34(%eax),%ebx
801074a0:	8b 45 08             	mov    0x8(%ebp),%eax
801074a3:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801074a6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801074ac:	83 c0 28             	add    $0x28,%eax
801074af:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801074b2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801074b8:	8b 40 10             	mov    0x10(%eax),%eax
801074bb:	89 54 24 1c          	mov    %edx,0x1c(%esp)
801074bf:	89 7c 24 18          	mov    %edi,0x18(%esp)
801074c3:	89 74 24 14          	mov    %esi,0x14(%esp)
801074c7:	89 5c 24 10          	mov    %ebx,0x10(%esp)
801074cb:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801074cf:	8b 75 e4             	mov    -0x1c(%ebp),%esi
801074d2:	89 74 24 08          	mov    %esi,0x8(%esp)
801074d6:	89 44 24 04          	mov    %eax,0x4(%esp)
801074da:	c7 04 24 84 95 10 80 	movl   $0x80109584,(%esp)
801074e1:	e8 ba 8e ff ff       	call   801003a0 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
801074e6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801074ec:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
801074f3:	eb 01                	jmp    801074f6 <trap+0x1f7>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
801074f5:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801074f6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801074fc:	85 c0                	test   %eax,%eax
801074fe:	74 24                	je     80107524 <trap+0x225>
80107500:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107506:	8b 40 24             	mov    0x24(%eax),%eax
80107509:	85 c0                	test   %eax,%eax
8010750b:	74 17                	je     80107524 <trap+0x225>
8010750d:	8b 45 08             	mov    0x8(%ebp),%eax
80107510:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107514:	0f b7 c0             	movzwl %ax,%eax
80107517:	83 e0 03             	and    $0x3,%eax
8010751a:	83 f8 03             	cmp    $0x3,%eax
8010751d:	75 05                	jne    80107524 <trap+0x225>
    exit();
8010751f:	e8 6d d5 ff ff       	call   80104a91 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80107524:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010752a:	85 c0                	test   %eax,%eax
8010752c:	74 1e                	je     8010754c <trap+0x24d>
8010752e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107534:	8b 40 0c             	mov    0xc(%eax),%eax
80107537:	83 f8 04             	cmp    $0x4,%eax
8010753a:	75 10                	jne    8010754c <trap+0x24d>
8010753c:	8b 45 08             	mov    0x8(%ebp),%eax
8010753f:	8b 40 30             	mov    0x30(%eax),%eax
80107542:	83 f8 20             	cmp    $0x20,%eax
80107545:	75 05                	jne    8010754c <trap+0x24d>
    yield();
80107547:	e8 c9 d8 ff ff       	call   80104e15 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
8010754c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107552:	85 c0                	test   %eax,%eax
80107554:	74 24                	je     8010757a <trap+0x27b>
80107556:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010755c:	8b 40 24             	mov    0x24(%eax),%eax
8010755f:	85 c0                	test   %eax,%eax
80107561:	74 17                	je     8010757a <trap+0x27b>
80107563:	8b 45 08             	mov    0x8(%ebp),%eax
80107566:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010756a:	0f b7 c0             	movzwl %ax,%eax
8010756d:	83 e0 03             	and    $0x3,%eax
80107570:	83 f8 03             	cmp    $0x3,%eax
80107573:	75 05                	jne    8010757a <trap+0x27b>
    exit();
80107575:	e8 17 d5 ff ff       	call   80104a91 <exit>
}
8010757a:	83 c4 3c             	add    $0x3c,%esp
8010757d:	5b                   	pop    %ebx
8010757e:	5e                   	pop    %esi
8010757f:	5f                   	pop    %edi
80107580:	5d                   	pop    %ebp
80107581:	c3                   	ret    

80107582 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80107582:	55                   	push   %ebp
80107583:	89 e5                	mov    %esp,%ebp
80107585:	83 ec 14             	sub    $0x14,%esp
80107588:	8b 45 08             	mov    0x8(%ebp),%eax
8010758b:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010758f:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80107593:	89 c2                	mov    %eax,%edx
80107595:	ec                   	in     (%dx),%al
80107596:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80107599:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
8010759d:	c9                   	leave  
8010759e:	c3                   	ret    

8010759f <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010759f:	55                   	push   %ebp
801075a0:	89 e5                	mov    %esp,%ebp
801075a2:	83 ec 08             	sub    $0x8,%esp
801075a5:	8b 55 08             	mov    0x8(%ebp),%edx
801075a8:	8b 45 0c             	mov    0xc(%ebp),%eax
801075ab:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801075af:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801075b2:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801075b6:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801075ba:	ee                   	out    %al,(%dx)
}
801075bb:	c9                   	leave  
801075bc:	c3                   	ret    

801075bd <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
801075bd:	55                   	push   %ebp
801075be:	89 e5                	mov    %esp,%ebp
801075c0:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
801075c3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801075ca:	00 
801075cb:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
801075d2:	e8 c8 ff ff ff       	call   8010759f <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
801075d7:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
801075de:	00 
801075df:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
801075e6:	e8 b4 ff ff ff       	call   8010759f <outb>
  outb(COM1+0, 115200/9600);
801075eb:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
801075f2:	00 
801075f3:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801075fa:	e8 a0 ff ff ff       	call   8010759f <outb>
  outb(COM1+1, 0);
801075ff:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107606:	00 
80107607:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
8010760e:	e8 8c ff ff ff       	call   8010759f <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80107613:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
8010761a:	00 
8010761b:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107622:	e8 78 ff ff ff       	call   8010759f <outb>
  outb(COM1+4, 0);
80107627:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010762e:	00 
8010762f:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80107636:	e8 64 ff ff ff       	call   8010759f <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
8010763b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80107642:	00 
80107643:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
8010764a:	e8 50 ff ff ff       	call   8010759f <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
8010764f:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107656:	e8 27 ff ff ff       	call   80107582 <inb>
8010765b:	3c ff                	cmp    $0xff,%al
8010765d:	75 02                	jne    80107661 <uartinit+0xa4>
    return;
8010765f:	eb 6a                	jmp    801076cb <uartinit+0x10e>
  uart = 1;
80107661:	c7 05 4c c6 10 80 01 	movl   $0x1,0x8010c64c
80107668:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
8010766b:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107672:	e8 0b ff ff ff       	call   80107582 <inb>
  inb(COM1+0);
80107677:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
8010767e:	e8 ff fe ff ff       	call   80107582 <inb>
  picenable(IRQ_COM1);
80107683:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
8010768a:	e8 3c c9 ff ff       	call   80103fcb <picenable>
  ioapicenable(IRQ_COM1, 0);
8010768f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107696:	00 
80107697:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
8010769e:	e8 cc b4 ff ff       	call   80102b6f <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
801076a3:	c7 45 f4 48 96 10 80 	movl   $0x80109648,-0xc(%ebp)
801076aa:	eb 15                	jmp    801076c1 <uartinit+0x104>
    uartputc(*p);
801076ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076af:	0f b6 00             	movzbl (%eax),%eax
801076b2:	0f be c0             	movsbl %al,%eax
801076b5:	89 04 24             	mov    %eax,(%esp)
801076b8:	e8 10 00 00 00       	call   801076cd <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
801076bd:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801076c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076c4:	0f b6 00             	movzbl (%eax),%eax
801076c7:	84 c0                	test   %al,%al
801076c9:	75 e1                	jne    801076ac <uartinit+0xef>
    uartputc(*p);
}
801076cb:	c9                   	leave  
801076cc:	c3                   	ret    

801076cd <uartputc>:

void
uartputc(int c)
{
801076cd:	55                   	push   %ebp
801076ce:	89 e5                	mov    %esp,%ebp
801076d0:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
801076d3:	a1 4c c6 10 80       	mov    0x8010c64c,%eax
801076d8:	85 c0                	test   %eax,%eax
801076da:	75 02                	jne    801076de <uartputc+0x11>
    return;
801076dc:	eb 4b                	jmp    80107729 <uartputc+0x5c>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801076de:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801076e5:	eb 10                	jmp    801076f7 <uartputc+0x2a>
    microdelay(10);
801076e7:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
801076ee:	e8 14 ba ff ff       	call   80103107 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801076f3:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801076f7:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
801076fb:	7f 16                	jg     80107713 <uartputc+0x46>
801076fd:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107704:	e8 79 fe ff ff       	call   80107582 <inb>
80107709:	0f b6 c0             	movzbl %al,%eax
8010770c:	83 e0 20             	and    $0x20,%eax
8010770f:	85 c0                	test   %eax,%eax
80107711:	74 d4                	je     801076e7 <uartputc+0x1a>
    microdelay(10);
  outb(COM1+0, c);
80107713:	8b 45 08             	mov    0x8(%ebp),%eax
80107716:	0f b6 c0             	movzbl %al,%eax
80107719:	89 44 24 04          	mov    %eax,0x4(%esp)
8010771d:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107724:	e8 76 fe ff ff       	call   8010759f <outb>
}
80107729:	c9                   	leave  
8010772a:	c3                   	ret    

8010772b <uartgetc>:

static int
uartgetc(void)
{
8010772b:	55                   	push   %ebp
8010772c:	89 e5                	mov    %esp,%ebp
8010772e:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80107731:	a1 4c c6 10 80       	mov    0x8010c64c,%eax
80107736:	85 c0                	test   %eax,%eax
80107738:	75 07                	jne    80107741 <uartgetc+0x16>
    return -1;
8010773a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010773f:	eb 2c                	jmp    8010776d <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80107741:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107748:	e8 35 fe ff ff       	call   80107582 <inb>
8010774d:	0f b6 c0             	movzbl %al,%eax
80107750:	83 e0 01             	and    $0x1,%eax
80107753:	85 c0                	test   %eax,%eax
80107755:	75 07                	jne    8010775e <uartgetc+0x33>
    return -1;
80107757:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010775c:	eb 0f                	jmp    8010776d <uartgetc+0x42>
  return inb(COM1+0);
8010775e:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107765:	e8 18 fe ff ff       	call   80107582 <inb>
8010776a:	0f b6 c0             	movzbl %al,%eax
}
8010776d:	c9                   	leave  
8010776e:	c3                   	ret    

8010776f <uartintr>:

void
uartintr(void)
{
8010776f:	55                   	push   %ebp
80107770:	89 e5                	mov    %esp,%ebp
80107772:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80107775:	c7 04 24 2b 77 10 80 	movl   $0x8010772b,(%esp)
8010777c:	e8 2c 90 ff ff       	call   801007ad <consoleintr>
}
80107781:	c9                   	leave  
80107782:	c3                   	ret    

80107783 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80107783:	6a 00                	push   $0x0
  pushl $0
80107785:	6a 00                	push   $0x0
  jmp alltraps
80107787:	e9 7e f9 ff ff       	jmp    8010710a <alltraps>

8010778c <vector1>:
.globl vector1
vector1:
  pushl $0
8010778c:	6a 00                	push   $0x0
  pushl $1
8010778e:	6a 01                	push   $0x1
  jmp alltraps
80107790:	e9 75 f9 ff ff       	jmp    8010710a <alltraps>

80107795 <vector2>:
.globl vector2
vector2:
  pushl $0
80107795:	6a 00                	push   $0x0
  pushl $2
80107797:	6a 02                	push   $0x2
  jmp alltraps
80107799:	e9 6c f9 ff ff       	jmp    8010710a <alltraps>

8010779e <vector3>:
.globl vector3
vector3:
  pushl $0
8010779e:	6a 00                	push   $0x0
  pushl $3
801077a0:	6a 03                	push   $0x3
  jmp alltraps
801077a2:	e9 63 f9 ff ff       	jmp    8010710a <alltraps>

801077a7 <vector4>:
.globl vector4
vector4:
  pushl $0
801077a7:	6a 00                	push   $0x0
  pushl $4
801077a9:	6a 04                	push   $0x4
  jmp alltraps
801077ab:	e9 5a f9 ff ff       	jmp    8010710a <alltraps>

801077b0 <vector5>:
.globl vector5
vector5:
  pushl $0
801077b0:	6a 00                	push   $0x0
  pushl $5
801077b2:	6a 05                	push   $0x5
  jmp alltraps
801077b4:	e9 51 f9 ff ff       	jmp    8010710a <alltraps>

801077b9 <vector6>:
.globl vector6
vector6:
  pushl $0
801077b9:	6a 00                	push   $0x0
  pushl $6
801077bb:	6a 06                	push   $0x6
  jmp alltraps
801077bd:	e9 48 f9 ff ff       	jmp    8010710a <alltraps>

801077c2 <vector7>:
.globl vector7
vector7:
  pushl $0
801077c2:	6a 00                	push   $0x0
  pushl $7
801077c4:	6a 07                	push   $0x7
  jmp alltraps
801077c6:	e9 3f f9 ff ff       	jmp    8010710a <alltraps>

801077cb <vector8>:
.globl vector8
vector8:
  pushl $8
801077cb:	6a 08                	push   $0x8
  jmp alltraps
801077cd:	e9 38 f9 ff ff       	jmp    8010710a <alltraps>

801077d2 <vector9>:
.globl vector9
vector9:
  pushl $0
801077d2:	6a 00                	push   $0x0
  pushl $9
801077d4:	6a 09                	push   $0x9
  jmp alltraps
801077d6:	e9 2f f9 ff ff       	jmp    8010710a <alltraps>

801077db <vector10>:
.globl vector10
vector10:
  pushl $10
801077db:	6a 0a                	push   $0xa
  jmp alltraps
801077dd:	e9 28 f9 ff ff       	jmp    8010710a <alltraps>

801077e2 <vector11>:
.globl vector11
vector11:
  pushl $11
801077e2:	6a 0b                	push   $0xb
  jmp alltraps
801077e4:	e9 21 f9 ff ff       	jmp    8010710a <alltraps>

801077e9 <vector12>:
.globl vector12
vector12:
  pushl $12
801077e9:	6a 0c                	push   $0xc
  jmp alltraps
801077eb:	e9 1a f9 ff ff       	jmp    8010710a <alltraps>

801077f0 <vector13>:
.globl vector13
vector13:
  pushl $13
801077f0:	6a 0d                	push   $0xd
  jmp alltraps
801077f2:	e9 13 f9 ff ff       	jmp    8010710a <alltraps>

801077f7 <vector14>:
.globl vector14
vector14:
  pushl $14
801077f7:	6a 0e                	push   $0xe
  jmp alltraps
801077f9:	e9 0c f9 ff ff       	jmp    8010710a <alltraps>

801077fe <vector15>:
.globl vector15
vector15:
  pushl $0
801077fe:	6a 00                	push   $0x0
  pushl $15
80107800:	6a 0f                	push   $0xf
  jmp alltraps
80107802:	e9 03 f9 ff ff       	jmp    8010710a <alltraps>

80107807 <vector16>:
.globl vector16
vector16:
  pushl $0
80107807:	6a 00                	push   $0x0
  pushl $16
80107809:	6a 10                	push   $0x10
  jmp alltraps
8010780b:	e9 fa f8 ff ff       	jmp    8010710a <alltraps>

80107810 <vector17>:
.globl vector17
vector17:
  pushl $17
80107810:	6a 11                	push   $0x11
  jmp alltraps
80107812:	e9 f3 f8 ff ff       	jmp    8010710a <alltraps>

80107817 <vector18>:
.globl vector18
vector18:
  pushl $0
80107817:	6a 00                	push   $0x0
  pushl $18
80107819:	6a 12                	push   $0x12
  jmp alltraps
8010781b:	e9 ea f8 ff ff       	jmp    8010710a <alltraps>

80107820 <vector19>:
.globl vector19
vector19:
  pushl $0
80107820:	6a 00                	push   $0x0
  pushl $19
80107822:	6a 13                	push   $0x13
  jmp alltraps
80107824:	e9 e1 f8 ff ff       	jmp    8010710a <alltraps>

80107829 <vector20>:
.globl vector20
vector20:
  pushl $0
80107829:	6a 00                	push   $0x0
  pushl $20
8010782b:	6a 14                	push   $0x14
  jmp alltraps
8010782d:	e9 d8 f8 ff ff       	jmp    8010710a <alltraps>

80107832 <vector21>:
.globl vector21
vector21:
  pushl $0
80107832:	6a 00                	push   $0x0
  pushl $21
80107834:	6a 15                	push   $0x15
  jmp alltraps
80107836:	e9 cf f8 ff ff       	jmp    8010710a <alltraps>

8010783b <vector22>:
.globl vector22
vector22:
  pushl $0
8010783b:	6a 00                	push   $0x0
  pushl $22
8010783d:	6a 16                	push   $0x16
  jmp alltraps
8010783f:	e9 c6 f8 ff ff       	jmp    8010710a <alltraps>

80107844 <vector23>:
.globl vector23
vector23:
  pushl $0
80107844:	6a 00                	push   $0x0
  pushl $23
80107846:	6a 17                	push   $0x17
  jmp alltraps
80107848:	e9 bd f8 ff ff       	jmp    8010710a <alltraps>

8010784d <vector24>:
.globl vector24
vector24:
  pushl $0
8010784d:	6a 00                	push   $0x0
  pushl $24
8010784f:	6a 18                	push   $0x18
  jmp alltraps
80107851:	e9 b4 f8 ff ff       	jmp    8010710a <alltraps>

80107856 <vector25>:
.globl vector25
vector25:
  pushl $0
80107856:	6a 00                	push   $0x0
  pushl $25
80107858:	6a 19                	push   $0x19
  jmp alltraps
8010785a:	e9 ab f8 ff ff       	jmp    8010710a <alltraps>

8010785f <vector26>:
.globl vector26
vector26:
  pushl $0
8010785f:	6a 00                	push   $0x0
  pushl $26
80107861:	6a 1a                	push   $0x1a
  jmp alltraps
80107863:	e9 a2 f8 ff ff       	jmp    8010710a <alltraps>

80107868 <vector27>:
.globl vector27
vector27:
  pushl $0
80107868:	6a 00                	push   $0x0
  pushl $27
8010786a:	6a 1b                	push   $0x1b
  jmp alltraps
8010786c:	e9 99 f8 ff ff       	jmp    8010710a <alltraps>

80107871 <vector28>:
.globl vector28
vector28:
  pushl $0
80107871:	6a 00                	push   $0x0
  pushl $28
80107873:	6a 1c                	push   $0x1c
  jmp alltraps
80107875:	e9 90 f8 ff ff       	jmp    8010710a <alltraps>

8010787a <vector29>:
.globl vector29
vector29:
  pushl $0
8010787a:	6a 00                	push   $0x0
  pushl $29
8010787c:	6a 1d                	push   $0x1d
  jmp alltraps
8010787e:	e9 87 f8 ff ff       	jmp    8010710a <alltraps>

80107883 <vector30>:
.globl vector30
vector30:
  pushl $0
80107883:	6a 00                	push   $0x0
  pushl $30
80107885:	6a 1e                	push   $0x1e
  jmp alltraps
80107887:	e9 7e f8 ff ff       	jmp    8010710a <alltraps>

8010788c <vector31>:
.globl vector31
vector31:
  pushl $0
8010788c:	6a 00                	push   $0x0
  pushl $31
8010788e:	6a 1f                	push   $0x1f
  jmp alltraps
80107890:	e9 75 f8 ff ff       	jmp    8010710a <alltraps>

80107895 <vector32>:
.globl vector32
vector32:
  pushl $0
80107895:	6a 00                	push   $0x0
  pushl $32
80107897:	6a 20                	push   $0x20
  jmp alltraps
80107899:	e9 6c f8 ff ff       	jmp    8010710a <alltraps>

8010789e <vector33>:
.globl vector33
vector33:
  pushl $0
8010789e:	6a 00                	push   $0x0
  pushl $33
801078a0:	6a 21                	push   $0x21
  jmp alltraps
801078a2:	e9 63 f8 ff ff       	jmp    8010710a <alltraps>

801078a7 <vector34>:
.globl vector34
vector34:
  pushl $0
801078a7:	6a 00                	push   $0x0
  pushl $34
801078a9:	6a 22                	push   $0x22
  jmp alltraps
801078ab:	e9 5a f8 ff ff       	jmp    8010710a <alltraps>

801078b0 <vector35>:
.globl vector35
vector35:
  pushl $0
801078b0:	6a 00                	push   $0x0
  pushl $35
801078b2:	6a 23                	push   $0x23
  jmp alltraps
801078b4:	e9 51 f8 ff ff       	jmp    8010710a <alltraps>

801078b9 <vector36>:
.globl vector36
vector36:
  pushl $0
801078b9:	6a 00                	push   $0x0
  pushl $36
801078bb:	6a 24                	push   $0x24
  jmp alltraps
801078bd:	e9 48 f8 ff ff       	jmp    8010710a <alltraps>

801078c2 <vector37>:
.globl vector37
vector37:
  pushl $0
801078c2:	6a 00                	push   $0x0
  pushl $37
801078c4:	6a 25                	push   $0x25
  jmp alltraps
801078c6:	e9 3f f8 ff ff       	jmp    8010710a <alltraps>

801078cb <vector38>:
.globl vector38
vector38:
  pushl $0
801078cb:	6a 00                	push   $0x0
  pushl $38
801078cd:	6a 26                	push   $0x26
  jmp alltraps
801078cf:	e9 36 f8 ff ff       	jmp    8010710a <alltraps>

801078d4 <vector39>:
.globl vector39
vector39:
  pushl $0
801078d4:	6a 00                	push   $0x0
  pushl $39
801078d6:	6a 27                	push   $0x27
  jmp alltraps
801078d8:	e9 2d f8 ff ff       	jmp    8010710a <alltraps>

801078dd <vector40>:
.globl vector40
vector40:
  pushl $0
801078dd:	6a 00                	push   $0x0
  pushl $40
801078df:	6a 28                	push   $0x28
  jmp alltraps
801078e1:	e9 24 f8 ff ff       	jmp    8010710a <alltraps>

801078e6 <vector41>:
.globl vector41
vector41:
  pushl $0
801078e6:	6a 00                	push   $0x0
  pushl $41
801078e8:	6a 29                	push   $0x29
  jmp alltraps
801078ea:	e9 1b f8 ff ff       	jmp    8010710a <alltraps>

801078ef <vector42>:
.globl vector42
vector42:
  pushl $0
801078ef:	6a 00                	push   $0x0
  pushl $42
801078f1:	6a 2a                	push   $0x2a
  jmp alltraps
801078f3:	e9 12 f8 ff ff       	jmp    8010710a <alltraps>

801078f8 <vector43>:
.globl vector43
vector43:
  pushl $0
801078f8:	6a 00                	push   $0x0
  pushl $43
801078fa:	6a 2b                	push   $0x2b
  jmp alltraps
801078fc:	e9 09 f8 ff ff       	jmp    8010710a <alltraps>

80107901 <vector44>:
.globl vector44
vector44:
  pushl $0
80107901:	6a 00                	push   $0x0
  pushl $44
80107903:	6a 2c                	push   $0x2c
  jmp alltraps
80107905:	e9 00 f8 ff ff       	jmp    8010710a <alltraps>

8010790a <vector45>:
.globl vector45
vector45:
  pushl $0
8010790a:	6a 00                	push   $0x0
  pushl $45
8010790c:	6a 2d                	push   $0x2d
  jmp alltraps
8010790e:	e9 f7 f7 ff ff       	jmp    8010710a <alltraps>

80107913 <vector46>:
.globl vector46
vector46:
  pushl $0
80107913:	6a 00                	push   $0x0
  pushl $46
80107915:	6a 2e                	push   $0x2e
  jmp alltraps
80107917:	e9 ee f7 ff ff       	jmp    8010710a <alltraps>

8010791c <vector47>:
.globl vector47
vector47:
  pushl $0
8010791c:	6a 00                	push   $0x0
  pushl $47
8010791e:	6a 2f                	push   $0x2f
  jmp alltraps
80107920:	e9 e5 f7 ff ff       	jmp    8010710a <alltraps>

80107925 <vector48>:
.globl vector48
vector48:
  pushl $0
80107925:	6a 00                	push   $0x0
  pushl $48
80107927:	6a 30                	push   $0x30
  jmp alltraps
80107929:	e9 dc f7 ff ff       	jmp    8010710a <alltraps>

8010792e <vector49>:
.globl vector49
vector49:
  pushl $0
8010792e:	6a 00                	push   $0x0
  pushl $49
80107930:	6a 31                	push   $0x31
  jmp alltraps
80107932:	e9 d3 f7 ff ff       	jmp    8010710a <alltraps>

80107937 <vector50>:
.globl vector50
vector50:
  pushl $0
80107937:	6a 00                	push   $0x0
  pushl $50
80107939:	6a 32                	push   $0x32
  jmp alltraps
8010793b:	e9 ca f7 ff ff       	jmp    8010710a <alltraps>

80107940 <vector51>:
.globl vector51
vector51:
  pushl $0
80107940:	6a 00                	push   $0x0
  pushl $51
80107942:	6a 33                	push   $0x33
  jmp alltraps
80107944:	e9 c1 f7 ff ff       	jmp    8010710a <alltraps>

80107949 <vector52>:
.globl vector52
vector52:
  pushl $0
80107949:	6a 00                	push   $0x0
  pushl $52
8010794b:	6a 34                	push   $0x34
  jmp alltraps
8010794d:	e9 b8 f7 ff ff       	jmp    8010710a <alltraps>

80107952 <vector53>:
.globl vector53
vector53:
  pushl $0
80107952:	6a 00                	push   $0x0
  pushl $53
80107954:	6a 35                	push   $0x35
  jmp alltraps
80107956:	e9 af f7 ff ff       	jmp    8010710a <alltraps>

8010795b <vector54>:
.globl vector54
vector54:
  pushl $0
8010795b:	6a 00                	push   $0x0
  pushl $54
8010795d:	6a 36                	push   $0x36
  jmp alltraps
8010795f:	e9 a6 f7 ff ff       	jmp    8010710a <alltraps>

80107964 <vector55>:
.globl vector55
vector55:
  pushl $0
80107964:	6a 00                	push   $0x0
  pushl $55
80107966:	6a 37                	push   $0x37
  jmp alltraps
80107968:	e9 9d f7 ff ff       	jmp    8010710a <alltraps>

8010796d <vector56>:
.globl vector56
vector56:
  pushl $0
8010796d:	6a 00                	push   $0x0
  pushl $56
8010796f:	6a 38                	push   $0x38
  jmp alltraps
80107971:	e9 94 f7 ff ff       	jmp    8010710a <alltraps>

80107976 <vector57>:
.globl vector57
vector57:
  pushl $0
80107976:	6a 00                	push   $0x0
  pushl $57
80107978:	6a 39                	push   $0x39
  jmp alltraps
8010797a:	e9 8b f7 ff ff       	jmp    8010710a <alltraps>

8010797f <vector58>:
.globl vector58
vector58:
  pushl $0
8010797f:	6a 00                	push   $0x0
  pushl $58
80107981:	6a 3a                	push   $0x3a
  jmp alltraps
80107983:	e9 82 f7 ff ff       	jmp    8010710a <alltraps>

80107988 <vector59>:
.globl vector59
vector59:
  pushl $0
80107988:	6a 00                	push   $0x0
  pushl $59
8010798a:	6a 3b                	push   $0x3b
  jmp alltraps
8010798c:	e9 79 f7 ff ff       	jmp    8010710a <alltraps>

80107991 <vector60>:
.globl vector60
vector60:
  pushl $0
80107991:	6a 00                	push   $0x0
  pushl $60
80107993:	6a 3c                	push   $0x3c
  jmp alltraps
80107995:	e9 70 f7 ff ff       	jmp    8010710a <alltraps>

8010799a <vector61>:
.globl vector61
vector61:
  pushl $0
8010799a:	6a 00                	push   $0x0
  pushl $61
8010799c:	6a 3d                	push   $0x3d
  jmp alltraps
8010799e:	e9 67 f7 ff ff       	jmp    8010710a <alltraps>

801079a3 <vector62>:
.globl vector62
vector62:
  pushl $0
801079a3:	6a 00                	push   $0x0
  pushl $62
801079a5:	6a 3e                	push   $0x3e
  jmp alltraps
801079a7:	e9 5e f7 ff ff       	jmp    8010710a <alltraps>

801079ac <vector63>:
.globl vector63
vector63:
  pushl $0
801079ac:	6a 00                	push   $0x0
  pushl $63
801079ae:	6a 3f                	push   $0x3f
  jmp alltraps
801079b0:	e9 55 f7 ff ff       	jmp    8010710a <alltraps>

801079b5 <vector64>:
.globl vector64
vector64:
  pushl $0
801079b5:	6a 00                	push   $0x0
  pushl $64
801079b7:	6a 40                	push   $0x40
  jmp alltraps
801079b9:	e9 4c f7 ff ff       	jmp    8010710a <alltraps>

801079be <vector65>:
.globl vector65
vector65:
  pushl $0
801079be:	6a 00                	push   $0x0
  pushl $65
801079c0:	6a 41                	push   $0x41
  jmp alltraps
801079c2:	e9 43 f7 ff ff       	jmp    8010710a <alltraps>

801079c7 <vector66>:
.globl vector66
vector66:
  pushl $0
801079c7:	6a 00                	push   $0x0
  pushl $66
801079c9:	6a 42                	push   $0x42
  jmp alltraps
801079cb:	e9 3a f7 ff ff       	jmp    8010710a <alltraps>

801079d0 <vector67>:
.globl vector67
vector67:
  pushl $0
801079d0:	6a 00                	push   $0x0
  pushl $67
801079d2:	6a 43                	push   $0x43
  jmp alltraps
801079d4:	e9 31 f7 ff ff       	jmp    8010710a <alltraps>

801079d9 <vector68>:
.globl vector68
vector68:
  pushl $0
801079d9:	6a 00                	push   $0x0
  pushl $68
801079db:	6a 44                	push   $0x44
  jmp alltraps
801079dd:	e9 28 f7 ff ff       	jmp    8010710a <alltraps>

801079e2 <vector69>:
.globl vector69
vector69:
  pushl $0
801079e2:	6a 00                	push   $0x0
  pushl $69
801079e4:	6a 45                	push   $0x45
  jmp alltraps
801079e6:	e9 1f f7 ff ff       	jmp    8010710a <alltraps>

801079eb <vector70>:
.globl vector70
vector70:
  pushl $0
801079eb:	6a 00                	push   $0x0
  pushl $70
801079ed:	6a 46                	push   $0x46
  jmp alltraps
801079ef:	e9 16 f7 ff ff       	jmp    8010710a <alltraps>

801079f4 <vector71>:
.globl vector71
vector71:
  pushl $0
801079f4:	6a 00                	push   $0x0
  pushl $71
801079f6:	6a 47                	push   $0x47
  jmp alltraps
801079f8:	e9 0d f7 ff ff       	jmp    8010710a <alltraps>

801079fd <vector72>:
.globl vector72
vector72:
  pushl $0
801079fd:	6a 00                	push   $0x0
  pushl $72
801079ff:	6a 48                	push   $0x48
  jmp alltraps
80107a01:	e9 04 f7 ff ff       	jmp    8010710a <alltraps>

80107a06 <vector73>:
.globl vector73
vector73:
  pushl $0
80107a06:	6a 00                	push   $0x0
  pushl $73
80107a08:	6a 49                	push   $0x49
  jmp alltraps
80107a0a:	e9 fb f6 ff ff       	jmp    8010710a <alltraps>

80107a0f <vector74>:
.globl vector74
vector74:
  pushl $0
80107a0f:	6a 00                	push   $0x0
  pushl $74
80107a11:	6a 4a                	push   $0x4a
  jmp alltraps
80107a13:	e9 f2 f6 ff ff       	jmp    8010710a <alltraps>

80107a18 <vector75>:
.globl vector75
vector75:
  pushl $0
80107a18:	6a 00                	push   $0x0
  pushl $75
80107a1a:	6a 4b                	push   $0x4b
  jmp alltraps
80107a1c:	e9 e9 f6 ff ff       	jmp    8010710a <alltraps>

80107a21 <vector76>:
.globl vector76
vector76:
  pushl $0
80107a21:	6a 00                	push   $0x0
  pushl $76
80107a23:	6a 4c                	push   $0x4c
  jmp alltraps
80107a25:	e9 e0 f6 ff ff       	jmp    8010710a <alltraps>

80107a2a <vector77>:
.globl vector77
vector77:
  pushl $0
80107a2a:	6a 00                	push   $0x0
  pushl $77
80107a2c:	6a 4d                	push   $0x4d
  jmp alltraps
80107a2e:	e9 d7 f6 ff ff       	jmp    8010710a <alltraps>

80107a33 <vector78>:
.globl vector78
vector78:
  pushl $0
80107a33:	6a 00                	push   $0x0
  pushl $78
80107a35:	6a 4e                	push   $0x4e
  jmp alltraps
80107a37:	e9 ce f6 ff ff       	jmp    8010710a <alltraps>

80107a3c <vector79>:
.globl vector79
vector79:
  pushl $0
80107a3c:	6a 00                	push   $0x0
  pushl $79
80107a3e:	6a 4f                	push   $0x4f
  jmp alltraps
80107a40:	e9 c5 f6 ff ff       	jmp    8010710a <alltraps>

80107a45 <vector80>:
.globl vector80
vector80:
  pushl $0
80107a45:	6a 00                	push   $0x0
  pushl $80
80107a47:	6a 50                	push   $0x50
  jmp alltraps
80107a49:	e9 bc f6 ff ff       	jmp    8010710a <alltraps>

80107a4e <vector81>:
.globl vector81
vector81:
  pushl $0
80107a4e:	6a 00                	push   $0x0
  pushl $81
80107a50:	6a 51                	push   $0x51
  jmp alltraps
80107a52:	e9 b3 f6 ff ff       	jmp    8010710a <alltraps>

80107a57 <vector82>:
.globl vector82
vector82:
  pushl $0
80107a57:	6a 00                	push   $0x0
  pushl $82
80107a59:	6a 52                	push   $0x52
  jmp alltraps
80107a5b:	e9 aa f6 ff ff       	jmp    8010710a <alltraps>

80107a60 <vector83>:
.globl vector83
vector83:
  pushl $0
80107a60:	6a 00                	push   $0x0
  pushl $83
80107a62:	6a 53                	push   $0x53
  jmp alltraps
80107a64:	e9 a1 f6 ff ff       	jmp    8010710a <alltraps>

80107a69 <vector84>:
.globl vector84
vector84:
  pushl $0
80107a69:	6a 00                	push   $0x0
  pushl $84
80107a6b:	6a 54                	push   $0x54
  jmp alltraps
80107a6d:	e9 98 f6 ff ff       	jmp    8010710a <alltraps>

80107a72 <vector85>:
.globl vector85
vector85:
  pushl $0
80107a72:	6a 00                	push   $0x0
  pushl $85
80107a74:	6a 55                	push   $0x55
  jmp alltraps
80107a76:	e9 8f f6 ff ff       	jmp    8010710a <alltraps>

80107a7b <vector86>:
.globl vector86
vector86:
  pushl $0
80107a7b:	6a 00                	push   $0x0
  pushl $86
80107a7d:	6a 56                	push   $0x56
  jmp alltraps
80107a7f:	e9 86 f6 ff ff       	jmp    8010710a <alltraps>

80107a84 <vector87>:
.globl vector87
vector87:
  pushl $0
80107a84:	6a 00                	push   $0x0
  pushl $87
80107a86:	6a 57                	push   $0x57
  jmp alltraps
80107a88:	e9 7d f6 ff ff       	jmp    8010710a <alltraps>

80107a8d <vector88>:
.globl vector88
vector88:
  pushl $0
80107a8d:	6a 00                	push   $0x0
  pushl $88
80107a8f:	6a 58                	push   $0x58
  jmp alltraps
80107a91:	e9 74 f6 ff ff       	jmp    8010710a <alltraps>

80107a96 <vector89>:
.globl vector89
vector89:
  pushl $0
80107a96:	6a 00                	push   $0x0
  pushl $89
80107a98:	6a 59                	push   $0x59
  jmp alltraps
80107a9a:	e9 6b f6 ff ff       	jmp    8010710a <alltraps>

80107a9f <vector90>:
.globl vector90
vector90:
  pushl $0
80107a9f:	6a 00                	push   $0x0
  pushl $90
80107aa1:	6a 5a                	push   $0x5a
  jmp alltraps
80107aa3:	e9 62 f6 ff ff       	jmp    8010710a <alltraps>

80107aa8 <vector91>:
.globl vector91
vector91:
  pushl $0
80107aa8:	6a 00                	push   $0x0
  pushl $91
80107aaa:	6a 5b                	push   $0x5b
  jmp alltraps
80107aac:	e9 59 f6 ff ff       	jmp    8010710a <alltraps>

80107ab1 <vector92>:
.globl vector92
vector92:
  pushl $0
80107ab1:	6a 00                	push   $0x0
  pushl $92
80107ab3:	6a 5c                	push   $0x5c
  jmp alltraps
80107ab5:	e9 50 f6 ff ff       	jmp    8010710a <alltraps>

80107aba <vector93>:
.globl vector93
vector93:
  pushl $0
80107aba:	6a 00                	push   $0x0
  pushl $93
80107abc:	6a 5d                	push   $0x5d
  jmp alltraps
80107abe:	e9 47 f6 ff ff       	jmp    8010710a <alltraps>

80107ac3 <vector94>:
.globl vector94
vector94:
  pushl $0
80107ac3:	6a 00                	push   $0x0
  pushl $94
80107ac5:	6a 5e                	push   $0x5e
  jmp alltraps
80107ac7:	e9 3e f6 ff ff       	jmp    8010710a <alltraps>

80107acc <vector95>:
.globl vector95
vector95:
  pushl $0
80107acc:	6a 00                	push   $0x0
  pushl $95
80107ace:	6a 5f                	push   $0x5f
  jmp alltraps
80107ad0:	e9 35 f6 ff ff       	jmp    8010710a <alltraps>

80107ad5 <vector96>:
.globl vector96
vector96:
  pushl $0
80107ad5:	6a 00                	push   $0x0
  pushl $96
80107ad7:	6a 60                	push   $0x60
  jmp alltraps
80107ad9:	e9 2c f6 ff ff       	jmp    8010710a <alltraps>

80107ade <vector97>:
.globl vector97
vector97:
  pushl $0
80107ade:	6a 00                	push   $0x0
  pushl $97
80107ae0:	6a 61                	push   $0x61
  jmp alltraps
80107ae2:	e9 23 f6 ff ff       	jmp    8010710a <alltraps>

80107ae7 <vector98>:
.globl vector98
vector98:
  pushl $0
80107ae7:	6a 00                	push   $0x0
  pushl $98
80107ae9:	6a 62                	push   $0x62
  jmp alltraps
80107aeb:	e9 1a f6 ff ff       	jmp    8010710a <alltraps>

80107af0 <vector99>:
.globl vector99
vector99:
  pushl $0
80107af0:	6a 00                	push   $0x0
  pushl $99
80107af2:	6a 63                	push   $0x63
  jmp alltraps
80107af4:	e9 11 f6 ff ff       	jmp    8010710a <alltraps>

80107af9 <vector100>:
.globl vector100
vector100:
  pushl $0
80107af9:	6a 00                	push   $0x0
  pushl $100
80107afb:	6a 64                	push   $0x64
  jmp alltraps
80107afd:	e9 08 f6 ff ff       	jmp    8010710a <alltraps>

80107b02 <vector101>:
.globl vector101
vector101:
  pushl $0
80107b02:	6a 00                	push   $0x0
  pushl $101
80107b04:	6a 65                	push   $0x65
  jmp alltraps
80107b06:	e9 ff f5 ff ff       	jmp    8010710a <alltraps>

80107b0b <vector102>:
.globl vector102
vector102:
  pushl $0
80107b0b:	6a 00                	push   $0x0
  pushl $102
80107b0d:	6a 66                	push   $0x66
  jmp alltraps
80107b0f:	e9 f6 f5 ff ff       	jmp    8010710a <alltraps>

80107b14 <vector103>:
.globl vector103
vector103:
  pushl $0
80107b14:	6a 00                	push   $0x0
  pushl $103
80107b16:	6a 67                	push   $0x67
  jmp alltraps
80107b18:	e9 ed f5 ff ff       	jmp    8010710a <alltraps>

80107b1d <vector104>:
.globl vector104
vector104:
  pushl $0
80107b1d:	6a 00                	push   $0x0
  pushl $104
80107b1f:	6a 68                	push   $0x68
  jmp alltraps
80107b21:	e9 e4 f5 ff ff       	jmp    8010710a <alltraps>

80107b26 <vector105>:
.globl vector105
vector105:
  pushl $0
80107b26:	6a 00                	push   $0x0
  pushl $105
80107b28:	6a 69                	push   $0x69
  jmp alltraps
80107b2a:	e9 db f5 ff ff       	jmp    8010710a <alltraps>

80107b2f <vector106>:
.globl vector106
vector106:
  pushl $0
80107b2f:	6a 00                	push   $0x0
  pushl $106
80107b31:	6a 6a                	push   $0x6a
  jmp alltraps
80107b33:	e9 d2 f5 ff ff       	jmp    8010710a <alltraps>

80107b38 <vector107>:
.globl vector107
vector107:
  pushl $0
80107b38:	6a 00                	push   $0x0
  pushl $107
80107b3a:	6a 6b                	push   $0x6b
  jmp alltraps
80107b3c:	e9 c9 f5 ff ff       	jmp    8010710a <alltraps>

80107b41 <vector108>:
.globl vector108
vector108:
  pushl $0
80107b41:	6a 00                	push   $0x0
  pushl $108
80107b43:	6a 6c                	push   $0x6c
  jmp alltraps
80107b45:	e9 c0 f5 ff ff       	jmp    8010710a <alltraps>

80107b4a <vector109>:
.globl vector109
vector109:
  pushl $0
80107b4a:	6a 00                	push   $0x0
  pushl $109
80107b4c:	6a 6d                	push   $0x6d
  jmp alltraps
80107b4e:	e9 b7 f5 ff ff       	jmp    8010710a <alltraps>

80107b53 <vector110>:
.globl vector110
vector110:
  pushl $0
80107b53:	6a 00                	push   $0x0
  pushl $110
80107b55:	6a 6e                	push   $0x6e
  jmp alltraps
80107b57:	e9 ae f5 ff ff       	jmp    8010710a <alltraps>

80107b5c <vector111>:
.globl vector111
vector111:
  pushl $0
80107b5c:	6a 00                	push   $0x0
  pushl $111
80107b5e:	6a 6f                	push   $0x6f
  jmp alltraps
80107b60:	e9 a5 f5 ff ff       	jmp    8010710a <alltraps>

80107b65 <vector112>:
.globl vector112
vector112:
  pushl $0
80107b65:	6a 00                	push   $0x0
  pushl $112
80107b67:	6a 70                	push   $0x70
  jmp alltraps
80107b69:	e9 9c f5 ff ff       	jmp    8010710a <alltraps>

80107b6e <vector113>:
.globl vector113
vector113:
  pushl $0
80107b6e:	6a 00                	push   $0x0
  pushl $113
80107b70:	6a 71                	push   $0x71
  jmp alltraps
80107b72:	e9 93 f5 ff ff       	jmp    8010710a <alltraps>

80107b77 <vector114>:
.globl vector114
vector114:
  pushl $0
80107b77:	6a 00                	push   $0x0
  pushl $114
80107b79:	6a 72                	push   $0x72
  jmp alltraps
80107b7b:	e9 8a f5 ff ff       	jmp    8010710a <alltraps>

80107b80 <vector115>:
.globl vector115
vector115:
  pushl $0
80107b80:	6a 00                	push   $0x0
  pushl $115
80107b82:	6a 73                	push   $0x73
  jmp alltraps
80107b84:	e9 81 f5 ff ff       	jmp    8010710a <alltraps>

80107b89 <vector116>:
.globl vector116
vector116:
  pushl $0
80107b89:	6a 00                	push   $0x0
  pushl $116
80107b8b:	6a 74                	push   $0x74
  jmp alltraps
80107b8d:	e9 78 f5 ff ff       	jmp    8010710a <alltraps>

80107b92 <vector117>:
.globl vector117
vector117:
  pushl $0
80107b92:	6a 00                	push   $0x0
  pushl $117
80107b94:	6a 75                	push   $0x75
  jmp alltraps
80107b96:	e9 6f f5 ff ff       	jmp    8010710a <alltraps>

80107b9b <vector118>:
.globl vector118
vector118:
  pushl $0
80107b9b:	6a 00                	push   $0x0
  pushl $118
80107b9d:	6a 76                	push   $0x76
  jmp alltraps
80107b9f:	e9 66 f5 ff ff       	jmp    8010710a <alltraps>

80107ba4 <vector119>:
.globl vector119
vector119:
  pushl $0
80107ba4:	6a 00                	push   $0x0
  pushl $119
80107ba6:	6a 77                	push   $0x77
  jmp alltraps
80107ba8:	e9 5d f5 ff ff       	jmp    8010710a <alltraps>

80107bad <vector120>:
.globl vector120
vector120:
  pushl $0
80107bad:	6a 00                	push   $0x0
  pushl $120
80107baf:	6a 78                	push   $0x78
  jmp alltraps
80107bb1:	e9 54 f5 ff ff       	jmp    8010710a <alltraps>

80107bb6 <vector121>:
.globl vector121
vector121:
  pushl $0
80107bb6:	6a 00                	push   $0x0
  pushl $121
80107bb8:	6a 79                	push   $0x79
  jmp alltraps
80107bba:	e9 4b f5 ff ff       	jmp    8010710a <alltraps>

80107bbf <vector122>:
.globl vector122
vector122:
  pushl $0
80107bbf:	6a 00                	push   $0x0
  pushl $122
80107bc1:	6a 7a                	push   $0x7a
  jmp alltraps
80107bc3:	e9 42 f5 ff ff       	jmp    8010710a <alltraps>

80107bc8 <vector123>:
.globl vector123
vector123:
  pushl $0
80107bc8:	6a 00                	push   $0x0
  pushl $123
80107bca:	6a 7b                	push   $0x7b
  jmp alltraps
80107bcc:	e9 39 f5 ff ff       	jmp    8010710a <alltraps>

80107bd1 <vector124>:
.globl vector124
vector124:
  pushl $0
80107bd1:	6a 00                	push   $0x0
  pushl $124
80107bd3:	6a 7c                	push   $0x7c
  jmp alltraps
80107bd5:	e9 30 f5 ff ff       	jmp    8010710a <alltraps>

80107bda <vector125>:
.globl vector125
vector125:
  pushl $0
80107bda:	6a 00                	push   $0x0
  pushl $125
80107bdc:	6a 7d                	push   $0x7d
  jmp alltraps
80107bde:	e9 27 f5 ff ff       	jmp    8010710a <alltraps>

80107be3 <vector126>:
.globl vector126
vector126:
  pushl $0
80107be3:	6a 00                	push   $0x0
  pushl $126
80107be5:	6a 7e                	push   $0x7e
  jmp alltraps
80107be7:	e9 1e f5 ff ff       	jmp    8010710a <alltraps>

80107bec <vector127>:
.globl vector127
vector127:
  pushl $0
80107bec:	6a 00                	push   $0x0
  pushl $127
80107bee:	6a 7f                	push   $0x7f
  jmp alltraps
80107bf0:	e9 15 f5 ff ff       	jmp    8010710a <alltraps>

80107bf5 <vector128>:
.globl vector128
vector128:
  pushl $0
80107bf5:	6a 00                	push   $0x0
  pushl $128
80107bf7:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80107bfc:	e9 09 f5 ff ff       	jmp    8010710a <alltraps>

80107c01 <vector129>:
.globl vector129
vector129:
  pushl $0
80107c01:	6a 00                	push   $0x0
  pushl $129
80107c03:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80107c08:	e9 fd f4 ff ff       	jmp    8010710a <alltraps>

80107c0d <vector130>:
.globl vector130
vector130:
  pushl $0
80107c0d:	6a 00                	push   $0x0
  pushl $130
80107c0f:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80107c14:	e9 f1 f4 ff ff       	jmp    8010710a <alltraps>

80107c19 <vector131>:
.globl vector131
vector131:
  pushl $0
80107c19:	6a 00                	push   $0x0
  pushl $131
80107c1b:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107c20:	e9 e5 f4 ff ff       	jmp    8010710a <alltraps>

80107c25 <vector132>:
.globl vector132
vector132:
  pushl $0
80107c25:	6a 00                	push   $0x0
  pushl $132
80107c27:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80107c2c:	e9 d9 f4 ff ff       	jmp    8010710a <alltraps>

80107c31 <vector133>:
.globl vector133
vector133:
  pushl $0
80107c31:	6a 00                	push   $0x0
  pushl $133
80107c33:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80107c38:	e9 cd f4 ff ff       	jmp    8010710a <alltraps>

80107c3d <vector134>:
.globl vector134
vector134:
  pushl $0
80107c3d:	6a 00                	push   $0x0
  pushl $134
80107c3f:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80107c44:	e9 c1 f4 ff ff       	jmp    8010710a <alltraps>

80107c49 <vector135>:
.globl vector135
vector135:
  pushl $0
80107c49:	6a 00                	push   $0x0
  pushl $135
80107c4b:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80107c50:	e9 b5 f4 ff ff       	jmp    8010710a <alltraps>

80107c55 <vector136>:
.globl vector136
vector136:
  pushl $0
80107c55:	6a 00                	push   $0x0
  pushl $136
80107c57:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80107c5c:	e9 a9 f4 ff ff       	jmp    8010710a <alltraps>

80107c61 <vector137>:
.globl vector137
vector137:
  pushl $0
80107c61:	6a 00                	push   $0x0
  pushl $137
80107c63:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80107c68:	e9 9d f4 ff ff       	jmp    8010710a <alltraps>

80107c6d <vector138>:
.globl vector138
vector138:
  pushl $0
80107c6d:	6a 00                	push   $0x0
  pushl $138
80107c6f:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80107c74:	e9 91 f4 ff ff       	jmp    8010710a <alltraps>

80107c79 <vector139>:
.globl vector139
vector139:
  pushl $0
80107c79:	6a 00                	push   $0x0
  pushl $139
80107c7b:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80107c80:	e9 85 f4 ff ff       	jmp    8010710a <alltraps>

80107c85 <vector140>:
.globl vector140
vector140:
  pushl $0
80107c85:	6a 00                	push   $0x0
  pushl $140
80107c87:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80107c8c:	e9 79 f4 ff ff       	jmp    8010710a <alltraps>

80107c91 <vector141>:
.globl vector141
vector141:
  pushl $0
80107c91:	6a 00                	push   $0x0
  pushl $141
80107c93:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80107c98:	e9 6d f4 ff ff       	jmp    8010710a <alltraps>

80107c9d <vector142>:
.globl vector142
vector142:
  pushl $0
80107c9d:	6a 00                	push   $0x0
  pushl $142
80107c9f:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107ca4:	e9 61 f4 ff ff       	jmp    8010710a <alltraps>

80107ca9 <vector143>:
.globl vector143
vector143:
  pushl $0
80107ca9:	6a 00                	push   $0x0
  pushl $143
80107cab:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107cb0:	e9 55 f4 ff ff       	jmp    8010710a <alltraps>

80107cb5 <vector144>:
.globl vector144
vector144:
  pushl $0
80107cb5:	6a 00                	push   $0x0
  pushl $144
80107cb7:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80107cbc:	e9 49 f4 ff ff       	jmp    8010710a <alltraps>

80107cc1 <vector145>:
.globl vector145
vector145:
  pushl $0
80107cc1:	6a 00                	push   $0x0
  pushl $145
80107cc3:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80107cc8:	e9 3d f4 ff ff       	jmp    8010710a <alltraps>

80107ccd <vector146>:
.globl vector146
vector146:
  pushl $0
80107ccd:	6a 00                	push   $0x0
  pushl $146
80107ccf:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80107cd4:	e9 31 f4 ff ff       	jmp    8010710a <alltraps>

80107cd9 <vector147>:
.globl vector147
vector147:
  pushl $0
80107cd9:	6a 00                	push   $0x0
  pushl $147
80107cdb:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80107ce0:	e9 25 f4 ff ff       	jmp    8010710a <alltraps>

80107ce5 <vector148>:
.globl vector148
vector148:
  pushl $0
80107ce5:	6a 00                	push   $0x0
  pushl $148
80107ce7:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80107cec:	e9 19 f4 ff ff       	jmp    8010710a <alltraps>

80107cf1 <vector149>:
.globl vector149
vector149:
  pushl $0
80107cf1:	6a 00                	push   $0x0
  pushl $149
80107cf3:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80107cf8:	e9 0d f4 ff ff       	jmp    8010710a <alltraps>

80107cfd <vector150>:
.globl vector150
vector150:
  pushl $0
80107cfd:	6a 00                	push   $0x0
  pushl $150
80107cff:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80107d04:	e9 01 f4 ff ff       	jmp    8010710a <alltraps>

80107d09 <vector151>:
.globl vector151
vector151:
  pushl $0
80107d09:	6a 00                	push   $0x0
  pushl $151
80107d0b:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80107d10:	e9 f5 f3 ff ff       	jmp    8010710a <alltraps>

80107d15 <vector152>:
.globl vector152
vector152:
  pushl $0
80107d15:	6a 00                	push   $0x0
  pushl $152
80107d17:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107d1c:	e9 e9 f3 ff ff       	jmp    8010710a <alltraps>

80107d21 <vector153>:
.globl vector153
vector153:
  pushl $0
80107d21:	6a 00                	push   $0x0
  pushl $153
80107d23:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107d28:	e9 dd f3 ff ff       	jmp    8010710a <alltraps>

80107d2d <vector154>:
.globl vector154
vector154:
  pushl $0
80107d2d:	6a 00                	push   $0x0
  pushl $154
80107d2f:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80107d34:	e9 d1 f3 ff ff       	jmp    8010710a <alltraps>

80107d39 <vector155>:
.globl vector155
vector155:
  pushl $0
80107d39:	6a 00                	push   $0x0
  pushl $155
80107d3b:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107d40:	e9 c5 f3 ff ff       	jmp    8010710a <alltraps>

80107d45 <vector156>:
.globl vector156
vector156:
  pushl $0
80107d45:	6a 00                	push   $0x0
  pushl $156
80107d47:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107d4c:	e9 b9 f3 ff ff       	jmp    8010710a <alltraps>

80107d51 <vector157>:
.globl vector157
vector157:
  pushl $0
80107d51:	6a 00                	push   $0x0
  pushl $157
80107d53:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80107d58:	e9 ad f3 ff ff       	jmp    8010710a <alltraps>

80107d5d <vector158>:
.globl vector158
vector158:
  pushl $0
80107d5d:	6a 00                	push   $0x0
  pushl $158
80107d5f:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107d64:	e9 a1 f3 ff ff       	jmp    8010710a <alltraps>

80107d69 <vector159>:
.globl vector159
vector159:
  pushl $0
80107d69:	6a 00                	push   $0x0
  pushl $159
80107d6b:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107d70:	e9 95 f3 ff ff       	jmp    8010710a <alltraps>

80107d75 <vector160>:
.globl vector160
vector160:
  pushl $0
80107d75:	6a 00                	push   $0x0
  pushl $160
80107d77:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80107d7c:	e9 89 f3 ff ff       	jmp    8010710a <alltraps>

80107d81 <vector161>:
.globl vector161
vector161:
  pushl $0
80107d81:	6a 00                	push   $0x0
  pushl $161
80107d83:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80107d88:	e9 7d f3 ff ff       	jmp    8010710a <alltraps>

80107d8d <vector162>:
.globl vector162
vector162:
  pushl $0
80107d8d:	6a 00                	push   $0x0
  pushl $162
80107d8f:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107d94:	e9 71 f3 ff ff       	jmp    8010710a <alltraps>

80107d99 <vector163>:
.globl vector163
vector163:
  pushl $0
80107d99:	6a 00                	push   $0x0
  pushl $163
80107d9b:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107da0:	e9 65 f3 ff ff       	jmp    8010710a <alltraps>

80107da5 <vector164>:
.globl vector164
vector164:
  pushl $0
80107da5:	6a 00                	push   $0x0
  pushl $164
80107da7:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80107dac:	e9 59 f3 ff ff       	jmp    8010710a <alltraps>

80107db1 <vector165>:
.globl vector165
vector165:
  pushl $0
80107db1:	6a 00                	push   $0x0
  pushl $165
80107db3:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107db8:	e9 4d f3 ff ff       	jmp    8010710a <alltraps>

80107dbd <vector166>:
.globl vector166
vector166:
  pushl $0
80107dbd:	6a 00                	push   $0x0
  pushl $166
80107dbf:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107dc4:	e9 41 f3 ff ff       	jmp    8010710a <alltraps>

80107dc9 <vector167>:
.globl vector167
vector167:
  pushl $0
80107dc9:	6a 00                	push   $0x0
  pushl $167
80107dcb:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107dd0:	e9 35 f3 ff ff       	jmp    8010710a <alltraps>

80107dd5 <vector168>:
.globl vector168
vector168:
  pushl $0
80107dd5:	6a 00                	push   $0x0
  pushl $168
80107dd7:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107ddc:	e9 29 f3 ff ff       	jmp    8010710a <alltraps>

80107de1 <vector169>:
.globl vector169
vector169:
  pushl $0
80107de1:	6a 00                	push   $0x0
  pushl $169
80107de3:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107de8:	e9 1d f3 ff ff       	jmp    8010710a <alltraps>

80107ded <vector170>:
.globl vector170
vector170:
  pushl $0
80107ded:	6a 00                	push   $0x0
  pushl $170
80107def:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107df4:	e9 11 f3 ff ff       	jmp    8010710a <alltraps>

80107df9 <vector171>:
.globl vector171
vector171:
  pushl $0
80107df9:	6a 00                	push   $0x0
  pushl $171
80107dfb:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107e00:	e9 05 f3 ff ff       	jmp    8010710a <alltraps>

80107e05 <vector172>:
.globl vector172
vector172:
  pushl $0
80107e05:	6a 00                	push   $0x0
  pushl $172
80107e07:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107e0c:	e9 f9 f2 ff ff       	jmp    8010710a <alltraps>

80107e11 <vector173>:
.globl vector173
vector173:
  pushl $0
80107e11:	6a 00                	push   $0x0
  pushl $173
80107e13:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107e18:	e9 ed f2 ff ff       	jmp    8010710a <alltraps>

80107e1d <vector174>:
.globl vector174
vector174:
  pushl $0
80107e1d:	6a 00                	push   $0x0
  pushl $174
80107e1f:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107e24:	e9 e1 f2 ff ff       	jmp    8010710a <alltraps>

80107e29 <vector175>:
.globl vector175
vector175:
  pushl $0
80107e29:	6a 00                	push   $0x0
  pushl $175
80107e2b:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107e30:	e9 d5 f2 ff ff       	jmp    8010710a <alltraps>

80107e35 <vector176>:
.globl vector176
vector176:
  pushl $0
80107e35:	6a 00                	push   $0x0
  pushl $176
80107e37:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107e3c:	e9 c9 f2 ff ff       	jmp    8010710a <alltraps>

80107e41 <vector177>:
.globl vector177
vector177:
  pushl $0
80107e41:	6a 00                	push   $0x0
  pushl $177
80107e43:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107e48:	e9 bd f2 ff ff       	jmp    8010710a <alltraps>

80107e4d <vector178>:
.globl vector178
vector178:
  pushl $0
80107e4d:	6a 00                	push   $0x0
  pushl $178
80107e4f:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107e54:	e9 b1 f2 ff ff       	jmp    8010710a <alltraps>

80107e59 <vector179>:
.globl vector179
vector179:
  pushl $0
80107e59:	6a 00                	push   $0x0
  pushl $179
80107e5b:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107e60:	e9 a5 f2 ff ff       	jmp    8010710a <alltraps>

80107e65 <vector180>:
.globl vector180
vector180:
  pushl $0
80107e65:	6a 00                	push   $0x0
  pushl $180
80107e67:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107e6c:	e9 99 f2 ff ff       	jmp    8010710a <alltraps>

80107e71 <vector181>:
.globl vector181
vector181:
  pushl $0
80107e71:	6a 00                	push   $0x0
  pushl $181
80107e73:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107e78:	e9 8d f2 ff ff       	jmp    8010710a <alltraps>

80107e7d <vector182>:
.globl vector182
vector182:
  pushl $0
80107e7d:	6a 00                	push   $0x0
  pushl $182
80107e7f:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107e84:	e9 81 f2 ff ff       	jmp    8010710a <alltraps>

80107e89 <vector183>:
.globl vector183
vector183:
  pushl $0
80107e89:	6a 00                	push   $0x0
  pushl $183
80107e8b:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107e90:	e9 75 f2 ff ff       	jmp    8010710a <alltraps>

80107e95 <vector184>:
.globl vector184
vector184:
  pushl $0
80107e95:	6a 00                	push   $0x0
  pushl $184
80107e97:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80107e9c:	e9 69 f2 ff ff       	jmp    8010710a <alltraps>

80107ea1 <vector185>:
.globl vector185
vector185:
  pushl $0
80107ea1:	6a 00                	push   $0x0
  pushl $185
80107ea3:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107ea8:	e9 5d f2 ff ff       	jmp    8010710a <alltraps>

80107ead <vector186>:
.globl vector186
vector186:
  pushl $0
80107ead:	6a 00                	push   $0x0
  pushl $186
80107eaf:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107eb4:	e9 51 f2 ff ff       	jmp    8010710a <alltraps>

80107eb9 <vector187>:
.globl vector187
vector187:
  pushl $0
80107eb9:	6a 00                	push   $0x0
  pushl $187
80107ebb:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107ec0:	e9 45 f2 ff ff       	jmp    8010710a <alltraps>

80107ec5 <vector188>:
.globl vector188
vector188:
  pushl $0
80107ec5:	6a 00                	push   $0x0
  pushl $188
80107ec7:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80107ecc:	e9 39 f2 ff ff       	jmp    8010710a <alltraps>

80107ed1 <vector189>:
.globl vector189
vector189:
  pushl $0
80107ed1:	6a 00                	push   $0x0
  pushl $189
80107ed3:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80107ed8:	e9 2d f2 ff ff       	jmp    8010710a <alltraps>

80107edd <vector190>:
.globl vector190
vector190:
  pushl $0
80107edd:	6a 00                	push   $0x0
  pushl $190
80107edf:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107ee4:	e9 21 f2 ff ff       	jmp    8010710a <alltraps>

80107ee9 <vector191>:
.globl vector191
vector191:
  pushl $0
80107ee9:	6a 00                	push   $0x0
  pushl $191
80107eeb:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107ef0:	e9 15 f2 ff ff       	jmp    8010710a <alltraps>

80107ef5 <vector192>:
.globl vector192
vector192:
  pushl $0
80107ef5:	6a 00                	push   $0x0
  pushl $192
80107ef7:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107efc:	e9 09 f2 ff ff       	jmp    8010710a <alltraps>

80107f01 <vector193>:
.globl vector193
vector193:
  pushl $0
80107f01:	6a 00                	push   $0x0
  pushl $193
80107f03:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107f08:	e9 fd f1 ff ff       	jmp    8010710a <alltraps>

80107f0d <vector194>:
.globl vector194
vector194:
  pushl $0
80107f0d:	6a 00                	push   $0x0
  pushl $194
80107f0f:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80107f14:	e9 f1 f1 ff ff       	jmp    8010710a <alltraps>

80107f19 <vector195>:
.globl vector195
vector195:
  pushl $0
80107f19:	6a 00                	push   $0x0
  pushl $195
80107f1b:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107f20:	e9 e5 f1 ff ff       	jmp    8010710a <alltraps>

80107f25 <vector196>:
.globl vector196
vector196:
  pushl $0
80107f25:	6a 00                	push   $0x0
  pushl $196
80107f27:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107f2c:	e9 d9 f1 ff ff       	jmp    8010710a <alltraps>

80107f31 <vector197>:
.globl vector197
vector197:
  pushl $0
80107f31:	6a 00                	push   $0x0
  pushl $197
80107f33:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107f38:	e9 cd f1 ff ff       	jmp    8010710a <alltraps>

80107f3d <vector198>:
.globl vector198
vector198:
  pushl $0
80107f3d:	6a 00                	push   $0x0
  pushl $198
80107f3f:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107f44:	e9 c1 f1 ff ff       	jmp    8010710a <alltraps>

80107f49 <vector199>:
.globl vector199
vector199:
  pushl $0
80107f49:	6a 00                	push   $0x0
  pushl $199
80107f4b:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107f50:	e9 b5 f1 ff ff       	jmp    8010710a <alltraps>

80107f55 <vector200>:
.globl vector200
vector200:
  pushl $0
80107f55:	6a 00                	push   $0x0
  pushl $200
80107f57:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107f5c:	e9 a9 f1 ff ff       	jmp    8010710a <alltraps>

80107f61 <vector201>:
.globl vector201
vector201:
  pushl $0
80107f61:	6a 00                	push   $0x0
  pushl $201
80107f63:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80107f68:	e9 9d f1 ff ff       	jmp    8010710a <alltraps>

80107f6d <vector202>:
.globl vector202
vector202:
  pushl $0
80107f6d:	6a 00                	push   $0x0
  pushl $202
80107f6f:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107f74:	e9 91 f1 ff ff       	jmp    8010710a <alltraps>

80107f79 <vector203>:
.globl vector203
vector203:
  pushl $0
80107f79:	6a 00                	push   $0x0
  pushl $203
80107f7b:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107f80:	e9 85 f1 ff ff       	jmp    8010710a <alltraps>

80107f85 <vector204>:
.globl vector204
vector204:
  pushl $0
80107f85:	6a 00                	push   $0x0
  pushl $204
80107f87:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80107f8c:	e9 79 f1 ff ff       	jmp    8010710a <alltraps>

80107f91 <vector205>:
.globl vector205
vector205:
  pushl $0
80107f91:	6a 00                	push   $0x0
  pushl $205
80107f93:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107f98:	e9 6d f1 ff ff       	jmp    8010710a <alltraps>

80107f9d <vector206>:
.globl vector206
vector206:
  pushl $0
80107f9d:	6a 00                	push   $0x0
  pushl $206
80107f9f:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107fa4:	e9 61 f1 ff ff       	jmp    8010710a <alltraps>

80107fa9 <vector207>:
.globl vector207
vector207:
  pushl $0
80107fa9:	6a 00                	push   $0x0
  pushl $207
80107fab:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107fb0:	e9 55 f1 ff ff       	jmp    8010710a <alltraps>

80107fb5 <vector208>:
.globl vector208
vector208:
  pushl $0
80107fb5:	6a 00                	push   $0x0
  pushl $208
80107fb7:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80107fbc:	e9 49 f1 ff ff       	jmp    8010710a <alltraps>

80107fc1 <vector209>:
.globl vector209
vector209:
  pushl $0
80107fc1:	6a 00                	push   $0x0
  pushl $209
80107fc3:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80107fc8:	e9 3d f1 ff ff       	jmp    8010710a <alltraps>

80107fcd <vector210>:
.globl vector210
vector210:
  pushl $0
80107fcd:	6a 00                	push   $0x0
  pushl $210
80107fcf:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80107fd4:	e9 31 f1 ff ff       	jmp    8010710a <alltraps>

80107fd9 <vector211>:
.globl vector211
vector211:
  pushl $0
80107fd9:	6a 00                	push   $0x0
  pushl $211
80107fdb:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107fe0:	e9 25 f1 ff ff       	jmp    8010710a <alltraps>

80107fe5 <vector212>:
.globl vector212
vector212:
  pushl $0
80107fe5:	6a 00                	push   $0x0
  pushl $212
80107fe7:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107fec:	e9 19 f1 ff ff       	jmp    8010710a <alltraps>

80107ff1 <vector213>:
.globl vector213
vector213:
  pushl $0
80107ff1:	6a 00                	push   $0x0
  pushl $213
80107ff3:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107ff8:	e9 0d f1 ff ff       	jmp    8010710a <alltraps>

80107ffd <vector214>:
.globl vector214
vector214:
  pushl $0
80107ffd:	6a 00                	push   $0x0
  pushl $214
80107fff:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80108004:	e9 01 f1 ff ff       	jmp    8010710a <alltraps>

80108009 <vector215>:
.globl vector215
vector215:
  pushl $0
80108009:	6a 00                	push   $0x0
  pushl $215
8010800b:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80108010:	e9 f5 f0 ff ff       	jmp    8010710a <alltraps>

80108015 <vector216>:
.globl vector216
vector216:
  pushl $0
80108015:	6a 00                	push   $0x0
  pushl $216
80108017:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
8010801c:	e9 e9 f0 ff ff       	jmp    8010710a <alltraps>

80108021 <vector217>:
.globl vector217
vector217:
  pushl $0
80108021:	6a 00                	push   $0x0
  pushl $217
80108023:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80108028:	e9 dd f0 ff ff       	jmp    8010710a <alltraps>

8010802d <vector218>:
.globl vector218
vector218:
  pushl $0
8010802d:	6a 00                	push   $0x0
  pushl $218
8010802f:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80108034:	e9 d1 f0 ff ff       	jmp    8010710a <alltraps>

80108039 <vector219>:
.globl vector219
vector219:
  pushl $0
80108039:	6a 00                	push   $0x0
  pushl $219
8010803b:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80108040:	e9 c5 f0 ff ff       	jmp    8010710a <alltraps>

80108045 <vector220>:
.globl vector220
vector220:
  pushl $0
80108045:	6a 00                	push   $0x0
  pushl $220
80108047:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
8010804c:	e9 b9 f0 ff ff       	jmp    8010710a <alltraps>

80108051 <vector221>:
.globl vector221
vector221:
  pushl $0
80108051:	6a 00                	push   $0x0
  pushl $221
80108053:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80108058:	e9 ad f0 ff ff       	jmp    8010710a <alltraps>

8010805d <vector222>:
.globl vector222
vector222:
  pushl $0
8010805d:	6a 00                	push   $0x0
  pushl $222
8010805f:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80108064:	e9 a1 f0 ff ff       	jmp    8010710a <alltraps>

80108069 <vector223>:
.globl vector223
vector223:
  pushl $0
80108069:	6a 00                	push   $0x0
  pushl $223
8010806b:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80108070:	e9 95 f0 ff ff       	jmp    8010710a <alltraps>

80108075 <vector224>:
.globl vector224
vector224:
  pushl $0
80108075:	6a 00                	push   $0x0
  pushl $224
80108077:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
8010807c:	e9 89 f0 ff ff       	jmp    8010710a <alltraps>

80108081 <vector225>:
.globl vector225
vector225:
  pushl $0
80108081:	6a 00                	push   $0x0
  pushl $225
80108083:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80108088:	e9 7d f0 ff ff       	jmp    8010710a <alltraps>

8010808d <vector226>:
.globl vector226
vector226:
  pushl $0
8010808d:	6a 00                	push   $0x0
  pushl $226
8010808f:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80108094:	e9 71 f0 ff ff       	jmp    8010710a <alltraps>

80108099 <vector227>:
.globl vector227
vector227:
  pushl $0
80108099:	6a 00                	push   $0x0
  pushl $227
8010809b:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
801080a0:	e9 65 f0 ff ff       	jmp    8010710a <alltraps>

801080a5 <vector228>:
.globl vector228
vector228:
  pushl $0
801080a5:	6a 00                	push   $0x0
  pushl $228
801080a7:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
801080ac:	e9 59 f0 ff ff       	jmp    8010710a <alltraps>

801080b1 <vector229>:
.globl vector229
vector229:
  pushl $0
801080b1:	6a 00                	push   $0x0
  pushl $229
801080b3:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
801080b8:	e9 4d f0 ff ff       	jmp    8010710a <alltraps>

801080bd <vector230>:
.globl vector230
vector230:
  pushl $0
801080bd:	6a 00                	push   $0x0
  pushl $230
801080bf:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
801080c4:	e9 41 f0 ff ff       	jmp    8010710a <alltraps>

801080c9 <vector231>:
.globl vector231
vector231:
  pushl $0
801080c9:	6a 00                	push   $0x0
  pushl $231
801080cb:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
801080d0:	e9 35 f0 ff ff       	jmp    8010710a <alltraps>

801080d5 <vector232>:
.globl vector232
vector232:
  pushl $0
801080d5:	6a 00                	push   $0x0
  pushl $232
801080d7:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
801080dc:	e9 29 f0 ff ff       	jmp    8010710a <alltraps>

801080e1 <vector233>:
.globl vector233
vector233:
  pushl $0
801080e1:	6a 00                	push   $0x0
  pushl $233
801080e3:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
801080e8:	e9 1d f0 ff ff       	jmp    8010710a <alltraps>

801080ed <vector234>:
.globl vector234
vector234:
  pushl $0
801080ed:	6a 00                	push   $0x0
  pushl $234
801080ef:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
801080f4:	e9 11 f0 ff ff       	jmp    8010710a <alltraps>

801080f9 <vector235>:
.globl vector235
vector235:
  pushl $0
801080f9:	6a 00                	push   $0x0
  pushl $235
801080fb:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80108100:	e9 05 f0 ff ff       	jmp    8010710a <alltraps>

80108105 <vector236>:
.globl vector236
vector236:
  pushl $0
80108105:	6a 00                	push   $0x0
  pushl $236
80108107:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
8010810c:	e9 f9 ef ff ff       	jmp    8010710a <alltraps>

80108111 <vector237>:
.globl vector237
vector237:
  pushl $0
80108111:	6a 00                	push   $0x0
  pushl $237
80108113:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80108118:	e9 ed ef ff ff       	jmp    8010710a <alltraps>

8010811d <vector238>:
.globl vector238
vector238:
  pushl $0
8010811d:	6a 00                	push   $0x0
  pushl $238
8010811f:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80108124:	e9 e1 ef ff ff       	jmp    8010710a <alltraps>

80108129 <vector239>:
.globl vector239
vector239:
  pushl $0
80108129:	6a 00                	push   $0x0
  pushl $239
8010812b:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80108130:	e9 d5 ef ff ff       	jmp    8010710a <alltraps>

80108135 <vector240>:
.globl vector240
vector240:
  pushl $0
80108135:	6a 00                	push   $0x0
  pushl $240
80108137:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
8010813c:	e9 c9 ef ff ff       	jmp    8010710a <alltraps>

80108141 <vector241>:
.globl vector241
vector241:
  pushl $0
80108141:	6a 00                	push   $0x0
  pushl $241
80108143:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80108148:	e9 bd ef ff ff       	jmp    8010710a <alltraps>

8010814d <vector242>:
.globl vector242
vector242:
  pushl $0
8010814d:	6a 00                	push   $0x0
  pushl $242
8010814f:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80108154:	e9 b1 ef ff ff       	jmp    8010710a <alltraps>

80108159 <vector243>:
.globl vector243
vector243:
  pushl $0
80108159:	6a 00                	push   $0x0
  pushl $243
8010815b:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80108160:	e9 a5 ef ff ff       	jmp    8010710a <alltraps>

80108165 <vector244>:
.globl vector244
vector244:
  pushl $0
80108165:	6a 00                	push   $0x0
  pushl $244
80108167:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
8010816c:	e9 99 ef ff ff       	jmp    8010710a <alltraps>

80108171 <vector245>:
.globl vector245
vector245:
  pushl $0
80108171:	6a 00                	push   $0x0
  pushl $245
80108173:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80108178:	e9 8d ef ff ff       	jmp    8010710a <alltraps>

8010817d <vector246>:
.globl vector246
vector246:
  pushl $0
8010817d:	6a 00                	push   $0x0
  pushl $246
8010817f:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80108184:	e9 81 ef ff ff       	jmp    8010710a <alltraps>

80108189 <vector247>:
.globl vector247
vector247:
  pushl $0
80108189:	6a 00                	push   $0x0
  pushl $247
8010818b:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80108190:	e9 75 ef ff ff       	jmp    8010710a <alltraps>

80108195 <vector248>:
.globl vector248
vector248:
  pushl $0
80108195:	6a 00                	push   $0x0
  pushl $248
80108197:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
8010819c:	e9 69 ef ff ff       	jmp    8010710a <alltraps>

801081a1 <vector249>:
.globl vector249
vector249:
  pushl $0
801081a1:	6a 00                	push   $0x0
  pushl $249
801081a3:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
801081a8:	e9 5d ef ff ff       	jmp    8010710a <alltraps>

801081ad <vector250>:
.globl vector250
vector250:
  pushl $0
801081ad:	6a 00                	push   $0x0
  pushl $250
801081af:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
801081b4:	e9 51 ef ff ff       	jmp    8010710a <alltraps>

801081b9 <vector251>:
.globl vector251
vector251:
  pushl $0
801081b9:	6a 00                	push   $0x0
  pushl $251
801081bb:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
801081c0:	e9 45 ef ff ff       	jmp    8010710a <alltraps>

801081c5 <vector252>:
.globl vector252
vector252:
  pushl $0
801081c5:	6a 00                	push   $0x0
  pushl $252
801081c7:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
801081cc:	e9 39 ef ff ff       	jmp    8010710a <alltraps>

801081d1 <vector253>:
.globl vector253
vector253:
  pushl $0
801081d1:	6a 00                	push   $0x0
  pushl $253
801081d3:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
801081d8:	e9 2d ef ff ff       	jmp    8010710a <alltraps>

801081dd <vector254>:
.globl vector254
vector254:
  pushl $0
801081dd:	6a 00                	push   $0x0
  pushl $254
801081df:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
801081e4:	e9 21 ef ff ff       	jmp    8010710a <alltraps>

801081e9 <vector255>:
.globl vector255
vector255:
  pushl $0
801081e9:	6a 00                	push   $0x0
  pushl $255
801081eb:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
801081f0:	e9 15 ef ff ff       	jmp    8010710a <alltraps>

801081f5 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
801081f5:	55                   	push   %ebp
801081f6:	89 e5                	mov    %esp,%ebp
801081f8:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
801081fb:	8b 45 0c             	mov    0xc(%ebp),%eax
801081fe:	83 e8 01             	sub    $0x1,%eax
80108201:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80108205:	8b 45 08             	mov    0x8(%ebp),%eax
80108208:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010820c:	8b 45 08             	mov    0x8(%ebp),%eax
8010820f:	c1 e8 10             	shr    $0x10,%eax
80108212:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80108216:	8d 45 fa             	lea    -0x6(%ebp),%eax
80108219:	0f 01 10             	lgdtl  (%eax)
}
8010821c:	c9                   	leave  
8010821d:	c3                   	ret    

8010821e <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
8010821e:	55                   	push   %ebp
8010821f:	89 e5                	mov    %esp,%ebp
80108221:	83 ec 04             	sub    $0x4,%esp
80108224:	8b 45 08             	mov    0x8(%ebp),%eax
80108227:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
8010822b:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010822f:	0f 00 d8             	ltr    %ax
}
80108232:	c9                   	leave  
80108233:	c3                   	ret    

80108234 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80108234:	55                   	push   %ebp
80108235:	89 e5                	mov    %esp,%ebp
80108237:	83 ec 04             	sub    $0x4,%esp
8010823a:	8b 45 08             	mov    0x8(%ebp),%eax
8010823d:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80108241:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80108245:	8e e8                	mov    %eax,%gs
}
80108247:	c9                   	leave  
80108248:	c3                   	ret    

80108249 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80108249:	55                   	push   %ebp
8010824a:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
8010824c:	8b 45 08             	mov    0x8(%ebp),%eax
8010824f:	0f 22 d8             	mov    %eax,%cr3
}
80108252:	5d                   	pop    %ebp
80108253:	c3                   	ret    

80108254 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80108254:	55                   	push   %ebp
80108255:	89 e5                	mov    %esp,%ebp
80108257:	8b 45 08             	mov    0x8(%ebp),%eax
8010825a:	05 00 00 00 80       	add    $0x80000000,%eax
8010825f:	5d                   	pop    %ebp
80108260:	c3                   	ret    

80108261 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80108261:	55                   	push   %ebp
80108262:	89 e5                	mov    %esp,%ebp
80108264:	8b 45 08             	mov    0x8(%ebp),%eax
80108267:	05 00 00 00 80       	add    $0x80000000,%eax
8010826c:	5d                   	pop    %ebp
8010826d:	c3                   	ret    

8010826e <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
8010826e:	55                   	push   %ebp
8010826f:	89 e5                	mov    %esp,%ebp
80108271:	53                   	push   %ebx
80108272:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80108275:	e8 10 ae ff ff       	call   8010308a <cpunum>
8010827a:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80108280:	05 a0 33 11 80       	add    $0x801133a0,%eax
80108285:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80108288:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010828b:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80108291:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108294:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
8010829a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010829d:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
801082a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082a4:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801082a8:	83 e2 f0             	and    $0xfffffff0,%edx
801082ab:	83 ca 0a             	or     $0xa,%edx
801082ae:	88 50 7d             	mov    %dl,0x7d(%eax)
801082b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082b4:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801082b8:	83 ca 10             	or     $0x10,%edx
801082bb:	88 50 7d             	mov    %dl,0x7d(%eax)
801082be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082c1:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801082c5:	83 e2 9f             	and    $0xffffff9f,%edx
801082c8:	88 50 7d             	mov    %dl,0x7d(%eax)
801082cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082ce:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801082d2:	83 ca 80             	or     $0xffffff80,%edx
801082d5:	88 50 7d             	mov    %dl,0x7d(%eax)
801082d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082db:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801082df:	83 ca 0f             	or     $0xf,%edx
801082e2:	88 50 7e             	mov    %dl,0x7e(%eax)
801082e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082e8:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801082ec:	83 e2 ef             	and    $0xffffffef,%edx
801082ef:	88 50 7e             	mov    %dl,0x7e(%eax)
801082f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082f5:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801082f9:	83 e2 df             	and    $0xffffffdf,%edx
801082fc:	88 50 7e             	mov    %dl,0x7e(%eax)
801082ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108302:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108306:	83 ca 40             	or     $0x40,%edx
80108309:	88 50 7e             	mov    %dl,0x7e(%eax)
8010830c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010830f:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108313:	83 ca 80             	or     $0xffffff80,%edx
80108316:	88 50 7e             	mov    %dl,0x7e(%eax)
80108319:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010831c:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80108320:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108323:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
8010832a:	ff ff 
8010832c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010832f:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80108336:	00 00 
80108338:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010833b:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80108342:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108345:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010834c:	83 e2 f0             	and    $0xfffffff0,%edx
8010834f:	83 ca 02             	or     $0x2,%edx
80108352:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108358:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010835b:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108362:	83 ca 10             	or     $0x10,%edx
80108365:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010836b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010836e:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108375:	83 e2 9f             	and    $0xffffff9f,%edx
80108378:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010837e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108381:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108388:	83 ca 80             	or     $0xffffff80,%edx
8010838b:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108391:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108394:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010839b:	83 ca 0f             	or     $0xf,%edx
8010839e:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801083a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083a7:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801083ae:	83 e2 ef             	and    $0xffffffef,%edx
801083b1:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801083b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083ba:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801083c1:	83 e2 df             	and    $0xffffffdf,%edx
801083c4:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801083ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083cd:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801083d4:	83 ca 40             	or     $0x40,%edx
801083d7:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801083dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083e0:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801083e7:	83 ca 80             	or     $0xffffff80,%edx
801083ea:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801083f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083f3:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
801083fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083fd:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80108404:	ff ff 
80108406:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108409:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80108410:	00 00 
80108412:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108415:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
8010841c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010841f:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108426:	83 e2 f0             	and    $0xfffffff0,%edx
80108429:	83 ca 0a             	or     $0xa,%edx
8010842c:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108432:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108435:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010843c:	83 ca 10             	or     $0x10,%edx
8010843f:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108445:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108448:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010844f:	83 ca 60             	or     $0x60,%edx
80108452:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108458:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010845b:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108462:	83 ca 80             	or     $0xffffff80,%edx
80108465:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010846b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010846e:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108475:	83 ca 0f             	or     $0xf,%edx
80108478:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010847e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108481:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108488:	83 e2 ef             	and    $0xffffffef,%edx
8010848b:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108491:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108494:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010849b:	83 e2 df             	and    $0xffffffdf,%edx
8010849e:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801084a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084a7:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801084ae:	83 ca 40             	or     $0x40,%edx
801084b1:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801084b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084ba:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801084c1:	83 ca 80             	or     $0xffffff80,%edx
801084c4:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801084ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084cd:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
801084d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084d7:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
801084de:	ff ff 
801084e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084e3:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
801084ea:	00 00 
801084ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084ef:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
801084f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084f9:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108500:	83 e2 f0             	and    $0xfffffff0,%edx
80108503:	83 ca 02             	or     $0x2,%edx
80108506:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010850c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010850f:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108516:	83 ca 10             	or     $0x10,%edx
80108519:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010851f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108522:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108529:	83 ca 60             	or     $0x60,%edx
8010852c:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108532:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108535:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010853c:	83 ca 80             	or     $0xffffff80,%edx
8010853f:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108545:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108548:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010854f:	83 ca 0f             	or     $0xf,%edx
80108552:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108558:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010855b:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108562:	83 e2 ef             	and    $0xffffffef,%edx
80108565:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010856b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010856e:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108575:	83 e2 df             	and    $0xffffffdf,%edx
80108578:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010857e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108581:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108588:	83 ca 40             	or     $0x40,%edx
8010858b:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108591:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108594:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010859b:	83 ca 80             	or     $0xffffff80,%edx
8010859e:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801085a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085a7:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
801085ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085b1:	05 b4 00 00 00       	add    $0xb4,%eax
801085b6:	89 c3                	mov    %eax,%ebx
801085b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085bb:	05 b4 00 00 00       	add    $0xb4,%eax
801085c0:	c1 e8 10             	shr    $0x10,%eax
801085c3:	89 c1                	mov    %eax,%ecx
801085c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085c8:	05 b4 00 00 00       	add    $0xb4,%eax
801085cd:	c1 e8 18             	shr    $0x18,%eax
801085d0:	89 c2                	mov    %eax,%edx
801085d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085d5:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
801085dc:	00 00 
801085de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085e1:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
801085e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085eb:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
801085f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085f4:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801085fb:	83 e1 f0             	and    $0xfffffff0,%ecx
801085fe:	83 c9 02             	or     $0x2,%ecx
80108601:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108607:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010860a:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108611:	83 c9 10             	or     $0x10,%ecx
80108614:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
8010861a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010861d:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108624:	83 e1 9f             	and    $0xffffff9f,%ecx
80108627:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
8010862d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108630:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108637:	83 c9 80             	or     $0xffffff80,%ecx
8010863a:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108640:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108643:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010864a:	83 e1 f0             	and    $0xfffffff0,%ecx
8010864d:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108653:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108656:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010865d:	83 e1 ef             	and    $0xffffffef,%ecx
80108660:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108666:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108669:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108670:	83 e1 df             	and    $0xffffffdf,%ecx
80108673:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108679:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010867c:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108683:	83 c9 40             	or     $0x40,%ecx
80108686:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010868c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010868f:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108696:	83 c9 80             	or     $0xffffff80,%ecx
80108699:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010869f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086a2:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
801086a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086ab:	83 c0 70             	add    $0x70,%eax
801086ae:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
801086b5:	00 
801086b6:	89 04 24             	mov    %eax,(%esp)
801086b9:	e8 37 fb ff ff       	call   801081f5 <lgdt>
  loadgs(SEG_KCPU << 3);
801086be:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
801086c5:	e8 6a fb ff ff       	call   80108234 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
801086ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086cd:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
801086d3:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
801086da:	00 00 00 00 
}
801086de:	83 c4 24             	add    $0x24,%esp
801086e1:	5b                   	pop    %ebx
801086e2:	5d                   	pop    %ebp
801086e3:	c3                   	ret    

801086e4 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
801086e4:	55                   	push   %ebp
801086e5:	89 e5                	mov    %esp,%ebp
801086e7:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
801086ea:	8b 45 0c             	mov    0xc(%ebp),%eax
801086ed:	c1 e8 16             	shr    $0x16,%eax
801086f0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801086f7:	8b 45 08             	mov    0x8(%ebp),%eax
801086fa:	01 d0                	add    %edx,%eax
801086fc:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
801086ff:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108702:	8b 00                	mov    (%eax),%eax
80108704:	83 e0 01             	and    $0x1,%eax
80108707:	85 c0                	test   %eax,%eax
80108709:	74 17                	je     80108722 <walkpgdir+0x3e>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
8010870b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010870e:	8b 00                	mov    (%eax),%eax
80108710:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108715:	89 04 24             	mov    %eax,(%esp)
80108718:	e8 44 fb ff ff       	call   80108261 <p2v>
8010871d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108720:	eb 4b                	jmp    8010876d <walkpgdir+0x89>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80108722:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80108726:	74 0e                	je     80108736 <walkpgdir+0x52>
80108728:	e8 c7 a5 ff ff       	call   80102cf4 <kalloc>
8010872d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108730:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108734:	75 07                	jne    8010873d <walkpgdir+0x59>
      return 0;
80108736:	b8 00 00 00 00       	mov    $0x0,%eax
8010873b:	eb 47                	jmp    80108784 <walkpgdir+0xa0>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
8010873d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108744:	00 
80108745:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010874c:	00 
8010874d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108750:	89 04 24             	mov    %eax,(%esp)
80108753:	e8 58 d5 ff ff       	call   80105cb0 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80108758:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010875b:	89 04 24             	mov    %eax,(%esp)
8010875e:	e8 f1 fa ff ff       	call   80108254 <v2p>
80108763:	83 c8 07             	or     $0x7,%eax
80108766:	89 c2                	mov    %eax,%edx
80108768:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010876b:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
8010876d:	8b 45 0c             	mov    0xc(%ebp),%eax
80108770:	c1 e8 0c             	shr    $0xc,%eax
80108773:	25 ff 03 00 00       	and    $0x3ff,%eax
80108778:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010877f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108782:	01 d0                	add    %edx,%eax
}
80108784:	c9                   	leave  
80108785:	c3                   	ret    

80108786 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80108786:	55                   	push   %ebp
80108787:	89 e5                	mov    %esp,%ebp
80108789:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
8010878c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010878f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108794:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80108797:	8b 55 0c             	mov    0xc(%ebp),%edx
8010879a:	8b 45 10             	mov    0x10(%ebp),%eax
8010879d:	01 d0                	add    %edx,%eax
8010879f:	83 e8 01             	sub    $0x1,%eax
801087a2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801087a7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
801087aa:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
801087b1:	00 
801087b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087b5:	89 44 24 04          	mov    %eax,0x4(%esp)
801087b9:	8b 45 08             	mov    0x8(%ebp),%eax
801087bc:	89 04 24             	mov    %eax,(%esp)
801087bf:	e8 20 ff ff ff       	call   801086e4 <walkpgdir>
801087c4:	89 45 ec             	mov    %eax,-0x14(%ebp)
801087c7:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801087cb:	75 07                	jne    801087d4 <mappages+0x4e>
      return -1;
801087cd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801087d2:	eb 48                	jmp    8010881c <mappages+0x96>
    if(*pte & PTE_P)
801087d4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801087d7:	8b 00                	mov    (%eax),%eax
801087d9:	83 e0 01             	and    $0x1,%eax
801087dc:	85 c0                	test   %eax,%eax
801087de:	74 0c                	je     801087ec <mappages+0x66>
      panic("remap");
801087e0:	c7 04 24 50 96 10 80 	movl   $0x80109650,(%esp)
801087e7:	e8 4e 7d ff ff       	call   8010053a <panic>
    *pte = pa | perm | PTE_P;
801087ec:	8b 45 18             	mov    0x18(%ebp),%eax
801087ef:	0b 45 14             	or     0x14(%ebp),%eax
801087f2:	83 c8 01             	or     $0x1,%eax
801087f5:	89 c2                	mov    %eax,%edx
801087f7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801087fa:	89 10                	mov    %edx,(%eax)
    if(a == last)
801087fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087ff:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108802:	75 08                	jne    8010880c <mappages+0x86>
      break;
80108804:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80108805:	b8 00 00 00 00       	mov    $0x0,%eax
8010880a:	eb 10                	jmp    8010881c <mappages+0x96>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
8010880c:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80108813:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
8010881a:	eb 8e                	jmp    801087aa <mappages+0x24>
  return 0;
}
8010881c:	c9                   	leave  
8010881d:	c3                   	ret    

8010881e <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
8010881e:	55                   	push   %ebp
8010881f:	89 e5                	mov    %esp,%ebp
80108821:	53                   	push   %ebx
80108822:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80108825:	e8 ca a4 ff ff       	call   80102cf4 <kalloc>
8010882a:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010882d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108831:	75 0a                	jne    8010883d <setupkvm+0x1f>
    return 0;
80108833:	b8 00 00 00 00       	mov    $0x0,%eax
80108838:	e9 98 00 00 00       	jmp    801088d5 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
8010883d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108844:	00 
80108845:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010884c:	00 
8010884d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108850:	89 04 24             	mov    %eax,(%esp)
80108853:	e8 58 d4 ff ff       	call   80105cb0 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80108858:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
8010885f:	e8 fd f9 ff ff       	call   80108261 <p2v>
80108864:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80108869:	76 0c                	jbe    80108877 <setupkvm+0x59>
    panic("PHYSTOP too high");
8010886b:	c7 04 24 56 96 10 80 	movl   $0x80109656,(%esp)
80108872:	e8 c3 7c ff ff       	call   8010053a <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108877:	c7 45 f4 a0 c4 10 80 	movl   $0x8010c4a0,-0xc(%ebp)
8010887e:	eb 49                	jmp    801088c9 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108880:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108883:	8b 48 0c             	mov    0xc(%eax),%ecx
80108886:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108889:	8b 50 04             	mov    0x4(%eax),%edx
8010888c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010888f:	8b 58 08             	mov    0x8(%eax),%ebx
80108892:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108895:	8b 40 04             	mov    0x4(%eax),%eax
80108898:	29 c3                	sub    %eax,%ebx
8010889a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010889d:	8b 00                	mov    (%eax),%eax
8010889f:	89 4c 24 10          	mov    %ecx,0x10(%esp)
801088a3:	89 54 24 0c          	mov    %edx,0xc(%esp)
801088a7:	89 5c 24 08          	mov    %ebx,0x8(%esp)
801088ab:	89 44 24 04          	mov    %eax,0x4(%esp)
801088af:	8b 45 f0             	mov    -0x10(%ebp),%eax
801088b2:	89 04 24             	mov    %eax,(%esp)
801088b5:	e8 cc fe ff ff       	call   80108786 <mappages>
801088ba:	85 c0                	test   %eax,%eax
801088bc:	79 07                	jns    801088c5 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
801088be:	b8 00 00 00 00       	mov    $0x0,%eax
801088c3:	eb 10                	jmp    801088d5 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801088c5:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801088c9:	81 7d f4 e0 c4 10 80 	cmpl   $0x8010c4e0,-0xc(%ebp)
801088d0:	72 ae                	jb     80108880 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
801088d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801088d5:	83 c4 34             	add    $0x34,%esp
801088d8:	5b                   	pop    %ebx
801088d9:	5d                   	pop    %ebp
801088da:	c3                   	ret    

801088db <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
801088db:	55                   	push   %ebp
801088dc:	89 e5                	mov    %esp,%ebp
801088de:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
801088e1:	e8 38 ff ff ff       	call   8010881e <setupkvm>
801088e6:	a3 78 75 12 80       	mov    %eax,0x80127578
  switchkvm();
801088eb:	e8 02 00 00 00       	call   801088f2 <switchkvm>
}
801088f0:	c9                   	leave  
801088f1:	c3                   	ret    

801088f2 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
801088f2:	55                   	push   %ebp
801088f3:	89 e5                	mov    %esp,%ebp
801088f5:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
801088f8:	a1 78 75 12 80       	mov    0x80127578,%eax
801088fd:	89 04 24             	mov    %eax,(%esp)
80108900:	e8 4f f9 ff ff       	call   80108254 <v2p>
80108905:	89 04 24             	mov    %eax,(%esp)
80108908:	e8 3c f9 ff ff       	call   80108249 <lcr3>
}
8010890d:	c9                   	leave  
8010890e:	c3                   	ret    

8010890f <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
8010890f:	55                   	push   %ebp
80108910:	89 e5                	mov    %esp,%ebp
80108912:	53                   	push   %ebx
80108913:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80108916:	e8 95 d2 ff ff       	call   80105bb0 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
8010891b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108921:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108928:	83 c2 08             	add    $0x8,%edx
8010892b:	89 d3                	mov    %edx,%ebx
8010892d:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108934:	83 c2 08             	add    $0x8,%edx
80108937:	c1 ea 10             	shr    $0x10,%edx
8010893a:	89 d1                	mov    %edx,%ecx
8010893c:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108943:	83 c2 08             	add    $0x8,%edx
80108946:	c1 ea 18             	shr    $0x18,%edx
80108949:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80108950:	67 00 
80108952:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80108959:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
8010895f:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108966:	83 e1 f0             	and    $0xfffffff0,%ecx
80108969:	83 c9 09             	or     $0x9,%ecx
8010896c:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108972:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108979:	83 c9 10             	or     $0x10,%ecx
8010897c:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108982:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108989:	83 e1 9f             	and    $0xffffff9f,%ecx
8010898c:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108992:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108999:	83 c9 80             	or     $0xffffff80,%ecx
8010899c:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801089a2:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801089a9:	83 e1 f0             	and    $0xfffffff0,%ecx
801089ac:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801089b2:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801089b9:	83 e1 ef             	and    $0xffffffef,%ecx
801089bc:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801089c2:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801089c9:	83 e1 df             	and    $0xffffffdf,%ecx
801089cc:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801089d2:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801089d9:	83 c9 40             	or     $0x40,%ecx
801089dc:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801089e2:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801089e9:	83 e1 7f             	and    $0x7f,%ecx
801089ec:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801089f2:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
801089f8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801089fe:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80108a05:	83 e2 ef             	and    $0xffffffef,%edx
80108a08:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80108a0e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108a14:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80108a1a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108a20:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80108a27:	8b 52 08             	mov    0x8(%edx),%edx
80108a2a:	81 c2 00 10 00 00    	add    $0x1000,%edx
80108a30:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80108a33:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80108a3a:	e8 df f7 ff ff       	call   8010821e <ltr>
  if(p->pgdir == 0)
80108a3f:	8b 45 08             	mov    0x8(%ebp),%eax
80108a42:	8b 40 04             	mov    0x4(%eax),%eax
80108a45:	85 c0                	test   %eax,%eax
80108a47:	75 0c                	jne    80108a55 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80108a49:	c7 04 24 67 96 10 80 	movl   $0x80109667,(%esp)
80108a50:	e8 e5 7a ff ff       	call   8010053a <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80108a55:	8b 45 08             	mov    0x8(%ebp),%eax
80108a58:	8b 40 04             	mov    0x4(%eax),%eax
80108a5b:	89 04 24             	mov    %eax,(%esp)
80108a5e:	e8 f1 f7 ff ff       	call   80108254 <v2p>
80108a63:	89 04 24             	mov    %eax,(%esp)
80108a66:	e8 de f7 ff ff       	call   80108249 <lcr3>
  popcli();
80108a6b:	e8 84 d1 ff ff       	call   80105bf4 <popcli>
}
80108a70:	83 c4 14             	add    $0x14,%esp
80108a73:	5b                   	pop    %ebx
80108a74:	5d                   	pop    %ebp
80108a75:	c3                   	ret    

80108a76 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80108a76:	55                   	push   %ebp
80108a77:	89 e5                	mov    %esp,%ebp
80108a79:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80108a7c:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80108a83:	76 0c                	jbe    80108a91 <inituvm+0x1b>
    panic("inituvm: more than a page");
80108a85:	c7 04 24 7b 96 10 80 	movl   $0x8010967b,(%esp)
80108a8c:	e8 a9 7a ff ff       	call   8010053a <panic>
  mem = kalloc();
80108a91:	e8 5e a2 ff ff       	call   80102cf4 <kalloc>
80108a96:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80108a99:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108aa0:	00 
80108aa1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108aa8:	00 
80108aa9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108aac:	89 04 24             	mov    %eax,(%esp)
80108aaf:	e8 fc d1 ff ff       	call   80105cb0 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108ab4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ab7:	89 04 24             	mov    %eax,(%esp)
80108aba:	e8 95 f7 ff ff       	call   80108254 <v2p>
80108abf:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108ac6:	00 
80108ac7:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108acb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108ad2:	00 
80108ad3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108ada:	00 
80108adb:	8b 45 08             	mov    0x8(%ebp),%eax
80108ade:	89 04 24             	mov    %eax,(%esp)
80108ae1:	e8 a0 fc ff ff       	call   80108786 <mappages>
  memmove(mem, init, sz);
80108ae6:	8b 45 10             	mov    0x10(%ebp),%eax
80108ae9:	89 44 24 08          	mov    %eax,0x8(%esp)
80108aed:	8b 45 0c             	mov    0xc(%ebp),%eax
80108af0:	89 44 24 04          	mov    %eax,0x4(%esp)
80108af4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108af7:	89 04 24             	mov    %eax,(%esp)
80108afa:	e8 80 d2 ff ff       	call   80105d7f <memmove>
}
80108aff:	c9                   	leave  
80108b00:	c3                   	ret    

80108b01 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80108b01:	55                   	push   %ebp
80108b02:	89 e5                	mov    %esp,%ebp
80108b04:	53                   	push   %ebx
80108b05:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80108b08:	8b 45 0c             	mov    0xc(%ebp),%eax
80108b0b:	25 ff 0f 00 00       	and    $0xfff,%eax
80108b10:	85 c0                	test   %eax,%eax
80108b12:	74 0c                	je     80108b20 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80108b14:	c7 04 24 98 96 10 80 	movl   $0x80109698,(%esp)
80108b1b:	e8 1a 7a ff ff       	call   8010053a <panic>
  for(i = 0; i < sz; i += PGSIZE){
80108b20:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108b27:	e9 a9 00 00 00       	jmp    80108bd5 <loaduvm+0xd4>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80108b2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b2f:	8b 55 0c             	mov    0xc(%ebp),%edx
80108b32:	01 d0                	add    %edx,%eax
80108b34:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108b3b:	00 
80108b3c:	89 44 24 04          	mov    %eax,0x4(%esp)
80108b40:	8b 45 08             	mov    0x8(%ebp),%eax
80108b43:	89 04 24             	mov    %eax,(%esp)
80108b46:	e8 99 fb ff ff       	call   801086e4 <walkpgdir>
80108b4b:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108b4e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108b52:	75 0c                	jne    80108b60 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80108b54:	c7 04 24 bb 96 10 80 	movl   $0x801096bb,(%esp)
80108b5b:	e8 da 79 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80108b60:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108b63:	8b 00                	mov    (%eax),%eax
80108b65:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108b6a:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80108b6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b70:	8b 55 18             	mov    0x18(%ebp),%edx
80108b73:	29 c2                	sub    %eax,%edx
80108b75:	89 d0                	mov    %edx,%eax
80108b77:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80108b7c:	77 0f                	ja     80108b8d <loaduvm+0x8c>
      n = sz - i;
80108b7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b81:	8b 55 18             	mov    0x18(%ebp),%edx
80108b84:	29 c2                	sub    %eax,%edx
80108b86:	89 d0                	mov    %edx,%eax
80108b88:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108b8b:	eb 07                	jmp    80108b94 <loaduvm+0x93>
    else
      n = PGSIZE;
80108b8d:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80108b94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b97:	8b 55 14             	mov    0x14(%ebp),%edx
80108b9a:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80108b9d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108ba0:	89 04 24             	mov    %eax,(%esp)
80108ba3:	e8 b9 f6 ff ff       	call   80108261 <p2v>
80108ba8:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108bab:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108baf:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108bb3:	89 44 24 04          	mov    %eax,0x4(%esp)
80108bb7:	8b 45 10             	mov    0x10(%ebp),%eax
80108bba:	89 04 24             	mov    %eax,(%esp)
80108bbd:	e8 9d 92 ff ff       	call   80101e5f <readi>
80108bc2:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108bc5:	74 07                	je     80108bce <loaduvm+0xcd>
      return -1;
80108bc7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108bcc:	eb 18                	jmp    80108be6 <loaduvm+0xe5>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80108bce:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108bd5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bd8:	3b 45 18             	cmp    0x18(%ebp),%eax
80108bdb:	0f 82 4b ff ff ff    	jb     80108b2c <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80108be1:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108be6:	83 c4 24             	add    $0x24,%esp
80108be9:	5b                   	pop    %ebx
80108bea:	5d                   	pop    %ebp
80108beb:	c3                   	ret    

80108bec <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108bec:	55                   	push   %ebp
80108bed:	89 e5                	mov    %esp,%ebp
80108bef:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80108bf2:	8b 45 10             	mov    0x10(%ebp),%eax
80108bf5:	85 c0                	test   %eax,%eax
80108bf7:	79 0a                	jns    80108c03 <allocuvm+0x17>
    return 0;
80108bf9:	b8 00 00 00 00       	mov    $0x0,%eax
80108bfe:	e9 c1 00 00 00       	jmp    80108cc4 <allocuvm+0xd8>
  if(newsz < oldsz)
80108c03:	8b 45 10             	mov    0x10(%ebp),%eax
80108c06:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108c09:	73 08                	jae    80108c13 <allocuvm+0x27>
    return oldsz;
80108c0b:	8b 45 0c             	mov    0xc(%ebp),%eax
80108c0e:	e9 b1 00 00 00       	jmp    80108cc4 <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
80108c13:	8b 45 0c             	mov    0xc(%ebp),%eax
80108c16:	05 ff 0f 00 00       	add    $0xfff,%eax
80108c1b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108c20:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80108c23:	e9 8d 00 00 00       	jmp    80108cb5 <allocuvm+0xc9>
    mem = kalloc();
80108c28:	e8 c7 a0 ff ff       	call   80102cf4 <kalloc>
80108c2d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80108c30:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108c34:	75 2c                	jne    80108c62 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80108c36:	c7 04 24 d9 96 10 80 	movl   $0x801096d9,(%esp)
80108c3d:	e8 5e 77 ff ff       	call   801003a0 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80108c42:	8b 45 0c             	mov    0xc(%ebp),%eax
80108c45:	89 44 24 08          	mov    %eax,0x8(%esp)
80108c49:	8b 45 10             	mov    0x10(%ebp),%eax
80108c4c:	89 44 24 04          	mov    %eax,0x4(%esp)
80108c50:	8b 45 08             	mov    0x8(%ebp),%eax
80108c53:	89 04 24             	mov    %eax,(%esp)
80108c56:	e8 6b 00 00 00       	call   80108cc6 <deallocuvm>
      return 0;
80108c5b:	b8 00 00 00 00       	mov    $0x0,%eax
80108c60:	eb 62                	jmp    80108cc4 <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80108c62:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108c69:	00 
80108c6a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108c71:	00 
80108c72:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108c75:	89 04 24             	mov    %eax,(%esp)
80108c78:	e8 33 d0 ff ff       	call   80105cb0 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108c7d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108c80:	89 04 24             	mov    %eax,(%esp)
80108c83:	e8 cc f5 ff ff       	call   80108254 <v2p>
80108c88:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108c8b:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108c92:	00 
80108c93:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108c97:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108c9e:	00 
80108c9f:	89 54 24 04          	mov    %edx,0x4(%esp)
80108ca3:	8b 45 08             	mov    0x8(%ebp),%eax
80108ca6:	89 04 24             	mov    %eax,(%esp)
80108ca9:	e8 d8 fa ff ff       	call   80108786 <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80108cae:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108cb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cb8:	3b 45 10             	cmp    0x10(%ebp),%eax
80108cbb:	0f 82 67 ff ff ff    	jb     80108c28 <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80108cc1:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108cc4:	c9                   	leave  
80108cc5:	c3                   	ret    

80108cc6 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108cc6:	55                   	push   %ebp
80108cc7:	89 e5                	mov    %esp,%ebp
80108cc9:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80108ccc:	8b 45 10             	mov    0x10(%ebp),%eax
80108ccf:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108cd2:	72 08                	jb     80108cdc <deallocuvm+0x16>
    return oldsz;
80108cd4:	8b 45 0c             	mov    0xc(%ebp),%eax
80108cd7:	e9 a4 00 00 00       	jmp    80108d80 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80108cdc:	8b 45 10             	mov    0x10(%ebp),%eax
80108cdf:	05 ff 0f 00 00       	add    $0xfff,%eax
80108ce4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108ce9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80108cec:	e9 80 00 00 00       	jmp    80108d71 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80108cf1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cf4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108cfb:	00 
80108cfc:	89 44 24 04          	mov    %eax,0x4(%esp)
80108d00:	8b 45 08             	mov    0x8(%ebp),%eax
80108d03:	89 04 24             	mov    %eax,(%esp)
80108d06:	e8 d9 f9 ff ff       	call   801086e4 <walkpgdir>
80108d0b:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80108d0e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108d12:	75 09                	jne    80108d1d <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80108d14:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80108d1b:	eb 4d                	jmp    80108d6a <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80108d1d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d20:	8b 00                	mov    (%eax),%eax
80108d22:	83 e0 01             	and    $0x1,%eax
80108d25:	85 c0                	test   %eax,%eax
80108d27:	74 41                	je     80108d6a <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80108d29:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d2c:	8b 00                	mov    (%eax),%eax
80108d2e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108d33:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80108d36:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108d3a:	75 0c                	jne    80108d48 <deallocuvm+0x82>
        panic("kfree");
80108d3c:	c7 04 24 f1 96 10 80 	movl   $0x801096f1,(%esp)
80108d43:	e8 f2 77 ff ff       	call   8010053a <panic>
      char *v = p2v(pa);
80108d48:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d4b:	89 04 24             	mov    %eax,(%esp)
80108d4e:	e8 0e f5 ff ff       	call   80108261 <p2v>
80108d53:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80108d56:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108d59:	89 04 24             	mov    %eax,(%esp)
80108d5c:	e8 fa 9e ff ff       	call   80102c5b <kfree>
      *pte = 0;
80108d61:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d64:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80108d6a:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108d71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d74:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108d77:	0f 82 74 ff ff ff    	jb     80108cf1 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80108d7d:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108d80:	c9                   	leave  
80108d81:	c3                   	ret    

80108d82 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80108d82:	55                   	push   %ebp
80108d83:	89 e5                	mov    %esp,%ebp
80108d85:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80108d88:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80108d8c:	75 0c                	jne    80108d9a <freevm+0x18>
    panic("freevm: no pgdir");
80108d8e:	c7 04 24 f7 96 10 80 	movl   $0x801096f7,(%esp)
80108d95:	e8 a0 77 ff ff       	call   8010053a <panic>
  deallocuvm(pgdir, KERNBASE, 0);
80108d9a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108da1:	00 
80108da2:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80108da9:	80 
80108daa:	8b 45 08             	mov    0x8(%ebp),%eax
80108dad:	89 04 24             	mov    %eax,(%esp)
80108db0:	e8 11 ff ff ff       	call   80108cc6 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80108db5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108dbc:	eb 48                	jmp    80108e06 <freevm+0x84>
    if(pgdir[i] & PTE_P){
80108dbe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108dc1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108dc8:	8b 45 08             	mov    0x8(%ebp),%eax
80108dcb:	01 d0                	add    %edx,%eax
80108dcd:	8b 00                	mov    (%eax),%eax
80108dcf:	83 e0 01             	and    $0x1,%eax
80108dd2:	85 c0                	test   %eax,%eax
80108dd4:	74 2c                	je     80108e02 <freevm+0x80>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80108dd6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108dd9:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108de0:	8b 45 08             	mov    0x8(%ebp),%eax
80108de3:	01 d0                	add    %edx,%eax
80108de5:	8b 00                	mov    (%eax),%eax
80108de7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108dec:	89 04 24             	mov    %eax,(%esp)
80108def:	e8 6d f4 ff ff       	call   80108261 <p2v>
80108df4:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108df7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108dfa:	89 04 24             	mov    %eax,(%esp)
80108dfd:	e8 59 9e ff ff       	call   80102c5b <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80108e02:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108e06:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80108e0d:	76 af                	jbe    80108dbe <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80108e0f:	8b 45 08             	mov    0x8(%ebp),%eax
80108e12:	89 04 24             	mov    %eax,(%esp)
80108e15:	e8 41 9e ff ff       	call   80102c5b <kfree>
}
80108e1a:	c9                   	leave  
80108e1b:	c3                   	ret    

80108e1c <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80108e1c:	55                   	push   %ebp
80108e1d:	89 e5                	mov    %esp,%ebp
80108e1f:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108e22:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108e29:	00 
80108e2a:	8b 45 0c             	mov    0xc(%ebp),%eax
80108e2d:	89 44 24 04          	mov    %eax,0x4(%esp)
80108e31:	8b 45 08             	mov    0x8(%ebp),%eax
80108e34:	89 04 24             	mov    %eax,(%esp)
80108e37:	e8 a8 f8 ff ff       	call   801086e4 <walkpgdir>
80108e3c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108e3f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108e43:	75 0c                	jne    80108e51 <clearpteu+0x35>
    panic("clearpteu");
80108e45:	c7 04 24 08 97 10 80 	movl   $0x80109708,(%esp)
80108e4c:	e8 e9 76 ff ff       	call   8010053a <panic>
  *pte &= ~PTE_U;
80108e51:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e54:	8b 00                	mov    (%eax),%eax
80108e56:	83 e0 fb             	and    $0xfffffffb,%eax
80108e59:	89 c2                	mov    %eax,%edx
80108e5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e5e:	89 10                	mov    %edx,(%eax)
}
80108e60:	c9                   	leave  
80108e61:	c3                   	ret    

80108e62 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80108e62:	55                   	push   %ebp
80108e63:	89 e5                	mov    %esp,%ebp
80108e65:	53                   	push   %ebx
80108e66:	83 ec 44             	sub    $0x44,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80108e69:	e8 b0 f9 ff ff       	call   8010881e <setupkvm>
80108e6e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108e71:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108e75:	75 0a                	jne    80108e81 <copyuvm+0x1f>
    return 0;
80108e77:	b8 00 00 00 00       	mov    $0x0,%eax
80108e7c:	e9 fd 00 00 00       	jmp    80108f7e <copyuvm+0x11c>
  for(i = 0; i < sz; i += PGSIZE){
80108e81:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108e88:	e9 d0 00 00 00       	jmp    80108f5d <copyuvm+0xfb>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108e8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e90:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108e97:	00 
80108e98:	89 44 24 04          	mov    %eax,0x4(%esp)
80108e9c:	8b 45 08             	mov    0x8(%ebp),%eax
80108e9f:	89 04 24             	mov    %eax,(%esp)
80108ea2:	e8 3d f8 ff ff       	call   801086e4 <walkpgdir>
80108ea7:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108eaa:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108eae:	75 0c                	jne    80108ebc <copyuvm+0x5a>
      panic("copyuvm: pte should exist");
80108eb0:	c7 04 24 12 97 10 80 	movl   $0x80109712,(%esp)
80108eb7:	e8 7e 76 ff ff       	call   8010053a <panic>
    if(!(*pte & PTE_P))
80108ebc:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108ebf:	8b 00                	mov    (%eax),%eax
80108ec1:	83 e0 01             	and    $0x1,%eax
80108ec4:	85 c0                	test   %eax,%eax
80108ec6:	75 0c                	jne    80108ed4 <copyuvm+0x72>
      panic("copyuvm: page not present");
80108ec8:	c7 04 24 2c 97 10 80 	movl   $0x8010972c,(%esp)
80108ecf:	e8 66 76 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80108ed4:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108ed7:	8b 00                	mov    (%eax),%eax
80108ed9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108ede:	89 45 e8             	mov    %eax,-0x18(%ebp)
    flags = PTE_FLAGS(*pte);
80108ee1:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108ee4:	8b 00                	mov    (%eax),%eax
80108ee6:	25 ff 0f 00 00       	and    $0xfff,%eax
80108eeb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if((mem = kalloc()) == 0)
80108eee:	e8 01 9e ff ff       	call   80102cf4 <kalloc>
80108ef3:	89 45 e0             	mov    %eax,-0x20(%ebp)
80108ef6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80108efa:	75 02                	jne    80108efe <copyuvm+0x9c>
      goto bad;
80108efc:	eb 70                	jmp    80108f6e <copyuvm+0x10c>
    memmove(mem, (char*)p2v(pa), PGSIZE);
80108efe:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108f01:	89 04 24             	mov    %eax,(%esp)
80108f04:	e8 58 f3 ff ff       	call   80108261 <p2v>
80108f09:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108f10:	00 
80108f11:	89 44 24 04          	mov    %eax,0x4(%esp)
80108f15:	8b 45 e0             	mov    -0x20(%ebp),%eax
80108f18:	89 04 24             	mov    %eax,(%esp)
80108f1b:	e8 5f ce ff ff       	call   80105d7f <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
80108f20:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
80108f23:	8b 45 e0             	mov    -0x20(%ebp),%eax
80108f26:	89 04 24             	mov    %eax,(%esp)
80108f29:	e8 26 f3 ff ff       	call   80108254 <v2p>
80108f2e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108f31:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80108f35:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108f39:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108f40:	00 
80108f41:	89 54 24 04          	mov    %edx,0x4(%esp)
80108f45:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108f48:	89 04 24             	mov    %eax,(%esp)
80108f4b:	e8 36 f8 ff ff       	call   80108786 <mappages>
80108f50:	85 c0                	test   %eax,%eax
80108f52:	79 02                	jns    80108f56 <copyuvm+0xf4>
      goto bad;
80108f54:	eb 18                	jmp    80108f6e <copyuvm+0x10c>
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80108f56:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108f5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f60:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108f63:	0f 82 24 ff ff ff    	jb     80108e8d <copyuvm+0x2b>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
      goto bad;
  }
  return d;
80108f69:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108f6c:	eb 10                	jmp    80108f7e <copyuvm+0x11c>

bad:
  freevm(d);
80108f6e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108f71:	89 04 24             	mov    %eax,(%esp)
80108f74:	e8 09 fe ff ff       	call   80108d82 <freevm>
  return 0;
80108f79:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108f7e:	83 c4 44             	add    $0x44,%esp
80108f81:	5b                   	pop    %ebx
80108f82:	5d                   	pop    %ebp
80108f83:	c3                   	ret    

80108f84 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80108f84:	55                   	push   %ebp
80108f85:	89 e5                	mov    %esp,%ebp
80108f87:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108f8a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108f91:	00 
80108f92:	8b 45 0c             	mov    0xc(%ebp),%eax
80108f95:	89 44 24 04          	mov    %eax,0x4(%esp)
80108f99:	8b 45 08             	mov    0x8(%ebp),%eax
80108f9c:	89 04 24             	mov    %eax,(%esp)
80108f9f:	e8 40 f7 ff ff       	call   801086e4 <walkpgdir>
80108fa4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
80108fa7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108faa:	8b 00                	mov    (%eax),%eax
80108fac:	83 e0 01             	and    $0x1,%eax
80108faf:	85 c0                	test   %eax,%eax
80108fb1:	75 07                	jne    80108fba <uva2ka+0x36>
    return 0;
80108fb3:	b8 00 00 00 00       	mov    $0x0,%eax
80108fb8:	eb 25                	jmp    80108fdf <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80108fba:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fbd:	8b 00                	mov    (%eax),%eax
80108fbf:	83 e0 04             	and    $0x4,%eax
80108fc2:	85 c0                	test   %eax,%eax
80108fc4:	75 07                	jne    80108fcd <uva2ka+0x49>
    return 0;
80108fc6:	b8 00 00 00 00       	mov    $0x0,%eax
80108fcb:	eb 12                	jmp    80108fdf <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80108fcd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fd0:	8b 00                	mov    (%eax),%eax
80108fd2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108fd7:	89 04 24             	mov    %eax,(%esp)
80108fda:	e8 82 f2 ff ff       	call   80108261 <p2v>
}
80108fdf:	c9                   	leave  
80108fe0:	c3                   	ret    

80108fe1 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80108fe1:	55                   	push   %ebp
80108fe2:	89 e5                	mov    %esp,%ebp
80108fe4:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80108fe7:	8b 45 10             	mov    0x10(%ebp),%eax
80108fea:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80108fed:	e9 87 00 00 00       	jmp    80109079 <copyout+0x98>
    va0 = (uint)PGROUNDDOWN(va);
80108ff2:	8b 45 0c             	mov    0xc(%ebp),%eax
80108ff5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108ffa:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80108ffd:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109000:	89 44 24 04          	mov    %eax,0x4(%esp)
80109004:	8b 45 08             	mov    0x8(%ebp),%eax
80109007:	89 04 24             	mov    %eax,(%esp)
8010900a:	e8 75 ff ff ff       	call   80108f84 <uva2ka>
8010900f:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80109012:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80109016:	75 07                	jne    8010901f <copyout+0x3e>
      return -1;
80109018:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010901d:	eb 69                	jmp    80109088 <copyout+0xa7>
    n = PGSIZE - (va - va0);
8010901f:	8b 45 0c             	mov    0xc(%ebp),%eax
80109022:	8b 55 ec             	mov    -0x14(%ebp),%edx
80109025:	29 c2                	sub    %eax,%edx
80109027:	89 d0                	mov    %edx,%eax
80109029:	05 00 10 00 00       	add    $0x1000,%eax
8010902e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80109031:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109034:	3b 45 14             	cmp    0x14(%ebp),%eax
80109037:	76 06                	jbe    8010903f <copyout+0x5e>
      n = len;
80109039:	8b 45 14             	mov    0x14(%ebp),%eax
8010903c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
8010903f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109042:	8b 55 0c             	mov    0xc(%ebp),%edx
80109045:	29 c2                	sub    %eax,%edx
80109047:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010904a:	01 c2                	add    %eax,%edx
8010904c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010904f:	89 44 24 08          	mov    %eax,0x8(%esp)
80109053:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109056:	89 44 24 04          	mov    %eax,0x4(%esp)
8010905a:	89 14 24             	mov    %edx,(%esp)
8010905d:	e8 1d cd ff ff       	call   80105d7f <memmove>
    len -= n;
80109062:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109065:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80109068:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010906b:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
8010906e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109071:	05 00 10 00 00       	add    $0x1000,%eax
80109076:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80109079:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010907d:	0f 85 6f ff ff ff    	jne    80108ff2 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
80109083:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109088:	c9                   	leave  
80109089:	c3                   	ret    
