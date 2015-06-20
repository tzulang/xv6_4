
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
8010002d:	b8 32 39 10 80       	mov    $0x80103932,%eax
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
8010003a:	c7 44 24 04 b4 94 10 	movl   $0x801094b4,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
80100049:	e8 14 5e 00 00       	call   80105e62 <initlock>

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
801000bd:	e8 c1 5d 00 00       	call   80105e83 <acquire>

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
80100104:	e8 dc 5d 00 00       	call   80105ee5 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 d6 10 	movl   $0x8010d660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 7e 4d 00 00       	call   80104ea2 <sleep>
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
8010017c:	e8 64 5d 00 00       	call   80105ee5 <release>
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
80100198:	c7 04 24 bb 94 10 80 	movl   $0x801094bb,(%esp)
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
801001d3:	e8 e4 27 00 00       	call   801029bc <iderw>
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
801001ef:	c7 04 24 cc 94 10 80 	movl   $0x801094cc,(%esp)
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
80100210:	e8 a7 27 00 00       	call   801029bc <iderw>
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
80100229:	c7 04 24 d3 94 10 80 	movl   $0x801094d3,(%esp)
80100230:	e8 05 03 00 00       	call   8010053a <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
8010023c:	e8 42 5c 00 00       	call   80105e83 <acquire>

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
8010029d:	e8 dc 4c 00 00       	call   80104f7e <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
801002a9:	e8 37 5c 00 00       	call   80105ee5 <release>
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
801003bb:	e8 c3 5a 00 00       	call   80105e83 <acquire>

  if (fmt == 0)
801003c0:	8b 45 08             	mov    0x8(%ebp),%eax
801003c3:	85 c0                	test   %eax,%eax
801003c5:	75 0c                	jne    801003d3 <cprintf+0x33>
    panic("null fmt");
801003c7:	c7 04 24 da 94 10 80 	movl   $0x801094da,(%esp)
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
801004b0:	c7 45 ec e3 94 10 80 	movl   $0x801094e3,-0x14(%ebp)
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
80100533:	e8 ad 59 00 00       	call   80105ee5 <release>
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
8010055f:	c7 04 24 ea 94 10 80 	movl   $0x801094ea,(%esp)
80100566:	e8 35 fe ff ff       	call   801003a0 <cprintf>
  cprintf(s);
8010056b:	8b 45 08             	mov    0x8(%ebp),%eax
8010056e:	89 04 24             	mov    %eax,(%esp)
80100571:	e8 2a fe ff ff       	call   801003a0 <cprintf>
  cprintf("\n");
80100576:	c7 04 24 f9 94 10 80 	movl   $0x801094f9,(%esp)
8010057d:	e8 1e fe ff ff       	call   801003a0 <cprintf>
  getcallerpcs(&s, pcs);
80100582:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100585:	89 44 24 04          	mov    %eax,0x4(%esp)
80100589:	8d 45 08             	lea    0x8(%ebp),%eax
8010058c:	89 04 24             	mov    %eax,(%esp)
8010058f:	e8 a0 59 00 00       	call   80105f34 <getcallerpcs>
  for(i=0; i<10; i++)
80100594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059b:	eb 1b                	jmp    801005b8 <panic+0x7e>
    cprintf(" %p", pcs[i]);
8010059d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a0:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801005a8:	c7 04 24 fb 94 10 80 	movl   $0x801094fb,(%esp)
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
801006b2:	e8 ef 5a 00 00       	call   801061a6 <memmove>
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
801006e1:	e8 f1 59 00 00       	call   801060d7 <memset>
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
80100776:	e8 79 73 00 00       	call   80107af4 <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 6d 73 00 00       	call   80107af4 <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 61 73 00 00       	call   80107af4 <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 54 73 00 00       	call   80107af4 <uartputc>
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
801007ba:	e8 c4 56 00 00       	call   80105e83 <acquire>
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
801007ea:	e8 35 48 00 00       	call   80105024 <procdump>
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
801008f3:	e8 86 46 00 00       	call   80104f7e <wakeup>
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
80100914:	e8 cc 55 00 00       	call   80105ee5 <release>
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
80100927:	e8 7d 11 00 00       	call   80101aa9 <iunlock>
  target = n;
8010092c:	8b 45 14             	mov    0x14(%ebp),%eax
8010092f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
80100932:	c7 04 24 80 17 11 80 	movl   $0x80111780,(%esp)
80100939:	e8 45 55 00 00       	call   80105e83 <acquire>
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
80100959:	e8 87 55 00 00       	call   80105ee5 <release>
        ilock(ip);
8010095e:	8b 45 08             	mov    0x8(%ebp),%eax
80100961:	89 04 24             	mov    %eax,(%esp)
80100964:	e8 f2 0f 00 00       	call   8010195b <ilock>
        return -1;
80100969:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010096e:	e9 a5 00 00 00       	jmp    80100a18 <consoleread+0xfd>
      }
      sleep(&input.r, &input.lock);
80100973:	c7 44 24 04 80 17 11 	movl   $0x80111780,0x4(%esp)
8010097a:	80 
8010097b:	c7 04 24 34 18 11 80 	movl   $0x80111834,(%esp)
80100982:	e8 1b 45 00 00       	call   80104ea2 <sleep>

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
801009fe:	e8 e2 54 00 00       	call   80105ee5 <release>
  ilock(ip);
80100a03:	8b 45 08             	mov    0x8(%ebp),%eax
80100a06:	89 04 24             	mov    %eax,(%esp)
80100a09:	e8 4d 0f 00 00       	call   8010195b <ilock>

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
80100a26:	e8 7e 10 00 00       	call   80101aa9 <iunlock>
  acquire(&cons.lock);
80100a2b:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
80100a32:	e8 4c 54 00 00       	call   80105e83 <acquire>
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
80100a6c:	e8 74 54 00 00       	call   80105ee5 <release>
  ilock(ip);
80100a71:	8b 45 08             	mov    0x8(%ebp),%eax
80100a74:	89 04 24             	mov    %eax,(%esp)
80100a77:	e8 df 0e 00 00       	call   8010195b <ilock>

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
80100a87:	c7 44 24 04 ff 94 10 	movl   $0x801094ff,0x4(%esp)
80100a8e:	80 
80100a8f:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
80100a96:	e8 c7 53 00 00       	call   80105e62 <initlock>
  initlock(&input.lock, "input");
80100a9b:	c7 44 24 04 07 95 10 	movl   $0x80109507,0x4(%esp)
80100aa2:	80 
80100aa3:	c7 04 24 80 17 11 80 	movl   $0x80111780,(%esp)
80100aaa:	e8 b3 53 00 00       	call   80105e62 <initlock>

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
80100ad4:	e8 fb 34 00 00       	call   80103fd4 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ad9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100ae0:	00 
80100ae1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ae8:	e8 8b 20 00 00       	call   80102b78 <ioapicenable>
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
80100af9:	e8 2d 2b 00 00       	call   8010362b <begin_op>
  if((ip = namei(path)) == 0){
80100afe:	8b 45 08             	mov    0x8(%ebp),%eax
80100b01:	89 04 24             	mov    %eax,(%esp)
80100b04:	e8 18 1b 00 00       	call   80102621 <namei>
80100b09:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b0c:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b10:	75 0f                	jne    80100b21 <exec+0x32>
    end_op();
80100b12:	e8 98 2b 00 00       	call   801036af <end_op>
    return -1;
80100b17:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b1c:	e9 e0 04 00 00       	jmp    80101001 <exec+0x512>
  }
  ilock(ip);
80100b21:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b24:	89 04 24             	mov    %eax,(%esp)
80100b27:	e8 2f 0e 00 00       	call   8010195b <ilock>
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
80100b53:	e8 10 13 00 00       	call   80101e68 <readi>
80100b58:	83 f8 33             	cmp    $0x33,%eax
80100b5b:	77 05                	ja     80100b62 <exec+0x73>
    goto bad;
80100b5d:	e9 73 04 00 00       	jmp    80100fd5 <exec+0x4e6>
  if(elf.magic != ELF_MAGIC)
80100b62:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100b68:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b6d:	74 05                	je     80100b74 <exec+0x85>
    goto bad;
80100b6f:	e9 61 04 00 00       	jmp    80100fd5 <exec+0x4e6>

  if((pgdir = setupkvm()) == 0)
80100b74:	e8 cc 80 00 00       	call   80108c45 <setupkvm>
80100b79:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100b7c:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100b80:	75 05                	jne    80100b87 <exec+0x98>
    goto bad;
80100b82:	e9 4e 04 00 00       	jmp    80100fd5 <exec+0x4e6>

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
80100bc2:	e8 a1 12 00 00       	call   80101e68 <readi>
80100bc7:	83 f8 20             	cmp    $0x20,%eax
80100bca:	74 05                	je     80100bd1 <exec+0xe2>
      goto bad;
80100bcc:	e9 04 04 00 00       	jmp    80100fd5 <exec+0x4e6>
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
80100bf1:	e9 df 03 00 00       	jmp    80100fd5 <exec+0x4e6>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100bf6:	8b 95 f4 fe ff ff    	mov    -0x10c(%ebp),%edx
80100bfc:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
80100c02:	01 d0                	add    %edx,%eax
80100c04:	89 44 24 08          	mov    %eax,0x8(%esp)
80100c08:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c0b:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c0f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c12:	89 04 24             	mov    %eax,(%esp)
80100c15:	e8 f9 83 00 00       	call   80109013 <allocuvm>
80100c1a:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100c1d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100c21:	75 05                	jne    80100c28 <exec+0x139>
      goto bad;
80100c23:	e9 ad 03 00 00       	jmp    80100fd5 <exec+0x4e6>
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
80100c53:	e8 d0 82 00 00       	call   80108f28 <loaduvm>
80100c58:	85 c0                	test   %eax,%eax
80100c5a:	79 05                	jns    80100c61 <exec+0x172>
      goto bad;
80100c5c:	e9 74 03 00 00       	jmp    80100fd5 <exec+0x4e6>
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
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }

  // proc->exe= ip->inum;
  proc->exe = namei(path);
80100c81:	65 8b 1d 04 00 00 00 	mov    %gs:0x4,%ebx
80100c88:	8b 45 08             	mov    0x8(%ebp),%eax
80100c8b:	89 04 24             	mov    %eax,(%esp)
80100c8e:	e8 8e 19 00 00       	call   80102621 <namei>
80100c93:	89 43 7c             	mov    %eax,0x7c(%ebx)
  iunlockput(ip);
80100c96:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100c99:	89 04 24             	mov    %eax,(%esp)
80100c9c:	e8 3e 0f 00 00       	call   80101bdf <iunlockput>
  end_op();
80100ca1:	e8 09 2a 00 00       	call   801036af <end_op>
  ip = 0;
80100ca6:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100cad:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cb0:	05 ff 0f 00 00       	add    $0xfff,%eax
80100cb5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100cba:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100cbd:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cc0:	05 00 20 00 00       	add    $0x2000,%eax
80100cc5:	89 44 24 08          	mov    %eax,0x8(%esp)
80100cc9:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100ccc:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cd0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cd3:	89 04 24             	mov    %eax,(%esp)
80100cd6:	e8 38 83 00 00       	call   80109013 <allocuvm>
80100cdb:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100cde:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100ce2:	75 05                	jne    80100ce9 <exec+0x1fa>
    goto bad;
80100ce4:	e9 ec 02 00 00       	jmp    80100fd5 <exec+0x4e6>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100ce9:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cec:	2d 00 20 00 00       	sub    $0x2000,%eax
80100cf1:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cf5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cf8:	89 04 24             	mov    %eax,(%esp)
80100cfb:	e8 43 85 00 00       	call   80109243 <clearpteu>
  sp = sz;
80100d00:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d03:	89 45 dc             	mov    %eax,-0x24(%ebp)

 
  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100d06:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100d0d:	e9 9a 00 00 00       	jmp    80100dac <exec+0x2bd>
    if(argc >= MAXARG)
80100d12:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100d16:	76 05                	jbe    80100d1d <exec+0x22e>
      goto bad;
80100d18:	e9 b8 02 00 00       	jmp    80100fd5 <exec+0x4e6>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100d1d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d20:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100d27:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d2a:	01 d0                	add    %edx,%eax
80100d2c:	8b 00                	mov    (%eax),%eax
80100d2e:	89 04 24             	mov    %eax,(%esp)
80100d31:	e8 0b 56 00 00       	call   80106341 <strlen>
80100d36:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100d39:	29 c2                	sub    %eax,%edx
80100d3b:	89 d0                	mov    %edx,%eax
80100d3d:	83 e8 01             	sub    $0x1,%eax
80100d40:	83 e0 fc             	and    $0xfffffffc,%eax
80100d43:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100d46:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d49:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100d50:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d53:	01 d0                	add    %edx,%eax
80100d55:	8b 00                	mov    (%eax),%eax
80100d57:	89 04 24             	mov    %eax,(%esp)
80100d5a:	e8 e2 55 00 00       	call   80106341 <strlen>
80100d5f:	83 c0 01             	add    $0x1,%eax
80100d62:	89 c2                	mov    %eax,%edx
80100d64:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d67:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
80100d6e:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d71:	01 c8                	add    %ecx,%eax
80100d73:	8b 00                	mov    (%eax),%eax
80100d75:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100d79:	89 44 24 08          	mov    %eax,0x8(%esp)
80100d7d:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d80:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d84:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d87:	89 04 24             	mov    %eax,(%esp)
80100d8a:	e8 79 86 00 00       	call   80109408 <copyout>
80100d8f:	85 c0                	test   %eax,%eax
80100d91:	79 05                	jns    80100d98 <exec+0x2a9>
      goto bad;
80100d93:	e9 3d 02 00 00       	jmp    80100fd5 <exec+0x4e6>
    ustack[3+argc] = sp;
80100d98:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d9b:	8d 50 03             	lea    0x3(%eax),%edx
80100d9e:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100da1:	89 84 95 40 ff ff ff 	mov    %eax,-0xc0(%ebp,%edx,4)
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

 
  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100da8:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100dac:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100daf:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100db6:	8b 45 0c             	mov    0xc(%ebp),%eax
80100db9:	01 d0                	add    %edx,%eax
80100dbb:	8b 00                	mov    (%eax),%eax
80100dbd:	85 c0                	test   %eax,%eax
80100dbf:	0f 85 4d ff ff ff    	jne    80100d12 <exec+0x223>
      goto bad;
    ustack[3+argc] = sp;


  }
  ustack[3+argc] = 0;
80100dc5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dc8:	83 c0 03             	add    $0x3,%eax
80100dcb:	c7 84 85 40 ff ff ff 	movl   $0x0,-0xc0(%ebp,%eax,4)
80100dd2:	00 00 00 00 



  ustack[0] = 0xffffffff;  // fake return PC
80100dd6:	c7 85 40 ff ff ff ff 	movl   $0xffffffff,-0xc0(%ebp)
80100ddd:	ff ff ff 
  ustack[1] = argc;
80100de0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100de3:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100de9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dec:	83 c0 01             	add    $0x1,%eax
80100def:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100df6:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100df9:	29 d0                	sub    %edx,%eax
80100dfb:	89 85 48 ff ff ff    	mov    %eax,-0xb8(%ebp)

  sp -= (3+argc+1) * 4;
80100e01:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e04:	83 c0 04             	add    $0x4,%eax
80100e07:	c1 e0 02             	shl    $0x2,%eax
80100e0a:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100e0d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e10:	83 c0 04             	add    $0x4,%eax
80100e13:	c1 e0 02             	shl    $0x2,%eax
80100e16:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100e1a:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
80100e20:	89 44 24 08          	mov    %eax,0x8(%esp)
80100e24:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e27:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e2b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e2e:	89 04 24             	mov    %eax,(%esp)
80100e31:	e8 d2 85 00 00       	call   80109408 <copyout>
80100e36:	85 c0                	test   %eax,%eax
80100e38:	79 05                	jns    80100e3f <exec+0x350>
    goto bad;
80100e3a:	e9 96 01 00 00       	jmp    80100fd5 <exec+0x4e6>

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e3f:	8b 45 08             	mov    0x8(%ebp),%eax
80100e42:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100e45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e48:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100e4b:	eb 17                	jmp    80100e64 <exec+0x375>
    if(*s == '/')
80100e4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e50:	0f b6 00             	movzbl (%eax),%eax
80100e53:	3c 2f                	cmp    $0x2f,%al
80100e55:	75 09                	jne    80100e60 <exec+0x371>
      last = s+1;
80100e57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e5a:	83 c0 01             	add    $0x1,%eax
80100e5d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e60:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100e64:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e67:	0f b6 00             	movzbl (%eax),%eax
80100e6a:	84 c0                	test   %al,%al
80100e6c:	75 df                	jne    80100e4d <exec+0x35e>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80100e6e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e74:	8d 50 28             	lea    0x28(%eax),%edx
80100e77:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100e7e:	00 
80100e7f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100e82:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e86:	89 14 24             	mov    %edx,(%esp)
80100e89:	e8 69 54 00 00       	call   801062f7 <safestrcpy>
  safestrcpy(proc->cmdline, path, strlen(path)+1);
80100e8e:	8b 45 08             	mov    0x8(%ebp),%eax
80100e91:	89 04 24             	mov    %eax,(%esp)
80100e94:	e8 a8 54 00 00       	call   80106341 <strlen>
80100e99:	83 c0 01             	add    $0x1,%eax
80100e9c:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80100ea3:	83 ea 80             	sub    $0xffffff80,%edx
80100ea6:	89 44 24 08          	mov    %eax,0x8(%esp)
80100eaa:	8b 45 08             	mov    0x8(%ebp),%eax
80100ead:	89 44 24 04          	mov    %eax,0x4(%esp)
80100eb1:	89 14 24             	mov    %edx,(%esp)
80100eb4:	e8 3e 54 00 00       	call   801062f7 <safestrcpy>
//  cprintf( "path : %s \n", proc->cmdline);
  for (i=0; i < MAXARGS; i++)  {
80100eb9:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100ec0:	e9 88 00 00 00       	jmp    80100f4d <exec+0x45e>
	  if (argv[i]){
80100ec5:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100ec8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100ecf:	8b 45 0c             	mov    0xc(%ebp),%eax
80100ed2:	01 d0                	add    %edx,%eax
80100ed4:	8b 00                	mov    (%eax),%eax
80100ed6:	85 c0                	test   %eax,%eax
80100ed8:	74 57                	je     80100f31 <exec+0x442>
		  safestrcpy(proc->args[i], argv[i], strlen(argv[i])+1);
80100eda:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100edd:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100ee4:	8b 45 0c             	mov    0xc(%ebp),%eax
80100ee7:	01 d0                	add    %edx,%eax
80100ee9:	8b 00                	mov    (%eax),%eax
80100eeb:	89 04 24             	mov    %eax,(%esp)
80100eee:	e8 4e 54 00 00       	call   80106341 <strlen>
80100ef3:	8d 48 01             	lea    0x1(%eax),%ecx
80100ef6:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100ef9:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100f00:	8b 45 0c             	mov    0xc(%ebp),%eax
80100f03:	01 d0                	add    %edx,%eax
80100f05:	8b 00                	mov    (%eax),%eax
80100f07:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80100f0e:	8b 5d ec             	mov    -0x14(%ebp),%ebx
80100f11:	6b db 64             	imul   $0x64,%ebx,%ebx
80100f14:	81 c3 e0 00 00 00    	add    $0xe0,%ebx
80100f1a:	01 da                	add    %ebx,%edx
80100f1c:	83 c2 04             	add    $0x4,%edx
80100f1f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80100f23:	89 44 24 04          	mov    %eax,0x4(%esp)
80100f27:	89 14 24             	mov    %edx,(%esp)
80100f2a:	e8 c8 53 00 00       	call   801062f7 <safestrcpy>
80100f2f:	eb 18                	jmp    80100f49 <exec+0x45a>
//		  cprintf( "arg : %s \n", proc->args[i]);
	  }
	  else proc->args[i][0]='\0';
80100f31:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80100f38:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100f3b:	6b c0 64             	imul   $0x64,%eax,%eax
80100f3e:	01 d0                	add    %edx,%eax
80100f40:	05 e0 00 00 00       	add    $0xe0,%eax
80100f45:	c6 40 04 00          	movb   $0x0,0x4(%eax)
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
  safestrcpy(proc->cmdline, path, strlen(path)+1);
//  cprintf( "path : %s \n", proc->cmdline);
  for (i=0; i < MAXARGS; i++)  {
80100f49:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100f4d:	83 7d ec 09          	cmpl   $0x9,-0x14(%ebp)
80100f51:	0f 8e 6e ff ff ff    	jle    80100ec5 <exec+0x3d6>
	  else proc->args[i][0]='\0';
  }
  


  proc->cmdline[strlen(path)]=0 ;
80100f57:	65 8b 1d 04 00 00 00 	mov    %gs:0x4,%ebx
80100f5e:	8b 45 08             	mov    0x8(%ebp),%eax
80100f61:	89 04 24             	mov    %eax,(%esp)
80100f64:	e8 d8 53 00 00       	call   80106341 <strlen>
80100f69:	c6 84 03 80 00 00 00 	movb   $0x0,0x80(%ebx,%eax,1)
80100f70:	00 


  // cprintf(" ******* cmdline %s\n", proc->cmdline);
  // Commit to the user image.
  oldpgdir = proc->pgdir;
80100f71:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f77:	8b 40 04             	mov    0x4(%eax),%eax
80100f7a:	89 45 d0             	mov    %eax,-0x30(%ebp)
  proc->pgdir = pgdir;
80100f7d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f83:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100f86:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80100f89:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f8f:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100f92:	89 10                	mov    %edx,(%eax)
  proc->tf->eip = elf.entry;  // main
80100f94:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f9a:	8b 40 18             	mov    0x18(%eax),%eax
80100f9d:	8b 95 24 ff ff ff    	mov    -0xdc(%ebp),%edx
80100fa3:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
80100fa6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100fac:	8b 40 18             	mov    0x18(%eax),%eax
80100faf:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100fb2:	89 50 44             	mov    %edx,0x44(%eax)
  
  switchuvm(proc);
80100fb5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100fbb:	89 04 24             	mov    %eax,(%esp)
80100fbe:	e8 73 7d 00 00       	call   80108d36 <switchuvm>
  freevm(oldpgdir);
80100fc3:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100fc6:	89 04 24             	mov    %eax,(%esp)
80100fc9:	e8 db 81 00 00       	call   801091a9 <freevm>
  return 0;
80100fce:	b8 00 00 00 00       	mov    $0x0,%eax
80100fd3:	eb 2c                	jmp    80101001 <exec+0x512>

 bad:
  if(pgdir)
80100fd5:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100fd9:	74 0b                	je     80100fe6 <exec+0x4f7>
    freevm(pgdir);
80100fdb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100fde:	89 04 24             	mov    %eax,(%esp)
80100fe1:	e8 c3 81 00 00       	call   801091a9 <freevm>
  if(ip){
80100fe6:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100fea:	74 10                	je     80100ffc <exec+0x50d>
    iunlockput(ip);
80100fec:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100fef:	89 04 24             	mov    %eax,(%esp)
80100ff2:	e8 e8 0b 00 00       	call   80101bdf <iunlockput>
    end_op();
80100ff7:	e8 b3 26 00 00       	call   801036af <end_op>
  }
  return -1;
80100ffc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80101001:	81 c4 34 01 00 00    	add    $0x134,%esp
80101007:	5b                   	pop    %ebx
80101008:	5d                   	pop    %ebp
80101009:	c3                   	ret    

8010100a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
8010100a:	55                   	push   %ebp
8010100b:	89 e5                	mov    %esp,%ebp
8010100d:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
80101010:	c7 44 24 04 0d 95 10 	movl   $0x8010950d,0x4(%esp)
80101017:	80 
80101018:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
8010101f:	e8 3e 4e 00 00       	call   80105e62 <initlock>
}
80101024:	c9                   	leave  
80101025:	c3                   	ret    

80101026 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80101026:	55                   	push   %ebp
80101027:	89 e5                	mov    %esp,%ebp
80101029:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
8010102c:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
80101033:	e8 4b 4e 00 00       	call   80105e83 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80101038:	c7 45 f4 74 18 11 80 	movl   $0x80111874,-0xc(%ebp)
8010103f:	eb 29                	jmp    8010106a <filealloc+0x44>
    if(f->ref == 0){
80101041:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101044:	8b 40 04             	mov    0x4(%eax),%eax
80101047:	85 c0                	test   %eax,%eax
80101049:	75 1b                	jne    80101066 <filealloc+0x40>
      f->ref = 1;
8010104b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010104e:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
80101055:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
8010105c:	e8 84 4e 00 00       	call   80105ee5 <release>
      return f;
80101061:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101064:	eb 1e                	jmp    80101084 <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80101066:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
8010106a:	81 7d f4 d4 21 11 80 	cmpl   $0x801121d4,-0xc(%ebp)
80101071:	72 ce                	jb     80101041 <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80101073:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
8010107a:	e8 66 4e 00 00       	call   80105ee5 <release>
  return 0;
8010107f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101084:	c9                   	leave  
80101085:	c3                   	ret    

80101086 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80101086:	55                   	push   %ebp
80101087:	89 e5                	mov    %esp,%ebp
80101089:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
8010108c:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
80101093:	e8 eb 4d 00 00       	call   80105e83 <acquire>
  if(f->ref < 1)
80101098:	8b 45 08             	mov    0x8(%ebp),%eax
8010109b:	8b 40 04             	mov    0x4(%eax),%eax
8010109e:	85 c0                	test   %eax,%eax
801010a0:	7f 0c                	jg     801010ae <filedup+0x28>
    panic("filedup");
801010a2:	c7 04 24 14 95 10 80 	movl   $0x80109514,(%esp)
801010a9:	e8 8c f4 ff ff       	call   8010053a <panic>
  f->ref++;
801010ae:	8b 45 08             	mov    0x8(%ebp),%eax
801010b1:	8b 40 04             	mov    0x4(%eax),%eax
801010b4:	8d 50 01             	lea    0x1(%eax),%edx
801010b7:	8b 45 08             	mov    0x8(%ebp),%eax
801010ba:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
801010bd:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
801010c4:	e8 1c 4e 00 00       	call   80105ee5 <release>
  return f;
801010c9:	8b 45 08             	mov    0x8(%ebp),%eax
}
801010cc:	c9                   	leave  
801010cd:	c3                   	ret    

801010ce <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
801010ce:	55                   	push   %ebp
801010cf:	89 e5                	mov    %esp,%ebp
801010d1:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
801010d4:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
801010db:	e8 a3 4d 00 00       	call   80105e83 <acquire>
  if(f->ref < 1)
801010e0:	8b 45 08             	mov    0x8(%ebp),%eax
801010e3:	8b 40 04             	mov    0x4(%eax),%eax
801010e6:	85 c0                	test   %eax,%eax
801010e8:	7f 0c                	jg     801010f6 <fileclose+0x28>
    panic("fileclose");
801010ea:	c7 04 24 1c 95 10 80 	movl   $0x8010951c,(%esp)
801010f1:	e8 44 f4 ff ff       	call   8010053a <panic>
  if(--f->ref > 0){
801010f6:	8b 45 08             	mov    0x8(%ebp),%eax
801010f9:	8b 40 04             	mov    0x4(%eax),%eax
801010fc:	8d 50 ff             	lea    -0x1(%eax),%edx
801010ff:	8b 45 08             	mov    0x8(%ebp),%eax
80101102:	89 50 04             	mov    %edx,0x4(%eax)
80101105:	8b 45 08             	mov    0x8(%ebp),%eax
80101108:	8b 40 04             	mov    0x4(%eax),%eax
8010110b:	85 c0                	test   %eax,%eax
8010110d:	7e 11                	jle    80101120 <fileclose+0x52>
    release(&ftable.lock);
8010110f:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
80101116:	e8 ca 4d 00 00       	call   80105ee5 <release>
8010111b:	e9 82 00 00 00       	jmp    801011a2 <fileclose+0xd4>
    return;
  }
  ff = *f;
80101120:	8b 45 08             	mov    0x8(%ebp),%eax
80101123:	8b 10                	mov    (%eax),%edx
80101125:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101128:	8b 50 04             	mov    0x4(%eax),%edx
8010112b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
8010112e:	8b 50 08             	mov    0x8(%eax),%edx
80101131:	89 55 e8             	mov    %edx,-0x18(%ebp)
80101134:	8b 50 0c             	mov    0xc(%eax),%edx
80101137:	89 55 ec             	mov    %edx,-0x14(%ebp)
8010113a:	8b 50 10             	mov    0x10(%eax),%edx
8010113d:	89 55 f0             	mov    %edx,-0x10(%ebp)
80101140:	8b 40 14             	mov    0x14(%eax),%eax
80101143:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
80101146:	8b 45 08             	mov    0x8(%ebp),%eax
80101149:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
80101150:	8b 45 08             	mov    0x8(%ebp),%eax
80101153:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
80101159:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
80101160:	e8 80 4d 00 00       	call   80105ee5 <release>
  
  if(ff.type == FD_PIPE)
80101165:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101168:	83 f8 01             	cmp    $0x1,%eax
8010116b:	75 18                	jne    80101185 <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
8010116d:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
80101171:	0f be d0             	movsbl %al,%edx
80101174:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101177:	89 54 24 04          	mov    %edx,0x4(%esp)
8010117b:	89 04 24             	mov    %eax,(%esp)
8010117e:	e8 01 31 00 00       	call   80104284 <pipeclose>
80101183:	eb 1d                	jmp    801011a2 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
80101185:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101188:	83 f8 02             	cmp    $0x2,%eax
8010118b:	75 15                	jne    801011a2 <fileclose+0xd4>
    begin_op();
8010118d:	e8 99 24 00 00       	call   8010362b <begin_op>
    iput(ff.ip);
80101192:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101195:	89 04 24             	mov    %eax,(%esp)
80101198:	e8 71 09 00 00       	call   80101b0e <iput>
    end_op();
8010119d:	e8 0d 25 00 00       	call   801036af <end_op>
  }
}
801011a2:	c9                   	leave  
801011a3:	c3                   	ret    

801011a4 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
801011a4:	55                   	push   %ebp
801011a5:	89 e5                	mov    %esp,%ebp
801011a7:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
801011aa:	8b 45 08             	mov    0x8(%ebp),%eax
801011ad:	8b 00                	mov    (%eax),%eax
801011af:	83 f8 02             	cmp    $0x2,%eax
801011b2:	75 38                	jne    801011ec <filestat+0x48>
    ilock(f->ip);
801011b4:	8b 45 08             	mov    0x8(%ebp),%eax
801011b7:	8b 40 10             	mov    0x10(%eax),%eax
801011ba:	89 04 24             	mov    %eax,(%esp)
801011bd:	e8 99 07 00 00       	call   8010195b <ilock>
    stati(f->ip, st);
801011c2:	8b 45 08             	mov    0x8(%ebp),%eax
801011c5:	8b 40 10             	mov    0x10(%eax),%eax
801011c8:	8b 55 0c             	mov    0xc(%ebp),%edx
801011cb:	89 54 24 04          	mov    %edx,0x4(%esp)
801011cf:	89 04 24             	mov    %eax,(%esp)
801011d2:	e8 4c 0c 00 00       	call   80101e23 <stati>
    iunlock(f->ip);
801011d7:	8b 45 08             	mov    0x8(%ebp),%eax
801011da:	8b 40 10             	mov    0x10(%eax),%eax
801011dd:	89 04 24             	mov    %eax,(%esp)
801011e0:	e8 c4 08 00 00       	call   80101aa9 <iunlock>
    return 0;
801011e5:	b8 00 00 00 00       	mov    $0x0,%eax
801011ea:	eb 05                	jmp    801011f1 <filestat+0x4d>
  }
  return -1;
801011ec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801011f1:	c9                   	leave  
801011f2:	c3                   	ret    

801011f3 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
801011f3:	55                   	push   %ebp
801011f4:	89 e5                	mov    %esp,%ebp
801011f6:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
801011f9:	8b 45 08             	mov    0x8(%ebp),%eax
801011fc:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101200:	84 c0                	test   %al,%al
80101202:	75 0a                	jne    8010120e <fileread+0x1b>
    return -1;
80101204:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101209:	e9 9f 00 00 00       	jmp    801012ad <fileread+0xba>
  if(f->type == FD_PIPE)
8010120e:	8b 45 08             	mov    0x8(%ebp),%eax
80101211:	8b 00                	mov    (%eax),%eax
80101213:	83 f8 01             	cmp    $0x1,%eax
80101216:	75 1e                	jne    80101236 <fileread+0x43>
    return piperead(f->pipe, addr, n);
80101218:	8b 45 08             	mov    0x8(%ebp),%eax
8010121b:	8b 40 0c             	mov    0xc(%eax),%eax
8010121e:	8b 55 10             	mov    0x10(%ebp),%edx
80101221:	89 54 24 08          	mov    %edx,0x8(%esp)
80101225:	8b 55 0c             	mov    0xc(%ebp),%edx
80101228:	89 54 24 04          	mov    %edx,0x4(%esp)
8010122c:	89 04 24             	mov    %eax,(%esp)
8010122f:	e8 d1 31 00 00       	call   80104405 <piperead>
80101234:	eb 77                	jmp    801012ad <fileread+0xba>
  if(f->type == FD_INODE){
80101236:	8b 45 08             	mov    0x8(%ebp),%eax
80101239:	8b 00                	mov    (%eax),%eax
8010123b:	83 f8 02             	cmp    $0x2,%eax
8010123e:	75 61                	jne    801012a1 <fileread+0xae>
    ilock(f->ip);
80101240:	8b 45 08             	mov    0x8(%ebp),%eax
80101243:	8b 40 10             	mov    0x10(%eax),%eax
80101246:	89 04 24             	mov    %eax,(%esp)
80101249:	e8 0d 07 00 00       	call   8010195b <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
8010124e:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101251:	8b 45 08             	mov    0x8(%ebp),%eax
80101254:	8b 50 14             	mov    0x14(%eax),%edx
80101257:	8b 45 08             	mov    0x8(%ebp),%eax
8010125a:	8b 40 10             	mov    0x10(%eax),%eax
8010125d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101261:	89 54 24 08          	mov    %edx,0x8(%esp)
80101265:	8b 55 0c             	mov    0xc(%ebp),%edx
80101268:	89 54 24 04          	mov    %edx,0x4(%esp)
8010126c:	89 04 24             	mov    %eax,(%esp)
8010126f:	e8 f4 0b 00 00       	call   80101e68 <readi>
80101274:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101277:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010127b:	7e 11                	jle    8010128e <fileread+0x9b>
      f->off += r;
8010127d:	8b 45 08             	mov    0x8(%ebp),%eax
80101280:	8b 50 14             	mov    0x14(%eax),%edx
80101283:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101286:	01 c2                	add    %eax,%edx
80101288:	8b 45 08             	mov    0x8(%ebp),%eax
8010128b:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
8010128e:	8b 45 08             	mov    0x8(%ebp),%eax
80101291:	8b 40 10             	mov    0x10(%eax),%eax
80101294:	89 04 24             	mov    %eax,(%esp)
80101297:	e8 0d 08 00 00       	call   80101aa9 <iunlock>
    return r;
8010129c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010129f:	eb 0c                	jmp    801012ad <fileread+0xba>
  }
  panic("fileread");
801012a1:	c7 04 24 26 95 10 80 	movl   $0x80109526,(%esp)
801012a8:	e8 8d f2 ff ff       	call   8010053a <panic>
}
801012ad:	c9                   	leave  
801012ae:	c3                   	ret    

801012af <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
801012af:	55                   	push   %ebp
801012b0:	89 e5                	mov    %esp,%ebp
801012b2:	53                   	push   %ebx
801012b3:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
801012b6:	8b 45 08             	mov    0x8(%ebp),%eax
801012b9:	0f b6 40 09          	movzbl 0x9(%eax),%eax
801012bd:	84 c0                	test   %al,%al
801012bf:	75 0a                	jne    801012cb <filewrite+0x1c>
    return -1;
801012c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801012c6:	e9 20 01 00 00       	jmp    801013eb <filewrite+0x13c>
  if(f->type == FD_PIPE)
801012cb:	8b 45 08             	mov    0x8(%ebp),%eax
801012ce:	8b 00                	mov    (%eax),%eax
801012d0:	83 f8 01             	cmp    $0x1,%eax
801012d3:	75 21                	jne    801012f6 <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
801012d5:	8b 45 08             	mov    0x8(%ebp),%eax
801012d8:	8b 40 0c             	mov    0xc(%eax),%eax
801012db:	8b 55 10             	mov    0x10(%ebp),%edx
801012de:	89 54 24 08          	mov    %edx,0x8(%esp)
801012e2:	8b 55 0c             	mov    0xc(%ebp),%edx
801012e5:	89 54 24 04          	mov    %edx,0x4(%esp)
801012e9:	89 04 24             	mov    %eax,(%esp)
801012ec:	e8 25 30 00 00       	call   80104316 <pipewrite>
801012f1:	e9 f5 00 00 00       	jmp    801013eb <filewrite+0x13c>
  if(f->type == FD_INODE){
801012f6:	8b 45 08             	mov    0x8(%ebp),%eax
801012f9:	8b 00                	mov    (%eax),%eax
801012fb:	83 f8 02             	cmp    $0x2,%eax
801012fe:	0f 85 db 00 00 00    	jne    801013df <filewrite+0x130>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
80101304:	c7 45 ec 00 1a 00 00 	movl   $0x1a00,-0x14(%ebp)
    int i = 0;
8010130b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
80101312:	e9 a8 00 00 00       	jmp    801013bf <filewrite+0x110>
      int n1 = n - i;
80101317:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010131a:	8b 55 10             	mov    0x10(%ebp),%edx
8010131d:	29 c2                	sub    %eax,%edx
8010131f:	89 d0                	mov    %edx,%eax
80101321:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
80101324:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101327:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010132a:	7e 06                	jle    80101332 <filewrite+0x83>
        n1 = max;
8010132c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010132f:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_op();
80101332:	e8 f4 22 00 00       	call   8010362b <begin_op>
      ilock(f->ip);
80101337:	8b 45 08             	mov    0x8(%ebp),%eax
8010133a:	8b 40 10             	mov    0x10(%eax),%eax
8010133d:	89 04 24             	mov    %eax,(%esp)
80101340:	e8 16 06 00 00       	call   8010195b <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80101345:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80101348:	8b 45 08             	mov    0x8(%ebp),%eax
8010134b:	8b 50 14             	mov    0x14(%eax),%edx
8010134e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
80101351:	8b 45 0c             	mov    0xc(%ebp),%eax
80101354:	01 c3                	add    %eax,%ebx
80101356:	8b 45 08             	mov    0x8(%ebp),%eax
80101359:	8b 40 10             	mov    0x10(%eax),%eax
8010135c:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101360:	89 54 24 08          	mov    %edx,0x8(%esp)
80101364:	89 5c 24 04          	mov    %ebx,0x4(%esp)
80101368:	89 04 24             	mov    %eax,(%esp)
8010136b:	e8 69 0c 00 00       	call   80101fd9 <writei>
80101370:	89 45 e8             	mov    %eax,-0x18(%ebp)
80101373:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101377:	7e 11                	jle    8010138a <filewrite+0xdb>
        f->off += r;
80101379:	8b 45 08             	mov    0x8(%ebp),%eax
8010137c:	8b 50 14             	mov    0x14(%eax),%edx
8010137f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101382:	01 c2                	add    %eax,%edx
80101384:	8b 45 08             	mov    0x8(%ebp),%eax
80101387:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
8010138a:	8b 45 08             	mov    0x8(%ebp),%eax
8010138d:	8b 40 10             	mov    0x10(%eax),%eax
80101390:	89 04 24             	mov    %eax,(%esp)
80101393:	e8 11 07 00 00       	call   80101aa9 <iunlock>
      end_op();
80101398:	e8 12 23 00 00       	call   801036af <end_op>

      if(r < 0)
8010139d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801013a1:	79 02                	jns    801013a5 <filewrite+0xf6>
        break;
801013a3:	eb 26                	jmp    801013cb <filewrite+0x11c>
      if(r != n1)
801013a5:	8b 45 e8             	mov    -0x18(%ebp),%eax
801013a8:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801013ab:	74 0c                	je     801013b9 <filewrite+0x10a>
        panic("short filewrite");
801013ad:	c7 04 24 2f 95 10 80 	movl   $0x8010952f,(%esp)
801013b4:	e8 81 f1 ff ff       	call   8010053a <panic>
      i += r;
801013b9:	8b 45 e8             	mov    -0x18(%ebp),%eax
801013bc:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
801013bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013c2:	3b 45 10             	cmp    0x10(%ebp),%eax
801013c5:	0f 8c 4c ff ff ff    	jl     80101317 <filewrite+0x68>
        break;
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
801013cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013ce:	3b 45 10             	cmp    0x10(%ebp),%eax
801013d1:	75 05                	jne    801013d8 <filewrite+0x129>
801013d3:	8b 45 10             	mov    0x10(%ebp),%eax
801013d6:	eb 05                	jmp    801013dd <filewrite+0x12e>
801013d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801013dd:	eb 0c                	jmp    801013eb <filewrite+0x13c>
  }
  panic("filewrite");
801013df:	c7 04 24 3f 95 10 80 	movl   $0x8010953f,(%esp)
801013e6:	e8 4f f1 ff ff       	call   8010053a <panic>
}
801013eb:	83 c4 24             	add    $0x24,%esp
801013ee:	5b                   	pop    %ebx
801013ef:	5d                   	pop    %ebp
801013f0:	c3                   	ret    

801013f1 <readsb>:
static void itrunc(struct inode*);

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
801013f1:	55                   	push   %ebp
801013f2:	89 e5                	mov    %esp,%ebp
801013f4:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
801013f7:	8b 45 08             	mov    0x8(%ebp),%eax
801013fa:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80101401:	00 
80101402:	89 04 24             	mov    %eax,(%esp)
80101405:	e8 9c ed ff ff       	call   801001a6 <bread>
8010140a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
8010140d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101410:	83 c0 18             	add    $0x18,%eax
80101413:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010141a:	00 
8010141b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010141f:	8b 45 0c             	mov    0xc(%ebp),%eax
80101422:	89 04 24             	mov    %eax,(%esp)
80101425:	e8 7c 4d 00 00       	call   801061a6 <memmove>
  brelse(bp);
8010142a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010142d:	89 04 24             	mov    %eax,(%esp)
80101430:	e8 e2 ed ff ff       	call   80100217 <brelse>
}
80101435:	c9                   	leave  
80101436:	c3                   	ret    

80101437 <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80101437:	55                   	push   %ebp
80101438:	89 e5                	mov    %esp,%ebp
8010143a:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
8010143d:	8b 55 0c             	mov    0xc(%ebp),%edx
80101440:	8b 45 08             	mov    0x8(%ebp),%eax
80101443:	89 54 24 04          	mov    %edx,0x4(%esp)
80101447:	89 04 24             	mov    %eax,(%esp)
8010144a:	e8 57 ed ff ff       	call   801001a6 <bread>
8010144f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
80101452:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101455:	83 c0 18             	add    $0x18,%eax
80101458:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010145f:	00 
80101460:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101467:	00 
80101468:	89 04 24             	mov    %eax,(%esp)
8010146b:	e8 67 4c 00 00       	call   801060d7 <memset>
  log_write(bp);
80101470:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101473:	89 04 24             	mov    %eax,(%esp)
80101476:	e8 bb 23 00 00       	call   80103836 <log_write>
  brelse(bp);
8010147b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010147e:	89 04 24             	mov    %eax,(%esp)
80101481:	e8 91 ed ff ff       	call   80100217 <brelse>
}
80101486:	c9                   	leave  
80101487:	c3                   	ret    

80101488 <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
80101488:	55                   	push   %ebp
80101489:	89 e5                	mov    %esp,%ebp
8010148b:	83 ec 38             	sub    $0x38,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
8010148e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
80101495:	8b 45 08             	mov    0x8(%ebp),%eax
80101498:	8d 55 d8             	lea    -0x28(%ebp),%edx
8010149b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010149f:	89 04 24             	mov    %eax,(%esp)
801014a2:	e8 4a ff ff ff       	call   801013f1 <readsb>
  for(b = 0; b < sb.size; b += BPB){
801014a7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801014ae:	e9 07 01 00 00       	jmp    801015ba <balloc+0x132>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
801014b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801014b6:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
801014bc:	85 c0                	test   %eax,%eax
801014be:	0f 48 c2             	cmovs  %edx,%eax
801014c1:	c1 f8 0c             	sar    $0xc,%eax
801014c4:	8b 55 e0             	mov    -0x20(%ebp),%edx
801014c7:	c1 ea 03             	shr    $0x3,%edx
801014ca:	01 d0                	add    %edx,%eax
801014cc:	83 c0 03             	add    $0x3,%eax
801014cf:	89 44 24 04          	mov    %eax,0x4(%esp)
801014d3:	8b 45 08             	mov    0x8(%ebp),%eax
801014d6:	89 04 24             	mov    %eax,(%esp)
801014d9:	e8 c8 ec ff ff       	call   801001a6 <bread>
801014de:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801014e1:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801014e8:	e9 9d 00 00 00       	jmp    8010158a <balloc+0x102>
      m = 1 << (bi % 8);
801014ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014f0:	99                   	cltd   
801014f1:	c1 ea 1d             	shr    $0x1d,%edx
801014f4:	01 d0                	add    %edx,%eax
801014f6:	83 e0 07             	and    $0x7,%eax
801014f9:	29 d0                	sub    %edx,%eax
801014fb:	ba 01 00 00 00       	mov    $0x1,%edx
80101500:	89 c1                	mov    %eax,%ecx
80101502:	d3 e2                	shl    %cl,%edx
80101504:	89 d0                	mov    %edx,%eax
80101506:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
80101509:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010150c:	8d 50 07             	lea    0x7(%eax),%edx
8010150f:	85 c0                	test   %eax,%eax
80101511:	0f 48 c2             	cmovs  %edx,%eax
80101514:	c1 f8 03             	sar    $0x3,%eax
80101517:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010151a:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
8010151f:	0f b6 c0             	movzbl %al,%eax
80101522:	23 45 e8             	and    -0x18(%ebp),%eax
80101525:	85 c0                	test   %eax,%eax
80101527:	75 5d                	jne    80101586 <balloc+0xfe>
        bp->data[bi/8] |= m;  // Mark block in use.
80101529:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010152c:	8d 50 07             	lea    0x7(%eax),%edx
8010152f:	85 c0                	test   %eax,%eax
80101531:	0f 48 c2             	cmovs  %edx,%eax
80101534:	c1 f8 03             	sar    $0x3,%eax
80101537:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010153a:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
8010153f:	89 d1                	mov    %edx,%ecx
80101541:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101544:	09 ca                	or     %ecx,%edx
80101546:	89 d1                	mov    %edx,%ecx
80101548:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010154b:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
8010154f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101552:	89 04 24             	mov    %eax,(%esp)
80101555:	e8 dc 22 00 00       	call   80103836 <log_write>
        brelse(bp);
8010155a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010155d:	89 04 24             	mov    %eax,(%esp)
80101560:	e8 b2 ec ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
80101565:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101568:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010156b:	01 c2                	add    %eax,%edx
8010156d:	8b 45 08             	mov    0x8(%ebp),%eax
80101570:	89 54 24 04          	mov    %edx,0x4(%esp)
80101574:	89 04 24             	mov    %eax,(%esp)
80101577:	e8 bb fe ff ff       	call   80101437 <bzero>
        return b + bi;
8010157c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010157f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101582:	01 d0                	add    %edx,%eax
80101584:	eb 4e                	jmp    801015d4 <balloc+0x14c>

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101586:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010158a:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
80101591:	7f 15                	jg     801015a8 <balloc+0x120>
80101593:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101596:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101599:	01 d0                	add    %edx,%eax
8010159b:	89 c2                	mov    %eax,%edx
8010159d:	8b 45 d8             	mov    -0x28(%ebp),%eax
801015a0:	39 c2                	cmp    %eax,%edx
801015a2:	0f 82 45 ff ff ff    	jb     801014ed <balloc+0x65>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
801015a8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801015ab:	89 04 24             	mov    %eax,(%esp)
801015ae:	e8 64 ec ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
801015b3:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801015ba:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015bd:	8b 45 d8             	mov    -0x28(%ebp),%eax
801015c0:	39 c2                	cmp    %eax,%edx
801015c2:	0f 82 eb fe ff ff    	jb     801014b3 <balloc+0x2b>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
801015c8:	c7 04 24 49 95 10 80 	movl   $0x80109549,(%esp)
801015cf:	e8 66 ef ff ff       	call   8010053a <panic>
}
801015d4:	c9                   	leave  
801015d5:	c3                   	ret    

801015d6 <bfree>:

// Free a disk block.
static void
bfree(int dev, uint b)
{
801015d6:	55                   	push   %ebp
801015d7:	89 e5                	mov    %esp,%ebp
801015d9:	83 ec 38             	sub    $0x38,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
801015dc:	8d 45 dc             	lea    -0x24(%ebp),%eax
801015df:	89 44 24 04          	mov    %eax,0x4(%esp)
801015e3:	8b 45 08             	mov    0x8(%ebp),%eax
801015e6:	89 04 24             	mov    %eax,(%esp)
801015e9:	e8 03 fe ff ff       	call   801013f1 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
801015ee:	8b 45 0c             	mov    0xc(%ebp),%eax
801015f1:	c1 e8 0c             	shr    $0xc,%eax
801015f4:	89 c2                	mov    %eax,%edx
801015f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801015f9:	c1 e8 03             	shr    $0x3,%eax
801015fc:	01 d0                	add    %edx,%eax
801015fe:	8d 50 03             	lea    0x3(%eax),%edx
80101601:	8b 45 08             	mov    0x8(%ebp),%eax
80101604:	89 54 24 04          	mov    %edx,0x4(%esp)
80101608:	89 04 24             	mov    %eax,(%esp)
8010160b:	e8 96 eb ff ff       	call   801001a6 <bread>
80101610:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80101613:	8b 45 0c             	mov    0xc(%ebp),%eax
80101616:	25 ff 0f 00 00       	and    $0xfff,%eax
8010161b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
8010161e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101621:	99                   	cltd   
80101622:	c1 ea 1d             	shr    $0x1d,%edx
80101625:	01 d0                	add    %edx,%eax
80101627:	83 e0 07             	and    $0x7,%eax
8010162a:	29 d0                	sub    %edx,%eax
8010162c:	ba 01 00 00 00       	mov    $0x1,%edx
80101631:	89 c1                	mov    %eax,%ecx
80101633:	d3 e2                	shl    %cl,%edx
80101635:	89 d0                	mov    %edx,%eax
80101637:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
8010163a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010163d:	8d 50 07             	lea    0x7(%eax),%edx
80101640:	85 c0                	test   %eax,%eax
80101642:	0f 48 c2             	cmovs  %edx,%eax
80101645:	c1 f8 03             	sar    $0x3,%eax
80101648:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010164b:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101650:	0f b6 c0             	movzbl %al,%eax
80101653:	23 45 ec             	and    -0x14(%ebp),%eax
80101656:	85 c0                	test   %eax,%eax
80101658:	75 0c                	jne    80101666 <bfree+0x90>
    panic("freeing free block");
8010165a:	c7 04 24 5f 95 10 80 	movl   $0x8010955f,(%esp)
80101661:	e8 d4 ee ff ff       	call   8010053a <panic>
  bp->data[bi/8] &= ~m;
80101666:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101669:	8d 50 07             	lea    0x7(%eax),%edx
8010166c:	85 c0                	test   %eax,%eax
8010166e:	0f 48 c2             	cmovs  %edx,%eax
80101671:	c1 f8 03             	sar    $0x3,%eax
80101674:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101677:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
8010167c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
8010167f:	f7 d1                	not    %ecx
80101681:	21 ca                	and    %ecx,%edx
80101683:	89 d1                	mov    %edx,%ecx
80101685:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101688:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
8010168c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010168f:	89 04 24             	mov    %eax,(%esp)
80101692:	e8 9f 21 00 00       	call   80103836 <log_write>
  brelse(bp);
80101697:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010169a:	89 04 24             	mov    %eax,(%esp)
8010169d:	e8 75 eb ff ff       	call   80100217 <brelse>
}
801016a2:	c9                   	leave  
801016a3:	c3                   	ret    

801016a4 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
801016a4:	55                   	push   %ebp
801016a5:	89 e5                	mov    %esp,%ebp
801016a7:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
801016aa:	c7 44 24 04 72 95 10 	movl   $0x80109572,0x4(%esp)
801016b1:	80 
801016b2:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
801016b9:	e8 a4 47 00 00       	call   80105e62 <initlock>
}
801016be:	c9                   	leave  
801016bf:	c3                   	ret    

801016c0 <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
801016c0:	55                   	push   %ebp
801016c1:	89 e5                	mov    %esp,%ebp
801016c3:	83 ec 38             	sub    $0x38,%esp
801016c6:	8b 45 0c             	mov    0xc(%ebp),%eax
801016c9:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
801016cd:	8b 45 08             	mov    0x8(%ebp),%eax
801016d0:	8d 55 dc             	lea    -0x24(%ebp),%edx
801016d3:	89 54 24 04          	mov    %edx,0x4(%esp)
801016d7:	89 04 24             	mov    %eax,(%esp)
801016da:	e8 12 fd ff ff       	call   801013f1 <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
801016df:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
801016e6:	e9 98 00 00 00       	jmp    80101783 <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
801016eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016ee:	c1 e8 03             	shr    $0x3,%eax
801016f1:	83 c0 02             	add    $0x2,%eax
801016f4:	89 44 24 04          	mov    %eax,0x4(%esp)
801016f8:	8b 45 08             	mov    0x8(%ebp),%eax
801016fb:	89 04 24             	mov    %eax,(%esp)
801016fe:	e8 a3 ea ff ff       	call   801001a6 <bread>
80101703:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80101706:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101709:	8d 50 18             	lea    0x18(%eax),%edx
8010170c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010170f:	83 e0 07             	and    $0x7,%eax
80101712:	c1 e0 06             	shl    $0x6,%eax
80101715:	01 d0                	add    %edx,%eax
80101717:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
8010171a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010171d:	0f b7 00             	movzwl (%eax),%eax
80101720:	66 85 c0             	test   %ax,%ax
80101723:	75 4f                	jne    80101774 <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
80101725:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
8010172c:	00 
8010172d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101734:	00 
80101735:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101738:	89 04 24             	mov    %eax,(%esp)
8010173b:	e8 97 49 00 00       	call   801060d7 <memset>
      dip->type = type;
80101740:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101743:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
80101747:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
8010174a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010174d:	89 04 24             	mov    %eax,(%esp)
80101750:	e8 e1 20 00 00       	call   80103836 <log_write>
      brelse(bp);
80101755:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101758:	89 04 24             	mov    %eax,(%esp)
8010175b:	e8 b7 ea ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
80101760:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101763:	89 44 24 04          	mov    %eax,0x4(%esp)
80101767:	8b 45 08             	mov    0x8(%ebp),%eax
8010176a:	89 04 24             	mov    %eax,(%esp)
8010176d:	e8 e5 00 00 00       	call   80101857 <iget>
80101772:	eb 29                	jmp    8010179d <ialloc+0xdd>
    }
    brelse(bp);
80101774:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101777:	89 04 24             	mov    %eax,(%esp)
8010177a:	e8 98 ea ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
8010177f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101783:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101786:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101789:	39 c2                	cmp    %eax,%edx
8010178b:	0f 82 5a ff ff ff    	jb     801016eb <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
80101791:	c7 04 24 79 95 10 80 	movl   $0x80109579,(%esp)
80101798:	e8 9d ed ff ff       	call   8010053a <panic>
}
8010179d:	c9                   	leave  
8010179e:	c3                   	ret    

8010179f <iupdate>:

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
8010179f:	55                   	push   %ebp
801017a0:	89 e5                	mov    %esp,%ebp
801017a2:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
801017a5:	8b 45 08             	mov    0x8(%ebp),%eax
801017a8:	8b 40 04             	mov    0x4(%eax),%eax
801017ab:	c1 e8 03             	shr    $0x3,%eax
801017ae:	8d 50 02             	lea    0x2(%eax),%edx
801017b1:	8b 45 08             	mov    0x8(%ebp),%eax
801017b4:	8b 00                	mov    (%eax),%eax
801017b6:	89 54 24 04          	mov    %edx,0x4(%esp)
801017ba:	89 04 24             	mov    %eax,(%esp)
801017bd:	e8 e4 e9 ff ff       	call   801001a6 <bread>
801017c2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
801017c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017c8:	8d 50 18             	lea    0x18(%eax),%edx
801017cb:	8b 45 08             	mov    0x8(%ebp),%eax
801017ce:	8b 40 04             	mov    0x4(%eax),%eax
801017d1:	83 e0 07             	and    $0x7,%eax
801017d4:	c1 e0 06             	shl    $0x6,%eax
801017d7:	01 d0                	add    %edx,%eax
801017d9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
801017dc:	8b 45 08             	mov    0x8(%ebp),%eax
801017df:	0f b7 50 10          	movzwl 0x10(%eax),%edx
801017e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017e6:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
801017e9:	8b 45 08             	mov    0x8(%ebp),%eax
801017ec:	0f b7 50 12          	movzwl 0x12(%eax),%edx
801017f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017f3:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
801017f7:	8b 45 08             	mov    0x8(%ebp),%eax
801017fa:	0f b7 50 14          	movzwl 0x14(%eax),%edx
801017fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101801:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101805:	8b 45 08             	mov    0x8(%ebp),%eax
80101808:	0f b7 50 16          	movzwl 0x16(%eax),%edx
8010180c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010180f:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
80101813:	8b 45 08             	mov    0x8(%ebp),%eax
80101816:	8b 50 18             	mov    0x18(%eax),%edx
80101819:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010181c:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
8010181f:	8b 45 08             	mov    0x8(%ebp),%eax
80101822:	8d 50 1c             	lea    0x1c(%eax),%edx
80101825:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101828:	83 c0 0c             	add    $0xc,%eax
8010182b:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101832:	00 
80101833:	89 54 24 04          	mov    %edx,0x4(%esp)
80101837:	89 04 24             	mov    %eax,(%esp)
8010183a:	e8 67 49 00 00       	call   801061a6 <memmove>
  log_write(bp);
8010183f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101842:	89 04 24             	mov    %eax,(%esp)
80101845:	e8 ec 1f 00 00       	call   80103836 <log_write>
  brelse(bp);
8010184a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010184d:	89 04 24             	mov    %eax,(%esp)
80101850:	e8 c2 e9 ff ff       	call   80100217 <brelse>
}
80101855:	c9                   	leave  
80101856:	c3                   	ret    

80101857 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
80101857:	55                   	push   %ebp
80101858:	89 e5                	mov    %esp,%ebp
8010185a:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
8010185d:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101864:	e8 1a 46 00 00       	call   80105e83 <acquire>

  // Is the inode already cached?
  empty = 0;
80101869:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101870:	c7 45 f4 b4 22 11 80 	movl   $0x801122b4,-0xc(%ebp)
80101877:	eb 59                	jmp    801018d2 <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
80101879:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010187c:	8b 40 08             	mov    0x8(%eax),%eax
8010187f:	85 c0                	test   %eax,%eax
80101881:	7e 35                	jle    801018b8 <iget+0x61>
80101883:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101886:	8b 00                	mov    (%eax),%eax
80101888:	3b 45 08             	cmp    0x8(%ebp),%eax
8010188b:	75 2b                	jne    801018b8 <iget+0x61>
8010188d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101890:	8b 40 04             	mov    0x4(%eax),%eax
80101893:	3b 45 0c             	cmp    0xc(%ebp),%eax
80101896:	75 20                	jne    801018b8 <iget+0x61>
      ip->ref++;
80101898:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010189b:	8b 40 08             	mov    0x8(%eax),%eax
8010189e:	8d 50 01             	lea    0x1(%eax),%edx
801018a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018a4:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
801018a7:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
801018ae:	e8 32 46 00 00       	call   80105ee5 <release>
      return ip;
801018b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018b6:	eb 6f                	jmp    80101927 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801018b8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801018bc:	75 10                	jne    801018ce <iget+0x77>
801018be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018c1:	8b 40 08             	mov    0x8(%eax),%eax
801018c4:	85 c0                	test   %eax,%eax
801018c6:	75 06                	jne    801018ce <iget+0x77>
      empty = ip;
801018c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018cb:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801018ce:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
801018d2:	81 7d f4 54 32 11 80 	cmpl   $0x80113254,-0xc(%ebp)
801018d9:	72 9e                	jb     80101879 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
801018db:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801018df:	75 0c                	jne    801018ed <iget+0x96>
    panic("iget: no inodes");
801018e1:	c7 04 24 8b 95 10 80 	movl   $0x8010958b,(%esp)
801018e8:	e8 4d ec ff ff       	call   8010053a <panic>

  ip = empty;
801018ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018f0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
801018f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018f6:	8b 55 08             	mov    0x8(%ebp),%edx
801018f9:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
801018fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018fe:	8b 55 0c             	mov    0xc(%ebp),%edx
80101901:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80101904:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101907:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
8010190e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101911:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
80101918:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
8010191f:	e8 c1 45 00 00       	call   80105ee5 <release>

  return ip;
80101924:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80101927:	c9                   	leave  
80101928:	c3                   	ret    

80101929 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
80101929:	55                   	push   %ebp
8010192a:	89 e5                	mov    %esp,%ebp
8010192c:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
8010192f:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101936:	e8 48 45 00 00       	call   80105e83 <acquire>
  ip->ref++;
8010193b:	8b 45 08             	mov    0x8(%ebp),%eax
8010193e:	8b 40 08             	mov    0x8(%eax),%eax
80101941:	8d 50 01             	lea    0x1(%eax),%edx
80101944:	8b 45 08             	mov    0x8(%ebp),%eax
80101947:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
8010194a:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101951:	e8 8f 45 00 00       	call   80105ee5 <release>
  return ip;
80101956:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101959:	c9                   	leave  
8010195a:	c3                   	ret    

8010195b <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
8010195b:	55                   	push   %ebp
8010195c:	89 e5                	mov    %esp,%ebp
8010195e:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
80101961:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101965:	74 0a                	je     80101971 <ilock+0x16>
80101967:	8b 45 08             	mov    0x8(%ebp),%eax
8010196a:	8b 40 08             	mov    0x8(%eax),%eax
8010196d:	85 c0                	test   %eax,%eax
8010196f:	7f 0c                	jg     8010197d <ilock+0x22>
    panic("ilock");
80101971:	c7 04 24 9b 95 10 80 	movl   $0x8010959b,(%esp)
80101978:	e8 bd eb ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
8010197d:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101984:	e8 fa 44 00 00       	call   80105e83 <acquire>
  while(ip->flags & I_BUSY)
80101989:	eb 13                	jmp    8010199e <ilock+0x43>
    sleep(ip, &icache.lock);
8010198b:	c7 44 24 04 80 22 11 	movl   $0x80112280,0x4(%esp)
80101992:	80 
80101993:	8b 45 08             	mov    0x8(%ebp),%eax
80101996:	89 04 24             	mov    %eax,(%esp)
80101999:	e8 04 35 00 00       	call   80104ea2 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
8010199e:	8b 45 08             	mov    0x8(%ebp),%eax
801019a1:	8b 40 0c             	mov    0xc(%eax),%eax
801019a4:	83 e0 01             	and    $0x1,%eax
801019a7:	85 c0                	test   %eax,%eax
801019a9:	75 e0                	jne    8010198b <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
801019ab:	8b 45 08             	mov    0x8(%ebp),%eax
801019ae:	8b 40 0c             	mov    0xc(%eax),%eax
801019b1:	83 c8 01             	or     $0x1,%eax
801019b4:	89 c2                	mov    %eax,%edx
801019b6:	8b 45 08             	mov    0x8(%ebp),%eax
801019b9:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
801019bc:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
801019c3:	e8 1d 45 00 00       	call   80105ee5 <release>

  if(!(ip->flags & I_VALID)){
801019c8:	8b 45 08             	mov    0x8(%ebp),%eax
801019cb:	8b 40 0c             	mov    0xc(%eax),%eax
801019ce:	83 e0 02             	and    $0x2,%eax
801019d1:	85 c0                	test   %eax,%eax
801019d3:	0f 85 ce 00 00 00    	jne    80101aa7 <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
801019d9:	8b 45 08             	mov    0x8(%ebp),%eax
801019dc:	8b 40 04             	mov    0x4(%eax),%eax
801019df:	c1 e8 03             	shr    $0x3,%eax
801019e2:	8d 50 02             	lea    0x2(%eax),%edx
801019e5:	8b 45 08             	mov    0x8(%ebp),%eax
801019e8:	8b 00                	mov    (%eax),%eax
801019ea:	89 54 24 04          	mov    %edx,0x4(%esp)
801019ee:	89 04 24             	mov    %eax,(%esp)
801019f1:	e8 b0 e7 ff ff       	call   801001a6 <bread>
801019f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
801019f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019fc:	8d 50 18             	lea    0x18(%eax),%edx
801019ff:	8b 45 08             	mov    0x8(%ebp),%eax
80101a02:	8b 40 04             	mov    0x4(%eax),%eax
80101a05:	83 e0 07             	and    $0x7,%eax
80101a08:	c1 e0 06             	shl    $0x6,%eax
80101a0b:	01 d0                	add    %edx,%eax
80101a0d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80101a10:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a13:	0f b7 10             	movzwl (%eax),%edx
80101a16:	8b 45 08             	mov    0x8(%ebp),%eax
80101a19:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
80101a1d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a20:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101a24:	8b 45 08             	mov    0x8(%ebp),%eax
80101a27:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
80101a2b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a2e:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101a32:	8b 45 08             	mov    0x8(%ebp),%eax
80101a35:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
80101a39:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a3c:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101a40:	8b 45 08             	mov    0x8(%ebp),%eax
80101a43:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
80101a47:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a4a:	8b 50 08             	mov    0x8(%eax),%edx
80101a4d:	8b 45 08             	mov    0x8(%ebp),%eax
80101a50:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101a53:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a56:	8d 50 0c             	lea    0xc(%eax),%edx
80101a59:	8b 45 08             	mov    0x8(%ebp),%eax
80101a5c:	83 c0 1c             	add    $0x1c,%eax
80101a5f:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101a66:	00 
80101a67:	89 54 24 04          	mov    %edx,0x4(%esp)
80101a6b:	89 04 24             	mov    %eax,(%esp)
80101a6e:	e8 33 47 00 00       	call   801061a6 <memmove>
    brelse(bp);
80101a73:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a76:	89 04 24             	mov    %eax,(%esp)
80101a79:	e8 99 e7 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
80101a7e:	8b 45 08             	mov    0x8(%ebp),%eax
80101a81:	8b 40 0c             	mov    0xc(%eax),%eax
80101a84:	83 c8 02             	or     $0x2,%eax
80101a87:	89 c2                	mov    %eax,%edx
80101a89:	8b 45 08             	mov    0x8(%ebp),%eax
80101a8c:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
80101a8f:	8b 45 08             	mov    0x8(%ebp),%eax
80101a92:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101a96:	66 85 c0             	test   %ax,%ax
80101a99:	75 0c                	jne    80101aa7 <ilock+0x14c>
      panic("ilock: no type");
80101a9b:	c7 04 24 a1 95 10 80 	movl   $0x801095a1,(%esp)
80101aa2:	e8 93 ea ff ff       	call   8010053a <panic>
  }
}
80101aa7:	c9                   	leave  
80101aa8:	c3                   	ret    

80101aa9 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80101aa9:	55                   	push   %ebp
80101aaa:	89 e5                	mov    %esp,%ebp
80101aac:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
80101aaf:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101ab3:	74 17                	je     80101acc <iunlock+0x23>
80101ab5:	8b 45 08             	mov    0x8(%ebp),%eax
80101ab8:	8b 40 0c             	mov    0xc(%eax),%eax
80101abb:	83 e0 01             	and    $0x1,%eax
80101abe:	85 c0                	test   %eax,%eax
80101ac0:	74 0a                	je     80101acc <iunlock+0x23>
80101ac2:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac5:	8b 40 08             	mov    0x8(%eax),%eax
80101ac8:	85 c0                	test   %eax,%eax
80101aca:	7f 0c                	jg     80101ad8 <iunlock+0x2f>
    panic("iunlock");
80101acc:	c7 04 24 b0 95 10 80 	movl   $0x801095b0,(%esp)
80101ad3:	e8 62 ea ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80101ad8:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101adf:	e8 9f 43 00 00       	call   80105e83 <acquire>
  ip->flags &= ~I_BUSY;
80101ae4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ae7:	8b 40 0c             	mov    0xc(%eax),%eax
80101aea:	83 e0 fe             	and    $0xfffffffe,%eax
80101aed:	89 c2                	mov    %eax,%edx
80101aef:	8b 45 08             	mov    0x8(%ebp),%eax
80101af2:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80101af5:	8b 45 08             	mov    0x8(%ebp),%eax
80101af8:	89 04 24             	mov    %eax,(%esp)
80101afb:	e8 7e 34 00 00       	call   80104f7e <wakeup>
  release(&icache.lock);
80101b00:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101b07:	e8 d9 43 00 00       	call   80105ee5 <release>
}
80101b0c:	c9                   	leave  
80101b0d:	c3                   	ret    

80101b0e <iput>:
// to it, free the inode (and its content) on disk.
// All calls to iput() must be inside a transaction in
// case it has to free the inode.
void
iput(struct inode *ip)
{
80101b0e:	55                   	push   %ebp
80101b0f:	89 e5                	mov    %esp,%ebp
80101b11:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101b14:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101b1b:	e8 63 43 00 00       	call   80105e83 <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101b20:	8b 45 08             	mov    0x8(%ebp),%eax
80101b23:	8b 40 08             	mov    0x8(%eax),%eax
80101b26:	83 f8 01             	cmp    $0x1,%eax
80101b29:	0f 85 93 00 00 00    	jne    80101bc2 <iput+0xb4>
80101b2f:	8b 45 08             	mov    0x8(%ebp),%eax
80101b32:	8b 40 0c             	mov    0xc(%eax),%eax
80101b35:	83 e0 02             	and    $0x2,%eax
80101b38:	85 c0                	test   %eax,%eax
80101b3a:	0f 84 82 00 00 00    	je     80101bc2 <iput+0xb4>
80101b40:	8b 45 08             	mov    0x8(%ebp),%eax
80101b43:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101b47:	66 85 c0             	test   %ax,%ax
80101b4a:	75 76                	jne    80101bc2 <iput+0xb4>
    // inode has no links and no other references: truncate and free.
    if(ip->flags & I_BUSY)
80101b4c:	8b 45 08             	mov    0x8(%ebp),%eax
80101b4f:	8b 40 0c             	mov    0xc(%eax),%eax
80101b52:	83 e0 01             	and    $0x1,%eax
80101b55:	85 c0                	test   %eax,%eax
80101b57:	74 0c                	je     80101b65 <iput+0x57>
      panic("iput busy");
80101b59:	c7 04 24 b8 95 10 80 	movl   $0x801095b8,(%esp)
80101b60:	e8 d5 e9 ff ff       	call   8010053a <panic>
    ip->flags |= I_BUSY;
80101b65:	8b 45 08             	mov    0x8(%ebp),%eax
80101b68:	8b 40 0c             	mov    0xc(%eax),%eax
80101b6b:	83 c8 01             	or     $0x1,%eax
80101b6e:	89 c2                	mov    %eax,%edx
80101b70:	8b 45 08             	mov    0x8(%ebp),%eax
80101b73:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101b76:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101b7d:	e8 63 43 00 00       	call   80105ee5 <release>
    itrunc(ip);
80101b82:	8b 45 08             	mov    0x8(%ebp),%eax
80101b85:	89 04 24             	mov    %eax,(%esp)
80101b88:	e8 7d 01 00 00       	call   80101d0a <itrunc>
    ip->type = 0;
80101b8d:	8b 45 08             	mov    0x8(%ebp),%eax
80101b90:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101b96:	8b 45 08             	mov    0x8(%ebp),%eax
80101b99:	89 04 24             	mov    %eax,(%esp)
80101b9c:	e8 fe fb ff ff       	call   8010179f <iupdate>
    acquire(&icache.lock);
80101ba1:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101ba8:	e8 d6 42 00 00       	call   80105e83 <acquire>
    ip->flags = 0;
80101bad:	8b 45 08             	mov    0x8(%ebp),%eax
80101bb0:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101bb7:	8b 45 08             	mov    0x8(%ebp),%eax
80101bba:	89 04 24             	mov    %eax,(%esp)
80101bbd:	e8 bc 33 00 00       	call   80104f7e <wakeup>
  }
  ip->ref--;
80101bc2:	8b 45 08             	mov    0x8(%ebp),%eax
80101bc5:	8b 40 08             	mov    0x8(%eax),%eax
80101bc8:	8d 50 ff             	lea    -0x1(%eax),%edx
80101bcb:	8b 45 08             	mov    0x8(%ebp),%eax
80101bce:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101bd1:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101bd8:	e8 08 43 00 00       	call   80105ee5 <release>
}
80101bdd:	c9                   	leave  
80101bde:	c3                   	ret    

80101bdf <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101bdf:	55                   	push   %ebp
80101be0:	89 e5                	mov    %esp,%ebp
80101be2:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101be5:	8b 45 08             	mov    0x8(%ebp),%eax
80101be8:	89 04 24             	mov    %eax,(%esp)
80101beb:	e8 b9 fe ff ff       	call   80101aa9 <iunlock>
  iput(ip);
80101bf0:	8b 45 08             	mov    0x8(%ebp),%eax
80101bf3:	89 04 24             	mov    %eax,(%esp)
80101bf6:	e8 13 ff ff ff       	call   80101b0e <iput>
}
80101bfb:	c9                   	leave  
80101bfc:	c3                   	ret    

80101bfd <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101bfd:	55                   	push   %ebp
80101bfe:	89 e5                	mov    %esp,%ebp
80101c00:	53                   	push   %ebx
80101c01:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101c04:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101c08:	77 3e                	ja     80101c48 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101c0a:	8b 45 08             	mov    0x8(%ebp),%eax
80101c0d:	8b 55 0c             	mov    0xc(%ebp),%edx
80101c10:	83 c2 04             	add    $0x4,%edx
80101c13:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101c17:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c1a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101c1e:	75 20                	jne    80101c40 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101c20:	8b 45 08             	mov    0x8(%ebp),%eax
80101c23:	8b 00                	mov    (%eax),%eax
80101c25:	89 04 24             	mov    %eax,(%esp)
80101c28:	e8 5b f8 ff ff       	call   80101488 <balloc>
80101c2d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c30:	8b 45 08             	mov    0x8(%ebp),%eax
80101c33:	8b 55 0c             	mov    0xc(%ebp),%edx
80101c36:	8d 4a 04             	lea    0x4(%edx),%ecx
80101c39:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c3c:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101c40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c43:	e9 bc 00 00 00       	jmp    80101d04 <bmap+0x107>
  }
  bn -= NDIRECT;
80101c48:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101c4c:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101c50:	0f 87 a2 00 00 00    	ja     80101cf8 <bmap+0xfb>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101c56:	8b 45 08             	mov    0x8(%ebp),%eax
80101c59:	8b 40 4c             	mov    0x4c(%eax),%eax
80101c5c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c5f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101c63:	75 19                	jne    80101c7e <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101c65:	8b 45 08             	mov    0x8(%ebp),%eax
80101c68:	8b 00                	mov    (%eax),%eax
80101c6a:	89 04 24             	mov    %eax,(%esp)
80101c6d:	e8 16 f8 ff ff       	call   80101488 <balloc>
80101c72:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c75:	8b 45 08             	mov    0x8(%ebp),%eax
80101c78:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c7b:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80101c7e:	8b 45 08             	mov    0x8(%ebp),%eax
80101c81:	8b 00                	mov    (%eax),%eax
80101c83:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c86:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c8a:	89 04 24             	mov    %eax,(%esp)
80101c8d:	e8 14 e5 ff ff       	call   801001a6 <bread>
80101c92:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101c95:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c98:	83 c0 18             	add    $0x18,%eax
80101c9b:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101c9e:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ca1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101ca8:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101cab:	01 d0                	add    %edx,%eax
80101cad:	8b 00                	mov    (%eax),%eax
80101caf:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101cb2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101cb6:	75 30                	jne    80101ce8 <bmap+0xeb>
      a[bn] = addr = balloc(ip->dev);
80101cb8:	8b 45 0c             	mov    0xc(%ebp),%eax
80101cbb:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101cc2:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101cc5:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80101cc8:	8b 45 08             	mov    0x8(%ebp),%eax
80101ccb:	8b 00                	mov    (%eax),%eax
80101ccd:	89 04 24             	mov    %eax,(%esp)
80101cd0:	e8 b3 f7 ff ff       	call   80101488 <balloc>
80101cd5:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101cd8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101cdb:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101cdd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ce0:	89 04 24             	mov    %eax,(%esp)
80101ce3:	e8 4e 1b 00 00       	call   80103836 <log_write>
    }
    brelse(bp);
80101ce8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ceb:	89 04 24             	mov    %eax,(%esp)
80101cee:	e8 24 e5 ff ff       	call   80100217 <brelse>
    return addr;
80101cf3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101cf6:	eb 0c                	jmp    80101d04 <bmap+0x107>
  }

  panic("bmap: out of range");
80101cf8:	c7 04 24 c2 95 10 80 	movl   $0x801095c2,(%esp)
80101cff:	e8 36 e8 ff ff       	call   8010053a <panic>
}
80101d04:	83 c4 24             	add    $0x24,%esp
80101d07:	5b                   	pop    %ebx
80101d08:	5d                   	pop    %ebp
80101d09:	c3                   	ret    

80101d0a <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101d0a:	55                   	push   %ebp
80101d0b:	89 e5                	mov    %esp,%ebp
80101d0d:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101d10:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101d17:	eb 44                	jmp    80101d5d <itrunc+0x53>
    if(ip->addrs[i]){
80101d19:	8b 45 08             	mov    0x8(%ebp),%eax
80101d1c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d1f:	83 c2 04             	add    $0x4,%edx
80101d22:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101d26:	85 c0                	test   %eax,%eax
80101d28:	74 2f                	je     80101d59 <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101d2a:	8b 45 08             	mov    0x8(%ebp),%eax
80101d2d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d30:	83 c2 04             	add    $0x4,%edx
80101d33:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101d37:	8b 45 08             	mov    0x8(%ebp),%eax
80101d3a:	8b 00                	mov    (%eax),%eax
80101d3c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d40:	89 04 24             	mov    %eax,(%esp)
80101d43:	e8 8e f8 ff ff       	call   801015d6 <bfree>
      ip->addrs[i] = 0;
80101d48:	8b 45 08             	mov    0x8(%ebp),%eax
80101d4b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d4e:	83 c2 04             	add    $0x4,%edx
80101d51:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101d58:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101d59:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101d5d:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101d61:	7e b6                	jle    80101d19 <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80101d63:	8b 45 08             	mov    0x8(%ebp),%eax
80101d66:	8b 40 4c             	mov    0x4c(%eax),%eax
80101d69:	85 c0                	test   %eax,%eax
80101d6b:	0f 84 9b 00 00 00    	je     80101e0c <itrunc+0x102>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101d71:	8b 45 08             	mov    0x8(%ebp),%eax
80101d74:	8b 50 4c             	mov    0x4c(%eax),%edx
80101d77:	8b 45 08             	mov    0x8(%ebp),%eax
80101d7a:	8b 00                	mov    (%eax),%eax
80101d7c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d80:	89 04 24             	mov    %eax,(%esp)
80101d83:	e8 1e e4 ff ff       	call   801001a6 <bread>
80101d88:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101d8b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d8e:	83 c0 18             	add    $0x18,%eax
80101d91:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101d94:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101d9b:	eb 3b                	jmp    80101dd8 <itrunc+0xce>
      if(a[j])
80101d9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101da0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101da7:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101daa:	01 d0                	add    %edx,%eax
80101dac:	8b 00                	mov    (%eax),%eax
80101dae:	85 c0                	test   %eax,%eax
80101db0:	74 22                	je     80101dd4 <itrunc+0xca>
        bfree(ip->dev, a[j]);
80101db2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101db5:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101dbc:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101dbf:	01 d0                	add    %edx,%eax
80101dc1:	8b 10                	mov    (%eax),%edx
80101dc3:	8b 45 08             	mov    0x8(%ebp),%eax
80101dc6:	8b 00                	mov    (%eax),%eax
80101dc8:	89 54 24 04          	mov    %edx,0x4(%esp)
80101dcc:	89 04 24             	mov    %eax,(%esp)
80101dcf:	e8 02 f8 ff ff       	call   801015d6 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101dd4:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101dd8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ddb:	83 f8 7f             	cmp    $0x7f,%eax
80101dde:	76 bd                	jbe    80101d9d <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101de0:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101de3:	89 04 24             	mov    %eax,(%esp)
80101de6:	e8 2c e4 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101deb:	8b 45 08             	mov    0x8(%ebp),%eax
80101dee:	8b 50 4c             	mov    0x4c(%eax),%edx
80101df1:	8b 45 08             	mov    0x8(%ebp),%eax
80101df4:	8b 00                	mov    (%eax),%eax
80101df6:	89 54 24 04          	mov    %edx,0x4(%esp)
80101dfa:	89 04 24             	mov    %eax,(%esp)
80101dfd:	e8 d4 f7 ff ff       	call   801015d6 <bfree>
    ip->addrs[NDIRECT] = 0;
80101e02:	8b 45 08             	mov    0x8(%ebp),%eax
80101e05:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80101e0c:	8b 45 08             	mov    0x8(%ebp),%eax
80101e0f:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80101e16:	8b 45 08             	mov    0x8(%ebp),%eax
80101e19:	89 04 24             	mov    %eax,(%esp)
80101e1c:	e8 7e f9 ff ff       	call   8010179f <iupdate>
}
80101e21:	c9                   	leave  
80101e22:	c3                   	ret    

80101e23 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80101e23:	55                   	push   %ebp
80101e24:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101e26:	8b 45 08             	mov    0x8(%ebp),%eax
80101e29:	8b 00                	mov    (%eax),%eax
80101e2b:	89 c2                	mov    %eax,%edx
80101e2d:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e30:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101e33:	8b 45 08             	mov    0x8(%ebp),%eax
80101e36:	8b 50 04             	mov    0x4(%eax),%edx
80101e39:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e3c:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101e3f:	8b 45 08             	mov    0x8(%ebp),%eax
80101e42:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101e46:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e49:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101e4c:	8b 45 08             	mov    0x8(%ebp),%eax
80101e4f:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101e53:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e56:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101e5a:	8b 45 08             	mov    0x8(%ebp),%eax
80101e5d:	8b 50 18             	mov    0x18(%eax),%edx
80101e60:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e63:	89 50 10             	mov    %edx,0x10(%eax)
}
80101e66:	5d                   	pop    %ebp
80101e67:	c3                   	ret    

80101e68 <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101e68:	55                   	push   %ebp
80101e69:	89 e5                	mov    %esp,%ebp
80101e6b:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101e6e:	8b 45 08             	mov    0x8(%ebp),%eax
80101e71:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101e75:	66 83 f8 03          	cmp    $0x3,%ax
80101e79:	75 6d                	jne    80101ee8 <readi+0x80>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101e7b:	8b 45 08             	mov    0x8(%ebp),%eax
80101e7e:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101e82:	66 85 c0             	test   %ax,%ax
80101e85:	78 23                	js     80101eaa <readi+0x42>
80101e87:	8b 45 08             	mov    0x8(%ebp),%eax
80101e8a:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101e8e:	66 83 f8 09          	cmp    $0x9,%ax
80101e92:	7f 16                	jg     80101eaa <readi+0x42>
80101e94:	8b 45 08             	mov    0x8(%ebp),%eax
80101e97:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101e9b:	98                   	cwtl   
80101e9c:	c1 e0 04             	shl    $0x4,%eax
80101e9f:	05 e8 21 11 80       	add    $0x801121e8,%eax
80101ea4:	8b 00                	mov    (%eax),%eax
80101ea6:	85 c0                	test   %eax,%eax
80101ea8:	75 0a                	jne    80101eb4 <readi+0x4c>
      return -1;
80101eaa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101eaf:	e9 23 01 00 00       	jmp    80101fd7 <readi+0x16f>
    return devsw[ip->major].read(ip, dst, off, n);
80101eb4:	8b 45 08             	mov    0x8(%ebp),%eax
80101eb7:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101ebb:	98                   	cwtl   
80101ebc:	c1 e0 04             	shl    $0x4,%eax
80101ebf:	05 e8 21 11 80       	add    $0x801121e8,%eax
80101ec4:	8b 00                	mov    (%eax),%eax
80101ec6:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101ec9:	8b 55 10             	mov    0x10(%ebp),%edx
80101ecc:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101ed0:	89 54 24 08          	mov    %edx,0x8(%esp)
80101ed4:	8b 55 0c             	mov    0xc(%ebp),%edx
80101ed7:	89 54 24 04          	mov    %edx,0x4(%esp)
80101edb:	8b 55 08             	mov    0x8(%ebp),%edx
80101ede:	89 14 24             	mov    %edx,(%esp)
80101ee1:	ff d0                	call   *%eax
80101ee3:	e9 ef 00 00 00       	jmp    80101fd7 <readi+0x16f>
  }

  if(off > ip->size || off + n < off)
80101ee8:	8b 45 08             	mov    0x8(%ebp),%eax
80101eeb:	8b 40 18             	mov    0x18(%eax),%eax
80101eee:	3b 45 10             	cmp    0x10(%ebp),%eax
80101ef1:	72 0d                	jb     80101f00 <readi+0x98>
80101ef3:	8b 45 14             	mov    0x14(%ebp),%eax
80101ef6:	8b 55 10             	mov    0x10(%ebp),%edx
80101ef9:	01 d0                	add    %edx,%eax
80101efb:	3b 45 10             	cmp    0x10(%ebp),%eax
80101efe:	73 0a                	jae    80101f0a <readi+0xa2>
    return -1;
80101f00:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f05:	e9 cd 00 00 00       	jmp    80101fd7 <readi+0x16f>
  if(off + n > ip->size)
80101f0a:	8b 45 14             	mov    0x14(%ebp),%eax
80101f0d:	8b 55 10             	mov    0x10(%ebp),%edx
80101f10:	01 c2                	add    %eax,%edx
80101f12:	8b 45 08             	mov    0x8(%ebp),%eax
80101f15:	8b 40 18             	mov    0x18(%eax),%eax
80101f18:	39 c2                	cmp    %eax,%edx
80101f1a:	76 0c                	jbe    80101f28 <readi+0xc0>
    n = ip->size - off;
80101f1c:	8b 45 08             	mov    0x8(%ebp),%eax
80101f1f:	8b 40 18             	mov    0x18(%eax),%eax
80101f22:	2b 45 10             	sub    0x10(%ebp),%eax
80101f25:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101f28:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101f2f:	e9 94 00 00 00       	jmp    80101fc8 <readi+0x160>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101f34:	8b 45 10             	mov    0x10(%ebp),%eax
80101f37:	c1 e8 09             	shr    $0x9,%eax
80101f3a:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f3e:	8b 45 08             	mov    0x8(%ebp),%eax
80101f41:	89 04 24             	mov    %eax,(%esp)
80101f44:	e8 b4 fc ff ff       	call   80101bfd <bmap>
80101f49:	8b 55 08             	mov    0x8(%ebp),%edx
80101f4c:	8b 12                	mov    (%edx),%edx
80101f4e:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f52:	89 14 24             	mov    %edx,(%esp)
80101f55:	e8 4c e2 ff ff       	call   801001a6 <bread>
80101f5a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101f5d:	8b 45 10             	mov    0x10(%ebp),%eax
80101f60:	25 ff 01 00 00       	and    $0x1ff,%eax
80101f65:	89 c2                	mov    %eax,%edx
80101f67:	b8 00 02 00 00       	mov    $0x200,%eax
80101f6c:	29 d0                	sub    %edx,%eax
80101f6e:	89 c2                	mov    %eax,%edx
80101f70:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101f73:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101f76:	29 c1                	sub    %eax,%ecx
80101f78:	89 c8                	mov    %ecx,%eax
80101f7a:	39 c2                	cmp    %eax,%edx
80101f7c:	0f 46 c2             	cmovbe %edx,%eax
80101f7f:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80101f82:	8b 45 10             	mov    0x10(%ebp),%eax
80101f85:	25 ff 01 00 00       	and    $0x1ff,%eax
80101f8a:	8d 50 10             	lea    0x10(%eax),%edx
80101f8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f90:	01 d0                	add    %edx,%eax
80101f92:	8d 50 08             	lea    0x8(%eax),%edx
80101f95:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f98:	89 44 24 08          	mov    %eax,0x8(%esp)
80101f9c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101fa0:	8b 45 0c             	mov    0xc(%ebp),%eax
80101fa3:	89 04 24             	mov    %eax,(%esp)
80101fa6:	e8 fb 41 00 00       	call   801061a6 <memmove>
    brelse(bp);
80101fab:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fae:	89 04 24             	mov    %eax,(%esp)
80101fb1:	e8 61 e2 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101fb6:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fb9:	01 45 f4             	add    %eax,-0xc(%ebp)
80101fbc:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fbf:	01 45 10             	add    %eax,0x10(%ebp)
80101fc2:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fc5:	01 45 0c             	add    %eax,0xc(%ebp)
80101fc8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101fcb:	3b 45 14             	cmp    0x14(%ebp),%eax
80101fce:	0f 82 60 ff ff ff    	jb     80101f34 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80101fd4:	8b 45 14             	mov    0x14(%ebp),%eax
}
80101fd7:	c9                   	leave  
80101fd8:	c3                   	ret    

80101fd9 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80101fd9:	55                   	push   %ebp
80101fda:	89 e5                	mov    %esp,%ebp
80101fdc:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101fdf:	8b 45 08             	mov    0x8(%ebp),%eax
80101fe2:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101fe6:	66 83 f8 03          	cmp    $0x3,%ax
80101fea:	75 66                	jne    80102052 <writei+0x79>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80101fec:	8b 45 08             	mov    0x8(%ebp),%eax
80101fef:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101ff3:	66 85 c0             	test   %ax,%ax
80101ff6:	78 23                	js     8010201b <writei+0x42>
80101ff8:	8b 45 08             	mov    0x8(%ebp),%eax
80101ffb:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101fff:	66 83 f8 09          	cmp    $0x9,%ax
80102003:	7f 16                	jg     8010201b <writei+0x42>
80102005:	8b 45 08             	mov    0x8(%ebp),%eax
80102008:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010200c:	98                   	cwtl   
8010200d:	c1 e0 04             	shl    $0x4,%eax
80102010:	05 ec 21 11 80       	add    $0x801121ec,%eax
80102015:	8b 00                	mov    (%eax),%eax
80102017:	85 c0                	test   %eax,%eax
80102019:	75 0a                	jne    80102025 <writei+0x4c>
      return -1;
8010201b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102020:	e9 47 01 00 00       	jmp    8010216c <writei+0x193>
    return devsw[ip->major].write(ip, src, n);
80102025:	8b 45 08             	mov    0x8(%ebp),%eax
80102028:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010202c:	98                   	cwtl   
8010202d:	c1 e0 04             	shl    $0x4,%eax
80102030:	05 ec 21 11 80       	add    $0x801121ec,%eax
80102035:	8b 00                	mov    (%eax),%eax
80102037:	8b 55 14             	mov    0x14(%ebp),%edx
8010203a:	89 54 24 08          	mov    %edx,0x8(%esp)
8010203e:	8b 55 0c             	mov    0xc(%ebp),%edx
80102041:	89 54 24 04          	mov    %edx,0x4(%esp)
80102045:	8b 55 08             	mov    0x8(%ebp),%edx
80102048:	89 14 24             	mov    %edx,(%esp)
8010204b:	ff d0                	call   *%eax
8010204d:	e9 1a 01 00 00       	jmp    8010216c <writei+0x193>
  }

  if(off > ip->size || off + n < off)
80102052:	8b 45 08             	mov    0x8(%ebp),%eax
80102055:	8b 40 18             	mov    0x18(%eax),%eax
80102058:	3b 45 10             	cmp    0x10(%ebp),%eax
8010205b:	72 0d                	jb     8010206a <writei+0x91>
8010205d:	8b 45 14             	mov    0x14(%ebp),%eax
80102060:	8b 55 10             	mov    0x10(%ebp),%edx
80102063:	01 d0                	add    %edx,%eax
80102065:	3b 45 10             	cmp    0x10(%ebp),%eax
80102068:	73 0a                	jae    80102074 <writei+0x9b>
    return -1;
8010206a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010206f:	e9 f8 00 00 00       	jmp    8010216c <writei+0x193>
  if(off + n > MAXFILE*BSIZE)
80102074:	8b 45 14             	mov    0x14(%ebp),%eax
80102077:	8b 55 10             	mov    0x10(%ebp),%edx
8010207a:	01 d0                	add    %edx,%eax
8010207c:	3d 00 18 01 00       	cmp    $0x11800,%eax
80102081:	76 0a                	jbe    8010208d <writei+0xb4>
    return -1;
80102083:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102088:	e9 df 00 00 00       	jmp    8010216c <writei+0x193>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010208d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102094:	e9 9f 00 00 00       	jmp    80102138 <writei+0x15f>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80102099:	8b 45 10             	mov    0x10(%ebp),%eax
8010209c:	c1 e8 09             	shr    $0x9,%eax
8010209f:	89 44 24 04          	mov    %eax,0x4(%esp)
801020a3:	8b 45 08             	mov    0x8(%ebp),%eax
801020a6:	89 04 24             	mov    %eax,(%esp)
801020a9:	e8 4f fb ff ff       	call   80101bfd <bmap>
801020ae:	8b 55 08             	mov    0x8(%ebp),%edx
801020b1:	8b 12                	mov    (%edx),%edx
801020b3:	89 44 24 04          	mov    %eax,0x4(%esp)
801020b7:	89 14 24             	mov    %edx,(%esp)
801020ba:	e8 e7 e0 ff ff       	call   801001a6 <bread>
801020bf:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
801020c2:	8b 45 10             	mov    0x10(%ebp),%eax
801020c5:	25 ff 01 00 00       	and    $0x1ff,%eax
801020ca:	89 c2                	mov    %eax,%edx
801020cc:	b8 00 02 00 00       	mov    $0x200,%eax
801020d1:	29 d0                	sub    %edx,%eax
801020d3:	89 c2                	mov    %eax,%edx
801020d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801020d8:	8b 4d 14             	mov    0x14(%ebp),%ecx
801020db:	29 c1                	sub    %eax,%ecx
801020dd:	89 c8                	mov    %ecx,%eax
801020df:	39 c2                	cmp    %eax,%edx
801020e1:	0f 46 c2             	cmovbe %edx,%eax
801020e4:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
801020e7:	8b 45 10             	mov    0x10(%ebp),%eax
801020ea:	25 ff 01 00 00       	and    $0x1ff,%eax
801020ef:	8d 50 10             	lea    0x10(%eax),%edx
801020f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020f5:	01 d0                	add    %edx,%eax
801020f7:	8d 50 08             	lea    0x8(%eax),%edx
801020fa:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020fd:	89 44 24 08          	mov    %eax,0x8(%esp)
80102101:	8b 45 0c             	mov    0xc(%ebp),%eax
80102104:	89 44 24 04          	mov    %eax,0x4(%esp)
80102108:	89 14 24             	mov    %edx,(%esp)
8010210b:	e8 96 40 00 00       	call   801061a6 <memmove>
    log_write(bp);
80102110:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102113:	89 04 24             	mov    %eax,(%esp)
80102116:	e8 1b 17 00 00       	call   80103836 <log_write>
    brelse(bp);
8010211b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010211e:	89 04 24             	mov    %eax,(%esp)
80102121:	e8 f1 e0 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102126:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102129:	01 45 f4             	add    %eax,-0xc(%ebp)
8010212c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010212f:	01 45 10             	add    %eax,0x10(%ebp)
80102132:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102135:	01 45 0c             	add    %eax,0xc(%ebp)
80102138:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010213b:	3b 45 14             	cmp    0x14(%ebp),%eax
8010213e:	0f 82 55 ff ff ff    	jb     80102099 <writei+0xc0>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
80102144:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80102148:	74 1f                	je     80102169 <writei+0x190>
8010214a:	8b 45 08             	mov    0x8(%ebp),%eax
8010214d:	8b 40 18             	mov    0x18(%eax),%eax
80102150:	3b 45 10             	cmp    0x10(%ebp),%eax
80102153:	73 14                	jae    80102169 <writei+0x190>
    ip->size = off;
80102155:	8b 45 08             	mov    0x8(%ebp),%eax
80102158:	8b 55 10             	mov    0x10(%ebp),%edx
8010215b:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
8010215e:	8b 45 08             	mov    0x8(%ebp),%eax
80102161:	89 04 24             	mov    %eax,(%esp)
80102164:	e8 36 f6 ff ff       	call   8010179f <iupdate>
  }
  return n;
80102169:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010216c:	c9                   	leave  
8010216d:	c3                   	ret    

8010216e <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
8010216e:	55                   	push   %ebp
8010216f:	89 e5                	mov    %esp,%ebp
80102171:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
80102174:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
8010217b:	00 
8010217c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010217f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102183:	8b 45 08             	mov    0x8(%ebp),%eax
80102186:	89 04 24             	mov    %eax,(%esp)
80102189:	e8 bb 40 00 00       	call   80106249 <strncmp>
}
8010218e:	c9                   	leave  
8010218f:	c3                   	ret    

80102190 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
80102190:	55                   	push   %ebp
80102191:	89 e5                	mov    %esp,%ebp
80102193:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;
  struct inode *ip;

  if(dp->type != T_DIR && !IS_DEV_DIR(dp))
80102196:	8b 45 08             	mov    0x8(%ebp),%eax
80102199:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010219d:	66 83 f8 01          	cmp    $0x1,%ax
801021a1:	74 4d                	je     801021f0 <dirlookup+0x60>
801021a3:	8b 45 08             	mov    0x8(%ebp),%eax
801021a6:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801021aa:	66 83 f8 03          	cmp    $0x3,%ax
801021ae:	75 34                	jne    801021e4 <dirlookup+0x54>
801021b0:	8b 45 08             	mov    0x8(%ebp),%eax
801021b3:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801021b7:	98                   	cwtl   
801021b8:	c1 e0 04             	shl    $0x4,%eax
801021bb:	05 e0 21 11 80       	add    $0x801121e0,%eax
801021c0:	8b 00                	mov    (%eax),%eax
801021c2:	85 c0                	test   %eax,%eax
801021c4:	74 1e                	je     801021e4 <dirlookup+0x54>
801021c6:	8b 45 08             	mov    0x8(%ebp),%eax
801021c9:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801021cd:	98                   	cwtl   
801021ce:	c1 e0 04             	shl    $0x4,%eax
801021d1:	05 e0 21 11 80       	add    $0x801121e0,%eax
801021d6:	8b 00                	mov    (%eax),%eax
801021d8:	8b 55 08             	mov    0x8(%ebp),%edx
801021db:	89 14 24             	mov    %edx,(%esp)
801021de:	ff d0                	call   *%eax
801021e0:	85 c0                	test   %eax,%eax
801021e2:	75 0c                	jne    801021f0 <dirlookup+0x60>
    panic("dirlookup not DIR");
801021e4:	c7 04 24 d5 95 10 80 	movl   $0x801095d5,(%esp)
801021eb:	e8 4a e3 ff ff       	call   8010053a <panic>

  for(off = 0; off < dp->size || dp->type == T_DEV; off += sizeof(de)){
801021f0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801021f7:	e9 fd 00 00 00       	jmp    801022f9 <dirlookup+0x169>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de)) {
801021fc:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102203:	00 
80102204:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102207:	89 44 24 08          	mov    %eax,0x8(%esp)
8010220b:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010220e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102212:	8b 45 08             	mov    0x8(%ebp),%eax
80102215:	89 04 24             	mov    %eax,(%esp)
80102218:	e8 4b fc ff ff       	call   80101e68 <readi>
8010221d:	83 f8 10             	cmp    $0x10,%eax
80102220:	74 23                	je     80102245 <dirlookup+0xb5>
      if (dp->type == T_DEV)
80102222:	8b 45 08             	mov    0x8(%ebp),%eax
80102225:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102229:	66 83 f8 03          	cmp    $0x3,%ax
8010222d:	75 0a                	jne    80102239 <dirlookup+0xa9>
        return 0;
8010222f:	b8 00 00 00 00       	mov    $0x0,%eax
80102234:	e9 e5 00 00 00       	jmp    8010231e <dirlookup+0x18e>
      else
        panic("dirlink read");
80102239:	c7 04 24 e7 95 10 80 	movl   $0x801095e7,(%esp)
80102240:	e8 f5 e2 ff ff       	call   8010053a <panic>
    }
    if(de.inum == 0)
80102245:	0f b7 45 dc          	movzwl -0x24(%ebp),%eax
80102249:	66 85 c0             	test   %ax,%ax
8010224c:	75 05                	jne    80102253 <dirlookup+0xc3>
      continue;
8010224e:	e9 a2 00 00 00       	jmp    801022f5 <dirlookup+0x165>
    if(namecmp(name, de.name) == 0){
80102253:	8d 45 dc             	lea    -0x24(%ebp),%eax
80102256:	83 c0 02             	add    $0x2,%eax
80102259:	89 44 24 04          	mov    %eax,0x4(%esp)
8010225d:	8b 45 0c             	mov    0xc(%ebp),%eax
80102260:	89 04 24             	mov    %eax,(%esp)
80102263:	e8 06 ff ff ff       	call   8010216e <namecmp>
80102268:	85 c0                	test   %eax,%eax
8010226a:	0f 85 85 00 00 00    	jne    801022f5 <dirlookup+0x165>
      // entry matches path element
      if(poff)
80102270:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80102274:	74 08                	je     8010227e <dirlookup+0xee>
        *poff = off;
80102276:	8b 45 10             	mov    0x10(%ebp),%eax
80102279:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010227c:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
8010227e:	0f b7 45 dc          	movzwl -0x24(%ebp),%eax
80102282:	0f b7 c0             	movzwl %ax,%eax
80102285:	89 45 f0             	mov    %eax,-0x10(%ebp)
      ip = iget(dp->dev, inum);
80102288:	8b 45 08             	mov    0x8(%ebp),%eax
8010228b:	8b 00                	mov    (%eax),%eax
8010228d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102290:	89 54 24 04          	mov    %edx,0x4(%esp)
80102294:	89 04 24             	mov    %eax,(%esp)
80102297:	e8 bb f5 ff ff       	call   80101857 <iget>
8010229c:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if (!(ip->flags & I_VALID) && dp->type == T_DEV && devsw[dp->major].iread) {
8010229f:	8b 45 ec             	mov    -0x14(%ebp),%eax
801022a2:	8b 40 0c             	mov    0xc(%eax),%eax
801022a5:	83 e0 02             	and    $0x2,%eax
801022a8:	85 c0                	test   %eax,%eax
801022aa:	75 44                	jne    801022f0 <dirlookup+0x160>
801022ac:	8b 45 08             	mov    0x8(%ebp),%eax
801022af:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801022b3:	66 83 f8 03          	cmp    $0x3,%ax
801022b7:	75 37                	jne    801022f0 <dirlookup+0x160>
801022b9:	8b 45 08             	mov    0x8(%ebp),%eax
801022bc:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801022c0:	98                   	cwtl   
801022c1:	c1 e0 04             	shl    $0x4,%eax
801022c4:	05 e4 21 11 80       	add    $0x801121e4,%eax
801022c9:	8b 00                	mov    (%eax),%eax
801022cb:	85 c0                	test   %eax,%eax
801022cd:	74 21                	je     801022f0 <dirlookup+0x160>
        devsw[dp->major].iread(dp, ip);
801022cf:	8b 45 08             	mov    0x8(%ebp),%eax
801022d2:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801022d6:	98                   	cwtl   
801022d7:	c1 e0 04             	shl    $0x4,%eax
801022da:	05 e4 21 11 80       	add    $0x801121e4,%eax
801022df:	8b 00                	mov    (%eax),%eax
801022e1:	8b 55 ec             	mov    -0x14(%ebp),%edx
801022e4:	89 54 24 04          	mov    %edx,0x4(%esp)
801022e8:	8b 55 08             	mov    0x8(%ebp),%edx
801022eb:	89 14 24             	mov    %edx,(%esp)
801022ee:	ff d0                	call   *%eax
      }
      return ip;
801022f0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801022f3:	eb 29                	jmp    8010231e <dirlookup+0x18e>
  struct inode *ip;

  if(dp->type != T_DIR && !IS_DEV_DIR(dp))
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size || dp->type == T_DEV; off += sizeof(de)){
801022f5:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801022f9:	8b 45 08             	mov    0x8(%ebp),%eax
801022fc:	8b 40 18             	mov    0x18(%eax),%eax
801022ff:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80102302:	0f 87 f4 fe ff ff    	ja     801021fc <dirlookup+0x6c>
80102308:	8b 45 08             	mov    0x8(%ebp),%eax
8010230b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010230f:	66 83 f8 03          	cmp    $0x3,%ax
80102313:	0f 84 e3 fe ff ff    	je     801021fc <dirlookup+0x6c>
      }
      return ip;
    }
  }

  return 0;
80102319:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010231e:	c9                   	leave  
8010231f:	c3                   	ret    

80102320 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
80102320:	55                   	push   %ebp
80102321:	89 e5                	mov    %esp,%ebp
80102323:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
80102326:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010232d:	00 
8010232e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102331:	89 44 24 04          	mov    %eax,0x4(%esp)
80102335:	8b 45 08             	mov    0x8(%ebp),%eax
80102338:	89 04 24             	mov    %eax,(%esp)
8010233b:	e8 50 fe ff ff       	call   80102190 <dirlookup>
80102340:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102343:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102347:	74 15                	je     8010235e <dirlink+0x3e>
    iput(ip);
80102349:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010234c:	89 04 24             	mov    %eax,(%esp)
8010234f:	e8 ba f7 ff ff       	call   80101b0e <iput>
    return -1;
80102354:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102359:	e9 b7 00 00 00       	jmp    80102415 <dirlink+0xf5>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
8010235e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102365:	eb 46                	jmp    801023ad <dirlink+0x8d>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102367:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010236a:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102371:	00 
80102372:	89 44 24 08          	mov    %eax,0x8(%esp)
80102376:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102379:	89 44 24 04          	mov    %eax,0x4(%esp)
8010237d:	8b 45 08             	mov    0x8(%ebp),%eax
80102380:	89 04 24             	mov    %eax,(%esp)
80102383:	e8 e0 fa ff ff       	call   80101e68 <readi>
80102388:	83 f8 10             	cmp    $0x10,%eax
8010238b:	74 0c                	je     80102399 <dirlink+0x79>
      panic("dirlink read");
8010238d:	c7 04 24 e7 95 10 80 	movl   $0x801095e7,(%esp)
80102394:	e8 a1 e1 ff ff       	call   8010053a <panic>
    if(de.inum == 0)
80102399:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010239d:	66 85 c0             	test   %ax,%ax
801023a0:	75 02                	jne    801023a4 <dirlink+0x84>
      break;
801023a2:	eb 16                	jmp    801023ba <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801023a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023a7:	83 c0 10             	add    $0x10,%eax
801023aa:	89 45 f4             	mov    %eax,-0xc(%ebp)
801023ad:	8b 55 f4             	mov    -0xc(%ebp),%edx
801023b0:	8b 45 08             	mov    0x8(%ebp),%eax
801023b3:	8b 40 18             	mov    0x18(%eax),%eax
801023b6:	39 c2                	cmp    %eax,%edx
801023b8:	72 ad                	jb     80102367 <dirlink+0x47>
      panic("dirlink read");
    if(de.inum == 0)
      break;
  }

  strncpy(de.name, name, DIRSIZ);
801023ba:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801023c1:	00 
801023c2:	8b 45 0c             	mov    0xc(%ebp),%eax
801023c5:	89 44 24 04          	mov    %eax,0x4(%esp)
801023c9:	8d 45 e0             	lea    -0x20(%ebp),%eax
801023cc:	83 c0 02             	add    $0x2,%eax
801023cf:	89 04 24             	mov    %eax,(%esp)
801023d2:	e8 c8 3e 00 00       	call   8010629f <strncpy>
  de.inum = inum;
801023d7:	8b 45 10             	mov    0x10(%ebp),%eax
801023da:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801023de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023e1:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801023e8:	00 
801023e9:	89 44 24 08          	mov    %eax,0x8(%esp)
801023ed:	8d 45 e0             	lea    -0x20(%ebp),%eax
801023f0:	89 44 24 04          	mov    %eax,0x4(%esp)
801023f4:	8b 45 08             	mov    0x8(%ebp),%eax
801023f7:	89 04 24             	mov    %eax,(%esp)
801023fa:	e8 da fb ff ff       	call   80101fd9 <writei>
801023ff:	83 f8 10             	cmp    $0x10,%eax
80102402:	74 0c                	je     80102410 <dirlink+0xf0>
    panic("dirlink");
80102404:	c7 04 24 f4 95 10 80 	movl   $0x801095f4,(%esp)
8010240b:	e8 2a e1 ff ff       	call   8010053a <panic>
  
  return 0;
80102410:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102415:	c9                   	leave  
80102416:	c3                   	ret    

80102417 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80102417:	55                   	push   %ebp
80102418:	89 e5                	mov    %esp,%ebp
8010241a:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
8010241d:	eb 04                	jmp    80102423 <skipelem+0xc>
    path++;
8010241f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
80102423:	8b 45 08             	mov    0x8(%ebp),%eax
80102426:	0f b6 00             	movzbl (%eax),%eax
80102429:	3c 2f                	cmp    $0x2f,%al
8010242b:	74 f2                	je     8010241f <skipelem+0x8>
    path++;
  if(*path == 0)
8010242d:	8b 45 08             	mov    0x8(%ebp),%eax
80102430:	0f b6 00             	movzbl (%eax),%eax
80102433:	84 c0                	test   %al,%al
80102435:	75 0a                	jne    80102441 <skipelem+0x2a>
    return 0;
80102437:	b8 00 00 00 00       	mov    $0x0,%eax
8010243c:	e9 86 00 00 00       	jmp    801024c7 <skipelem+0xb0>
  s = path;
80102441:	8b 45 08             	mov    0x8(%ebp),%eax
80102444:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
80102447:	eb 04                	jmp    8010244d <skipelem+0x36>
    path++;
80102449:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
8010244d:	8b 45 08             	mov    0x8(%ebp),%eax
80102450:	0f b6 00             	movzbl (%eax),%eax
80102453:	3c 2f                	cmp    $0x2f,%al
80102455:	74 0a                	je     80102461 <skipelem+0x4a>
80102457:	8b 45 08             	mov    0x8(%ebp),%eax
8010245a:	0f b6 00             	movzbl (%eax),%eax
8010245d:	84 c0                	test   %al,%al
8010245f:	75 e8                	jne    80102449 <skipelem+0x32>
    path++;
  len = path - s;
80102461:	8b 55 08             	mov    0x8(%ebp),%edx
80102464:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102467:	29 c2                	sub    %eax,%edx
80102469:	89 d0                	mov    %edx,%eax
8010246b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
8010246e:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
80102472:	7e 1c                	jle    80102490 <skipelem+0x79>
    memmove(name, s, DIRSIZ);
80102474:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
8010247b:	00 
8010247c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010247f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102483:	8b 45 0c             	mov    0xc(%ebp),%eax
80102486:	89 04 24             	mov    %eax,(%esp)
80102489:	e8 18 3d 00 00       	call   801061a6 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
8010248e:	eb 2a                	jmp    801024ba <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
80102490:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102493:	89 44 24 08          	mov    %eax,0x8(%esp)
80102497:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010249a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010249e:	8b 45 0c             	mov    0xc(%ebp),%eax
801024a1:	89 04 24             	mov    %eax,(%esp)
801024a4:	e8 fd 3c 00 00       	call   801061a6 <memmove>
    name[len] = 0;
801024a9:	8b 55 f0             	mov    -0x10(%ebp),%edx
801024ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801024af:	01 d0                	add    %edx,%eax
801024b1:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
801024b4:	eb 04                	jmp    801024ba <skipelem+0xa3>
    path++;
801024b6:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801024ba:	8b 45 08             	mov    0x8(%ebp),%eax
801024bd:	0f b6 00             	movzbl (%eax),%eax
801024c0:	3c 2f                	cmp    $0x2f,%al
801024c2:	74 f2                	je     801024b6 <skipelem+0x9f>
    path++;
  return path;
801024c4:	8b 45 08             	mov    0x8(%ebp),%eax
}
801024c7:	c9                   	leave  
801024c8:	c3                   	ret    

801024c9 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
801024c9:	55                   	push   %ebp
801024ca:	89 e5                	mov    %esp,%ebp
801024cc:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
801024cf:	8b 45 08             	mov    0x8(%ebp),%eax
801024d2:	0f b6 00             	movzbl (%eax),%eax
801024d5:	3c 2f                	cmp    $0x2f,%al
801024d7:	75 1c                	jne    801024f5 <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
801024d9:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801024e0:	00 
801024e1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801024e8:	e8 6a f3 ff ff       	call   80101857 <iget>
801024ed:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801024f0:	e9 f0 00 00 00       	jmp    801025e5 <namex+0x11c>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
801024f5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801024fb:	8b 40 78             	mov    0x78(%eax),%eax
801024fe:	89 04 24             	mov    %eax,(%esp)
80102501:	e8 23 f4 ff ff       	call   80101929 <idup>
80102506:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
80102509:	e9 d7 00 00 00       	jmp    801025e5 <namex+0x11c>
    ilock(ip);
8010250e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102511:	89 04 24             	mov    %eax,(%esp)
80102514:	e8 42 f4 ff ff       	call   8010195b <ilock>
    if(ip->type != T_DIR && !IS_DEV_DIR(ip)){
80102519:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010251c:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102520:	66 83 f8 01          	cmp    $0x1,%ax
80102524:	74 56                	je     8010257c <namex+0xb3>
80102526:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102529:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010252d:	66 83 f8 03          	cmp    $0x3,%ax
80102531:	75 34                	jne    80102567 <namex+0x9e>
80102533:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102536:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010253a:	98                   	cwtl   
8010253b:	c1 e0 04             	shl    $0x4,%eax
8010253e:	05 e0 21 11 80       	add    $0x801121e0,%eax
80102543:	8b 00                	mov    (%eax),%eax
80102545:	85 c0                	test   %eax,%eax
80102547:	74 1e                	je     80102567 <namex+0x9e>
80102549:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010254c:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102550:	98                   	cwtl   
80102551:	c1 e0 04             	shl    $0x4,%eax
80102554:	05 e0 21 11 80       	add    $0x801121e0,%eax
80102559:	8b 00                	mov    (%eax),%eax
8010255b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010255e:	89 14 24             	mov    %edx,(%esp)
80102561:	ff d0                	call   *%eax
80102563:	85 c0                	test   %eax,%eax
80102565:	75 15                	jne    8010257c <namex+0xb3>
      iunlockput(ip);
80102567:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010256a:	89 04 24             	mov    %eax,(%esp)
8010256d:	e8 6d f6 ff ff       	call   80101bdf <iunlockput>
      return 0;
80102572:	b8 00 00 00 00       	mov    $0x0,%eax
80102577:	e9 a3 00 00 00       	jmp    8010261f <namex+0x156>
    }
    if(nameiparent && *path == '\0'){
8010257c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102580:	74 1d                	je     8010259f <namex+0xd6>
80102582:	8b 45 08             	mov    0x8(%ebp),%eax
80102585:	0f b6 00             	movzbl (%eax),%eax
80102588:	84 c0                	test   %al,%al
8010258a:	75 13                	jne    8010259f <namex+0xd6>
      // Stop one level early.
      iunlock(ip);
8010258c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010258f:	89 04 24             	mov    %eax,(%esp)
80102592:	e8 12 f5 ff ff       	call   80101aa9 <iunlock>
      return ip;
80102597:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010259a:	e9 80 00 00 00       	jmp    8010261f <namex+0x156>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
8010259f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801025a6:	00 
801025a7:	8b 45 10             	mov    0x10(%ebp),%eax
801025aa:	89 44 24 04          	mov    %eax,0x4(%esp)
801025ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025b1:	89 04 24             	mov    %eax,(%esp)
801025b4:	e8 d7 fb ff ff       	call   80102190 <dirlookup>
801025b9:	89 45 f0             	mov    %eax,-0x10(%ebp)
801025bc:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801025c0:	75 12                	jne    801025d4 <namex+0x10b>
      iunlockput(ip);
801025c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025c5:	89 04 24             	mov    %eax,(%esp)
801025c8:	e8 12 f6 ff ff       	call   80101bdf <iunlockput>
      return 0;
801025cd:	b8 00 00 00 00       	mov    $0x0,%eax
801025d2:	eb 4b                	jmp    8010261f <namex+0x156>
    }
    iunlockput(ip);
801025d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025d7:	89 04 24             	mov    %eax,(%esp)
801025da:	e8 00 f6 ff ff       	call   80101bdf <iunlockput>
    ip = next;
801025df:	8b 45 f0             	mov    -0x10(%ebp),%eax
801025e2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801025e5:	8b 45 10             	mov    0x10(%ebp),%eax
801025e8:	89 44 24 04          	mov    %eax,0x4(%esp)
801025ec:	8b 45 08             	mov    0x8(%ebp),%eax
801025ef:	89 04 24             	mov    %eax,(%esp)
801025f2:	e8 20 fe ff ff       	call   80102417 <skipelem>
801025f7:	89 45 08             	mov    %eax,0x8(%ebp)
801025fa:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801025fe:	0f 85 0a ff ff ff    	jne    8010250e <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
80102604:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102608:	74 12                	je     8010261c <namex+0x153>
    iput(ip);
8010260a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010260d:	89 04 24             	mov    %eax,(%esp)
80102610:	e8 f9 f4 ff ff       	call   80101b0e <iput>
    return 0;
80102615:	b8 00 00 00 00       	mov    $0x0,%eax
8010261a:	eb 03                	jmp    8010261f <namex+0x156>
  }
  return ip;
8010261c:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010261f:	c9                   	leave  
80102620:	c3                   	ret    

80102621 <namei>:

struct inode*
namei(char *path)
{
80102621:	55                   	push   %ebp
80102622:	89 e5                	mov    %esp,%ebp
80102624:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80102627:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010262a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010262e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102635:	00 
80102636:	8b 45 08             	mov    0x8(%ebp),%eax
80102639:	89 04 24             	mov    %eax,(%esp)
8010263c:	e8 88 fe ff ff       	call   801024c9 <namex>
}
80102641:	c9                   	leave  
80102642:	c3                   	ret    

80102643 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80102643:	55                   	push   %ebp
80102644:	89 e5                	mov    %esp,%ebp
80102646:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
80102649:	8b 45 0c             	mov    0xc(%ebp),%eax
8010264c:	89 44 24 08          	mov    %eax,0x8(%esp)
80102650:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102657:	00 
80102658:	8b 45 08             	mov    0x8(%ebp),%eax
8010265b:	89 04 24             	mov    %eax,(%esp)
8010265e:	e8 66 fe ff ff       	call   801024c9 <namex>
}
80102663:	c9                   	leave  
80102664:	c3                   	ret    

80102665 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102665:	55                   	push   %ebp
80102666:	89 e5                	mov    %esp,%ebp
80102668:	83 ec 14             	sub    $0x14,%esp
8010266b:	8b 45 08             	mov    0x8(%ebp),%eax
8010266e:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102672:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102676:	89 c2                	mov    %eax,%edx
80102678:	ec                   	in     (%dx),%al
80102679:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
8010267c:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102680:	c9                   	leave  
80102681:	c3                   	ret    

80102682 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
80102682:	55                   	push   %ebp
80102683:	89 e5                	mov    %esp,%ebp
80102685:	57                   	push   %edi
80102686:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
80102687:	8b 55 08             	mov    0x8(%ebp),%edx
8010268a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010268d:	8b 45 10             	mov    0x10(%ebp),%eax
80102690:	89 cb                	mov    %ecx,%ebx
80102692:	89 df                	mov    %ebx,%edi
80102694:	89 c1                	mov    %eax,%ecx
80102696:	fc                   	cld    
80102697:	f3 6d                	rep insl (%dx),%es:(%edi)
80102699:	89 c8                	mov    %ecx,%eax
8010269b:	89 fb                	mov    %edi,%ebx
8010269d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801026a0:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
801026a3:	5b                   	pop    %ebx
801026a4:	5f                   	pop    %edi
801026a5:	5d                   	pop    %ebp
801026a6:	c3                   	ret    

801026a7 <outb>:

static inline void
outb(ushort port, uchar data)
{
801026a7:	55                   	push   %ebp
801026a8:	89 e5                	mov    %esp,%ebp
801026aa:	83 ec 08             	sub    $0x8,%esp
801026ad:	8b 55 08             	mov    0x8(%ebp),%edx
801026b0:	8b 45 0c             	mov    0xc(%ebp),%eax
801026b3:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801026b7:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801026ba:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801026be:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801026c2:	ee                   	out    %al,(%dx)
}
801026c3:	c9                   	leave  
801026c4:	c3                   	ret    

801026c5 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
801026c5:	55                   	push   %ebp
801026c6:	89 e5                	mov    %esp,%ebp
801026c8:	56                   	push   %esi
801026c9:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
801026ca:	8b 55 08             	mov    0x8(%ebp),%edx
801026cd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801026d0:	8b 45 10             	mov    0x10(%ebp),%eax
801026d3:	89 cb                	mov    %ecx,%ebx
801026d5:	89 de                	mov    %ebx,%esi
801026d7:	89 c1                	mov    %eax,%ecx
801026d9:	fc                   	cld    
801026da:	f3 6f                	rep outsl %ds:(%esi),(%dx)
801026dc:	89 c8                	mov    %ecx,%eax
801026de:	89 f3                	mov    %esi,%ebx
801026e0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801026e3:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
801026e6:	5b                   	pop    %ebx
801026e7:	5e                   	pop    %esi
801026e8:	5d                   	pop    %ebp
801026e9:	c3                   	ret    

801026ea <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
801026ea:	55                   	push   %ebp
801026eb:	89 e5                	mov    %esp,%ebp
801026ed:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
801026f0:	90                   	nop
801026f1:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801026f8:	e8 68 ff ff ff       	call   80102665 <inb>
801026fd:	0f b6 c0             	movzbl %al,%eax
80102700:	89 45 fc             	mov    %eax,-0x4(%ebp)
80102703:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102706:	25 c0 00 00 00       	and    $0xc0,%eax
8010270b:	83 f8 40             	cmp    $0x40,%eax
8010270e:	75 e1                	jne    801026f1 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102710:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102714:	74 11                	je     80102727 <idewait+0x3d>
80102716:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102719:	83 e0 21             	and    $0x21,%eax
8010271c:	85 c0                	test   %eax,%eax
8010271e:	74 07                	je     80102727 <idewait+0x3d>
    return -1;
80102720:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102725:	eb 05                	jmp    8010272c <idewait+0x42>
  return 0;
80102727:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010272c:	c9                   	leave  
8010272d:	c3                   	ret    

8010272e <ideinit>:

void
ideinit(void)
{
8010272e:	55                   	push   %ebp
8010272f:	89 e5                	mov    %esp,%ebp
80102731:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
80102734:	c7 44 24 04 fc 95 10 	movl   $0x801095fc,0x4(%esp)
8010273b:	80 
8010273c:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102743:	e8 1a 37 00 00       	call   80105e62 <initlock>
  picenable(IRQ_IDE);
80102748:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
8010274f:	e8 80 18 00 00       	call   80103fd4 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102754:	a1 80 39 11 80       	mov    0x80113980,%eax
80102759:	83 e8 01             	sub    $0x1,%eax
8010275c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102760:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102767:	e8 0c 04 00 00       	call   80102b78 <ioapicenable>
  idewait(0);
8010276c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102773:	e8 72 ff ff ff       	call   801026ea <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80102778:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
8010277f:	00 
80102780:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102787:	e8 1b ff ff ff       	call   801026a7 <outb>
  for(i=0; i<1000; i++){
8010278c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102793:	eb 20                	jmp    801027b5 <ideinit+0x87>
    if(inb(0x1f7) != 0){
80102795:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010279c:	e8 c4 fe ff ff       	call   80102665 <inb>
801027a1:	84 c0                	test   %al,%al
801027a3:	74 0c                	je     801027b1 <ideinit+0x83>
      havedisk1 = 1;
801027a5:	c7 05 38 c6 10 80 01 	movl   $0x1,0x8010c638
801027ac:	00 00 00 
      break;
801027af:	eb 0d                	jmp    801027be <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
801027b1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801027b5:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
801027bc:	7e d7                	jle    80102795 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
801027be:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
801027c5:	00 
801027c6:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801027cd:	e8 d5 fe ff ff       	call   801026a7 <outb>
}
801027d2:	c9                   	leave  
801027d3:	c3                   	ret    

801027d4 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
801027d4:	55                   	push   %ebp
801027d5:	89 e5                	mov    %esp,%ebp
801027d7:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
801027da:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801027de:	75 0c                	jne    801027ec <idestart+0x18>
    panic("idestart");
801027e0:	c7 04 24 00 96 10 80 	movl   $0x80109600,(%esp)
801027e7:	e8 4e dd ff ff       	call   8010053a <panic>

  idewait(0);
801027ec:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801027f3:	e8 f2 fe ff ff       	call   801026ea <idewait>
  outb(0x3f6, 0);  // generate interrupt
801027f8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801027ff:	00 
80102800:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
80102807:	e8 9b fe ff ff       	call   801026a7 <outb>
  outb(0x1f2, 1);  // number of sectors
8010280c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102813:	00 
80102814:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
8010281b:	e8 87 fe ff ff       	call   801026a7 <outb>
  outb(0x1f3, b->sector & 0xff);
80102820:	8b 45 08             	mov    0x8(%ebp),%eax
80102823:	8b 40 08             	mov    0x8(%eax),%eax
80102826:	0f b6 c0             	movzbl %al,%eax
80102829:	89 44 24 04          	mov    %eax,0x4(%esp)
8010282d:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80102834:	e8 6e fe ff ff       	call   801026a7 <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
80102839:	8b 45 08             	mov    0x8(%ebp),%eax
8010283c:	8b 40 08             	mov    0x8(%eax),%eax
8010283f:	c1 e8 08             	shr    $0x8,%eax
80102842:	0f b6 c0             	movzbl %al,%eax
80102845:	89 44 24 04          	mov    %eax,0x4(%esp)
80102849:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102850:	e8 52 fe ff ff       	call   801026a7 <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
80102855:	8b 45 08             	mov    0x8(%ebp),%eax
80102858:	8b 40 08             	mov    0x8(%eax),%eax
8010285b:	c1 e8 10             	shr    $0x10,%eax
8010285e:	0f b6 c0             	movzbl %al,%eax
80102861:	89 44 24 04          	mov    %eax,0x4(%esp)
80102865:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
8010286c:	e8 36 fe ff ff       	call   801026a7 <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
80102871:	8b 45 08             	mov    0x8(%ebp),%eax
80102874:	8b 40 04             	mov    0x4(%eax),%eax
80102877:	83 e0 01             	and    $0x1,%eax
8010287a:	c1 e0 04             	shl    $0x4,%eax
8010287d:	89 c2                	mov    %eax,%edx
8010287f:	8b 45 08             	mov    0x8(%ebp),%eax
80102882:	8b 40 08             	mov    0x8(%eax),%eax
80102885:	c1 e8 18             	shr    $0x18,%eax
80102888:	83 e0 0f             	and    $0xf,%eax
8010288b:	09 d0                	or     %edx,%eax
8010288d:	83 c8 e0             	or     $0xffffffe0,%eax
80102890:	0f b6 c0             	movzbl %al,%eax
80102893:	89 44 24 04          	mov    %eax,0x4(%esp)
80102897:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010289e:	e8 04 fe ff ff       	call   801026a7 <outb>
  if(b->flags & B_DIRTY){
801028a3:	8b 45 08             	mov    0x8(%ebp),%eax
801028a6:	8b 00                	mov    (%eax),%eax
801028a8:	83 e0 04             	and    $0x4,%eax
801028ab:	85 c0                	test   %eax,%eax
801028ad:	74 34                	je     801028e3 <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
801028af:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
801028b6:	00 
801028b7:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801028be:	e8 e4 fd ff ff       	call   801026a7 <outb>
    outsl(0x1f0, b->data, 512/4);
801028c3:	8b 45 08             	mov    0x8(%ebp),%eax
801028c6:	83 c0 18             	add    $0x18,%eax
801028c9:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801028d0:	00 
801028d1:	89 44 24 04          	mov    %eax,0x4(%esp)
801028d5:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
801028dc:	e8 e4 fd ff ff       	call   801026c5 <outsl>
801028e1:	eb 14                	jmp    801028f7 <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
801028e3:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801028ea:	00 
801028eb:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801028f2:	e8 b0 fd ff ff       	call   801026a7 <outb>
  }
}
801028f7:	c9                   	leave  
801028f8:	c3                   	ret    

801028f9 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
801028f9:	55                   	push   %ebp
801028fa:	89 e5                	mov    %esp,%ebp
801028fc:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
801028ff:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102906:	e8 78 35 00 00       	call   80105e83 <acquire>
  if((b = idequeue) == 0){
8010290b:	a1 34 c6 10 80       	mov    0x8010c634,%eax
80102910:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102913:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102917:	75 11                	jne    8010292a <ideintr+0x31>
    release(&idelock);
80102919:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102920:	e8 c0 35 00 00       	call   80105ee5 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80102925:	e9 90 00 00 00       	jmp    801029ba <ideintr+0xc1>
  }
  idequeue = b->qnext;
8010292a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010292d:	8b 40 14             	mov    0x14(%eax),%eax
80102930:	a3 34 c6 10 80       	mov    %eax,0x8010c634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80102935:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102938:	8b 00                	mov    (%eax),%eax
8010293a:	83 e0 04             	and    $0x4,%eax
8010293d:	85 c0                	test   %eax,%eax
8010293f:	75 2e                	jne    8010296f <ideintr+0x76>
80102941:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102948:	e8 9d fd ff ff       	call   801026ea <idewait>
8010294d:	85 c0                	test   %eax,%eax
8010294f:	78 1e                	js     8010296f <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
80102951:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102954:	83 c0 18             	add    $0x18,%eax
80102957:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010295e:	00 
8010295f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102963:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
8010296a:	e8 13 fd ff ff       	call   80102682 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
8010296f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102972:	8b 00                	mov    (%eax),%eax
80102974:	83 c8 02             	or     $0x2,%eax
80102977:	89 c2                	mov    %eax,%edx
80102979:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010297c:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
8010297e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102981:	8b 00                	mov    (%eax),%eax
80102983:	83 e0 fb             	and    $0xfffffffb,%eax
80102986:	89 c2                	mov    %eax,%edx
80102988:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010298b:	89 10                	mov    %edx,(%eax)
  wakeup(b);
8010298d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102990:	89 04 24             	mov    %eax,(%esp)
80102993:	e8 e6 25 00 00       	call   80104f7e <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80102998:	a1 34 c6 10 80       	mov    0x8010c634,%eax
8010299d:	85 c0                	test   %eax,%eax
8010299f:	74 0d                	je     801029ae <ideintr+0xb5>
    idestart(idequeue);
801029a1:	a1 34 c6 10 80       	mov    0x8010c634,%eax
801029a6:	89 04 24             	mov    %eax,(%esp)
801029a9:	e8 26 fe ff ff       	call   801027d4 <idestart>

  release(&idelock);
801029ae:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
801029b5:	e8 2b 35 00 00       	call   80105ee5 <release>
}
801029ba:	c9                   	leave  
801029bb:	c3                   	ret    

801029bc <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
801029bc:	55                   	push   %ebp
801029bd:	89 e5                	mov    %esp,%ebp
801029bf:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
801029c2:	8b 45 08             	mov    0x8(%ebp),%eax
801029c5:	8b 00                	mov    (%eax),%eax
801029c7:	83 e0 01             	and    $0x1,%eax
801029ca:	85 c0                	test   %eax,%eax
801029cc:	75 0c                	jne    801029da <iderw+0x1e>
    panic("iderw: buf not busy");
801029ce:	c7 04 24 09 96 10 80 	movl   $0x80109609,(%esp)
801029d5:	e8 60 db ff ff       	call   8010053a <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
801029da:	8b 45 08             	mov    0x8(%ebp),%eax
801029dd:	8b 00                	mov    (%eax),%eax
801029df:	83 e0 06             	and    $0x6,%eax
801029e2:	83 f8 02             	cmp    $0x2,%eax
801029e5:	75 0c                	jne    801029f3 <iderw+0x37>
    panic("iderw: nothing to do");
801029e7:	c7 04 24 1d 96 10 80 	movl   $0x8010961d,(%esp)
801029ee:	e8 47 db ff ff       	call   8010053a <panic>
  if(b->dev != 0 && !havedisk1)
801029f3:	8b 45 08             	mov    0x8(%ebp),%eax
801029f6:	8b 40 04             	mov    0x4(%eax),%eax
801029f9:	85 c0                	test   %eax,%eax
801029fb:	74 15                	je     80102a12 <iderw+0x56>
801029fd:	a1 38 c6 10 80       	mov    0x8010c638,%eax
80102a02:	85 c0                	test   %eax,%eax
80102a04:	75 0c                	jne    80102a12 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
80102a06:	c7 04 24 32 96 10 80 	movl   $0x80109632,(%esp)
80102a0d:	e8 28 db ff ff       	call   8010053a <panic>

  acquire(&idelock);  //DOC:acquire-lock
80102a12:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102a19:	e8 65 34 00 00       	call   80105e83 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80102a1e:	8b 45 08             	mov    0x8(%ebp),%eax
80102a21:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80102a28:	c7 45 f4 34 c6 10 80 	movl   $0x8010c634,-0xc(%ebp)
80102a2f:	eb 0b                	jmp    80102a3c <iderw+0x80>
80102a31:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a34:	8b 00                	mov    (%eax),%eax
80102a36:	83 c0 14             	add    $0x14,%eax
80102a39:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102a3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a3f:	8b 00                	mov    (%eax),%eax
80102a41:	85 c0                	test   %eax,%eax
80102a43:	75 ec                	jne    80102a31 <iderw+0x75>
    ;
  *pp = b;
80102a45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a48:	8b 55 08             	mov    0x8(%ebp),%edx
80102a4b:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80102a4d:	a1 34 c6 10 80       	mov    0x8010c634,%eax
80102a52:	3b 45 08             	cmp    0x8(%ebp),%eax
80102a55:	75 0d                	jne    80102a64 <iderw+0xa8>
    idestart(b);
80102a57:	8b 45 08             	mov    0x8(%ebp),%eax
80102a5a:	89 04 24             	mov    %eax,(%esp)
80102a5d:	e8 72 fd ff ff       	call   801027d4 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102a62:	eb 15                	jmp    80102a79 <iderw+0xbd>
80102a64:	eb 13                	jmp    80102a79 <iderw+0xbd>
    sleep(b, &idelock);
80102a66:	c7 44 24 04 00 c6 10 	movl   $0x8010c600,0x4(%esp)
80102a6d:	80 
80102a6e:	8b 45 08             	mov    0x8(%ebp),%eax
80102a71:	89 04 24             	mov    %eax,(%esp)
80102a74:	e8 29 24 00 00       	call   80104ea2 <sleep>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102a79:	8b 45 08             	mov    0x8(%ebp),%eax
80102a7c:	8b 00                	mov    (%eax),%eax
80102a7e:	83 e0 06             	and    $0x6,%eax
80102a81:	83 f8 02             	cmp    $0x2,%eax
80102a84:	75 e0                	jne    80102a66 <iderw+0xaa>
    sleep(b, &idelock);
  }

  release(&idelock);
80102a86:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102a8d:	e8 53 34 00 00       	call   80105ee5 <release>
}
80102a92:	c9                   	leave  
80102a93:	c3                   	ret    

80102a94 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102a94:	55                   	push   %ebp
80102a95:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102a97:	a1 54 32 11 80       	mov    0x80113254,%eax
80102a9c:	8b 55 08             	mov    0x8(%ebp),%edx
80102a9f:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80102aa1:	a1 54 32 11 80       	mov    0x80113254,%eax
80102aa6:	8b 40 10             	mov    0x10(%eax),%eax
}
80102aa9:	5d                   	pop    %ebp
80102aaa:	c3                   	ret    

80102aab <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80102aab:	55                   	push   %ebp
80102aac:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102aae:	a1 54 32 11 80       	mov    0x80113254,%eax
80102ab3:	8b 55 08             	mov    0x8(%ebp),%edx
80102ab6:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80102ab8:	a1 54 32 11 80       	mov    0x80113254,%eax
80102abd:	8b 55 0c             	mov    0xc(%ebp),%edx
80102ac0:	89 50 10             	mov    %edx,0x10(%eax)
}
80102ac3:	5d                   	pop    %ebp
80102ac4:	c3                   	ret    

80102ac5 <ioapicinit>:

void
ioapicinit(void)
{
80102ac5:	55                   	push   %ebp
80102ac6:	89 e5                	mov    %esp,%ebp
80102ac8:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80102acb:	a1 84 33 11 80       	mov    0x80113384,%eax
80102ad0:	85 c0                	test   %eax,%eax
80102ad2:	75 05                	jne    80102ad9 <ioapicinit+0x14>
    return;
80102ad4:	e9 9d 00 00 00       	jmp    80102b76 <ioapicinit+0xb1>

  ioapic = (volatile struct ioapic*)IOAPIC;
80102ad9:	c7 05 54 32 11 80 00 	movl   $0xfec00000,0x80113254
80102ae0:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80102ae3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102aea:	e8 a5 ff ff ff       	call   80102a94 <ioapicread>
80102aef:	c1 e8 10             	shr    $0x10,%eax
80102af2:	25 ff 00 00 00       	and    $0xff,%eax
80102af7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80102afa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102b01:	e8 8e ff ff ff       	call   80102a94 <ioapicread>
80102b06:	c1 e8 18             	shr    $0x18,%eax
80102b09:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80102b0c:	0f b6 05 80 33 11 80 	movzbl 0x80113380,%eax
80102b13:	0f b6 c0             	movzbl %al,%eax
80102b16:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102b19:	74 0c                	je     80102b27 <ioapicinit+0x62>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102b1b:	c7 04 24 50 96 10 80 	movl   $0x80109650,(%esp)
80102b22:	e8 79 d8 ff ff       	call   801003a0 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102b27:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102b2e:	eb 3e                	jmp    80102b6e <ioapicinit+0xa9>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80102b30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b33:	83 c0 20             	add    $0x20,%eax
80102b36:	0d 00 00 01 00       	or     $0x10000,%eax
80102b3b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102b3e:	83 c2 08             	add    $0x8,%edx
80102b41:	01 d2                	add    %edx,%edx
80102b43:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b47:	89 14 24             	mov    %edx,(%esp)
80102b4a:	e8 5c ff ff ff       	call   80102aab <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102b4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b52:	83 c0 08             	add    $0x8,%eax
80102b55:	01 c0                	add    %eax,%eax
80102b57:	83 c0 01             	add    $0x1,%eax
80102b5a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102b61:	00 
80102b62:	89 04 24             	mov    %eax,(%esp)
80102b65:	e8 41 ff ff ff       	call   80102aab <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102b6a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102b6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b71:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80102b74:	7e ba                	jle    80102b30 <ioapicinit+0x6b>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80102b76:	c9                   	leave  
80102b77:	c3                   	ret    

80102b78 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102b78:	55                   	push   %ebp
80102b79:	89 e5                	mov    %esp,%ebp
80102b7b:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80102b7e:	a1 84 33 11 80       	mov    0x80113384,%eax
80102b83:	85 c0                	test   %eax,%eax
80102b85:	75 02                	jne    80102b89 <ioapicenable+0x11>
    return;
80102b87:	eb 37                	jmp    80102bc0 <ioapicenable+0x48>

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80102b89:	8b 45 08             	mov    0x8(%ebp),%eax
80102b8c:	83 c0 20             	add    $0x20,%eax
80102b8f:	8b 55 08             	mov    0x8(%ebp),%edx
80102b92:	83 c2 08             	add    $0x8,%edx
80102b95:	01 d2                	add    %edx,%edx
80102b97:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b9b:	89 14 24             	mov    %edx,(%esp)
80102b9e:	e8 08 ff ff ff       	call   80102aab <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80102ba3:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ba6:	c1 e0 18             	shl    $0x18,%eax
80102ba9:	8b 55 08             	mov    0x8(%ebp),%edx
80102bac:	83 c2 08             	add    $0x8,%edx
80102baf:	01 d2                	add    %edx,%edx
80102bb1:	83 c2 01             	add    $0x1,%edx
80102bb4:	89 44 24 04          	mov    %eax,0x4(%esp)
80102bb8:	89 14 24             	mov    %edx,(%esp)
80102bbb:	e8 eb fe ff ff       	call   80102aab <ioapicwrite>
}
80102bc0:	c9                   	leave  
80102bc1:	c3                   	ret    

80102bc2 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80102bc2:	55                   	push   %ebp
80102bc3:	89 e5                	mov    %esp,%ebp
80102bc5:	8b 45 08             	mov    0x8(%ebp),%eax
80102bc8:	05 00 00 00 80       	add    $0x80000000,%eax
80102bcd:	5d                   	pop    %ebp
80102bce:	c3                   	ret    

80102bcf <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80102bcf:	55                   	push   %ebp
80102bd0:	89 e5                	mov    %esp,%ebp
80102bd2:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80102bd5:	c7 44 24 04 82 96 10 	movl   $0x80109682,0x4(%esp)
80102bdc:	80 
80102bdd:	c7 04 24 60 32 11 80 	movl   $0x80113260,(%esp)
80102be4:	e8 79 32 00 00       	call   80105e62 <initlock>
  kmem.use_lock = 0;
80102be9:	c7 05 94 32 11 80 00 	movl   $0x0,0x80113294
80102bf0:	00 00 00 
  freerange(vstart, vend);
80102bf3:	8b 45 0c             	mov    0xc(%ebp),%eax
80102bf6:	89 44 24 04          	mov    %eax,0x4(%esp)
80102bfa:	8b 45 08             	mov    0x8(%ebp),%eax
80102bfd:	89 04 24             	mov    %eax,(%esp)
80102c00:	e8 26 00 00 00       	call   80102c2b <freerange>
}
80102c05:	c9                   	leave  
80102c06:	c3                   	ret    

80102c07 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102c07:	55                   	push   %ebp
80102c08:	89 e5                	mov    %esp,%ebp
80102c0a:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80102c0d:	8b 45 0c             	mov    0xc(%ebp),%eax
80102c10:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c14:	8b 45 08             	mov    0x8(%ebp),%eax
80102c17:	89 04 24             	mov    %eax,(%esp)
80102c1a:	e8 0c 00 00 00       	call   80102c2b <freerange>
  kmem.use_lock = 1;
80102c1f:	c7 05 94 32 11 80 01 	movl   $0x1,0x80113294
80102c26:	00 00 00 
}
80102c29:	c9                   	leave  
80102c2a:	c3                   	ret    

80102c2b <freerange>:

void
freerange(void *vstart, void *vend)
{
80102c2b:	55                   	push   %ebp
80102c2c:	89 e5                	mov    %esp,%ebp
80102c2e:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102c31:	8b 45 08             	mov    0x8(%ebp),%eax
80102c34:	05 ff 0f 00 00       	add    $0xfff,%eax
80102c39:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102c3e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102c41:	eb 12                	jmp    80102c55 <freerange+0x2a>
    kfree(p);
80102c43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c46:	89 04 24             	mov    %eax,(%esp)
80102c49:	e8 16 00 00 00       	call   80102c64 <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102c4e:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102c55:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c58:	05 00 10 00 00       	add    $0x1000,%eax
80102c5d:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102c60:	76 e1                	jbe    80102c43 <freerange+0x18>
    kfree(p);
}
80102c62:	c9                   	leave  
80102c63:	c3                   	ret    

80102c64 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102c64:	55                   	push   %ebp
80102c65:	89 e5                	mov    %esp,%ebp
80102c67:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80102c6a:	8b 45 08             	mov    0x8(%ebp),%eax
80102c6d:	25 ff 0f 00 00       	and    $0xfff,%eax
80102c72:	85 c0                	test   %eax,%eax
80102c74:	75 1b                	jne    80102c91 <kfree+0x2d>
80102c76:	81 7d 08 7c 75 12 80 	cmpl   $0x8012757c,0x8(%ebp)
80102c7d:	72 12                	jb     80102c91 <kfree+0x2d>
80102c7f:	8b 45 08             	mov    0x8(%ebp),%eax
80102c82:	89 04 24             	mov    %eax,(%esp)
80102c85:	e8 38 ff ff ff       	call   80102bc2 <v2p>
80102c8a:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102c8f:	76 0c                	jbe    80102c9d <kfree+0x39>
    panic("kfree");
80102c91:	c7 04 24 87 96 10 80 	movl   $0x80109687,(%esp)
80102c98:	e8 9d d8 ff ff       	call   8010053a <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102c9d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102ca4:	00 
80102ca5:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102cac:	00 
80102cad:	8b 45 08             	mov    0x8(%ebp),%eax
80102cb0:	89 04 24             	mov    %eax,(%esp)
80102cb3:	e8 1f 34 00 00       	call   801060d7 <memset>

  if(kmem.use_lock)
80102cb8:	a1 94 32 11 80       	mov    0x80113294,%eax
80102cbd:	85 c0                	test   %eax,%eax
80102cbf:	74 0c                	je     80102ccd <kfree+0x69>
    acquire(&kmem.lock);
80102cc1:	c7 04 24 60 32 11 80 	movl   $0x80113260,(%esp)
80102cc8:	e8 b6 31 00 00       	call   80105e83 <acquire>
  r = (struct run*)v;
80102ccd:	8b 45 08             	mov    0x8(%ebp),%eax
80102cd0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102cd3:	8b 15 98 32 11 80    	mov    0x80113298,%edx
80102cd9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102cdc:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102cde:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ce1:	a3 98 32 11 80       	mov    %eax,0x80113298
  if(kmem.use_lock)
80102ce6:	a1 94 32 11 80       	mov    0x80113294,%eax
80102ceb:	85 c0                	test   %eax,%eax
80102ced:	74 0c                	je     80102cfb <kfree+0x97>
    release(&kmem.lock);
80102cef:	c7 04 24 60 32 11 80 	movl   $0x80113260,(%esp)
80102cf6:	e8 ea 31 00 00       	call   80105ee5 <release>
}
80102cfb:	c9                   	leave  
80102cfc:	c3                   	ret    

80102cfd <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102cfd:	55                   	push   %ebp
80102cfe:	89 e5                	mov    %esp,%ebp
80102d00:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80102d03:	a1 94 32 11 80       	mov    0x80113294,%eax
80102d08:	85 c0                	test   %eax,%eax
80102d0a:	74 0c                	je     80102d18 <kalloc+0x1b>
    acquire(&kmem.lock);
80102d0c:	c7 04 24 60 32 11 80 	movl   $0x80113260,(%esp)
80102d13:	e8 6b 31 00 00       	call   80105e83 <acquire>
  r = kmem.freelist;
80102d18:	a1 98 32 11 80       	mov    0x80113298,%eax
80102d1d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102d20:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102d24:	74 0a                	je     80102d30 <kalloc+0x33>
    kmem.freelist = r->next;
80102d26:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d29:	8b 00                	mov    (%eax),%eax
80102d2b:	a3 98 32 11 80       	mov    %eax,0x80113298
  if(kmem.use_lock)
80102d30:	a1 94 32 11 80       	mov    0x80113294,%eax
80102d35:	85 c0                	test   %eax,%eax
80102d37:	74 0c                	je     80102d45 <kalloc+0x48>
    release(&kmem.lock);
80102d39:	c7 04 24 60 32 11 80 	movl   $0x80113260,(%esp)
80102d40:	e8 a0 31 00 00       	call   80105ee5 <release>
  return (char*)r;
80102d45:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102d48:	c9                   	leave  
80102d49:	c3                   	ret    

80102d4a <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102d4a:	55                   	push   %ebp
80102d4b:	89 e5                	mov    %esp,%ebp
80102d4d:	83 ec 14             	sub    $0x14,%esp
80102d50:	8b 45 08             	mov    0x8(%ebp),%eax
80102d53:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102d57:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102d5b:	89 c2                	mov    %eax,%edx
80102d5d:	ec                   	in     (%dx),%al
80102d5e:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102d61:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102d65:	c9                   	leave  
80102d66:	c3                   	ret    

80102d67 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102d67:	55                   	push   %ebp
80102d68:	89 e5                	mov    %esp,%ebp
80102d6a:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102d6d:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102d74:	e8 d1 ff ff ff       	call   80102d4a <inb>
80102d79:	0f b6 c0             	movzbl %al,%eax
80102d7c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102d7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d82:	83 e0 01             	and    $0x1,%eax
80102d85:	85 c0                	test   %eax,%eax
80102d87:	75 0a                	jne    80102d93 <kbdgetc+0x2c>
    return -1;
80102d89:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102d8e:	e9 25 01 00 00       	jmp    80102eb8 <kbdgetc+0x151>
  data = inb(KBDATAP);
80102d93:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80102d9a:	e8 ab ff ff ff       	call   80102d4a <inb>
80102d9f:	0f b6 c0             	movzbl %al,%eax
80102da2:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102da5:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102dac:	75 17                	jne    80102dc5 <kbdgetc+0x5e>
    shift |= E0ESC;
80102dae:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102db3:	83 c8 40             	or     $0x40,%eax
80102db6:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
    return 0;
80102dbb:	b8 00 00 00 00       	mov    $0x0,%eax
80102dc0:	e9 f3 00 00 00       	jmp    80102eb8 <kbdgetc+0x151>
  } else if(data & 0x80){
80102dc5:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102dc8:	25 80 00 00 00       	and    $0x80,%eax
80102dcd:	85 c0                	test   %eax,%eax
80102dcf:	74 45                	je     80102e16 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102dd1:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102dd6:	83 e0 40             	and    $0x40,%eax
80102dd9:	85 c0                	test   %eax,%eax
80102ddb:	75 08                	jne    80102de5 <kbdgetc+0x7e>
80102ddd:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102de0:	83 e0 7f             	and    $0x7f,%eax
80102de3:	eb 03                	jmp    80102de8 <kbdgetc+0x81>
80102de5:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102de8:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102deb:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102dee:	05 20 a0 10 80       	add    $0x8010a020,%eax
80102df3:	0f b6 00             	movzbl (%eax),%eax
80102df6:	83 c8 40             	or     $0x40,%eax
80102df9:	0f b6 c0             	movzbl %al,%eax
80102dfc:	f7 d0                	not    %eax
80102dfe:	89 c2                	mov    %eax,%edx
80102e00:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102e05:	21 d0                	and    %edx,%eax
80102e07:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
    return 0;
80102e0c:	b8 00 00 00 00       	mov    $0x0,%eax
80102e11:	e9 a2 00 00 00       	jmp    80102eb8 <kbdgetc+0x151>
  } else if(shift & E0ESC){
80102e16:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102e1b:	83 e0 40             	and    $0x40,%eax
80102e1e:	85 c0                	test   %eax,%eax
80102e20:	74 14                	je     80102e36 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102e22:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102e29:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102e2e:	83 e0 bf             	and    $0xffffffbf,%eax
80102e31:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
  }

  shift |= shiftcode[data];
80102e36:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e39:	05 20 a0 10 80       	add    $0x8010a020,%eax
80102e3e:	0f b6 00             	movzbl (%eax),%eax
80102e41:	0f b6 d0             	movzbl %al,%edx
80102e44:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102e49:	09 d0                	or     %edx,%eax
80102e4b:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
  shift ^= togglecode[data];
80102e50:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e53:	05 20 a1 10 80       	add    $0x8010a120,%eax
80102e58:	0f b6 00             	movzbl (%eax),%eax
80102e5b:	0f b6 d0             	movzbl %al,%edx
80102e5e:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102e63:	31 d0                	xor    %edx,%eax
80102e65:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
  c = charcode[shift & (CTL | SHIFT)][data];
80102e6a:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102e6f:	83 e0 03             	and    $0x3,%eax
80102e72:	8b 14 85 20 a5 10 80 	mov    -0x7fef5ae0(,%eax,4),%edx
80102e79:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e7c:	01 d0                	add    %edx,%eax
80102e7e:	0f b6 00             	movzbl (%eax),%eax
80102e81:	0f b6 c0             	movzbl %al,%eax
80102e84:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102e87:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102e8c:	83 e0 08             	and    $0x8,%eax
80102e8f:	85 c0                	test   %eax,%eax
80102e91:	74 22                	je     80102eb5 <kbdgetc+0x14e>
    if('a' <= c && c <= 'z')
80102e93:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102e97:	76 0c                	jbe    80102ea5 <kbdgetc+0x13e>
80102e99:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102e9d:	77 06                	ja     80102ea5 <kbdgetc+0x13e>
      c += 'A' - 'a';
80102e9f:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102ea3:	eb 10                	jmp    80102eb5 <kbdgetc+0x14e>
    else if('A' <= c && c <= 'Z')
80102ea5:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102ea9:	76 0a                	jbe    80102eb5 <kbdgetc+0x14e>
80102eab:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102eaf:	77 04                	ja     80102eb5 <kbdgetc+0x14e>
      c += 'a' - 'A';
80102eb1:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102eb5:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102eb8:	c9                   	leave  
80102eb9:	c3                   	ret    

80102eba <kbdintr>:

void
kbdintr(void)
{
80102eba:	55                   	push   %ebp
80102ebb:	89 e5                	mov    %esp,%ebp
80102ebd:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80102ec0:	c7 04 24 67 2d 10 80 	movl   $0x80102d67,(%esp)
80102ec7:	e8 e1 d8 ff ff       	call   801007ad <consoleintr>
}
80102ecc:	c9                   	leave  
80102ecd:	c3                   	ret    

80102ece <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102ece:	55                   	push   %ebp
80102ecf:	89 e5                	mov    %esp,%ebp
80102ed1:	83 ec 14             	sub    $0x14,%esp
80102ed4:	8b 45 08             	mov    0x8(%ebp),%eax
80102ed7:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102edb:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102edf:	89 c2                	mov    %eax,%edx
80102ee1:	ec                   	in     (%dx),%al
80102ee2:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102ee5:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102ee9:	c9                   	leave  
80102eea:	c3                   	ret    

80102eeb <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80102eeb:	55                   	push   %ebp
80102eec:	89 e5                	mov    %esp,%ebp
80102eee:	83 ec 08             	sub    $0x8,%esp
80102ef1:	8b 55 08             	mov    0x8(%ebp),%edx
80102ef4:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ef7:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102efb:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102efe:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102f02:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102f06:	ee                   	out    %al,(%dx)
}
80102f07:	c9                   	leave  
80102f08:	c3                   	ret    

80102f09 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80102f09:	55                   	push   %ebp
80102f0a:	89 e5                	mov    %esp,%ebp
80102f0c:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80102f0f:	9c                   	pushf  
80102f10:	58                   	pop    %eax
80102f11:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80102f14:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80102f17:	c9                   	leave  
80102f18:	c3                   	ret    

80102f19 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102f19:	55                   	push   %ebp
80102f1a:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102f1c:	a1 9c 32 11 80       	mov    0x8011329c,%eax
80102f21:	8b 55 08             	mov    0x8(%ebp),%edx
80102f24:	c1 e2 02             	shl    $0x2,%edx
80102f27:	01 c2                	add    %eax,%edx
80102f29:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f2c:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102f2e:	a1 9c 32 11 80       	mov    0x8011329c,%eax
80102f33:	83 c0 20             	add    $0x20,%eax
80102f36:	8b 00                	mov    (%eax),%eax
}
80102f38:	5d                   	pop    %ebp
80102f39:	c3                   	ret    

80102f3a <lapicinit>:
//PAGEBREAK!

void
lapicinit(void)
{
80102f3a:	55                   	push   %ebp
80102f3b:	89 e5                	mov    %esp,%ebp
80102f3d:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80102f40:	a1 9c 32 11 80       	mov    0x8011329c,%eax
80102f45:	85 c0                	test   %eax,%eax
80102f47:	75 05                	jne    80102f4e <lapicinit+0x14>
    return;
80102f49:	e9 43 01 00 00       	jmp    80103091 <lapicinit+0x157>

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102f4e:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80102f55:	00 
80102f56:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80102f5d:	e8 b7 ff ff ff       	call   80102f19 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102f62:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80102f69:	00 
80102f6a:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80102f71:	e8 a3 ff ff ff       	call   80102f19 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102f76:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80102f7d:	00 
80102f7e:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102f85:	e8 8f ff ff ff       	call   80102f19 <lapicw>
  lapicw(TICR, 10000000); 
80102f8a:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80102f91:	00 
80102f92:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80102f99:	e8 7b ff ff ff       	call   80102f19 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102f9e:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102fa5:	00 
80102fa6:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80102fad:	e8 67 ff ff ff       	call   80102f19 <lapicw>
  lapicw(LINT1, MASKED);
80102fb2:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102fb9:	00 
80102fba:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80102fc1:	e8 53 ff ff ff       	call   80102f19 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102fc6:	a1 9c 32 11 80       	mov    0x8011329c,%eax
80102fcb:	83 c0 30             	add    $0x30,%eax
80102fce:	8b 00                	mov    (%eax),%eax
80102fd0:	c1 e8 10             	shr    $0x10,%eax
80102fd3:	0f b6 c0             	movzbl %al,%eax
80102fd6:	83 f8 03             	cmp    $0x3,%eax
80102fd9:	76 14                	jbe    80102fef <lapicinit+0xb5>
    lapicw(PCINT, MASKED);
80102fdb:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102fe2:	00 
80102fe3:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80102fea:	e8 2a ff ff ff       	call   80102f19 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102fef:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80102ff6:	00 
80102ff7:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80102ffe:	e8 16 ff ff ff       	call   80102f19 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80103003:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010300a:	00 
8010300b:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103012:	e8 02 ff ff ff       	call   80102f19 <lapicw>
  lapicw(ESR, 0);
80103017:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010301e:	00 
8010301f:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103026:	e8 ee fe ff ff       	call   80102f19 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
8010302b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103032:	00 
80103033:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
8010303a:	e8 da fe ff ff       	call   80102f19 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
8010303f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103046:	00 
80103047:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010304e:	e8 c6 fe ff ff       	call   80102f19 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80103053:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
8010305a:	00 
8010305b:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103062:	e8 b2 fe ff ff       	call   80102f19 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80103067:	90                   	nop
80103068:	a1 9c 32 11 80       	mov    0x8011329c,%eax
8010306d:	05 00 03 00 00       	add    $0x300,%eax
80103072:	8b 00                	mov    (%eax),%eax
80103074:	25 00 10 00 00       	and    $0x1000,%eax
80103079:	85 c0                	test   %eax,%eax
8010307b:	75 eb                	jne    80103068 <lapicinit+0x12e>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
8010307d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103084:	00 
80103085:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010308c:	e8 88 fe ff ff       	call   80102f19 <lapicw>
}
80103091:	c9                   	leave  
80103092:	c3                   	ret    

80103093 <cpunum>:

int
cpunum(void)
{
80103093:	55                   	push   %ebp
80103094:	89 e5                	mov    %esp,%ebp
80103096:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80103099:	e8 6b fe ff ff       	call   80102f09 <readeflags>
8010309e:	25 00 02 00 00       	and    $0x200,%eax
801030a3:	85 c0                	test   %eax,%eax
801030a5:	74 25                	je     801030cc <cpunum+0x39>
    static int n;
    if(n++ == 0)
801030a7:	a1 40 c6 10 80       	mov    0x8010c640,%eax
801030ac:	8d 50 01             	lea    0x1(%eax),%edx
801030af:	89 15 40 c6 10 80    	mov    %edx,0x8010c640
801030b5:	85 c0                	test   %eax,%eax
801030b7:	75 13                	jne    801030cc <cpunum+0x39>
      cprintf("cpu called from %x with interrupts enabled\n",
801030b9:	8b 45 04             	mov    0x4(%ebp),%eax
801030bc:	89 44 24 04          	mov    %eax,0x4(%esp)
801030c0:	c7 04 24 90 96 10 80 	movl   $0x80109690,(%esp)
801030c7:	e8 d4 d2 ff ff       	call   801003a0 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
801030cc:	a1 9c 32 11 80       	mov    0x8011329c,%eax
801030d1:	85 c0                	test   %eax,%eax
801030d3:	74 0f                	je     801030e4 <cpunum+0x51>
    return lapic[ID]>>24;
801030d5:	a1 9c 32 11 80       	mov    0x8011329c,%eax
801030da:	83 c0 20             	add    $0x20,%eax
801030dd:	8b 00                	mov    (%eax),%eax
801030df:	c1 e8 18             	shr    $0x18,%eax
801030e2:	eb 05                	jmp    801030e9 <cpunum+0x56>
  return 0;
801030e4:	b8 00 00 00 00       	mov    $0x0,%eax
}
801030e9:	c9                   	leave  
801030ea:	c3                   	ret    

801030eb <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
801030eb:	55                   	push   %ebp
801030ec:	89 e5                	mov    %esp,%ebp
801030ee:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
801030f1:	a1 9c 32 11 80       	mov    0x8011329c,%eax
801030f6:	85 c0                	test   %eax,%eax
801030f8:	74 14                	je     8010310e <lapiceoi+0x23>
    lapicw(EOI, 0);
801030fa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103101:	00 
80103102:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103109:	e8 0b fe ff ff       	call   80102f19 <lapicw>
}
8010310e:	c9                   	leave  
8010310f:	c3                   	ret    

80103110 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80103110:	55                   	push   %ebp
80103111:	89 e5                	mov    %esp,%ebp
}
80103113:	5d                   	pop    %ebp
80103114:	c3                   	ret    

80103115 <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
80103115:	55                   	push   %ebp
80103116:	89 e5                	mov    %esp,%ebp
80103118:	83 ec 1c             	sub    $0x1c,%esp
8010311b:	8b 45 08             	mov    0x8(%ebp),%eax
8010311e:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
80103121:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80103128:	00 
80103129:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80103130:	e8 b6 fd ff ff       	call   80102eeb <outb>
  outb(CMOS_PORT+1, 0x0A);
80103135:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
8010313c:	00 
8010313d:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80103144:	e8 a2 fd ff ff       	call   80102eeb <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80103149:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80103150:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103153:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80103158:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010315b:	8d 50 02             	lea    0x2(%eax),%edx
8010315e:	8b 45 0c             	mov    0xc(%ebp),%eax
80103161:	c1 e8 04             	shr    $0x4,%eax
80103164:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80103167:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
8010316b:	c1 e0 18             	shl    $0x18,%eax
8010316e:	89 44 24 04          	mov    %eax,0x4(%esp)
80103172:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103179:	e8 9b fd ff ff       	call   80102f19 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
8010317e:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80103185:	00 
80103186:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010318d:	e8 87 fd ff ff       	call   80102f19 <lapicw>
  microdelay(200);
80103192:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103199:	e8 72 ff ff ff       	call   80103110 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
8010319e:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
801031a5:	00 
801031a6:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801031ad:	e8 67 fd ff ff       	call   80102f19 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
801031b2:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
801031b9:	e8 52 ff ff ff       	call   80103110 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801031be:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801031c5:	eb 40                	jmp    80103207 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
801031c7:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801031cb:	c1 e0 18             	shl    $0x18,%eax
801031ce:	89 44 24 04          	mov    %eax,0x4(%esp)
801031d2:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801031d9:	e8 3b fd ff ff       	call   80102f19 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
801031de:	8b 45 0c             	mov    0xc(%ebp),%eax
801031e1:	c1 e8 0c             	shr    $0xc,%eax
801031e4:	80 cc 06             	or     $0x6,%ah
801031e7:	89 44 24 04          	mov    %eax,0x4(%esp)
801031eb:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801031f2:	e8 22 fd ff ff       	call   80102f19 <lapicw>
    microdelay(200);
801031f7:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801031fe:	e8 0d ff ff ff       	call   80103110 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103203:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103207:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
8010320b:	7e ba                	jle    801031c7 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
8010320d:	c9                   	leave  
8010320e:	c3                   	ret    

8010320f <cmos_read>:
#define DAY     0x07
#define MONTH   0x08
#define YEAR    0x09

static uint cmos_read(uint reg)
{
8010320f:	55                   	push   %ebp
80103210:	89 e5                	mov    %esp,%ebp
80103212:	83 ec 08             	sub    $0x8,%esp
  outb(CMOS_PORT,  reg);
80103215:	8b 45 08             	mov    0x8(%ebp),%eax
80103218:	0f b6 c0             	movzbl %al,%eax
8010321b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010321f:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80103226:	e8 c0 fc ff ff       	call   80102eeb <outb>
  microdelay(200);
8010322b:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103232:	e8 d9 fe ff ff       	call   80103110 <microdelay>

  return inb(CMOS_RETURN);
80103237:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
8010323e:	e8 8b fc ff ff       	call   80102ece <inb>
80103243:	0f b6 c0             	movzbl %al,%eax
}
80103246:	c9                   	leave  
80103247:	c3                   	ret    

80103248 <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
80103248:	55                   	push   %ebp
80103249:	89 e5                	mov    %esp,%ebp
8010324b:	83 ec 04             	sub    $0x4,%esp
  r->second = cmos_read(SECS);
8010324e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80103255:	e8 b5 ff ff ff       	call   8010320f <cmos_read>
8010325a:	8b 55 08             	mov    0x8(%ebp),%edx
8010325d:	89 02                	mov    %eax,(%edx)
  r->minute = cmos_read(MINS);
8010325f:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80103266:	e8 a4 ff ff ff       	call   8010320f <cmos_read>
8010326b:	8b 55 08             	mov    0x8(%ebp),%edx
8010326e:	89 42 04             	mov    %eax,0x4(%edx)
  r->hour   = cmos_read(HOURS);
80103271:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80103278:	e8 92 ff ff ff       	call   8010320f <cmos_read>
8010327d:	8b 55 08             	mov    0x8(%ebp),%edx
80103280:	89 42 08             	mov    %eax,0x8(%edx)
  r->day    = cmos_read(DAY);
80103283:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
8010328a:	e8 80 ff ff ff       	call   8010320f <cmos_read>
8010328f:	8b 55 08             	mov    0x8(%ebp),%edx
80103292:	89 42 0c             	mov    %eax,0xc(%edx)
  r->month  = cmos_read(MONTH);
80103295:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010329c:	e8 6e ff ff ff       	call   8010320f <cmos_read>
801032a1:	8b 55 08             	mov    0x8(%ebp),%edx
801032a4:	89 42 10             	mov    %eax,0x10(%edx)
  r->year   = cmos_read(YEAR);
801032a7:	c7 04 24 09 00 00 00 	movl   $0x9,(%esp)
801032ae:	e8 5c ff ff ff       	call   8010320f <cmos_read>
801032b3:	8b 55 08             	mov    0x8(%ebp),%edx
801032b6:	89 42 14             	mov    %eax,0x14(%edx)
}
801032b9:	c9                   	leave  
801032ba:	c3                   	ret    

801032bb <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
801032bb:	55                   	push   %ebp
801032bc:	89 e5                	mov    %esp,%ebp
801032be:	83 ec 58             	sub    $0x58,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
801032c1:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
801032c8:	e8 42 ff ff ff       	call   8010320f <cmos_read>
801032cd:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
801032d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032d3:	83 e0 04             	and    $0x4,%eax
801032d6:	85 c0                	test   %eax,%eax
801032d8:	0f 94 c0             	sete   %al
801032db:	0f b6 c0             	movzbl %al,%eax
801032de:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
801032e1:	8d 45 d8             	lea    -0x28(%ebp),%eax
801032e4:	89 04 24             	mov    %eax,(%esp)
801032e7:	e8 5c ff ff ff       	call   80103248 <fill_rtcdate>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
801032ec:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
801032f3:	e8 17 ff ff ff       	call   8010320f <cmos_read>
801032f8:	25 80 00 00 00       	and    $0x80,%eax
801032fd:	85 c0                	test   %eax,%eax
801032ff:	74 02                	je     80103303 <cmostime+0x48>
        continue;
80103301:	eb 36                	jmp    80103339 <cmostime+0x7e>
    fill_rtcdate(&t2);
80103303:	8d 45 c0             	lea    -0x40(%ebp),%eax
80103306:	89 04 24             	mov    %eax,(%esp)
80103309:	e8 3a ff ff ff       	call   80103248 <fill_rtcdate>
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
8010330e:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
80103315:	00 
80103316:	8d 45 c0             	lea    -0x40(%ebp),%eax
80103319:	89 44 24 04          	mov    %eax,0x4(%esp)
8010331d:	8d 45 d8             	lea    -0x28(%ebp),%eax
80103320:	89 04 24             	mov    %eax,(%esp)
80103323:	e8 26 2e 00 00       	call   8010614e <memcmp>
80103328:	85 c0                	test   %eax,%eax
8010332a:	75 0d                	jne    80103339 <cmostime+0x7e>
      break;
8010332c:	90                   	nop
  }

  // convert
  if (bcd) {
8010332d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103331:	0f 84 ac 00 00 00    	je     801033e3 <cmostime+0x128>
80103337:	eb 02                	jmp    8010333b <cmostime+0x80>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
80103339:	eb a6                	jmp    801032e1 <cmostime+0x26>

  // convert
  if (bcd) {
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
8010333b:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010333e:	c1 e8 04             	shr    $0x4,%eax
80103341:	89 c2                	mov    %eax,%edx
80103343:	89 d0                	mov    %edx,%eax
80103345:	c1 e0 02             	shl    $0x2,%eax
80103348:	01 d0                	add    %edx,%eax
8010334a:	01 c0                	add    %eax,%eax
8010334c:	8b 55 d8             	mov    -0x28(%ebp),%edx
8010334f:	83 e2 0f             	and    $0xf,%edx
80103352:	01 d0                	add    %edx,%eax
80103354:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
80103357:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010335a:	c1 e8 04             	shr    $0x4,%eax
8010335d:	89 c2                	mov    %eax,%edx
8010335f:	89 d0                	mov    %edx,%eax
80103361:	c1 e0 02             	shl    $0x2,%eax
80103364:	01 d0                	add    %edx,%eax
80103366:	01 c0                	add    %eax,%eax
80103368:	8b 55 dc             	mov    -0x24(%ebp),%edx
8010336b:	83 e2 0f             	and    $0xf,%edx
8010336e:	01 d0                	add    %edx,%eax
80103370:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
80103373:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103376:	c1 e8 04             	shr    $0x4,%eax
80103379:	89 c2                	mov    %eax,%edx
8010337b:	89 d0                	mov    %edx,%eax
8010337d:	c1 e0 02             	shl    $0x2,%eax
80103380:	01 d0                	add    %edx,%eax
80103382:	01 c0                	add    %eax,%eax
80103384:	8b 55 e0             	mov    -0x20(%ebp),%edx
80103387:	83 e2 0f             	and    $0xf,%edx
8010338a:	01 d0                	add    %edx,%eax
8010338c:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
8010338f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103392:	c1 e8 04             	shr    $0x4,%eax
80103395:	89 c2                	mov    %eax,%edx
80103397:	89 d0                	mov    %edx,%eax
80103399:	c1 e0 02             	shl    $0x2,%eax
8010339c:	01 d0                	add    %edx,%eax
8010339e:	01 c0                	add    %eax,%eax
801033a0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801033a3:	83 e2 0f             	and    $0xf,%edx
801033a6:	01 d0                	add    %edx,%eax
801033a8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
801033ab:	8b 45 e8             	mov    -0x18(%ebp),%eax
801033ae:	c1 e8 04             	shr    $0x4,%eax
801033b1:	89 c2                	mov    %eax,%edx
801033b3:	89 d0                	mov    %edx,%eax
801033b5:	c1 e0 02             	shl    $0x2,%eax
801033b8:	01 d0                	add    %edx,%eax
801033ba:	01 c0                	add    %eax,%eax
801033bc:	8b 55 e8             	mov    -0x18(%ebp),%edx
801033bf:	83 e2 0f             	and    $0xf,%edx
801033c2:	01 d0                	add    %edx,%eax
801033c4:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
801033c7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033ca:	c1 e8 04             	shr    $0x4,%eax
801033cd:	89 c2                	mov    %eax,%edx
801033cf:	89 d0                	mov    %edx,%eax
801033d1:	c1 e0 02             	shl    $0x2,%eax
801033d4:	01 d0                	add    %edx,%eax
801033d6:	01 c0                	add    %eax,%eax
801033d8:	8b 55 ec             	mov    -0x14(%ebp),%edx
801033db:	83 e2 0f             	and    $0xf,%edx
801033de:	01 d0                	add    %edx,%eax
801033e0:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
801033e3:	8b 45 08             	mov    0x8(%ebp),%eax
801033e6:	8b 55 d8             	mov    -0x28(%ebp),%edx
801033e9:	89 10                	mov    %edx,(%eax)
801033eb:	8b 55 dc             	mov    -0x24(%ebp),%edx
801033ee:	89 50 04             	mov    %edx,0x4(%eax)
801033f1:	8b 55 e0             	mov    -0x20(%ebp),%edx
801033f4:	89 50 08             	mov    %edx,0x8(%eax)
801033f7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801033fa:	89 50 0c             	mov    %edx,0xc(%eax)
801033fd:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103400:	89 50 10             	mov    %edx,0x10(%eax)
80103403:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103406:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
80103409:	8b 45 08             	mov    0x8(%ebp),%eax
8010340c:	8b 40 14             	mov    0x14(%eax),%eax
8010340f:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
80103415:	8b 45 08             	mov    0x8(%ebp),%eax
80103418:	89 50 14             	mov    %edx,0x14(%eax)
}
8010341b:	c9                   	leave  
8010341c:	c3                   	ret    

8010341d <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(void)
{
8010341d:	55                   	push   %ebp
8010341e:	89 e5                	mov    %esp,%ebp
80103420:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
80103423:	c7 44 24 04 bc 96 10 	movl   $0x801096bc,0x4(%esp)
8010342a:	80 
8010342b:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
80103432:	e8 2b 2a 00 00       	call   80105e62 <initlock>
  readsb(ROOTDEV, &sb);
80103437:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010343a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010343e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103445:	e8 a7 df ff ff       	call   801013f1 <readsb>
  log.start = sb.size - sb.nlog;
8010344a:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010344d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103450:	29 c2                	sub    %eax,%edx
80103452:	89 d0                	mov    %edx,%eax
80103454:	a3 d4 32 11 80       	mov    %eax,0x801132d4
  log.size = sb.nlog;
80103459:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010345c:	a3 d8 32 11 80       	mov    %eax,0x801132d8
  log.dev = ROOTDEV;
80103461:	c7 05 e4 32 11 80 01 	movl   $0x1,0x801132e4
80103468:	00 00 00 
  recover_from_log();
8010346b:	e8 9a 01 00 00       	call   8010360a <recover_from_log>
}
80103470:	c9                   	leave  
80103471:	c3                   	ret    

80103472 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
80103472:	55                   	push   %ebp
80103473:	89 e5                	mov    %esp,%ebp
80103475:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103478:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010347f:	e9 8c 00 00 00       	jmp    80103510 <install_trans+0x9e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80103484:	8b 15 d4 32 11 80    	mov    0x801132d4,%edx
8010348a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010348d:	01 d0                	add    %edx,%eax
8010348f:	83 c0 01             	add    $0x1,%eax
80103492:	89 c2                	mov    %eax,%edx
80103494:	a1 e4 32 11 80       	mov    0x801132e4,%eax
80103499:	89 54 24 04          	mov    %edx,0x4(%esp)
8010349d:	89 04 24             	mov    %eax,(%esp)
801034a0:	e8 01 cd ff ff       	call   801001a6 <bread>
801034a5:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
801034a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801034ab:	83 c0 10             	add    $0x10,%eax
801034ae:	8b 04 85 ac 32 11 80 	mov    -0x7feecd54(,%eax,4),%eax
801034b5:	89 c2                	mov    %eax,%edx
801034b7:	a1 e4 32 11 80       	mov    0x801132e4,%eax
801034bc:	89 54 24 04          	mov    %edx,0x4(%esp)
801034c0:	89 04 24             	mov    %eax,(%esp)
801034c3:	e8 de cc ff ff       	call   801001a6 <bread>
801034c8:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801034cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801034ce:	8d 50 18             	lea    0x18(%eax),%edx
801034d1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801034d4:	83 c0 18             	add    $0x18,%eax
801034d7:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801034de:	00 
801034df:	89 54 24 04          	mov    %edx,0x4(%esp)
801034e3:	89 04 24             	mov    %eax,(%esp)
801034e6:	e8 bb 2c 00 00       	call   801061a6 <memmove>
    bwrite(dbuf);  // write dst to disk
801034eb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801034ee:	89 04 24             	mov    %eax,(%esp)
801034f1:	e8 e7 cc ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
801034f6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801034f9:	89 04 24             	mov    %eax,(%esp)
801034fc:	e8 16 cd ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80103501:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103504:	89 04 24             	mov    %eax,(%esp)
80103507:	e8 0b cd ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010350c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103510:	a1 e8 32 11 80       	mov    0x801132e8,%eax
80103515:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103518:	0f 8f 66 ff ff ff    	jg     80103484 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
8010351e:	c9                   	leave  
8010351f:	c3                   	ret    

80103520 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103520:	55                   	push   %ebp
80103521:	89 e5                	mov    %esp,%ebp
80103523:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103526:	a1 d4 32 11 80       	mov    0x801132d4,%eax
8010352b:	89 c2                	mov    %eax,%edx
8010352d:	a1 e4 32 11 80       	mov    0x801132e4,%eax
80103532:	89 54 24 04          	mov    %edx,0x4(%esp)
80103536:	89 04 24             	mov    %eax,(%esp)
80103539:	e8 68 cc ff ff       	call   801001a6 <bread>
8010353e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103541:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103544:	83 c0 18             	add    $0x18,%eax
80103547:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
8010354a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010354d:	8b 00                	mov    (%eax),%eax
8010354f:	a3 e8 32 11 80       	mov    %eax,0x801132e8
  for (i = 0; i < log.lh.n; i++) {
80103554:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010355b:	eb 1b                	jmp    80103578 <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
8010355d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103560:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103563:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103567:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010356a:	83 c2 10             	add    $0x10,%edx
8010356d:	89 04 95 ac 32 11 80 	mov    %eax,-0x7feecd54(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80103574:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103578:	a1 e8 32 11 80       	mov    0x801132e8,%eax
8010357d:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103580:	7f db                	jg     8010355d <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
80103582:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103585:	89 04 24             	mov    %eax,(%esp)
80103588:	e8 8a cc ff ff       	call   80100217 <brelse>
}
8010358d:	c9                   	leave  
8010358e:	c3                   	ret    

8010358f <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
8010358f:	55                   	push   %ebp
80103590:	89 e5                	mov    %esp,%ebp
80103592:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103595:	a1 d4 32 11 80       	mov    0x801132d4,%eax
8010359a:	89 c2                	mov    %eax,%edx
8010359c:	a1 e4 32 11 80       	mov    0x801132e4,%eax
801035a1:	89 54 24 04          	mov    %edx,0x4(%esp)
801035a5:	89 04 24             	mov    %eax,(%esp)
801035a8:	e8 f9 cb ff ff       	call   801001a6 <bread>
801035ad:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
801035b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035b3:	83 c0 18             	add    $0x18,%eax
801035b6:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
801035b9:	8b 15 e8 32 11 80    	mov    0x801132e8,%edx
801035bf:	8b 45 ec             	mov    -0x14(%ebp),%eax
801035c2:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
801035c4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801035cb:	eb 1b                	jmp    801035e8 <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
801035cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035d0:	83 c0 10             	add    $0x10,%eax
801035d3:	8b 0c 85 ac 32 11 80 	mov    -0x7feecd54(,%eax,4),%ecx
801035da:	8b 45 ec             	mov    -0x14(%ebp),%eax
801035dd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801035e0:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
801035e4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801035e8:	a1 e8 32 11 80       	mov    0x801132e8,%eax
801035ed:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801035f0:	7f db                	jg     801035cd <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
801035f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035f5:	89 04 24             	mov    %eax,(%esp)
801035f8:	e8 e0 cb ff ff       	call   801001dd <bwrite>
  brelse(buf);
801035fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103600:	89 04 24             	mov    %eax,(%esp)
80103603:	e8 0f cc ff ff       	call   80100217 <brelse>
}
80103608:	c9                   	leave  
80103609:	c3                   	ret    

8010360a <recover_from_log>:

static void
recover_from_log(void)
{
8010360a:	55                   	push   %ebp
8010360b:	89 e5                	mov    %esp,%ebp
8010360d:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103610:	e8 0b ff ff ff       	call   80103520 <read_head>
  install_trans(); // if committed, copy from log to disk
80103615:	e8 58 fe ff ff       	call   80103472 <install_trans>
  log.lh.n = 0;
8010361a:	c7 05 e8 32 11 80 00 	movl   $0x0,0x801132e8
80103621:	00 00 00 
  write_head(); // clear the log
80103624:	e8 66 ff ff ff       	call   8010358f <write_head>
}
80103629:	c9                   	leave  
8010362a:	c3                   	ret    

8010362b <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
8010362b:	55                   	push   %ebp
8010362c:	89 e5                	mov    %esp,%ebp
8010362e:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103631:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
80103638:	e8 46 28 00 00       	call   80105e83 <acquire>
  while(1){
    if(log.committing){
8010363d:	a1 e0 32 11 80       	mov    0x801132e0,%eax
80103642:	85 c0                	test   %eax,%eax
80103644:	74 16                	je     8010365c <begin_op+0x31>
      sleep(&log, &log.lock);
80103646:	c7 44 24 04 a0 32 11 	movl   $0x801132a0,0x4(%esp)
8010364d:	80 
8010364e:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
80103655:	e8 48 18 00 00       	call   80104ea2 <sleep>
8010365a:	eb 4f                	jmp    801036ab <begin_op+0x80>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
8010365c:	8b 0d e8 32 11 80    	mov    0x801132e8,%ecx
80103662:	a1 dc 32 11 80       	mov    0x801132dc,%eax
80103667:	8d 50 01             	lea    0x1(%eax),%edx
8010366a:	89 d0                	mov    %edx,%eax
8010366c:	c1 e0 02             	shl    $0x2,%eax
8010366f:	01 d0                	add    %edx,%eax
80103671:	01 c0                	add    %eax,%eax
80103673:	01 c8                	add    %ecx,%eax
80103675:	83 f8 1e             	cmp    $0x1e,%eax
80103678:	7e 16                	jle    80103690 <begin_op+0x65>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
8010367a:	c7 44 24 04 a0 32 11 	movl   $0x801132a0,0x4(%esp)
80103681:	80 
80103682:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
80103689:	e8 14 18 00 00       	call   80104ea2 <sleep>
8010368e:	eb 1b                	jmp    801036ab <begin_op+0x80>
    } else {
      log.outstanding += 1;
80103690:	a1 dc 32 11 80       	mov    0x801132dc,%eax
80103695:	83 c0 01             	add    $0x1,%eax
80103698:	a3 dc 32 11 80       	mov    %eax,0x801132dc
      release(&log.lock);
8010369d:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
801036a4:	e8 3c 28 00 00       	call   80105ee5 <release>
      break;
801036a9:	eb 02                	jmp    801036ad <begin_op+0x82>
    }
  }
801036ab:	eb 90                	jmp    8010363d <begin_op+0x12>
}
801036ad:	c9                   	leave  
801036ae:	c3                   	ret    

801036af <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
801036af:	55                   	push   %ebp
801036b0:	89 e5                	mov    %esp,%ebp
801036b2:	83 ec 28             	sub    $0x28,%esp
  int do_commit = 0;
801036b5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
801036bc:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
801036c3:	e8 bb 27 00 00       	call   80105e83 <acquire>
  log.outstanding -= 1;
801036c8:	a1 dc 32 11 80       	mov    0x801132dc,%eax
801036cd:	83 e8 01             	sub    $0x1,%eax
801036d0:	a3 dc 32 11 80       	mov    %eax,0x801132dc
  if(log.committing)
801036d5:	a1 e0 32 11 80       	mov    0x801132e0,%eax
801036da:	85 c0                	test   %eax,%eax
801036dc:	74 0c                	je     801036ea <end_op+0x3b>
    panic("log.committing");
801036de:	c7 04 24 c0 96 10 80 	movl   $0x801096c0,(%esp)
801036e5:	e8 50 ce ff ff       	call   8010053a <panic>
  if(log.outstanding == 0){
801036ea:	a1 dc 32 11 80       	mov    0x801132dc,%eax
801036ef:	85 c0                	test   %eax,%eax
801036f1:	75 13                	jne    80103706 <end_op+0x57>
    do_commit = 1;
801036f3:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
801036fa:	c7 05 e0 32 11 80 01 	movl   $0x1,0x801132e0
80103701:	00 00 00 
80103704:	eb 0c                	jmp    80103712 <end_op+0x63>
  } else {
    // begin_op() may be waiting for log space.
    wakeup(&log);
80103706:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
8010370d:	e8 6c 18 00 00       	call   80104f7e <wakeup>
  }
  release(&log.lock);
80103712:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
80103719:	e8 c7 27 00 00       	call   80105ee5 <release>

  if(do_commit){
8010371e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103722:	74 33                	je     80103757 <end_op+0xa8>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
80103724:	e8 de 00 00 00       	call   80103807 <commit>
    acquire(&log.lock);
80103729:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
80103730:	e8 4e 27 00 00       	call   80105e83 <acquire>
    log.committing = 0;
80103735:	c7 05 e0 32 11 80 00 	movl   $0x0,0x801132e0
8010373c:	00 00 00 
    wakeup(&log);
8010373f:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
80103746:	e8 33 18 00 00       	call   80104f7e <wakeup>
    release(&log.lock);
8010374b:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
80103752:	e8 8e 27 00 00       	call   80105ee5 <release>
  }
}
80103757:	c9                   	leave  
80103758:	c3                   	ret    

80103759 <write_log>:

// Copy modified blocks from cache to log.
static void 
write_log(void)
{
80103759:	55                   	push   %ebp
8010375a:	89 e5                	mov    %esp,%ebp
8010375c:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010375f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103766:	e9 8c 00 00 00       	jmp    801037f7 <write_log+0x9e>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
8010376b:	8b 15 d4 32 11 80    	mov    0x801132d4,%edx
80103771:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103774:	01 d0                	add    %edx,%eax
80103776:	83 c0 01             	add    $0x1,%eax
80103779:	89 c2                	mov    %eax,%edx
8010377b:	a1 e4 32 11 80       	mov    0x801132e4,%eax
80103780:	89 54 24 04          	mov    %edx,0x4(%esp)
80103784:	89 04 24             	mov    %eax,(%esp)
80103787:	e8 1a ca ff ff       	call   801001a6 <bread>
8010378c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.sector[tail]); // cache block
8010378f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103792:	83 c0 10             	add    $0x10,%eax
80103795:	8b 04 85 ac 32 11 80 	mov    -0x7feecd54(,%eax,4),%eax
8010379c:	89 c2                	mov    %eax,%edx
8010379e:	a1 e4 32 11 80       	mov    0x801132e4,%eax
801037a3:	89 54 24 04          	mov    %edx,0x4(%esp)
801037a7:	89 04 24             	mov    %eax,(%esp)
801037aa:	e8 f7 c9 ff ff       	call   801001a6 <bread>
801037af:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
801037b2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801037b5:	8d 50 18             	lea    0x18(%eax),%edx
801037b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037bb:	83 c0 18             	add    $0x18,%eax
801037be:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801037c5:	00 
801037c6:	89 54 24 04          	mov    %edx,0x4(%esp)
801037ca:	89 04 24             	mov    %eax,(%esp)
801037cd:	e8 d4 29 00 00       	call   801061a6 <memmove>
    bwrite(to);  // write the log
801037d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037d5:	89 04 24             	mov    %eax,(%esp)
801037d8:	e8 00 ca ff ff       	call   801001dd <bwrite>
    brelse(from); 
801037dd:	8b 45 ec             	mov    -0x14(%ebp),%eax
801037e0:	89 04 24             	mov    %eax,(%esp)
801037e3:	e8 2f ca ff ff       	call   80100217 <brelse>
    brelse(to);
801037e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037eb:	89 04 24             	mov    %eax,(%esp)
801037ee:	e8 24 ca ff ff       	call   80100217 <brelse>
static void 
write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801037f3:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801037f7:	a1 e8 32 11 80       	mov    0x801132e8,%eax
801037fc:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801037ff:	0f 8f 66 ff ff ff    	jg     8010376b <write_log+0x12>
    memmove(to->data, from->data, BSIZE);
    bwrite(to);  // write the log
    brelse(from); 
    brelse(to);
  }
}
80103805:	c9                   	leave  
80103806:	c3                   	ret    

80103807 <commit>:

static void
commit()
{
80103807:	55                   	push   %ebp
80103808:	89 e5                	mov    %esp,%ebp
8010380a:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
8010380d:	a1 e8 32 11 80       	mov    0x801132e8,%eax
80103812:	85 c0                	test   %eax,%eax
80103814:	7e 1e                	jle    80103834 <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
80103816:	e8 3e ff ff ff       	call   80103759 <write_log>
    write_head();    // Write header to disk -- the real commit
8010381b:	e8 6f fd ff ff       	call   8010358f <write_head>
    install_trans(); // Now install writes to home locations
80103820:	e8 4d fc ff ff       	call   80103472 <install_trans>
    log.lh.n = 0; 
80103825:	c7 05 e8 32 11 80 00 	movl   $0x0,0x801132e8
8010382c:	00 00 00 
    write_head();    // Erase the transaction from the log
8010382f:	e8 5b fd ff ff       	call   8010358f <write_head>
  }
}
80103834:	c9                   	leave  
80103835:	c3                   	ret    

80103836 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103836:	55                   	push   %ebp
80103837:	89 e5                	mov    %esp,%ebp
80103839:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
8010383c:	a1 e8 32 11 80       	mov    0x801132e8,%eax
80103841:	83 f8 1d             	cmp    $0x1d,%eax
80103844:	7f 12                	jg     80103858 <log_write+0x22>
80103846:	a1 e8 32 11 80       	mov    0x801132e8,%eax
8010384b:	8b 15 d8 32 11 80    	mov    0x801132d8,%edx
80103851:	83 ea 01             	sub    $0x1,%edx
80103854:	39 d0                	cmp    %edx,%eax
80103856:	7c 0c                	jl     80103864 <log_write+0x2e>
    panic("too big a transaction");
80103858:	c7 04 24 cf 96 10 80 	movl   $0x801096cf,(%esp)
8010385f:	e8 d6 cc ff ff       	call   8010053a <panic>
  if (log.outstanding < 1)
80103864:	a1 dc 32 11 80       	mov    0x801132dc,%eax
80103869:	85 c0                	test   %eax,%eax
8010386b:	7f 0c                	jg     80103879 <log_write+0x43>
    panic("log_write outside of trans");
8010386d:	c7 04 24 e5 96 10 80 	movl   $0x801096e5,(%esp)
80103874:	e8 c1 cc ff ff       	call   8010053a <panic>

  acquire(&log.lock);
80103879:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
80103880:	e8 fe 25 00 00       	call   80105e83 <acquire>
  for (i = 0; i < log.lh.n; i++) {
80103885:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010388c:	eb 1f                	jmp    801038ad <log_write+0x77>
    if (log.lh.sector[i] == b->sector)   // log absorbtion
8010388e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103891:	83 c0 10             	add    $0x10,%eax
80103894:	8b 04 85 ac 32 11 80 	mov    -0x7feecd54(,%eax,4),%eax
8010389b:	89 c2                	mov    %eax,%edx
8010389d:	8b 45 08             	mov    0x8(%ebp),%eax
801038a0:	8b 40 08             	mov    0x8(%eax),%eax
801038a3:	39 c2                	cmp    %eax,%edx
801038a5:	75 02                	jne    801038a9 <log_write+0x73>
      break;
801038a7:	eb 0e                	jmp    801038b7 <log_write+0x81>
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
801038a9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801038ad:	a1 e8 32 11 80       	mov    0x801132e8,%eax
801038b2:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801038b5:	7f d7                	jg     8010388e <log_write+0x58>
    if (log.lh.sector[i] == b->sector)   // log absorbtion
      break;
  }
  log.lh.sector[i] = b->sector;
801038b7:	8b 45 08             	mov    0x8(%ebp),%eax
801038ba:	8b 40 08             	mov    0x8(%eax),%eax
801038bd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801038c0:	83 c2 10             	add    $0x10,%edx
801038c3:	89 04 95 ac 32 11 80 	mov    %eax,-0x7feecd54(,%edx,4)
  if (i == log.lh.n)
801038ca:	a1 e8 32 11 80       	mov    0x801132e8,%eax
801038cf:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801038d2:	75 0d                	jne    801038e1 <log_write+0xab>
    log.lh.n++;
801038d4:	a1 e8 32 11 80       	mov    0x801132e8,%eax
801038d9:	83 c0 01             	add    $0x1,%eax
801038dc:	a3 e8 32 11 80       	mov    %eax,0x801132e8
  b->flags |= B_DIRTY; // prevent eviction
801038e1:	8b 45 08             	mov    0x8(%ebp),%eax
801038e4:	8b 00                	mov    (%eax),%eax
801038e6:	83 c8 04             	or     $0x4,%eax
801038e9:	89 c2                	mov    %eax,%edx
801038eb:	8b 45 08             	mov    0x8(%ebp),%eax
801038ee:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
801038f0:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
801038f7:	e8 e9 25 00 00       	call   80105ee5 <release>
}
801038fc:	c9                   	leave  
801038fd:	c3                   	ret    

801038fe <v2p>:
801038fe:	55                   	push   %ebp
801038ff:	89 e5                	mov    %esp,%ebp
80103901:	8b 45 08             	mov    0x8(%ebp),%eax
80103904:	05 00 00 00 80       	add    $0x80000000,%eax
80103909:	5d                   	pop    %ebp
8010390a:	c3                   	ret    

8010390b <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
8010390b:	55                   	push   %ebp
8010390c:	89 e5                	mov    %esp,%ebp
8010390e:	8b 45 08             	mov    0x8(%ebp),%eax
80103911:	05 00 00 00 80       	add    $0x80000000,%eax
80103916:	5d                   	pop    %ebp
80103917:	c3                   	ret    

80103918 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103918:	55                   	push   %ebp
80103919:	89 e5                	mov    %esp,%ebp
8010391b:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
8010391e:	8b 55 08             	mov    0x8(%ebp),%edx
80103921:	8b 45 0c             	mov    0xc(%ebp),%eax
80103924:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103927:	f0 87 02             	lock xchg %eax,(%edx)
8010392a:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
8010392d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80103930:	c9                   	leave  
80103931:	c3                   	ret    

80103932 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103932:	55                   	push   %ebp
80103933:	89 e5                	mov    %esp,%ebp
80103935:	83 e4 f0             	and    $0xfffffff0,%esp
80103938:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
8010393b:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103942:	80 
80103943:	c7 04 24 7c 75 12 80 	movl   $0x8012757c,(%esp)
8010394a:	e8 80 f2 ff ff       	call   80102bcf <kinit1>
  kvmalloc();      // kernel page table
8010394f:	e8 ae 53 00 00       	call   80108d02 <kvmalloc>
  mpinit();        // collect info about this machine
80103954:	e8 4b 04 00 00       	call   80103da4 <mpinit>
  lapicinit();
80103959:	e8 dc f5 ff ff       	call   80102f3a <lapicinit>
  seginit();       // set up segments
8010395e:	e8 32 4d 00 00       	call   80108695 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103963:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103969:	0f b6 00             	movzbl (%eax),%eax
8010396c:	0f b6 c0             	movzbl %al,%eax
8010396f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103973:	c7 04 24 00 97 10 80 	movl   $0x80109700,(%esp)
8010397a:	e8 21 ca ff ff       	call   801003a0 <cprintf>
  picinit();       // interrupt controller
8010397f:	e8 7e 06 00 00       	call   80104002 <picinit>
  ioapicinit();    // another interrupt controller
80103984:	e8 3c f1 ff ff       	call   80102ac5 <ioapicinit>
  procfsinit();
80103989:	e8 66 23 00 00       	call   80105cf4 <procfsinit>
  consoleinit();   // I/O devices & their interrupts
8010398e:	e8 ee d0 ff ff       	call   80100a81 <consoleinit>
  uartinit();      // serial port
80103993:	e8 4c 40 00 00       	call   801079e4 <uartinit>
  pinit();         // process table
80103998:	e8 6f 0b 00 00       	call   8010450c <pinit>
  tvinit();        // trap vectors
8010399d:	e8 f4 3b 00 00       	call   80107596 <tvinit>
  binit();         // buffer cache
801039a2:	e8 8d c6 ff ff       	call   80100034 <binit>
  fileinit();      // file table
801039a7:	e8 5e d6 ff ff       	call   8010100a <fileinit>
  iinit();         // inode cache
801039ac:	e8 f3 dc ff ff       	call   801016a4 <iinit>
  ideinit();       // disk
801039b1:	e8 78 ed ff ff       	call   8010272e <ideinit>
  if(!ismp)
801039b6:	a1 84 33 11 80       	mov    0x80113384,%eax
801039bb:	85 c0                	test   %eax,%eax
801039bd:	75 05                	jne    801039c4 <main+0x92>
    timerinit();   // uniprocessor timer
801039bf:	e8 1d 3b 00 00       	call   801074e1 <timerinit>
  startothers();   // start other processors
801039c4:	e8 7f 00 00 00       	call   80103a48 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
801039c9:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
801039d0:	8e 
801039d1:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
801039d8:	e8 2a f2 ff ff       	call   80102c07 <kinit2>
  userinit();      // first user process
801039dd:	e8 48 0c 00 00       	call   8010462a <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
801039e2:	e8 1a 00 00 00       	call   80103a01 <mpmain>

801039e7 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
801039e7:	55                   	push   %ebp
801039e8:	89 e5                	mov    %esp,%ebp
801039ea:	83 ec 08             	sub    $0x8,%esp
  switchkvm(); 
801039ed:	e8 27 53 00 00       	call   80108d19 <switchkvm>
  seginit();
801039f2:	e8 9e 4c 00 00       	call   80108695 <seginit>
  lapicinit();
801039f7:	e8 3e f5 ff ff       	call   80102f3a <lapicinit>
  mpmain();
801039fc:	e8 00 00 00 00       	call   80103a01 <mpmain>

80103a01 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103a01:	55                   	push   %ebp
80103a02:	89 e5                	mov    %esp,%ebp
80103a04:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
80103a07:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103a0d:	0f b6 00             	movzbl (%eax),%eax
80103a10:	0f b6 c0             	movzbl %al,%eax
80103a13:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a17:	c7 04 24 17 97 10 80 	movl   $0x80109717,(%esp)
80103a1e:	e8 7d c9 ff ff       	call   801003a0 <cprintf>
  idtinit();       // load idt register
80103a23:	e8 e2 3c 00 00       	call   8010770a <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103a28:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103a2e:	05 a8 00 00 00       	add    $0xa8,%eax
80103a33:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103a3a:	00 
80103a3b:	89 04 24             	mov    %eax,(%esp)
80103a3e:	e8 d5 fe ff ff       	call   80103918 <xchg>
  scheduler();     // start running processes
80103a43:	e8 af 12 00 00       	call   80104cf7 <scheduler>

80103a48 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103a48:	55                   	push   %ebp
80103a49:	89 e5                	mov    %esp,%ebp
80103a4b:	53                   	push   %ebx
80103a4c:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103a4f:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103a56:	e8 b0 fe ff ff       	call   8010390b <p2v>
80103a5b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103a5e:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103a63:	89 44 24 08          	mov    %eax,0x8(%esp)
80103a67:	c7 44 24 04 0c c5 10 	movl   $0x8010c50c,0x4(%esp)
80103a6e:	80 
80103a6f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a72:	89 04 24             	mov    %eax,(%esp)
80103a75:	e8 2c 27 00 00       	call   801061a6 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103a7a:	c7 45 f4 a0 33 11 80 	movl   $0x801133a0,-0xc(%ebp)
80103a81:	e9 85 00 00 00       	jmp    80103b0b <startothers+0xc3>
    if(c == cpus+cpunum())  // We've started already.
80103a86:	e8 08 f6 ff ff       	call   80103093 <cpunum>
80103a8b:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103a91:	05 a0 33 11 80       	add    $0x801133a0,%eax
80103a96:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103a99:	75 02                	jne    80103a9d <startothers+0x55>
      continue;
80103a9b:	eb 67                	jmp    80103b04 <startothers+0xbc>

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80103a9d:	e8 5b f2 ff ff       	call   80102cfd <kalloc>
80103aa2:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80103aa5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103aa8:	83 e8 04             	sub    $0x4,%eax
80103aab:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103aae:	81 c2 00 10 00 00    	add    $0x1000,%edx
80103ab4:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
80103ab6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ab9:	83 e8 08             	sub    $0x8,%eax
80103abc:	c7 00 e7 39 10 80    	movl   $0x801039e7,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80103ac2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ac5:	8d 58 f4             	lea    -0xc(%eax),%ebx
80103ac8:	c7 04 24 00 b0 10 80 	movl   $0x8010b000,(%esp)
80103acf:	e8 2a fe ff ff       	call   801038fe <v2p>
80103ad4:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80103ad6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ad9:	89 04 24             	mov    %eax,(%esp)
80103adc:	e8 1d fe ff ff       	call   801038fe <v2p>
80103ae1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103ae4:	0f b6 12             	movzbl (%edx),%edx
80103ae7:	0f b6 d2             	movzbl %dl,%edx
80103aea:	89 44 24 04          	mov    %eax,0x4(%esp)
80103aee:	89 14 24             	mov    %edx,(%esp)
80103af1:	e8 1f f6 ff ff       	call   80103115 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80103af6:	90                   	nop
80103af7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103afa:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80103b00:	85 c0                	test   %eax,%eax
80103b02:	74 f3                	je     80103af7 <startothers+0xaf>
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80103b04:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80103b0b:	a1 80 39 11 80       	mov    0x80113980,%eax
80103b10:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103b16:	05 a0 33 11 80       	add    $0x801133a0,%eax
80103b1b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103b1e:	0f 87 62 ff ff ff    	ja     80103a86 <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103b24:	83 c4 24             	add    $0x24,%esp
80103b27:	5b                   	pop    %ebx
80103b28:	5d                   	pop    %ebp
80103b29:	c3                   	ret    

80103b2a <p2v>:
80103b2a:	55                   	push   %ebp
80103b2b:	89 e5                	mov    %esp,%ebp
80103b2d:	8b 45 08             	mov    0x8(%ebp),%eax
80103b30:	05 00 00 00 80       	add    $0x80000000,%eax
80103b35:	5d                   	pop    %ebp
80103b36:	c3                   	ret    

80103b37 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103b37:	55                   	push   %ebp
80103b38:	89 e5                	mov    %esp,%ebp
80103b3a:	83 ec 14             	sub    $0x14,%esp
80103b3d:	8b 45 08             	mov    0x8(%ebp),%eax
80103b40:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103b44:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80103b48:	89 c2                	mov    %eax,%edx
80103b4a:	ec                   	in     (%dx),%al
80103b4b:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80103b4e:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80103b52:	c9                   	leave  
80103b53:	c3                   	ret    

80103b54 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103b54:	55                   	push   %ebp
80103b55:	89 e5                	mov    %esp,%ebp
80103b57:	83 ec 08             	sub    $0x8,%esp
80103b5a:	8b 55 08             	mov    0x8(%ebp),%edx
80103b5d:	8b 45 0c             	mov    0xc(%ebp),%eax
80103b60:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103b64:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103b67:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103b6b:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103b6f:	ee                   	out    %al,(%dx)
}
80103b70:	c9                   	leave  
80103b71:	c3                   	ret    

80103b72 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80103b72:	55                   	push   %ebp
80103b73:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
80103b75:	a1 44 c6 10 80       	mov    0x8010c644,%eax
80103b7a:	89 c2                	mov    %eax,%edx
80103b7c:	b8 a0 33 11 80       	mov    $0x801133a0,%eax
80103b81:	29 c2                	sub    %eax,%edx
80103b83:	89 d0                	mov    %edx,%eax
80103b85:	c1 f8 02             	sar    $0x2,%eax
80103b88:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80103b8e:	5d                   	pop    %ebp
80103b8f:	c3                   	ret    

80103b90 <sum>:

static uchar
sum(uchar *addr, int len)
{
80103b90:	55                   	push   %ebp
80103b91:	89 e5                	mov    %esp,%ebp
80103b93:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
80103b96:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80103b9d:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103ba4:	eb 15                	jmp    80103bbb <sum+0x2b>
    sum += addr[i];
80103ba6:	8b 55 fc             	mov    -0x4(%ebp),%edx
80103ba9:	8b 45 08             	mov    0x8(%ebp),%eax
80103bac:	01 d0                	add    %edx,%eax
80103bae:	0f b6 00             	movzbl (%eax),%eax
80103bb1:	0f b6 c0             	movzbl %al,%eax
80103bb4:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
80103bb7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103bbb:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103bbe:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103bc1:	7c e3                	jl     80103ba6 <sum+0x16>
    sum += addr[i];
  return sum;
80103bc3:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103bc6:	c9                   	leave  
80103bc7:	c3                   	ret    

80103bc8 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80103bc8:	55                   	push   %ebp
80103bc9:	89 e5                	mov    %esp,%ebp
80103bcb:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80103bce:	8b 45 08             	mov    0x8(%ebp),%eax
80103bd1:	89 04 24             	mov    %eax,(%esp)
80103bd4:	e8 51 ff ff ff       	call   80103b2a <p2v>
80103bd9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80103bdc:	8b 55 0c             	mov    0xc(%ebp),%edx
80103bdf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103be2:	01 d0                	add    %edx,%eax
80103be4:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80103be7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bea:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103bed:	eb 3f                	jmp    80103c2e <mpsearch1+0x66>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103bef:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103bf6:	00 
80103bf7:	c7 44 24 04 28 97 10 	movl   $0x80109728,0x4(%esp)
80103bfe:	80 
80103bff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c02:	89 04 24             	mov    %eax,(%esp)
80103c05:	e8 44 25 00 00       	call   8010614e <memcmp>
80103c0a:	85 c0                	test   %eax,%eax
80103c0c:	75 1c                	jne    80103c2a <mpsearch1+0x62>
80103c0e:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80103c15:	00 
80103c16:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c19:	89 04 24             	mov    %eax,(%esp)
80103c1c:	e8 6f ff ff ff       	call   80103b90 <sum>
80103c21:	84 c0                	test   %al,%al
80103c23:	75 05                	jne    80103c2a <mpsearch1+0x62>
      return (struct mp*)p;
80103c25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c28:	eb 11                	jmp    80103c3b <mpsearch1+0x73>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80103c2a:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103c2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c31:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103c34:	72 b9                	jb     80103bef <mpsearch1+0x27>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
80103c36:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103c3b:	c9                   	leave  
80103c3c:	c3                   	ret    

80103c3d <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103c3d:	55                   	push   %ebp
80103c3e:	89 e5                	mov    %esp,%ebp
80103c40:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103c43:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80103c4a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c4d:	83 c0 0f             	add    $0xf,%eax
80103c50:	0f b6 00             	movzbl (%eax),%eax
80103c53:	0f b6 c0             	movzbl %al,%eax
80103c56:	c1 e0 08             	shl    $0x8,%eax
80103c59:	89 c2                	mov    %eax,%edx
80103c5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c5e:	83 c0 0e             	add    $0xe,%eax
80103c61:	0f b6 00             	movzbl (%eax),%eax
80103c64:	0f b6 c0             	movzbl %al,%eax
80103c67:	09 d0                	or     %edx,%eax
80103c69:	c1 e0 04             	shl    $0x4,%eax
80103c6c:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103c6f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103c73:	74 21                	je     80103c96 <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80103c75:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103c7c:	00 
80103c7d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c80:	89 04 24             	mov    %eax,(%esp)
80103c83:	e8 40 ff ff ff       	call   80103bc8 <mpsearch1>
80103c88:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103c8b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103c8f:	74 50                	je     80103ce1 <mpsearch+0xa4>
      return mp;
80103c91:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c94:	eb 5f                	jmp    80103cf5 <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80103c96:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c99:	83 c0 14             	add    $0x14,%eax
80103c9c:	0f b6 00             	movzbl (%eax),%eax
80103c9f:	0f b6 c0             	movzbl %al,%eax
80103ca2:	c1 e0 08             	shl    $0x8,%eax
80103ca5:	89 c2                	mov    %eax,%edx
80103ca7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103caa:	83 c0 13             	add    $0x13,%eax
80103cad:	0f b6 00             	movzbl (%eax),%eax
80103cb0:	0f b6 c0             	movzbl %al,%eax
80103cb3:	09 d0                	or     %edx,%eax
80103cb5:	c1 e0 0a             	shl    $0xa,%eax
80103cb8:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103cbb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103cbe:	2d 00 04 00 00       	sub    $0x400,%eax
80103cc3:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103cca:	00 
80103ccb:	89 04 24             	mov    %eax,(%esp)
80103cce:	e8 f5 fe ff ff       	call   80103bc8 <mpsearch1>
80103cd3:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103cd6:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103cda:	74 05                	je     80103ce1 <mpsearch+0xa4>
      return mp;
80103cdc:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103cdf:	eb 14                	jmp    80103cf5 <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80103ce1:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103ce8:	00 
80103ce9:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80103cf0:	e8 d3 fe ff ff       	call   80103bc8 <mpsearch1>
}
80103cf5:	c9                   	leave  
80103cf6:	c3                   	ret    

80103cf7 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80103cf7:	55                   	push   %ebp
80103cf8:	89 e5                	mov    %esp,%ebp
80103cfa:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80103cfd:	e8 3b ff ff ff       	call   80103c3d <mpsearch>
80103d02:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103d05:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103d09:	74 0a                	je     80103d15 <mpconfig+0x1e>
80103d0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d0e:	8b 40 04             	mov    0x4(%eax),%eax
80103d11:	85 c0                	test   %eax,%eax
80103d13:	75 0a                	jne    80103d1f <mpconfig+0x28>
    return 0;
80103d15:	b8 00 00 00 00       	mov    $0x0,%eax
80103d1a:	e9 83 00 00 00       	jmp    80103da2 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80103d1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d22:	8b 40 04             	mov    0x4(%eax),%eax
80103d25:	89 04 24             	mov    %eax,(%esp)
80103d28:	e8 fd fd ff ff       	call   80103b2a <p2v>
80103d2d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103d30:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103d37:	00 
80103d38:	c7 44 24 04 2d 97 10 	movl   $0x8010972d,0x4(%esp)
80103d3f:	80 
80103d40:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d43:	89 04 24             	mov    %eax,(%esp)
80103d46:	e8 03 24 00 00       	call   8010614e <memcmp>
80103d4b:	85 c0                	test   %eax,%eax
80103d4d:	74 07                	je     80103d56 <mpconfig+0x5f>
    return 0;
80103d4f:	b8 00 00 00 00       	mov    $0x0,%eax
80103d54:	eb 4c                	jmp    80103da2 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
80103d56:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d59:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103d5d:	3c 01                	cmp    $0x1,%al
80103d5f:	74 12                	je     80103d73 <mpconfig+0x7c>
80103d61:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d64:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103d68:	3c 04                	cmp    $0x4,%al
80103d6a:	74 07                	je     80103d73 <mpconfig+0x7c>
    return 0;
80103d6c:	b8 00 00 00 00       	mov    $0x0,%eax
80103d71:	eb 2f                	jmp    80103da2 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80103d73:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d76:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103d7a:	0f b7 c0             	movzwl %ax,%eax
80103d7d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103d81:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d84:	89 04 24             	mov    %eax,(%esp)
80103d87:	e8 04 fe ff ff       	call   80103b90 <sum>
80103d8c:	84 c0                	test   %al,%al
80103d8e:	74 07                	je     80103d97 <mpconfig+0xa0>
    return 0;
80103d90:	b8 00 00 00 00       	mov    $0x0,%eax
80103d95:	eb 0b                	jmp    80103da2 <mpconfig+0xab>
  *pmp = mp;
80103d97:	8b 45 08             	mov    0x8(%ebp),%eax
80103d9a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103d9d:	89 10                	mov    %edx,(%eax)
  return conf;
80103d9f:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80103da2:	c9                   	leave  
80103da3:	c3                   	ret    

80103da4 <mpinit>:

void
mpinit(void)
{
80103da4:	55                   	push   %ebp
80103da5:	89 e5                	mov    %esp,%ebp
80103da7:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80103daa:	c7 05 44 c6 10 80 a0 	movl   $0x801133a0,0x8010c644
80103db1:	33 11 80 
  if((conf = mpconfig(&mp)) == 0)
80103db4:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103db7:	89 04 24             	mov    %eax,(%esp)
80103dba:	e8 38 ff ff ff       	call   80103cf7 <mpconfig>
80103dbf:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103dc2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103dc6:	75 05                	jne    80103dcd <mpinit+0x29>
    return;
80103dc8:	e9 9c 01 00 00       	jmp    80103f69 <mpinit+0x1c5>
  ismp = 1;
80103dcd:	c7 05 84 33 11 80 01 	movl   $0x1,0x80113384
80103dd4:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80103dd7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103dda:	8b 40 24             	mov    0x24(%eax),%eax
80103ddd:	a3 9c 32 11 80       	mov    %eax,0x8011329c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103de2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103de5:	83 c0 2c             	add    $0x2c,%eax
80103de8:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103deb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103dee:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103df2:	0f b7 d0             	movzwl %ax,%edx
80103df5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103df8:	01 d0                	add    %edx,%eax
80103dfa:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103dfd:	e9 f4 00 00 00       	jmp    80103ef6 <mpinit+0x152>
    switch(*p){
80103e02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e05:	0f b6 00             	movzbl (%eax),%eax
80103e08:	0f b6 c0             	movzbl %al,%eax
80103e0b:	83 f8 04             	cmp    $0x4,%eax
80103e0e:	0f 87 bf 00 00 00    	ja     80103ed3 <mpinit+0x12f>
80103e14:	8b 04 85 70 97 10 80 	mov    -0x7fef6890(,%eax,4),%eax
80103e1b:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103e1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e20:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80103e23:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103e26:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103e2a:	0f b6 d0             	movzbl %al,%edx
80103e2d:	a1 80 39 11 80       	mov    0x80113980,%eax
80103e32:	39 c2                	cmp    %eax,%edx
80103e34:	74 2d                	je     80103e63 <mpinit+0xbf>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80103e36:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103e39:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103e3d:	0f b6 d0             	movzbl %al,%edx
80103e40:	a1 80 39 11 80       	mov    0x80113980,%eax
80103e45:	89 54 24 08          	mov    %edx,0x8(%esp)
80103e49:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e4d:	c7 04 24 32 97 10 80 	movl   $0x80109732,(%esp)
80103e54:	e8 47 c5 ff ff       	call   801003a0 <cprintf>
        ismp = 0;
80103e59:	c7 05 84 33 11 80 00 	movl   $0x0,0x80113384
80103e60:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80103e63:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103e66:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80103e6a:	0f b6 c0             	movzbl %al,%eax
80103e6d:	83 e0 02             	and    $0x2,%eax
80103e70:	85 c0                	test   %eax,%eax
80103e72:	74 15                	je     80103e89 <mpinit+0xe5>
        bcpu = &cpus[ncpu];
80103e74:	a1 80 39 11 80       	mov    0x80113980,%eax
80103e79:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103e7f:	05 a0 33 11 80       	add    $0x801133a0,%eax
80103e84:	a3 44 c6 10 80       	mov    %eax,0x8010c644
      cpus[ncpu].id = ncpu;
80103e89:	8b 15 80 39 11 80    	mov    0x80113980,%edx
80103e8f:	a1 80 39 11 80       	mov    0x80113980,%eax
80103e94:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80103e9a:	81 c2 a0 33 11 80    	add    $0x801133a0,%edx
80103ea0:	88 02                	mov    %al,(%edx)
      ncpu++;
80103ea2:	a1 80 39 11 80       	mov    0x80113980,%eax
80103ea7:	83 c0 01             	add    $0x1,%eax
80103eaa:	a3 80 39 11 80       	mov    %eax,0x80113980
      p += sizeof(struct mpproc);
80103eaf:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80103eb3:	eb 41                	jmp    80103ef6 <mpinit+0x152>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80103eb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103eb8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80103ebb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103ebe:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103ec2:	a2 80 33 11 80       	mov    %al,0x80113380
      p += sizeof(struct mpioapic);
80103ec7:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103ecb:	eb 29                	jmp    80103ef6 <mpinit+0x152>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103ecd:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103ed1:	eb 23                	jmp    80103ef6 <mpinit+0x152>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80103ed3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ed6:	0f b6 00             	movzbl (%eax),%eax
80103ed9:	0f b6 c0             	movzbl %al,%eax
80103edc:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ee0:	c7 04 24 50 97 10 80 	movl   $0x80109750,(%esp)
80103ee7:	e8 b4 c4 ff ff       	call   801003a0 <cprintf>
      ismp = 0;
80103eec:	c7 05 84 33 11 80 00 	movl   $0x0,0x80113384
80103ef3:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103ef6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ef9:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103efc:	0f 82 00 ff ff ff    	jb     80103e02 <mpinit+0x5e>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80103f02:	a1 84 33 11 80       	mov    0x80113384,%eax
80103f07:	85 c0                	test   %eax,%eax
80103f09:	75 1d                	jne    80103f28 <mpinit+0x184>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80103f0b:	c7 05 80 39 11 80 01 	movl   $0x1,0x80113980
80103f12:	00 00 00 
    lapic = 0;
80103f15:	c7 05 9c 32 11 80 00 	movl   $0x0,0x8011329c
80103f1c:	00 00 00 
    ioapicid = 0;
80103f1f:	c6 05 80 33 11 80 00 	movb   $0x0,0x80113380
    return;
80103f26:	eb 41                	jmp    80103f69 <mpinit+0x1c5>
  }

  if(mp->imcrp){
80103f28:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103f2b:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103f2f:	84 c0                	test   %al,%al
80103f31:	74 36                	je     80103f69 <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103f33:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80103f3a:	00 
80103f3b:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80103f42:	e8 0d fc ff ff       	call   80103b54 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103f47:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103f4e:	e8 e4 fb ff ff       	call   80103b37 <inb>
80103f53:	83 c8 01             	or     $0x1,%eax
80103f56:	0f b6 c0             	movzbl %al,%eax
80103f59:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f5d:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103f64:	e8 eb fb ff ff       	call   80103b54 <outb>
  }
}
80103f69:	c9                   	leave  
80103f6a:	c3                   	ret    

80103f6b <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103f6b:	55                   	push   %ebp
80103f6c:	89 e5                	mov    %esp,%ebp
80103f6e:	83 ec 08             	sub    $0x8,%esp
80103f71:	8b 55 08             	mov    0x8(%ebp),%edx
80103f74:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f77:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103f7b:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103f7e:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103f82:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103f86:	ee                   	out    %al,(%dx)
}
80103f87:	c9                   	leave  
80103f88:	c3                   	ret    

80103f89 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80103f89:	55                   	push   %ebp
80103f8a:	89 e5                	mov    %esp,%ebp
80103f8c:	83 ec 0c             	sub    $0xc,%esp
80103f8f:	8b 45 08             	mov    0x8(%ebp),%eax
80103f92:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80103f96:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103f9a:	66 a3 00 c0 10 80    	mov    %ax,0x8010c000
  outb(IO_PIC1+1, mask);
80103fa0:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103fa4:	0f b6 c0             	movzbl %al,%eax
80103fa7:	89 44 24 04          	mov    %eax,0x4(%esp)
80103fab:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103fb2:	e8 b4 ff ff ff       	call   80103f6b <outb>
  outb(IO_PIC2+1, mask >> 8);
80103fb7:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103fbb:	66 c1 e8 08          	shr    $0x8,%ax
80103fbf:	0f b6 c0             	movzbl %al,%eax
80103fc2:	89 44 24 04          	mov    %eax,0x4(%esp)
80103fc6:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103fcd:	e8 99 ff ff ff       	call   80103f6b <outb>
}
80103fd2:	c9                   	leave  
80103fd3:	c3                   	ret    

80103fd4 <picenable>:

void
picenable(int irq)
{
80103fd4:	55                   	push   %ebp
80103fd5:	89 e5                	mov    %esp,%ebp
80103fd7:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80103fda:	8b 45 08             	mov    0x8(%ebp),%eax
80103fdd:	ba 01 00 00 00       	mov    $0x1,%edx
80103fe2:	89 c1                	mov    %eax,%ecx
80103fe4:	d3 e2                	shl    %cl,%edx
80103fe6:	89 d0                	mov    %edx,%eax
80103fe8:	f7 d0                	not    %eax
80103fea:	89 c2                	mov    %eax,%edx
80103fec:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80103ff3:	21 d0                	and    %edx,%eax
80103ff5:	0f b7 c0             	movzwl %ax,%eax
80103ff8:	89 04 24             	mov    %eax,(%esp)
80103ffb:	e8 89 ff ff ff       	call   80103f89 <picsetmask>
}
80104000:	c9                   	leave  
80104001:	c3                   	ret    

80104002 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80104002:	55                   	push   %ebp
80104003:	89 e5                	mov    %esp,%ebp
80104005:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80104008:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
8010400f:	00 
80104010:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104017:	e8 4f ff ff ff       	call   80103f6b <outb>
  outb(IO_PIC2+1, 0xFF);
8010401c:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104023:	00 
80104024:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010402b:	e8 3b ff ff ff       	call   80103f6b <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80104030:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80104037:	00 
80104038:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010403f:	e8 27 ff ff ff       	call   80103f6b <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80104044:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
8010404b:	00 
8010404c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104053:	e8 13 ff ff ff       	call   80103f6b <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80104058:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
8010405f:	00 
80104060:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104067:	e8 ff fe ff ff       	call   80103f6b <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
8010406c:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104073:	00 
80104074:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010407b:	e8 eb fe ff ff       	call   80103f6b <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80104080:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80104087:	00 
80104088:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010408f:	e8 d7 fe ff ff       	call   80103f6b <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80104094:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
8010409b:	00 
8010409c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801040a3:	e8 c3 fe ff ff       	call   80103f6b <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
801040a8:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
801040af:	00 
801040b0:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801040b7:	e8 af fe ff ff       	call   80103f6b <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
801040bc:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801040c3:	00 
801040c4:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801040cb:	e8 9b fe ff ff       	call   80103f6b <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
801040d0:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
801040d7:	00 
801040d8:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801040df:	e8 87 fe ff ff       	call   80103f6b <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
801040e4:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801040eb:	00 
801040ec:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801040f3:	e8 73 fe ff ff       	call   80103f6b <outb>

  outb(IO_PIC2, 0x68);             // OCW3
801040f8:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
801040ff:	00 
80104100:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104107:	e8 5f fe ff ff       	call   80103f6b <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
8010410c:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104113:	00 
80104114:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010411b:	e8 4b fe ff ff       	call   80103f6b <outb>

  if(irqmask != 0xFFFF)
80104120:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104127:	66 83 f8 ff          	cmp    $0xffff,%ax
8010412b:	74 12                	je     8010413f <picinit+0x13d>
    picsetmask(irqmask);
8010412d:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104134:	0f b7 c0             	movzwl %ax,%eax
80104137:	89 04 24             	mov    %eax,(%esp)
8010413a:	e8 4a fe ff ff       	call   80103f89 <picsetmask>
}
8010413f:	c9                   	leave  
80104140:	c3                   	ret    

80104141 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80104141:	55                   	push   %ebp
80104142:	89 e5                	mov    %esp,%ebp
80104144:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80104147:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
8010414e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104151:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80104157:	8b 45 0c             	mov    0xc(%ebp),%eax
8010415a:	8b 10                	mov    (%eax),%edx
8010415c:	8b 45 08             	mov    0x8(%ebp),%eax
8010415f:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80104161:	e8 c0 ce ff ff       	call   80101026 <filealloc>
80104166:	8b 55 08             	mov    0x8(%ebp),%edx
80104169:	89 02                	mov    %eax,(%edx)
8010416b:	8b 45 08             	mov    0x8(%ebp),%eax
8010416e:	8b 00                	mov    (%eax),%eax
80104170:	85 c0                	test   %eax,%eax
80104172:	0f 84 c8 00 00 00    	je     80104240 <pipealloc+0xff>
80104178:	e8 a9 ce ff ff       	call   80101026 <filealloc>
8010417d:	8b 55 0c             	mov    0xc(%ebp),%edx
80104180:	89 02                	mov    %eax,(%edx)
80104182:	8b 45 0c             	mov    0xc(%ebp),%eax
80104185:	8b 00                	mov    (%eax),%eax
80104187:	85 c0                	test   %eax,%eax
80104189:	0f 84 b1 00 00 00    	je     80104240 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
8010418f:	e8 69 eb ff ff       	call   80102cfd <kalloc>
80104194:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104197:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010419b:	75 05                	jne    801041a2 <pipealloc+0x61>
    goto bad;
8010419d:	e9 9e 00 00 00       	jmp    80104240 <pipealloc+0xff>
  p->readopen = 1;
801041a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041a5:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
801041ac:	00 00 00 
  p->writeopen = 1;
801041af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041b2:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
801041b9:	00 00 00 
  p->nwrite = 0;
801041bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041bf:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
801041c6:	00 00 00 
  p->nread = 0;
801041c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041cc:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
801041d3:	00 00 00 
  initlock(&p->lock, "pipe");
801041d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041d9:	c7 44 24 04 84 97 10 	movl   $0x80109784,0x4(%esp)
801041e0:	80 
801041e1:	89 04 24             	mov    %eax,(%esp)
801041e4:	e8 79 1c 00 00       	call   80105e62 <initlock>
  (*f0)->type = FD_PIPE;
801041e9:	8b 45 08             	mov    0x8(%ebp),%eax
801041ec:	8b 00                	mov    (%eax),%eax
801041ee:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
801041f4:	8b 45 08             	mov    0x8(%ebp),%eax
801041f7:	8b 00                	mov    (%eax),%eax
801041f9:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
801041fd:	8b 45 08             	mov    0x8(%ebp),%eax
80104200:	8b 00                	mov    (%eax),%eax
80104202:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80104206:	8b 45 08             	mov    0x8(%ebp),%eax
80104209:	8b 00                	mov    (%eax),%eax
8010420b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010420e:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80104211:	8b 45 0c             	mov    0xc(%ebp),%eax
80104214:	8b 00                	mov    (%eax),%eax
80104216:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
8010421c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010421f:	8b 00                	mov    (%eax),%eax
80104221:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80104225:	8b 45 0c             	mov    0xc(%ebp),%eax
80104228:	8b 00                	mov    (%eax),%eax
8010422a:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
8010422e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104231:	8b 00                	mov    (%eax),%eax
80104233:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104236:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80104239:	b8 00 00 00 00       	mov    $0x0,%eax
8010423e:	eb 42                	jmp    80104282 <pipealloc+0x141>

//PAGEBREAK: 20
 bad:
  if(p)
80104240:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104244:	74 0b                	je     80104251 <pipealloc+0x110>
    kfree((char*)p);
80104246:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104249:	89 04 24             	mov    %eax,(%esp)
8010424c:	e8 13 ea ff ff       	call   80102c64 <kfree>
  if(*f0)
80104251:	8b 45 08             	mov    0x8(%ebp),%eax
80104254:	8b 00                	mov    (%eax),%eax
80104256:	85 c0                	test   %eax,%eax
80104258:	74 0d                	je     80104267 <pipealloc+0x126>
    fileclose(*f0);
8010425a:	8b 45 08             	mov    0x8(%ebp),%eax
8010425d:	8b 00                	mov    (%eax),%eax
8010425f:	89 04 24             	mov    %eax,(%esp)
80104262:	e8 67 ce ff ff       	call   801010ce <fileclose>
  if(*f1)
80104267:	8b 45 0c             	mov    0xc(%ebp),%eax
8010426a:	8b 00                	mov    (%eax),%eax
8010426c:	85 c0                	test   %eax,%eax
8010426e:	74 0d                	je     8010427d <pipealloc+0x13c>
    fileclose(*f1);
80104270:	8b 45 0c             	mov    0xc(%ebp),%eax
80104273:	8b 00                	mov    (%eax),%eax
80104275:	89 04 24             	mov    %eax,(%esp)
80104278:	e8 51 ce ff ff       	call   801010ce <fileclose>
  return -1;
8010427d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104282:	c9                   	leave  
80104283:	c3                   	ret    

80104284 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80104284:	55                   	push   %ebp
80104285:	89 e5                	mov    %esp,%ebp
80104287:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
8010428a:	8b 45 08             	mov    0x8(%ebp),%eax
8010428d:	89 04 24             	mov    %eax,(%esp)
80104290:	e8 ee 1b 00 00       	call   80105e83 <acquire>
  if(writable){
80104295:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104299:	74 1f                	je     801042ba <pipeclose+0x36>
    p->writeopen = 0;
8010429b:	8b 45 08             	mov    0x8(%ebp),%eax
8010429e:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
801042a5:	00 00 00 
    wakeup(&p->nread);
801042a8:	8b 45 08             	mov    0x8(%ebp),%eax
801042ab:	05 34 02 00 00       	add    $0x234,%eax
801042b0:	89 04 24             	mov    %eax,(%esp)
801042b3:	e8 c6 0c 00 00       	call   80104f7e <wakeup>
801042b8:	eb 1d                	jmp    801042d7 <pipeclose+0x53>
  } else {
    p->readopen = 0;
801042ba:	8b 45 08             	mov    0x8(%ebp),%eax
801042bd:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
801042c4:	00 00 00 
    wakeup(&p->nwrite);
801042c7:	8b 45 08             	mov    0x8(%ebp),%eax
801042ca:	05 38 02 00 00       	add    $0x238,%eax
801042cf:	89 04 24             	mov    %eax,(%esp)
801042d2:	e8 a7 0c 00 00       	call   80104f7e <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
801042d7:	8b 45 08             	mov    0x8(%ebp),%eax
801042da:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801042e0:	85 c0                	test   %eax,%eax
801042e2:	75 25                	jne    80104309 <pipeclose+0x85>
801042e4:	8b 45 08             	mov    0x8(%ebp),%eax
801042e7:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801042ed:	85 c0                	test   %eax,%eax
801042ef:	75 18                	jne    80104309 <pipeclose+0x85>
    release(&p->lock);
801042f1:	8b 45 08             	mov    0x8(%ebp),%eax
801042f4:	89 04 24             	mov    %eax,(%esp)
801042f7:	e8 e9 1b 00 00       	call   80105ee5 <release>
    kfree((char*)p);
801042fc:	8b 45 08             	mov    0x8(%ebp),%eax
801042ff:	89 04 24             	mov    %eax,(%esp)
80104302:	e8 5d e9 ff ff       	call   80102c64 <kfree>
80104307:	eb 0b                	jmp    80104314 <pipeclose+0x90>
  } else
    release(&p->lock);
80104309:	8b 45 08             	mov    0x8(%ebp),%eax
8010430c:	89 04 24             	mov    %eax,(%esp)
8010430f:	e8 d1 1b 00 00       	call   80105ee5 <release>
}
80104314:	c9                   	leave  
80104315:	c3                   	ret    

80104316 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80104316:	55                   	push   %ebp
80104317:	89 e5                	mov    %esp,%ebp
80104319:	83 ec 28             	sub    $0x28,%esp
  int i;

  acquire(&p->lock);
8010431c:	8b 45 08             	mov    0x8(%ebp),%eax
8010431f:	89 04 24             	mov    %eax,(%esp)
80104322:	e8 5c 1b 00 00       	call   80105e83 <acquire>
  for(i = 0; i < n; i++){
80104327:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010432e:	e9 a6 00 00 00       	jmp    801043d9 <pipewrite+0xc3>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104333:	eb 57                	jmp    8010438c <pipewrite+0x76>
      if(p->readopen == 0 || proc->killed){
80104335:	8b 45 08             	mov    0x8(%ebp),%eax
80104338:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
8010433e:	85 c0                	test   %eax,%eax
80104340:	74 0d                	je     8010434f <pipewrite+0x39>
80104342:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104348:	8b 40 24             	mov    0x24(%eax),%eax
8010434b:	85 c0                	test   %eax,%eax
8010434d:	74 15                	je     80104364 <pipewrite+0x4e>
        release(&p->lock);
8010434f:	8b 45 08             	mov    0x8(%ebp),%eax
80104352:	89 04 24             	mov    %eax,(%esp)
80104355:	e8 8b 1b 00 00       	call   80105ee5 <release>
        return -1;
8010435a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010435f:	e9 9f 00 00 00       	jmp    80104403 <pipewrite+0xed>
      }
      wakeup(&p->nread);
80104364:	8b 45 08             	mov    0x8(%ebp),%eax
80104367:	05 34 02 00 00       	add    $0x234,%eax
8010436c:	89 04 24             	mov    %eax,(%esp)
8010436f:	e8 0a 0c 00 00       	call   80104f7e <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80104374:	8b 45 08             	mov    0x8(%ebp),%eax
80104377:	8b 55 08             	mov    0x8(%ebp),%edx
8010437a:	81 c2 38 02 00 00    	add    $0x238,%edx
80104380:	89 44 24 04          	mov    %eax,0x4(%esp)
80104384:	89 14 24             	mov    %edx,(%esp)
80104387:	e8 16 0b 00 00       	call   80104ea2 <sleep>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
8010438c:	8b 45 08             	mov    0x8(%ebp),%eax
8010438f:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80104395:	8b 45 08             	mov    0x8(%ebp),%eax
80104398:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
8010439e:	05 00 02 00 00       	add    $0x200,%eax
801043a3:	39 c2                	cmp    %eax,%edx
801043a5:	74 8e                	je     80104335 <pipewrite+0x1f>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
801043a7:	8b 45 08             	mov    0x8(%ebp),%eax
801043aa:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801043b0:	8d 48 01             	lea    0x1(%eax),%ecx
801043b3:	8b 55 08             	mov    0x8(%ebp),%edx
801043b6:	89 8a 38 02 00 00    	mov    %ecx,0x238(%edx)
801043bc:	25 ff 01 00 00       	and    $0x1ff,%eax
801043c1:	89 c1                	mov    %eax,%ecx
801043c3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801043c6:	8b 45 0c             	mov    0xc(%ebp),%eax
801043c9:	01 d0                	add    %edx,%eax
801043cb:	0f b6 10             	movzbl (%eax),%edx
801043ce:	8b 45 08             	mov    0x8(%ebp),%eax
801043d1:	88 54 08 34          	mov    %dl,0x34(%eax,%ecx,1)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
801043d5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801043d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043dc:	3b 45 10             	cmp    0x10(%ebp),%eax
801043df:	0f 8c 4e ff ff ff    	jl     80104333 <pipewrite+0x1d>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
801043e5:	8b 45 08             	mov    0x8(%ebp),%eax
801043e8:	05 34 02 00 00       	add    $0x234,%eax
801043ed:	89 04 24             	mov    %eax,(%esp)
801043f0:	e8 89 0b 00 00       	call   80104f7e <wakeup>
  release(&p->lock);
801043f5:	8b 45 08             	mov    0x8(%ebp),%eax
801043f8:	89 04 24             	mov    %eax,(%esp)
801043fb:	e8 e5 1a 00 00       	call   80105ee5 <release>
  return n;
80104400:	8b 45 10             	mov    0x10(%ebp),%eax
}
80104403:	c9                   	leave  
80104404:	c3                   	ret    

80104405 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80104405:	55                   	push   %ebp
80104406:	89 e5                	mov    %esp,%ebp
80104408:	53                   	push   %ebx
80104409:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
8010440c:	8b 45 08             	mov    0x8(%ebp),%eax
8010440f:	89 04 24             	mov    %eax,(%esp)
80104412:	e8 6c 1a 00 00       	call   80105e83 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104417:	eb 3a                	jmp    80104453 <piperead+0x4e>
    if(proc->killed){
80104419:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010441f:	8b 40 24             	mov    0x24(%eax),%eax
80104422:	85 c0                	test   %eax,%eax
80104424:	74 15                	je     8010443b <piperead+0x36>
      release(&p->lock);
80104426:	8b 45 08             	mov    0x8(%ebp),%eax
80104429:	89 04 24             	mov    %eax,(%esp)
8010442c:	e8 b4 1a 00 00       	call   80105ee5 <release>
      return -1;
80104431:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104436:	e9 b5 00 00 00       	jmp    801044f0 <piperead+0xeb>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
8010443b:	8b 45 08             	mov    0x8(%ebp),%eax
8010443e:	8b 55 08             	mov    0x8(%ebp),%edx
80104441:	81 c2 34 02 00 00    	add    $0x234,%edx
80104447:	89 44 24 04          	mov    %eax,0x4(%esp)
8010444b:	89 14 24             	mov    %edx,(%esp)
8010444e:	e8 4f 0a 00 00       	call   80104ea2 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104453:	8b 45 08             	mov    0x8(%ebp),%eax
80104456:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
8010445c:	8b 45 08             	mov    0x8(%ebp),%eax
8010445f:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104465:	39 c2                	cmp    %eax,%edx
80104467:	75 0d                	jne    80104476 <piperead+0x71>
80104469:	8b 45 08             	mov    0x8(%ebp),%eax
8010446c:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104472:	85 c0                	test   %eax,%eax
80104474:	75 a3                	jne    80104419 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104476:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010447d:	eb 4b                	jmp    801044ca <piperead+0xc5>
    if(p->nread == p->nwrite)
8010447f:	8b 45 08             	mov    0x8(%ebp),%eax
80104482:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104488:	8b 45 08             	mov    0x8(%ebp),%eax
8010448b:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104491:	39 c2                	cmp    %eax,%edx
80104493:	75 02                	jne    80104497 <piperead+0x92>
      break;
80104495:	eb 3b                	jmp    801044d2 <piperead+0xcd>
    addr[i] = p->data[p->nread++ % PIPESIZE];
80104497:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010449a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010449d:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
801044a0:	8b 45 08             	mov    0x8(%ebp),%eax
801044a3:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801044a9:	8d 48 01             	lea    0x1(%eax),%ecx
801044ac:	8b 55 08             	mov    0x8(%ebp),%edx
801044af:	89 8a 34 02 00 00    	mov    %ecx,0x234(%edx)
801044b5:	25 ff 01 00 00       	and    $0x1ff,%eax
801044ba:	89 c2                	mov    %eax,%edx
801044bc:	8b 45 08             	mov    0x8(%ebp),%eax
801044bf:	0f b6 44 10 34       	movzbl 0x34(%eax,%edx,1),%eax
801044c4:	88 03                	mov    %al,(%ebx)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801044c6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801044ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044cd:	3b 45 10             	cmp    0x10(%ebp),%eax
801044d0:	7c ad                	jl     8010447f <piperead+0x7a>
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
801044d2:	8b 45 08             	mov    0x8(%ebp),%eax
801044d5:	05 38 02 00 00       	add    $0x238,%eax
801044da:	89 04 24             	mov    %eax,(%esp)
801044dd:	e8 9c 0a 00 00       	call   80104f7e <wakeup>
  release(&p->lock);
801044e2:	8b 45 08             	mov    0x8(%ebp),%eax
801044e5:	89 04 24             	mov    %eax,(%esp)
801044e8:	e8 f8 19 00 00       	call   80105ee5 <release>
  return i;
801044ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801044f0:	83 c4 24             	add    $0x24,%esp
801044f3:	5b                   	pop    %ebx
801044f4:	5d                   	pop    %ebp
801044f5:	c3                   	ret    

801044f6 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801044f6:	55                   	push   %ebp
801044f7:	89 e5                	mov    %esp,%ebp
801044f9:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801044fc:	9c                   	pushf  
801044fd:	58                   	pop    %eax
801044fe:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80104501:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104504:	c9                   	leave  
80104505:	c3                   	ret    

80104506 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104506:	55                   	push   %ebp
80104507:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104509:	fb                   	sti    
}
8010450a:	5d                   	pop    %ebp
8010450b:	c3                   	ret    

8010450c <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
8010450c:	55                   	push   %ebp
8010450d:	89 e5                	mov    %esp,%ebp
8010450f:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104512:	c7 44 24 04 89 97 10 	movl   $0x80109789,0x4(%esp)
80104519:	80 
8010451a:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104521:	e8 3c 19 00 00       	call   80105e62 <initlock>
}
80104526:	c9                   	leave  
80104527:	c3                   	ret    

80104528 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104528:	55                   	push   %ebp
80104529:	89 e5                	mov    %esp,%ebp
8010452b:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
8010452e:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104535:	e8 49 19 00 00       	call   80105e83 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010453a:	c7 45 f4 d4 39 11 80 	movl   $0x801139d4,-0xc(%ebp)
80104541:	eb 53                	jmp    80104596 <allocproc+0x6e>
    if(p->state == UNUSED)
80104543:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104546:	8b 40 0c             	mov    0xc(%eax),%eax
80104549:	85 c0                	test   %eax,%eax
8010454b:	75 42                	jne    8010458f <allocproc+0x67>
      goto found;
8010454d:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
8010454e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104551:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
80104558:	a1 04 c0 10 80       	mov    0x8010c004,%eax
8010455d:	8d 50 01             	lea    0x1(%eax),%edx
80104560:	89 15 04 c0 10 80    	mov    %edx,0x8010c004
80104566:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104569:	89 42 10             	mov    %eax,0x10(%edx)
  release(&ptable.lock);
8010456c:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104573:	e8 6d 19 00 00       	call   80105ee5 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
80104578:	e8 80 e7 ff ff       	call   80102cfd <kalloc>
8010457d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104580:	89 42 08             	mov    %eax,0x8(%edx)
80104583:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104586:	8b 40 08             	mov    0x8(%eax),%eax
80104589:	85 c0                	test   %eax,%eax
8010458b:	75 36                	jne    801045c3 <allocproc+0x9b>
8010458d:	eb 23                	jmp    801045b2 <allocproc+0x8a>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010458f:	81 45 f4 cc 04 00 00 	addl   $0x4cc,-0xc(%ebp)
80104596:	81 7d f4 d4 6c 12 80 	cmpl   $0x80126cd4,-0xc(%ebp)
8010459d:	72 a4                	jb     80104543 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
8010459f:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
801045a6:	e8 3a 19 00 00       	call   80105ee5 <release>
  return 0;
801045ab:	b8 00 00 00 00       	mov    $0x0,%eax
801045b0:	eb 76                	jmp    80104628 <allocproc+0x100>
  p->pid = nextpid++;
  release(&ptable.lock);

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
    p->state = UNUSED;
801045b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045b5:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
801045bc:	b8 00 00 00 00       	mov    $0x0,%eax
801045c1:	eb 65                	jmp    80104628 <allocproc+0x100>
  }
  sp = p->kstack + KSTACKSIZE;
801045c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045c6:	8b 40 08             	mov    0x8(%eax),%eax
801045c9:	05 00 10 00 00       	add    $0x1000,%eax
801045ce:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
801045d1:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
801045d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045d8:	8b 55 f0             	mov    -0x10(%ebp),%edx
801045db:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
801045de:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
801045e2:	ba 51 75 10 80       	mov    $0x80107551,%edx
801045e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801045ea:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
801045ec:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
801045f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045f3:	8b 55 f0             	mov    -0x10(%ebp),%edx
801045f6:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
801045f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045fc:	8b 40 1c             	mov    0x1c(%eax),%eax
801045ff:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104606:	00 
80104607:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010460e:	00 
8010460f:	89 04 24             	mov    %eax,(%esp)
80104612:	e8 c0 1a 00 00       	call   801060d7 <memset>
  p->context->eip = (uint)forkret;
80104617:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010461a:	8b 40 1c             	mov    0x1c(%eax),%eax
8010461d:	ba 76 4e 10 80       	mov    $0x80104e76,%edx
80104622:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
80104625:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104628:	c9                   	leave  
80104629:	c3                   	ret    

8010462a <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
8010462a:	55                   	push   %ebp
8010462b:	89 e5                	mov    %esp,%ebp
8010462d:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int i;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104630:	e8 f3 fe ff ff       	call   80104528 <allocproc>
80104635:	89 45 f0             	mov    %eax,-0x10(%ebp)
  initproc = p;
80104638:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010463b:	a3 48 c6 10 80       	mov    %eax,0x8010c648
  if((p->pgdir = setupkvm()) == 0)
80104640:	e8 00 46 00 00       	call   80108c45 <setupkvm>
80104645:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104648:	89 42 04             	mov    %eax,0x4(%edx)
8010464b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010464e:	8b 40 04             	mov    0x4(%eax),%eax
80104651:	85 c0                	test   %eax,%eax
80104653:	75 0c                	jne    80104661 <userinit+0x37>
    panic("userinit: out of memory?");
80104655:	c7 04 24 90 97 10 80 	movl   $0x80109790,(%esp)
8010465c:	e8 d9 be ff ff       	call   8010053a <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104661:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104666:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104669:	8b 40 04             	mov    0x4(%eax),%eax
8010466c:	89 54 24 08          	mov    %edx,0x8(%esp)
80104670:	c7 44 24 04 e0 c4 10 	movl   $0x8010c4e0,0x4(%esp)
80104677:	80 
80104678:	89 04 24             	mov    %eax,(%esp)
8010467b:	e8 1d 48 00 00       	call   80108e9d <inituvm>
  p->sz = PGSIZE;
80104680:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104683:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80104689:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010468c:	8b 40 18             	mov    0x18(%eax),%eax
8010468f:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104696:	00 
80104697:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010469e:	00 
8010469f:	89 04 24             	mov    %eax,(%esp)
801046a2:	e8 30 1a 00 00       	call   801060d7 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801046a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801046aa:	8b 40 18             	mov    0x18(%eax),%eax
801046ad:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801046b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801046b6:	8b 40 18             	mov    0x18(%eax),%eax
801046b9:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
801046bf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801046c2:	8b 40 18             	mov    0x18(%eax),%eax
801046c5:	8b 55 f0             	mov    -0x10(%ebp),%edx
801046c8:	8b 52 18             	mov    0x18(%edx),%edx
801046cb:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801046cf:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801046d3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801046d6:	8b 40 18             	mov    0x18(%eax),%eax
801046d9:	8b 55 f0             	mov    -0x10(%ebp),%edx
801046dc:	8b 52 18             	mov    0x18(%edx),%edx
801046df:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801046e3:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801046e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801046ea:	8b 40 18             	mov    0x18(%eax),%eax
801046ed:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801046f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801046f7:	8b 40 18             	mov    0x18(%eax),%eax
801046fa:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104701:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104704:	8b 40 18             	mov    0x18(%eax),%eax
80104707:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
8010470e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104711:	83 c0 28             	add    $0x28,%eax
80104714:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010471b:	00 
8010471c:	c7 44 24 04 a9 97 10 	movl   $0x801097a9,0x4(%esp)
80104723:	80 
80104724:	89 04 24             	mov    %eax,(%esp)
80104727:	e8 cb 1b 00 00       	call   801062f7 <safestrcpy>
  p->cwd = namei("/");
8010472c:	c7 04 24 b2 97 10 80 	movl   $0x801097b2,(%esp)
80104733:	e8 e9 de ff ff       	call   80102621 <namei>
80104738:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010473b:	89 42 78             	mov    %eax,0x78(%edx)
  p->exe=0;
8010473e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104741:	c7 40 7c 00 00 00 00 	movl   $0x0,0x7c(%eax)

  p->cmdline[0]= '\0';
80104748:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010474b:	c6 80 80 00 00 00 00 	movb   $0x0,0x80(%eax)
  for (i=0; i < MAXARGS; i++)
80104752:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104759:	eb 18                	jmp    80104773 <userinit+0x149>
      p->args[i][0]='\0';
8010475b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010475e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104761:	6b c0 64             	imul   $0x64,%eax,%eax
80104764:	01 d0                	add    %edx,%eax
80104766:	05 e0 00 00 00       	add    $0xe0,%eax
8010476b:	c6 40 04 00          	movb   $0x0,0x4(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");
  p->exe=0;

  p->cmdline[0]= '\0';
  for (i=0; i < MAXARGS; i++)
8010476f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104773:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80104777:	7e e2                	jle    8010475b <userinit+0x131>
      p->args[i][0]='\0';

  p->state = RUNNABLE;
80104779:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010477c:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
80104783:	c9                   	leave  
80104784:	c3                   	ret    

80104785 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104785:	55                   	push   %ebp
80104786:	89 e5                	mov    %esp,%ebp
80104788:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
8010478b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104791:	8b 00                	mov    (%eax),%eax
80104793:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104796:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010479a:	7e 34                	jle    801047d0 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
8010479c:	8b 55 08             	mov    0x8(%ebp),%edx
8010479f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047a2:	01 c2                	add    %eax,%edx
801047a4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047aa:	8b 40 04             	mov    0x4(%eax),%eax
801047ad:	89 54 24 08          	mov    %edx,0x8(%esp)
801047b1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801047b4:	89 54 24 04          	mov    %edx,0x4(%esp)
801047b8:	89 04 24             	mov    %eax,(%esp)
801047bb:	e8 53 48 00 00       	call   80109013 <allocuvm>
801047c0:	89 45 f4             	mov    %eax,-0xc(%ebp)
801047c3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801047c7:	75 41                	jne    8010480a <growproc+0x85>
      return -1;
801047c9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047ce:	eb 58                	jmp    80104828 <growproc+0xa3>
  } else if(n < 0){
801047d0:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801047d4:	79 34                	jns    8010480a <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
801047d6:	8b 55 08             	mov    0x8(%ebp),%edx
801047d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047dc:	01 c2                	add    %eax,%edx
801047de:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047e4:	8b 40 04             	mov    0x4(%eax),%eax
801047e7:	89 54 24 08          	mov    %edx,0x8(%esp)
801047eb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801047ee:	89 54 24 04          	mov    %edx,0x4(%esp)
801047f2:	89 04 24             	mov    %eax,(%esp)
801047f5:	e8 f3 48 00 00       	call   801090ed <deallocuvm>
801047fa:	89 45 f4             	mov    %eax,-0xc(%ebp)
801047fd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104801:	75 07                	jne    8010480a <growproc+0x85>
      return -1;
80104803:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104808:	eb 1e                	jmp    80104828 <growproc+0xa3>
  }
  proc->sz = sz;
8010480a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104810:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104813:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104815:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010481b:	89 04 24             	mov    %eax,(%esp)
8010481e:	e8 13 45 00 00       	call   80108d36 <switchuvm>
  return 0;
80104823:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104828:	c9                   	leave  
80104829:	c3                   	ret    

8010482a <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
8010482a:	55                   	push   %ebp
8010482b:	89 e5                	mov    %esp,%ebp
8010482d:	57                   	push   %edi
8010482e:	56                   	push   %esi
8010482f:	53                   	push   %ebx
80104830:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104833:	e8 f0 fc ff ff       	call   80104528 <allocproc>
80104838:	89 45 e0             	mov    %eax,-0x20(%ebp)
8010483b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
8010483f:	75 0a                	jne    8010484b <fork+0x21>
    return -1;
80104841:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104846:	e9 4f 02 00 00       	jmp    80104a9a <fork+0x270>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
8010484b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104851:	8b 10                	mov    (%eax),%edx
80104853:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104859:	8b 40 04             	mov    0x4(%eax),%eax
8010485c:	89 54 24 04          	mov    %edx,0x4(%esp)
80104860:	89 04 24             	mov    %eax,(%esp)
80104863:	e8 21 4a 00 00       	call   80109289 <copyuvm>
80104868:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010486b:	89 42 04             	mov    %eax,0x4(%edx)
8010486e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104871:	8b 40 04             	mov    0x4(%eax),%eax
80104874:	85 c0                	test   %eax,%eax
80104876:	75 2c                	jne    801048a4 <fork+0x7a>
    kfree(np->kstack);
80104878:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010487b:	8b 40 08             	mov    0x8(%eax),%eax
8010487e:	89 04 24             	mov    %eax,(%esp)
80104881:	e8 de e3 ff ff       	call   80102c64 <kfree>
    np->kstack = 0;
80104886:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104889:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104890:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104893:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
8010489a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010489f:	e9 f6 01 00 00       	jmp    80104a9a <fork+0x270>
  }
  np->sz = proc->sz;
801048a4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048aa:	8b 10                	mov    (%eax),%edx
801048ac:	8b 45 e0             	mov    -0x20(%ebp),%eax
801048af:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
801048b1:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801048b8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801048bb:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
801048be:	8b 45 e0             	mov    -0x20(%ebp),%eax
801048c1:	8b 50 18             	mov    0x18(%eax),%edx
801048c4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048ca:	8b 40 18             	mov    0x18(%eax),%eax
801048cd:	89 c3                	mov    %eax,%ebx
801048cf:	b8 13 00 00 00       	mov    $0x13,%eax
801048d4:	89 d7                	mov    %edx,%edi
801048d6:	89 de                	mov    %ebx,%esi
801048d8:	89 c1                	mov    %eax,%ecx
801048da:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
801048dc:	8b 45 e0             	mov    -0x20(%ebp),%eax
801048df:	8b 40 18             	mov    0x18(%eax),%eax
801048e2:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
801048e9:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801048f0:	eb 3d                	jmp    8010492f <fork+0x105>
    if(proc->ofile[i])
801048f2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048f8:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801048fb:	83 c2 0c             	add    $0xc,%edx
801048fe:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104902:	85 c0                	test   %eax,%eax
80104904:	74 25                	je     8010492b <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
80104906:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010490c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010490f:	83 c2 0c             	add    $0xc,%edx
80104912:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104916:	89 04 24             	mov    %eax,(%esp)
80104919:	e8 68 c7 ff ff       	call   80101086 <filedup>
8010491e:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104921:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80104924:	83 c1 0c             	add    $0xc,%ecx
80104927:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
8010492b:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
8010492f:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104933:	7e bd                	jle    801048f2 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
80104935:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010493b:	8b 40 78             	mov    0x78(%eax),%eax
8010493e:	89 04 24             	mov    %eax,(%esp)
80104941:	e8 e3 cf ff ff       	call   80101929 <idup>
80104946:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104949:	89 42 78             	mov    %eax,0x78(%edx)

  safestrcpy(np->name, proc->name, sizeof(proc->name));
8010494c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104952:	8d 50 28             	lea    0x28(%eax),%edx
80104955:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104958:	83 c0 28             	add    $0x28,%eax
8010495b:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104962:	00 
80104963:	89 54 24 04          	mov    %edx,0x4(%esp)
80104967:	89 04 24             	mov    %eax,(%esp)
8010496a:	e8 88 19 00 00       	call   801062f7 <safestrcpy>
 
  pid = np->pid;
8010496f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104972:	8b 40 10             	mov    0x10(%eax),%eax
80104975:	89 45 dc             	mov    %eax,-0x24(%ebp)

  begin_op();
80104978:	e8 ae ec ff ff       	call   8010362b <begin_op>
  np->exe = namei(proc->cmdline);
8010497d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104983:	83 e8 80             	sub    $0xffffff80,%eax
80104986:	89 04 24             	mov    %eax,(%esp)
80104989:	e8 93 dc ff ff       	call   80102621 <namei>
8010498e:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104991:	89 42 7c             	mov    %eax,0x7c(%edx)
  end_op();
80104994:	e8 16 ed ff ff       	call   801036af <end_op>
  safestrcpy(np->cmdline, proc->cmdline, strlen(proc->cmdline));
80104999:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010499f:	83 e8 80             	sub    $0xffffff80,%eax
801049a2:	89 04 24             	mov    %eax,(%esp)
801049a5:	e8 97 19 00 00       	call   80106341 <strlen>
801049aa:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801049b1:	8d 8a 80 00 00 00    	lea    0x80(%edx),%ecx
801049b7:	8b 55 e0             	mov    -0x20(%ebp),%edx
801049ba:	83 ea 80             	sub    $0xffffff80,%edx
801049bd:	89 44 24 08          	mov    %eax,0x8(%esp)
801049c1:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801049c5:	89 14 24             	mov    %edx,(%esp)
801049c8:	e8 2a 19 00 00       	call   801062f7 <safestrcpy>

  for (i=0; i < MAXARGS; i++)  {
801049cd:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801049d4:	e9 92 00 00 00       	jmp    80104a6b <fork+0x241>
  	  if (proc->args[i])
801049d9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049df:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801049e2:	6b d2 64             	imul   $0x64,%edx,%edx
801049e5:	81 c2 e0 00 00 00    	add    $0xe0,%edx
801049eb:	01 d0                	add    %edx,%eax
801049ed:	83 c0 04             	add    $0x4,%eax
801049f0:	85 c0                	test   %eax,%eax
801049f2:	74 5f                	je     80104a53 <fork+0x229>
  		  safestrcpy(np->args[i], proc->args[i], strlen(proc->args[i])+1);
801049f4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049fa:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801049fd:	6b d2 64             	imul   $0x64,%edx,%edx
80104a00:	81 c2 e0 00 00 00    	add    $0xe0,%edx
80104a06:	01 d0                	add    %edx,%eax
80104a08:	83 c0 04             	add    $0x4,%eax
80104a0b:	89 04 24             	mov    %eax,(%esp)
80104a0e:	e8 2e 19 00 00       	call   80106341 <strlen>
80104a13:	8d 48 01             	lea    0x1(%eax),%ecx
80104a16:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a1c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104a1f:	6b d2 64             	imul   $0x64,%edx,%edx
80104a22:	81 c2 e0 00 00 00    	add    $0xe0,%edx
80104a28:	01 d0                	add    %edx,%eax
80104a2a:	8d 50 04             	lea    0x4(%eax),%edx
80104a2d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104a30:	6b c0 64             	imul   $0x64,%eax,%eax
80104a33:	8d 98 e0 00 00 00    	lea    0xe0(%eax),%ebx
80104a39:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104a3c:	01 d8                	add    %ebx,%eax
80104a3e:	83 c0 04             	add    $0x4,%eax
80104a41:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80104a45:	89 54 24 04          	mov    %edx,0x4(%esp)
80104a49:	89 04 24             	mov    %eax,(%esp)
80104a4c:	e8 a6 18 00 00       	call   801062f7 <safestrcpy>
80104a51:	eb 14                	jmp    80104a67 <fork+0x23d>
  	  else np->args[i][0]='\0';
80104a53:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104a56:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104a59:	6b c0 64             	imul   $0x64,%eax,%eax
80104a5c:	01 d0                	add    %edx,%eax
80104a5e:	05 e0 00 00 00       	add    $0xe0,%eax
80104a63:	c6 40 04 00          	movb   $0x0,0x4(%eax)
  begin_op();
  np->exe = namei(proc->cmdline);
  end_op();
  safestrcpy(np->cmdline, proc->cmdline, strlen(proc->cmdline));

  for (i=0; i < MAXARGS; i++)  {
80104a67:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104a6b:	83 7d e4 09          	cmpl   $0x9,-0x1c(%ebp)
80104a6f:	0f 8e 64 ff ff ff    	jle    801049d9 <fork+0x1af>
  		  safestrcpy(np->args[i], proc->args[i], strlen(proc->args[i])+1);
  	  else np->args[i][0]='\0';
  }

  // lock to force the compiler to emit the np->state write last.
  acquire(&ptable.lock);
80104a75:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104a7c:	e8 02 14 00 00       	call   80105e83 <acquire>
  np->state = RUNNABLE;
80104a81:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104a84:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)

  release(&ptable.lock);
80104a8b:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104a92:	e8 4e 14 00 00       	call   80105ee5 <release>
  
  return pid;
80104a97:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
80104a9a:	83 c4 2c             	add    $0x2c,%esp
80104a9d:	5b                   	pop    %ebx
80104a9e:	5e                   	pop    %esi
80104a9f:	5f                   	pop    %edi
80104aa0:	5d                   	pop    %ebp
80104aa1:	c3                   	ret    

80104aa2 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80104aa2:	55                   	push   %ebp
80104aa3:	89 e5                	mov    %esp,%ebp
80104aa5:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
80104aa8:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104aaf:	a1 48 c6 10 80       	mov    0x8010c648,%eax
80104ab4:	39 c2                	cmp    %eax,%edx
80104ab6:	75 0c                	jne    80104ac4 <exit+0x22>
    panic("init exiting");
80104ab8:	c7 04 24 b4 97 10 80 	movl   $0x801097b4,(%esp)
80104abf:	e8 76 ba ff ff       	call   8010053a <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104ac4:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104acb:	eb 44                	jmp    80104b11 <exit+0x6f>
    if(proc->ofile[fd]){
80104acd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ad3:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104ad6:	83 c2 0c             	add    $0xc,%edx
80104ad9:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104add:	85 c0                	test   %eax,%eax
80104adf:	74 2c                	je     80104b0d <exit+0x6b>
      fileclose(proc->ofile[fd]);
80104ae1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ae7:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104aea:	83 c2 0c             	add    $0xc,%edx
80104aed:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104af1:	89 04 24             	mov    %eax,(%esp)
80104af4:	e8 d5 c5 ff ff       	call   801010ce <fileclose>
      proc->ofile[fd] = 0;
80104af9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104aff:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104b02:	83 c2 0c             	add    $0xc,%edx
80104b05:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104b0c:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104b0d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104b11:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104b15:	7e b6                	jle    80104acd <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  begin_op();
80104b17:	e8 0f eb ff ff       	call   8010362b <begin_op>
  iput(proc->cwd);
80104b1c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b22:	8b 40 78             	mov    0x78(%eax),%eax
80104b25:	89 04 24             	mov    %eax,(%esp)
80104b28:	e8 e1 cf ff ff       	call   80101b0e <iput>
  iput(proc->exe);
80104b2d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b33:	8b 40 7c             	mov    0x7c(%eax),%eax
80104b36:	89 04 24             	mov    %eax,(%esp)
80104b39:	e8 d0 cf ff ff       	call   80101b0e <iput>
  end_op();
80104b3e:	e8 6c eb ff ff       	call   801036af <end_op>
  proc->cwd = 0;
80104b43:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b49:	c7 40 78 00 00 00 00 	movl   $0x0,0x78(%eax)
  proc->exe = 0;
80104b50:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b56:	c7 40 7c 00 00 00 00 	movl   $0x0,0x7c(%eax)

  acquire(&ptable.lock);
80104b5d:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104b64:	e8 1a 13 00 00       	call   80105e83 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
80104b69:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b6f:	8b 40 14             	mov    0x14(%eax),%eax
80104b72:	89 04 24             	mov    %eax,(%esp)
80104b75:	e8 c3 03 00 00       	call   80104f3d <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b7a:	c7 45 f4 d4 39 11 80 	movl   $0x801139d4,-0xc(%ebp)
80104b81:	eb 3b                	jmp    80104bbe <exit+0x11c>
    if(p->parent == proc){
80104b83:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b86:	8b 50 14             	mov    0x14(%eax),%edx
80104b89:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b8f:	39 c2                	cmp    %eax,%edx
80104b91:	75 24                	jne    80104bb7 <exit+0x115>
      p->parent = initproc;
80104b93:	8b 15 48 c6 10 80    	mov    0x8010c648,%edx
80104b99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b9c:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
80104b9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ba2:	8b 40 0c             	mov    0xc(%eax),%eax
80104ba5:	83 f8 05             	cmp    $0x5,%eax
80104ba8:	75 0d                	jne    80104bb7 <exit+0x115>
        wakeup1(initproc);
80104baa:	a1 48 c6 10 80       	mov    0x8010c648,%eax
80104baf:	89 04 24             	mov    %eax,(%esp)
80104bb2:	e8 86 03 00 00       	call   80104f3d <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104bb7:	81 45 f4 cc 04 00 00 	addl   $0x4cc,-0xc(%ebp)
80104bbe:	81 7d f4 d4 6c 12 80 	cmpl   $0x80126cd4,-0xc(%ebp)
80104bc5:	72 bc                	jb     80104b83 <exit+0xe1>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
80104bc7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104bcd:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80104bd4:	e8 b9 01 00 00       	call   80104d92 <sched>
  panic("zombie exit");
80104bd9:	c7 04 24 c1 97 10 80 	movl   $0x801097c1,(%esp)
80104be0:	e8 55 b9 ff ff       	call   8010053a <panic>

80104be5 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
80104be5:	55                   	push   %ebp
80104be6:	89 e5                	mov    %esp,%ebp
80104be8:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
80104beb:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104bf2:	e8 8c 12 00 00       	call   80105e83 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
80104bf7:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104bfe:	c7 45 f4 d4 39 11 80 	movl   $0x801139d4,-0xc(%ebp)
80104c05:	e9 9d 00 00 00       	jmp    80104ca7 <wait+0xc2>
      if(p->parent != proc)
80104c0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c0d:	8b 50 14             	mov    0x14(%eax),%edx
80104c10:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c16:	39 c2                	cmp    %eax,%edx
80104c18:	74 05                	je     80104c1f <wait+0x3a>
        continue;
80104c1a:	e9 81 00 00 00       	jmp    80104ca0 <wait+0xbb>
      havekids = 1;
80104c1f:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80104c26:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c29:	8b 40 0c             	mov    0xc(%eax),%eax
80104c2c:	83 f8 05             	cmp    $0x5,%eax
80104c2f:	75 6f                	jne    80104ca0 <wait+0xbb>
        // Found one.
        pid = p->pid;
80104c31:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c34:	8b 40 10             	mov    0x10(%eax),%eax
80104c37:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80104c3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c3d:	8b 40 08             	mov    0x8(%eax),%eax
80104c40:	89 04 24             	mov    %eax,(%esp)
80104c43:	e8 1c e0 ff ff       	call   80102c64 <kfree>
        p->kstack = 0;
80104c48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c4b:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80104c52:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c55:	8b 40 04             	mov    0x4(%eax),%eax
80104c58:	89 04 24             	mov    %eax,(%esp)
80104c5b:	e8 49 45 00 00       	call   801091a9 <freevm>
        p->state = UNUSED;
80104c60:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c63:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80104c6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c6d:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80104c74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c77:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80104c7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c81:	c6 40 28 00          	movb   $0x0,0x28(%eax)
        p->killed = 0;
80104c85:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c88:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
80104c8f:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104c96:	e8 4a 12 00 00       	call   80105ee5 <release>
        return pid;
80104c9b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104c9e:	eb 55                	jmp    80104cf5 <wait+0x110>

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104ca0:	81 45 f4 cc 04 00 00 	addl   $0x4cc,-0xc(%ebp)
80104ca7:	81 7d f4 d4 6c 12 80 	cmpl   $0x80126cd4,-0xc(%ebp)
80104cae:	0f 82 56 ff ff ff    	jb     80104c0a <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80104cb4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104cb8:	74 0d                	je     80104cc7 <wait+0xe2>
80104cba:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cc0:	8b 40 24             	mov    0x24(%eax),%eax
80104cc3:	85 c0                	test   %eax,%eax
80104cc5:	74 13                	je     80104cda <wait+0xf5>
      release(&ptable.lock);
80104cc7:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104cce:	e8 12 12 00 00       	call   80105ee5 <release>
      return -1;
80104cd3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cd8:	eb 1b                	jmp    80104cf5 <wait+0x110>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80104cda:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ce0:	c7 44 24 04 a0 39 11 	movl   $0x801139a0,0x4(%esp)
80104ce7:	80 
80104ce8:	89 04 24             	mov    %eax,(%esp)
80104ceb:	e8 b2 01 00 00       	call   80104ea2 <sleep>
  }
80104cf0:	e9 02 ff ff ff       	jmp    80104bf7 <wait+0x12>
}
80104cf5:	c9                   	leave  
80104cf6:	c3                   	ret    

80104cf7 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80104cf7:	55                   	push   %ebp
80104cf8:	89 e5                	mov    %esp,%ebp
80104cfa:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
80104cfd:	e8 04 f8 ff ff       	call   80104506 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80104d02:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104d09:	e8 75 11 00 00       	call   80105e83 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104d0e:	c7 45 f4 d4 39 11 80 	movl   $0x801139d4,-0xc(%ebp)
80104d15:	eb 61                	jmp    80104d78 <scheduler+0x81>
      if(p->state != RUNNABLE)
80104d17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d1a:	8b 40 0c             	mov    0xc(%eax),%eax
80104d1d:	83 f8 03             	cmp    $0x3,%eax
80104d20:	74 02                	je     80104d24 <scheduler+0x2d>
        continue;
80104d22:	eb 4d                	jmp    80104d71 <scheduler+0x7a>

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
80104d24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d27:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80104d2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d30:	89 04 24             	mov    %eax,(%esp)
80104d33:	e8 fe 3f 00 00       	call   80108d36 <switchuvm>
      p->state = RUNNING;
80104d38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d3b:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80104d42:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d48:	8b 40 1c             	mov    0x1c(%eax),%eax
80104d4b:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104d52:	83 c2 04             	add    $0x4,%edx
80104d55:	89 44 24 04          	mov    %eax,0x4(%esp)
80104d59:	89 14 24             	mov    %edx,(%esp)
80104d5c:	e8 07 16 00 00       	call   80106368 <swtch>
      switchkvm();
80104d61:	e8 b3 3f 00 00       	call   80108d19 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80104d66:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80104d6d:	00 00 00 00 
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104d71:	81 45 f4 cc 04 00 00 	addl   $0x4cc,-0xc(%ebp)
80104d78:	81 7d f4 d4 6c 12 80 	cmpl   $0x80126cd4,-0xc(%ebp)
80104d7f:	72 96                	jb     80104d17 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80104d81:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104d88:	e8 58 11 00 00       	call   80105ee5 <release>

  }
80104d8d:	e9 6b ff ff ff       	jmp    80104cfd <scheduler+0x6>

80104d92 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80104d92:	55                   	push   %ebp
80104d93:	89 e5                	mov    %esp,%ebp
80104d95:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80104d98:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104d9f:	e8 09 12 00 00       	call   80105fad <holding>
80104da4:	85 c0                	test   %eax,%eax
80104da6:	75 0c                	jne    80104db4 <sched+0x22>
    panic("sched ptable.lock");
80104da8:	c7 04 24 cd 97 10 80 	movl   $0x801097cd,(%esp)
80104daf:	e8 86 b7 ff ff       	call   8010053a <panic>
  if(cpu->ncli != 1)
80104db4:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104dba:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104dc0:	83 f8 01             	cmp    $0x1,%eax
80104dc3:	74 0c                	je     80104dd1 <sched+0x3f>
    panic("sched locks");
80104dc5:	c7 04 24 df 97 10 80 	movl   $0x801097df,(%esp)
80104dcc:	e8 69 b7 ff ff       	call   8010053a <panic>
  if(proc->state == RUNNING)
80104dd1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104dd7:	8b 40 0c             	mov    0xc(%eax),%eax
80104dda:	83 f8 04             	cmp    $0x4,%eax
80104ddd:	75 0c                	jne    80104deb <sched+0x59>
    panic("sched running");
80104ddf:	c7 04 24 eb 97 10 80 	movl   $0x801097eb,(%esp)
80104de6:	e8 4f b7 ff ff       	call   8010053a <panic>
  if(readeflags()&FL_IF)
80104deb:	e8 06 f7 ff ff       	call   801044f6 <readeflags>
80104df0:	25 00 02 00 00       	and    $0x200,%eax
80104df5:	85 c0                	test   %eax,%eax
80104df7:	74 0c                	je     80104e05 <sched+0x73>
    panic("sched interruptible");
80104df9:	c7 04 24 f9 97 10 80 	movl   $0x801097f9,(%esp)
80104e00:	e8 35 b7 ff ff       	call   8010053a <panic>
  intena = cpu->intena;
80104e05:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104e0b:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104e11:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80104e14:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104e1a:	8b 40 04             	mov    0x4(%eax),%eax
80104e1d:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104e24:	83 c2 1c             	add    $0x1c,%edx
80104e27:	89 44 24 04          	mov    %eax,0x4(%esp)
80104e2b:	89 14 24             	mov    %edx,(%esp)
80104e2e:	e8 35 15 00 00       	call   80106368 <swtch>
  cpu->intena = intena;
80104e33:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104e39:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e3c:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104e42:	c9                   	leave  
80104e43:	c3                   	ret    

80104e44 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80104e44:	55                   	push   %ebp
80104e45:	89 e5                	mov    %esp,%ebp
80104e47:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80104e4a:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104e51:	e8 2d 10 00 00       	call   80105e83 <acquire>
  proc->state = RUNNABLE;
80104e56:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e5c:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80104e63:	e8 2a ff ff ff       	call   80104d92 <sched>
  release(&ptable.lock);
80104e68:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104e6f:	e8 71 10 00 00       	call   80105ee5 <release>
}
80104e74:	c9                   	leave  
80104e75:	c3                   	ret    

80104e76 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80104e76:	55                   	push   %ebp
80104e77:	89 e5                	mov    %esp,%ebp
80104e79:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80104e7c:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104e83:	e8 5d 10 00 00       	call   80105ee5 <release>

  if (first) {
80104e88:	a1 08 c0 10 80       	mov    0x8010c008,%eax
80104e8d:	85 c0                	test   %eax,%eax
80104e8f:	74 0f                	je     80104ea0 <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80104e91:	c7 05 08 c0 10 80 00 	movl   $0x0,0x8010c008
80104e98:	00 00 00 
    initlog();
80104e9b:	e8 7d e5 ff ff       	call   8010341d <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80104ea0:	c9                   	leave  
80104ea1:	c3                   	ret    

80104ea2 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80104ea2:	55                   	push   %ebp
80104ea3:	89 e5                	mov    %esp,%ebp
80104ea5:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80104ea8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104eae:	85 c0                	test   %eax,%eax
80104eb0:	75 0c                	jne    80104ebe <sleep+0x1c>
    panic("sleep");
80104eb2:	c7 04 24 0d 98 10 80 	movl   $0x8010980d,(%esp)
80104eb9:	e8 7c b6 ff ff       	call   8010053a <panic>

  if(lk == 0)
80104ebe:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104ec2:	75 0c                	jne    80104ed0 <sleep+0x2e>
    panic("sleep without lk");
80104ec4:	c7 04 24 13 98 10 80 	movl   $0x80109813,(%esp)
80104ecb:	e8 6a b6 ff ff       	call   8010053a <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104ed0:	81 7d 0c a0 39 11 80 	cmpl   $0x801139a0,0xc(%ebp)
80104ed7:	74 17                	je     80104ef0 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80104ed9:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104ee0:	e8 9e 0f 00 00       	call   80105e83 <acquire>
    release(lk);
80104ee5:	8b 45 0c             	mov    0xc(%ebp),%eax
80104ee8:	89 04 24             	mov    %eax,(%esp)
80104eeb:	e8 f5 0f 00 00       	call   80105ee5 <release>
  }

  // Go to sleep.
  proc->chan = chan;
80104ef0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ef6:	8b 55 08             	mov    0x8(%ebp),%edx
80104ef9:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80104efc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f02:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
80104f09:	e8 84 fe ff ff       	call   80104d92 <sched>

  // Tidy up.
  proc->chan = 0;
80104f0e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f14:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80104f1b:	81 7d 0c a0 39 11 80 	cmpl   $0x801139a0,0xc(%ebp)
80104f22:	74 17                	je     80104f3b <sleep+0x99>
    release(&ptable.lock);
80104f24:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104f2b:	e8 b5 0f 00 00       	call   80105ee5 <release>
    acquire(lk);
80104f30:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f33:	89 04 24             	mov    %eax,(%esp)
80104f36:	e8 48 0f 00 00       	call   80105e83 <acquire>
  }
}
80104f3b:	c9                   	leave  
80104f3c:	c3                   	ret    

80104f3d <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104f3d:	55                   	push   %ebp
80104f3e:	89 e5                	mov    %esp,%ebp
80104f40:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104f43:	c7 45 fc d4 39 11 80 	movl   $0x801139d4,-0x4(%ebp)
80104f4a:	eb 27                	jmp    80104f73 <wakeup1+0x36>
    if(p->state == SLEEPING && p->chan == chan)
80104f4c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f4f:	8b 40 0c             	mov    0xc(%eax),%eax
80104f52:	83 f8 02             	cmp    $0x2,%eax
80104f55:	75 15                	jne    80104f6c <wakeup1+0x2f>
80104f57:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f5a:	8b 40 20             	mov    0x20(%eax),%eax
80104f5d:	3b 45 08             	cmp    0x8(%ebp),%eax
80104f60:	75 0a                	jne    80104f6c <wakeup1+0x2f>
      p->state = RUNNABLE;
80104f62:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f65:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104f6c:	81 45 fc cc 04 00 00 	addl   $0x4cc,-0x4(%ebp)
80104f73:	81 7d fc d4 6c 12 80 	cmpl   $0x80126cd4,-0x4(%ebp)
80104f7a:	72 d0                	jb     80104f4c <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80104f7c:	c9                   	leave  
80104f7d:	c3                   	ret    

80104f7e <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104f7e:	55                   	push   %ebp
80104f7f:	89 e5                	mov    %esp,%ebp
80104f81:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80104f84:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104f8b:	e8 f3 0e 00 00       	call   80105e83 <acquire>
  wakeup1(chan);
80104f90:	8b 45 08             	mov    0x8(%ebp),%eax
80104f93:	89 04 24             	mov    %eax,(%esp)
80104f96:	e8 a2 ff ff ff       	call   80104f3d <wakeup1>
  release(&ptable.lock);
80104f9b:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104fa2:	e8 3e 0f 00 00       	call   80105ee5 <release>
}
80104fa7:	c9                   	leave  
80104fa8:	c3                   	ret    

80104fa9 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104fa9:	55                   	push   %ebp
80104faa:	89 e5                	mov    %esp,%ebp
80104fac:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104faf:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104fb6:	e8 c8 0e 00 00       	call   80105e83 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104fbb:	c7 45 f4 d4 39 11 80 	movl   $0x801139d4,-0xc(%ebp)
80104fc2:	eb 44                	jmp    80105008 <kill+0x5f>
    if(p->pid == pid){
80104fc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fc7:	8b 40 10             	mov    0x10(%eax),%eax
80104fca:	3b 45 08             	cmp    0x8(%ebp),%eax
80104fcd:	75 32                	jne    80105001 <kill+0x58>
      p->killed = 1;
80104fcf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fd2:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104fd9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fdc:	8b 40 0c             	mov    0xc(%eax),%eax
80104fdf:	83 f8 02             	cmp    $0x2,%eax
80104fe2:	75 0a                	jne    80104fee <kill+0x45>
        p->state = RUNNABLE;
80104fe4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fe7:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104fee:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104ff5:	e8 eb 0e 00 00       	call   80105ee5 <release>
      return 0;
80104ffa:	b8 00 00 00 00       	mov    $0x0,%eax
80104fff:	eb 21                	jmp    80105022 <kill+0x79>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105001:	81 45 f4 cc 04 00 00 	addl   $0x4cc,-0xc(%ebp)
80105008:	81 7d f4 d4 6c 12 80 	cmpl   $0x80126cd4,-0xc(%ebp)
8010500f:	72 b3                	jb     80104fc4 <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80105011:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80105018:	e8 c8 0e 00 00       	call   80105ee5 <release>
  return -1;
8010501d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105022:	c9                   	leave  
80105023:	c3                   	ret    

80105024 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80105024:	55                   	push   %ebp
80105025:	89 e5                	mov    %esp,%ebp
80105027:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010502a:	c7 45 f0 d4 39 11 80 	movl   $0x801139d4,-0x10(%ebp)
80105031:	e9 d9 00 00 00       	jmp    8010510f <procdump+0xeb>
    if(p->state == UNUSED)
80105036:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105039:	8b 40 0c             	mov    0xc(%eax),%eax
8010503c:	85 c0                	test   %eax,%eax
8010503e:	75 05                	jne    80105045 <procdump+0x21>
      continue;
80105040:	e9 c3 00 00 00       	jmp    80105108 <procdump+0xe4>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80105045:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105048:	8b 40 0c             	mov    0xc(%eax),%eax
8010504b:	83 f8 05             	cmp    $0x5,%eax
8010504e:	77 23                	ja     80105073 <procdump+0x4f>
80105050:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105053:	8b 40 0c             	mov    0xc(%eax),%eax
80105056:	8b 04 85 0c c0 10 80 	mov    -0x7fef3ff4(,%eax,4),%eax
8010505d:	85 c0                	test   %eax,%eax
8010505f:	74 12                	je     80105073 <procdump+0x4f>
      state = states[p->state];
80105061:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105064:	8b 40 0c             	mov    0xc(%eax),%eax
80105067:	8b 04 85 0c c0 10 80 	mov    -0x7fef3ff4(,%eax,4),%eax
8010506e:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105071:	eb 07                	jmp    8010507a <procdump+0x56>
    else
      state = "???";
80105073:	c7 45 ec 24 98 10 80 	movl   $0x80109824,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
8010507a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010507d:	8d 50 28             	lea    0x28(%eax),%edx
80105080:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105083:	8b 40 10             	mov    0x10(%eax),%eax
80105086:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010508a:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010508d:	89 54 24 08          	mov    %edx,0x8(%esp)
80105091:	89 44 24 04          	mov    %eax,0x4(%esp)
80105095:	c7 04 24 28 98 10 80 	movl   $0x80109828,(%esp)
8010509c:	e8 ff b2 ff ff       	call   801003a0 <cprintf>
    if(p->state == SLEEPING){
801050a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801050a4:	8b 40 0c             	mov    0xc(%eax),%eax
801050a7:	83 f8 02             	cmp    $0x2,%eax
801050aa:	75 50                	jne    801050fc <procdump+0xd8>
      getcallerpcs((uint*)p->context->ebp+2, pc);
801050ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
801050af:	8b 40 1c             	mov    0x1c(%eax),%eax
801050b2:	8b 40 0c             	mov    0xc(%eax),%eax
801050b5:	83 c0 08             	add    $0x8,%eax
801050b8:	8d 55 c4             	lea    -0x3c(%ebp),%edx
801050bb:	89 54 24 04          	mov    %edx,0x4(%esp)
801050bf:	89 04 24             	mov    %eax,(%esp)
801050c2:	e8 6d 0e 00 00       	call   80105f34 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
801050c7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801050ce:	eb 1b                	jmp    801050eb <procdump+0xc7>
        cprintf(" %p", pc[i]);
801050d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801050d3:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
801050d7:	89 44 24 04          	mov    %eax,0x4(%esp)
801050db:	c7 04 24 31 98 10 80 	movl   $0x80109831,(%esp)
801050e2:	e8 b9 b2 ff ff       	call   801003a0 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
801050e7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801050eb:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801050ef:	7f 0b                	jg     801050fc <procdump+0xd8>
801050f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801050f4:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
801050f8:	85 c0                	test   %eax,%eax
801050fa:	75 d4                	jne    801050d0 <procdump+0xac>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
801050fc:	c7 04 24 35 98 10 80 	movl   $0x80109835,(%esp)
80105103:	e8 98 b2 ff ff       	call   801003a0 <cprintf>
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105108:	81 45 f0 cc 04 00 00 	addl   $0x4cc,-0x10(%ebp)
8010510f:	81 7d f0 d4 6c 12 80 	cmpl   $0x80126cd4,-0x10(%ebp)
80105116:	0f 82 1a ff ff ff    	jb     80105036 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
8010511c:	c9                   	leave  
8010511d:	c3                   	ret    

8010511e <getProcPIDS>:

// set pids to contain all the current pids number 
// returns the number of elemets in pids
int getProcPIDS (int *pids){
8010511e:	55                   	push   %ebp
8010511f:	89 e5                	mov    %esp,%ebp
80105121:	83 ec 28             	sub    $0x28,%esp

  struct proc *p;
  int count =0;
80105124:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  acquire(& ptable.lock);
8010512b:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80105132:	e8 4c 0d 00 00       	call   80105e83 <acquire>
  for(p = ptable.proc; p< &ptable.proc[NPROC]; p++){
80105137:	c7 45 f4 d4 39 11 80 	movl   $0x801139d4,-0xc(%ebp)
8010513e:	eb 43                	jmp    80105183 <getProcPIDS+0x65>

      if  ((p->state==SLEEPING ||  p->state==RUNNABLE || p->state==RUNNING )){
80105140:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105143:	8b 40 0c             	mov    0xc(%eax),%eax
80105146:	83 f8 02             	cmp    $0x2,%eax
80105149:	74 16                	je     80105161 <getProcPIDS+0x43>
8010514b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010514e:	8b 40 0c             	mov    0xc(%eax),%eax
80105151:	83 f8 03             	cmp    $0x3,%eax
80105154:	74 0b                	je     80105161 <getProcPIDS+0x43>
80105156:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105159:	8b 40 0c             	mov    0xc(%eax),%eax
8010515c:	83 f8 04             	cmp    $0x4,%eax
8010515f:	75 1b                	jne    8010517c <getProcPIDS+0x5e>
         pids[count]= p->pid;
80105161:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105164:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010516b:	8b 45 08             	mov    0x8(%ebp),%eax
8010516e:	01 c2                	add    %eax,%edx
80105170:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105173:	8b 40 10             	mov    0x10(%eax),%eax
80105176:	89 02                	mov    %eax,(%edx)
      	 //cprintf("%d   ", pids[count]);
         count++;
80105178:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
int getProcPIDS (int *pids){

  struct proc *p;
  int count =0;
  acquire(& ptable.lock);
  for(p = ptable.proc; p< &ptable.proc[NPROC]; p++){
8010517c:	81 45 f4 cc 04 00 00 	addl   $0x4cc,-0xc(%ebp)
80105183:	81 7d f4 d4 6c 12 80 	cmpl   $0x80126cd4,-0xc(%ebp)
8010518a:	72 b4                	jb     80105140 <getProcPIDS+0x22>
         count++;
      }

  }
  
  release(& ptable.lock);
8010518c:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80105193:	e8 4d 0d 00 00       	call   80105ee5 <release>
  return count;
80105198:	8b 45 f0             	mov    -0x10(%ebp),%eax

}
8010519b:	c9                   	leave  
8010519c:	c3                   	ret    

8010519d <procLock>:


// locks ptable
void procLock(){
8010519d:	55                   	push   %ebp
8010519e:	89 e5                	mov    %esp,%ebp
801051a0:	83 ec 18             	sub    $0x18,%esp
	acquire(&ptable.lock);
801051a3:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
801051aa:	e8 d4 0c 00 00       	call   80105e83 <acquire>
}
801051af:	c9                   	leave  
801051b0:	c3                   	ret    

801051b1 <procRelease>:

// release ptable
void procRelease(){
801051b1:	55                   	push   %ebp
801051b2:	89 e5                	mov    %esp,%ebp
801051b4:	83 ec 18             	sub    $0x18,%esp
	release(&ptable.lock);
801051b7:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
801051be:	e8 22 0d 00 00       	call   80105ee5 <release>
}
801051c3:	c9                   	leave  
801051c4:	c3                   	ret    

801051c5 <getProc>:


// returns the process struct with the current pid number
// if process is not found, or not alive the function return null
struct proc* getProc (int pid){
801051c5:	55                   	push   %ebp
801051c6:	89 e5                	mov    %esp,%ebp
801051c8:	83 ec 10             	sub    $0x10,%esp

  struct proc *p;

  for(p = ptable.proc; p< &ptable.proc[NPROC]; p++){
801051cb:	c7 45 fc d4 39 11 80 	movl   $0x801139d4,-0x4(%ebp)
801051d2:	eb 38                	jmp    8010520c <getProc+0x47>
      if  (p->pid==pid  && (p->state==SLEEPING ||  p->state==RUNNABLE || p->state==RUNNING )){
801051d4:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051d7:	8b 40 10             	mov    0x10(%eax),%eax
801051da:	3b 45 08             	cmp    0x8(%ebp),%eax
801051dd:	75 26                	jne    80105205 <getProc+0x40>
801051df:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051e2:	8b 40 0c             	mov    0xc(%eax),%eax
801051e5:	83 f8 02             	cmp    $0x2,%eax
801051e8:	74 16                	je     80105200 <getProc+0x3b>
801051ea:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051ed:	8b 40 0c             	mov    0xc(%eax),%eax
801051f0:	83 f8 03             	cmp    $0x3,%eax
801051f3:	74 0b                	je     80105200 <getProc+0x3b>
801051f5:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051f8:	8b 40 0c             	mov    0xc(%eax),%eax
801051fb:	83 f8 04             	cmp    $0x4,%eax
801051fe:	75 05                	jne    80105205 <getProc+0x40>
    	  return p;
80105200:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105203:	eb 15                	jmp    8010521a <getProc+0x55>
// if process is not found, or not alive the function return null
struct proc* getProc (int pid){

  struct proc *p;

  for(p = ptable.proc; p< &ptable.proc[NPROC]; p++){
80105205:	81 45 fc cc 04 00 00 	addl   $0x4cc,-0x4(%ebp)
8010520c:	81 7d fc d4 6c 12 80 	cmpl   $0x80126cd4,-0x4(%ebp)
80105213:	72 bf                	jb     801051d4 <getProc+0xf>
      if  (p->pid==pid  && (p->state==SLEEPING ||  p->state==RUNNABLE || p->state==RUNNING )){
    	  return p;
      }

  }
  return 0;
80105215:	b8 00 00 00 00       	mov    $0x0,%eax

}
8010521a:	c9                   	leave  
8010521b:	c3                   	ret    

8010521c <PID_PART>:
#define CWD_DNUM 3000
#define EXE_DNUM 4000
#define FDINFO_DNUM 5000
#define STATUS_DNUM 6000

static inline uint PID_PART(uint x) { return (x % 1000);}
8010521c:	55                   	push   %ebp
8010521d:	89 e5                	mov    %esp,%ebp
8010521f:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105222:	ba d3 4d 62 10       	mov    $0x10624dd3,%edx
80105227:	89 c8                	mov    %ecx,%eax
80105229:	f7 e2                	mul    %edx
8010522b:	89 d0                	mov    %edx,%eax
8010522d:	c1 e8 06             	shr    $0x6,%eax
80105230:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
80105236:	29 c1                	sub    %eax,%ecx
80105238:	89 c8                	mov    %ecx,%eax
8010523a:	5d                   	pop    %ebp
8010523b:	c3                   	ret    

8010523c <procfsisdir>:
int procfsInum;
int first=1;
 

int
procfsisdir(struct inode *ip) {
8010523c:	55                   	push   %ebp
8010523d:	89 e5                	mov    %esp,%ebp

 if (first){
8010523f:	a1 24 c0 10 80       	mov    0x8010c024,%eax
80105244:	85 c0                	test   %eax,%eax
80105246:	74 1e                	je     80105266 <procfsisdir+0x2a>
    procfsInum= ip->inum;
80105248:	8b 45 08             	mov    0x8(%ebp),%eax
8010524b:	8b 40 04             	mov    0x4(%eax),%eax
8010524e:	a3 d4 6c 12 80       	mov    %eax,0x80126cd4
    ip->minor =0;
80105253:	8b 45 08             	mov    0x8(%ebp),%eax
80105256:	66 c7 40 14 00 00    	movw   $0x0,0x14(%eax)
    first= 0;
8010525c:	c7 05 24 c0 10 80 00 	movl   $0x0,0x8010c024
80105263:	00 00 00 
  }


  if (ip->inum == procfsInum)
80105266:	8b 45 08             	mov    0x8(%ebp),%eax
80105269:	8b 50 04             	mov    0x4(%eax),%edx
8010526c:	a1 d4 6c 12 80       	mov    0x80126cd4,%eax
80105271:	39 c2                	cmp    %eax,%edx
80105273:	75 07                	jne    8010527c <procfsisdir+0x40>
	  return 1;
80105275:	b8 01 00 00 00       	mov    $0x1,%eax
8010527a:	eb 3f                	jmp    801052bb <procfsisdir+0x7f>

  if (ip->inum >= BASE_DIRENT_NUM && ip->inum <BASE_DNUM_LIM)
8010527c:	8b 45 08             	mov    0x8(%ebp),%eax
8010527f:	8b 40 04             	mov    0x4(%eax),%eax
80105282:	3d e7 03 00 00       	cmp    $0x3e7,%eax
80105287:	76 14                	jbe    8010529d <procfsisdir+0x61>
80105289:	8b 45 08             	mov    0x8(%ebp),%eax
8010528c:	8b 40 04             	mov    0x4(%eax),%eax
8010528f:	3d 27 04 00 00       	cmp    $0x427,%eax
80105294:	77 07                	ja     8010529d <procfsisdir+0x61>
    return 1;
80105296:	b8 01 00 00 00       	mov    $0x1,%eax
8010529b:	eb 1e                	jmp    801052bb <procfsisdir+0x7f>

 /// cprintf(" ########## %d \n", ip->inum / CWD_DNUM);
  if (ip->inum / CWD_DNUM  == 1){
8010529d:	8b 45 08             	mov    0x8(%ebp),%eax
801052a0:	8b 40 04             	mov    0x4(%eax),%eax
801052a3:	2d b8 0b 00 00       	sub    $0xbb8,%eax
801052a8:	3d b7 0b 00 00       	cmp    $0xbb7,%eax
801052ad:	77 07                	ja     801052b6 <procfsisdir+0x7a>
    return 1;
801052af:	b8 01 00 00 00       	mov    $0x1,%eax
801052b4:	eb 05                	jmp    801052bb <procfsisdir+0x7f>
  }
  
  else return 0;
801052b6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801052bb:	5d                   	pop    %ebp
801052bc:	c3                   	ret    

801052bd <procfsiread>:

void 
procfsiread(struct inode* dp, struct inode *ip) 
{
801052bd:	55                   	push   %ebp
801052be:	89 e5                	mov    %esp,%ebp
	// ip->flags = i_valid;
	// ip->major = 2;

 // cprintf("**** iread  inmu dp %d ip %d\n", dp->inum, ip->inum);
  //if (ip->inum >= BASE_DIRENT_NUM) {
    ip->type = T_DEV;
801052c0:	8b 45 0c             	mov    0xc(%ebp),%eax
801052c3:	66 c7 40 10 03 00    	movw   $0x3,0x10(%eax)
    ip->major = PROCFS;
801052c9:	8b 45 0c             	mov    0xc(%ebp),%eax
801052cc:	66 c7 40 12 02 00    	movw   $0x2,0x12(%eax)
    ip->size = 0;
801052d2:	8b 45 0c             	mov    0xc(%ebp),%eax
801052d5:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
    ip->flags |= I_VALID;
801052dc:	8b 45 0c             	mov    0xc(%ebp),%eax
801052df:	8b 40 0c             	mov    0xc(%eax),%eax
801052e2:	83 c8 02             	or     $0x2,%eax
801052e5:	89 c2                	mov    %eax,%edx
801052e7:	8b 45 0c             	mov    0xc(%ebp),%eax
801052ea:	89 50 0c             	mov    %edx,0xc(%eax)

  // cprintf("**** iread  type %d isdir %d  isdir(ip) %d\n",  ip->type, devsw[ip->major].isdir, devsw[ip->major].isdir(ip));
  // cprintf("**** iread  major dp %d ip %d\n", dp->major, ip->major);
  // cprintf("**** iread  minor dp %d ip %d\n", dp->minor, ip->minor);
    
}
801052ed:	5d                   	pop    %ebp
801052ee:	c3                   	ret    

801052ef <getProcList>:

int getProcList(char *buf, struct inode *pidIp) {
801052ef:	55                   	push   %ebp
801052f0:	89 e5                	mov    %esp,%ebp
801052f2:	81 ec 78 01 00 00    	sub    $0x178,%esp
  struct dirent de;
  int pidCount;
  int bufOff= 2;
801052f8:	c7 45 f4 02 00 00 00 	movl   $0x2,-0xc(%ebp)
  char stringNum[64];
  int  stringNumLength;


  //create "this dir" reference
  de.inum = procfsInum;
801052ff:	a1 d4 6c 12 80       	mov    0x80126cd4,%eax
80105304:	66 89 45 d8          	mov    %ax,-0x28(%ebp)
  memmove(de.name, ".", 2);
80105308:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
8010530f:	00 
80105310:	c7 44 24 04 61 98 10 	movl   $0x80109861,0x4(%esp)
80105317:	80 
80105318:	8d 45 d8             	lea    -0x28(%ebp),%eax
8010531b:	83 c0 02             	add    $0x2,%eax
8010531e:	89 04 24             	mov    %eax,(%esp)
80105321:	e8 80 0e 00 00       	call   801061a6 <memmove>
  memmove(buf, (char*)&de, sizeof(de));
80105326:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010532d:	00 
8010532e:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105331:	89 44 24 04          	mov    %eax,0x4(%esp)
80105335:	8b 45 08             	mov    0x8(%ebp),%eax
80105338:	89 04 24             	mov    %eax,(%esp)
8010533b:	e8 66 0e 00 00       	call   801061a6 <memmove>

  //create "prev dir" reference -procfs Dir
  de.inum = ROOTINO;
80105340:	66 c7 45 d8 01 00    	movw   $0x1,-0x28(%ebp)
  memmove(de.name, "..", 3);
80105346:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
8010534d:	00 
8010534e:	c7 44 24 04 63 98 10 	movl   $0x80109863,0x4(%esp)
80105355:	80 
80105356:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105359:	83 c0 02             	add    $0x2,%eax
8010535c:	89 04 24             	mov    %eax,(%esp)
8010535f:	e8 42 0e 00 00       	call   801061a6 <memmove>
  memmove(buf + sizeof(de), (char*)&de, sizeof(de));
80105364:	8b 45 08             	mov    0x8(%ebp),%eax
80105367:	8d 50 10             	lea    0x10(%eax),%edx
8010536a:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105371:	00 
80105372:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105375:	89 44 24 04          	mov    %eax,0x4(%esp)
80105379:	89 14 24             	mov    %edx,(%esp)
8010537c:	e8 25 0e 00 00       	call   801061a6 <memmove>

  // return the current running processes pids
  pidCount = getProcPIDS(pids);
80105381:	8d 85 d8 fe ff ff    	lea    -0x128(%ebp),%eax
80105387:	89 04 24             	mov    %eax,(%esp)
8010538a:	e8 8f fd ff ff       	call   8010511e <getProcPIDS>
8010538f:	89 45 ec             	mov    %eax,-0x14(%ebp)

  //push Pids as file entries
  for (pidIndex = 0; pidIndex< pidCount; pidIndex++){
80105392:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80105399:	eb 7f                	jmp    8010541a <getProcList+0x12b>

      de.inum = pids[pidIndex] + BASE_DIRENT_NUM ;
8010539b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010539e:	8b 84 85 d8 fe ff ff 	mov    -0x128(%ebp,%eax,4),%eax
801053a5:	66 05 e8 03          	add    $0x3e8,%ax
801053a9:	66 89 45 d8          	mov    %ax,-0x28(%ebp)
      
      stringNumLength = itoa(  pids[pidIndex], stringNum );
801053ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
801053b0:	8b 84 85 d8 fe ff ff 	mov    -0x128(%ebp,%eax,4),%eax
801053b7:	8d 95 98 fe ff ff    	lea    -0x168(%ebp),%edx
801053bd:	89 54 24 04          	mov    %edx,0x4(%esp)
801053c1:	89 04 24             	mov    %eax,(%esp)
801053c4:	e8 58 09 00 00       	call   80105d21 <itoa>
801053c9:	89 45 e8             	mov    %eax,-0x18(%ebp)

      memmove(de.name, stringNum, stringNumLength+1);
801053cc:	8b 45 e8             	mov    -0x18(%ebp),%eax
801053cf:	83 c0 01             	add    $0x1,%eax
801053d2:	89 44 24 08          	mov    %eax,0x8(%esp)
801053d6:	8d 85 98 fe ff ff    	lea    -0x168(%ebp),%eax
801053dc:	89 44 24 04          	mov    %eax,0x4(%esp)
801053e0:	8d 45 d8             	lea    -0x28(%ebp),%eax
801053e3:	83 c0 02             	add    $0x2,%eax
801053e6:	89 04 24             	mov    %eax,(%esp)
801053e9:	e8 b8 0d 00 00       	call   801061a6 <memmove>
      memmove(buf + bufOff * sizeof(de), (char*)&de, sizeof(de));
801053ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053f1:	c1 e0 04             	shl    $0x4,%eax
801053f4:	89 c2                	mov    %eax,%edx
801053f6:	8b 45 08             	mov    0x8(%ebp),%eax
801053f9:	01 c2                	add    %eax,%edx
801053fb:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105402:	00 
80105403:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105406:	89 44 24 04          	mov    %eax,0x4(%esp)
8010540a:	89 14 24             	mov    %edx,(%esp)
8010540d:	e8 94 0d 00 00       	call   801061a6 <memmove>
      bufOff++;
80105412:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

  // return the current running processes pids
  pidCount = getProcPIDS(pids);

  //push Pids as file entries
  for (pidIndex = 0; pidIndex< pidCount; pidIndex++){
80105416:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010541a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010541d:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80105420:	0f 8c 75 ff ff ff    	jl     8010539b <getProcList+0xac>
      memmove(buf + bufOff * sizeof(de), (char*)&de, sizeof(de));
      bufOff++;

  }

  return (bufOff)* sizeof(de);
80105426:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105429:	c1 e0 04             	shl    $0x4,%eax
}
8010542c:	c9                   	leave  
8010542d:	c3                   	ret    

8010542e <getProcEntry>:



int getProcEntry(uint pid ,char *buf, struct inode *ip) {
8010542e:	55                   	push   %ebp
8010542f:	89 e5                	mov    %esp,%ebp
80105431:	83 ec 38             	sub    $0x38,%esp

  struct dirent de;

  
  struct proc *p;
  procLock();
80105434:	e8 64 fd ff ff       	call   8010519d <procLock>

  p = getProc(pid);
80105439:	8b 45 08             	mov    0x8(%ebp),%eax
8010543c:	89 04 24             	mov    %eax,(%esp)
8010543f:	e8 81 fd ff ff       	call   801051c5 <getProc>
80105444:	89 45 f4             	mov    %eax,-0xc(%ebp)
  
  procRelease();
80105447:	e8 65 fd ff ff       	call   801051b1 <procRelease>
  if (!p){
8010544c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105450:	75 1d                	jne    8010546f <getProcEntry+0x41>
    cprintf ( " pid %d\n  ", pid );
80105452:	8b 45 08             	mov    0x8(%ebp),%eax
80105455:	89 44 24 04          	mov    %eax,0x4(%esp)
80105459:	c7 04 24 66 98 10 80 	movl   $0x80109866,(%esp)
80105460:	e8 3b af ff ff       	call   801003a0 <cprintf>
	  return 0;
80105465:	b8 00 00 00 00       	mov    $0x0,%eax
8010546a:	e9 ed 01 00 00       	jmp    8010565c <getProcEntry+0x22e>
  }


  //create "this dir" reference
  de.inum = ip->inum;
8010546f:	8b 45 10             	mov    0x10(%ebp),%eax
80105472:	8b 40 04             	mov    0x4(%eax),%eax
80105475:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)

  //cprintf(" ********* %d\n", ip->inum);
  memmove(de.name, ".", 2);
80105479:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
80105480:	00 
80105481:	c7 44 24 04 61 98 10 	movl   $0x80109861,0x4(%esp)
80105488:	80 
80105489:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010548c:	83 c0 02             	add    $0x2,%eax
8010548f:	89 04 24             	mov    %eax,(%esp)
80105492:	e8 0f 0d 00 00       	call   801061a6 <memmove>
  memmove(buf, (char*)&de, sizeof(de));
80105497:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010549e:	00 
8010549f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801054a2:	89 44 24 04          	mov    %eax,0x4(%esp)
801054a6:	8b 45 0c             	mov    0xc(%ebp),%eax
801054a9:	89 04 24             	mov    %eax,(%esp)
801054ac:	e8 f5 0c 00 00       	call   801061a6 <memmove>

  //create "prev dir" reference -root Dir
  de.inum = procfsInum;
801054b1:	a1 d4 6c 12 80       	mov    0x80126cd4,%eax
801054b6:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  memmove(de.name, "..", 3);
801054ba:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
801054c1:	00 
801054c2:	c7 44 24 04 63 98 10 	movl   $0x80109863,0x4(%esp)
801054c9:	80 
801054ca:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801054cd:	83 c0 02             	add    $0x2,%eax
801054d0:	89 04 24             	mov    %eax,(%esp)
801054d3:	e8 ce 0c 00 00       	call   801061a6 <memmove>
  memmove(buf + sizeof(de), (char*)&de, sizeof(de));
801054d8:	8b 45 0c             	mov    0xc(%ebp),%eax
801054db:	8d 50 10             	lea    0x10(%eax),%edx
801054de:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801054e5:	00 
801054e6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801054e9:	89 44 24 04          	mov    %eax,0x4(%esp)
801054ed:	89 14 24             	mov    %edx,(%esp)
801054f0:	e8 b1 0c 00 00       	call   801061a6 <memmove>

  //create "cmdline " reference 
  de.inum = CMDLINE_DNUM+pid;
801054f5:	8b 45 08             	mov    0x8(%ebp),%eax
801054f8:	66 05 d0 07          	add    $0x7d0,%ax
801054fc:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  memmove(de.name, "cmdline", 8);
80105500:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80105507:	00 
80105508:	c7 44 24 04 71 98 10 	movl   $0x80109871,0x4(%esp)
8010550f:	80 
80105510:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105513:	83 c0 02             	add    $0x2,%eax
80105516:	89 04 24             	mov    %eax,(%esp)
80105519:	e8 88 0c 00 00       	call   801061a6 <memmove>
  memmove(buf + 2*sizeof(de), (char*)&de, sizeof(de));
8010551e:	8b 45 0c             	mov    0xc(%ebp),%eax
80105521:	8d 50 20             	lea    0x20(%eax),%edx
80105524:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010552b:	00 
8010552c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010552f:	89 44 24 04          	mov    %eax,0x4(%esp)
80105533:	89 14 24             	mov    %edx,(%esp)
80105536:	e8 6b 0c 00 00       	call   801061a6 <memmove>

  //create "cwd " reference
  de.inum = p->cwd->inum;
8010553b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010553e:	8b 40 78             	mov    0x78(%eax),%eax
80105541:	8b 40 04             	mov    0x4(%eax),%eax
80105544:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  memmove(de.name, "cwd", 4);
80105548:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010554f:	00 
80105550:	c7 44 24 04 79 98 10 	movl   $0x80109879,0x4(%esp)
80105557:	80 
80105558:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010555b:	83 c0 02             	add    $0x2,%eax
8010555e:	89 04 24             	mov    %eax,(%esp)
80105561:	e8 40 0c 00 00       	call   801061a6 <memmove>
  memmove(buf + 3*sizeof(de), (char*)&de, sizeof(de));
80105566:	8b 45 0c             	mov    0xc(%ebp),%eax
80105569:	8d 50 30             	lea    0x30(%eax),%edx
8010556c:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105573:	00 
80105574:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105577:	89 44 24 04          	mov    %eax,0x4(%esp)
8010557b:	89 14 24             	mov    %edx,(%esp)
8010557e:	e8 23 0c 00 00       	call   801061a6 <memmove>

  //create "exe " reference
  de.inum = (p->exe)->inum;
80105583:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105586:	8b 40 7c             	mov    0x7c(%eax),%eax
80105589:	8b 40 04             	mov    0x4(%eax),%eax
8010558c:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  memmove(de.name, "exe", 4);
80105590:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80105597:	00 
80105598:	c7 44 24 04 7d 98 10 	movl   $0x8010987d,0x4(%esp)
8010559f:	80 
801055a0:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801055a3:	83 c0 02             	add    $0x2,%eax
801055a6:	89 04 24             	mov    %eax,(%esp)
801055a9:	e8 f8 0b 00 00       	call   801061a6 <memmove>
  memmove(buf + 4*sizeof(de), (char*)&de, sizeof(de));
801055ae:	8b 45 0c             	mov    0xc(%ebp),%eax
801055b1:	8d 50 40             	lea    0x40(%eax),%edx
801055b4:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801055bb:	00 
801055bc:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801055bf:	89 44 24 04          	mov    %eax,0x4(%esp)
801055c3:	89 14 24             	mov    %edx,(%esp)
801055c6:	e8 db 0b 00 00       	call   801061a6 <memmove>

  //create "fdinfo " reference -root Dir
  de.inum = FDINFO_DNUM + pid;
801055cb:	8b 45 08             	mov    0x8(%ebp),%eax
801055ce:	66 05 88 13          	add    $0x1388,%ax
801055d2:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  memmove(de.name, "fdinfo", 7);
801055d6:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
801055dd:	00 
801055de:	c7 44 24 04 81 98 10 	movl   $0x80109881,0x4(%esp)
801055e5:	80 
801055e6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801055e9:	83 c0 02             	add    $0x2,%eax
801055ec:	89 04 24             	mov    %eax,(%esp)
801055ef:	e8 b2 0b 00 00       	call   801061a6 <memmove>
  memmove(buf + 5*sizeof(de), (char*)&de, sizeof(de));
801055f4:	8b 45 0c             	mov    0xc(%ebp),%eax
801055f7:	8d 50 50             	lea    0x50(%eax),%edx
801055fa:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105601:	00 
80105602:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105605:	89 44 24 04          	mov    %eax,0x4(%esp)
80105609:	89 14 24             	mov    %edx,(%esp)
8010560c:	e8 95 0b 00 00       	call   801061a6 <memmove>

  //create "status " reference -root Dir
  de.inum = STATUS_DNUM + pid;
80105611:	8b 45 08             	mov    0x8(%ebp),%eax
80105614:	66 05 70 17          	add    $0x1770,%ax
80105618:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  memmove(de.name, "status", 7);
8010561c:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
80105623:	00 
80105624:	c7 44 24 04 88 98 10 	movl   $0x80109888,0x4(%esp)
8010562b:	80 
8010562c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010562f:	83 c0 02             	add    $0x2,%eax
80105632:	89 04 24             	mov    %eax,(%esp)
80105635:	e8 6c 0b 00 00       	call   801061a6 <memmove>
  memmove(buf + 6*sizeof(de), (char*)&de, sizeof(de));
8010563a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010563d:	8d 50 60             	lea    0x60(%eax),%edx
80105640:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105647:	00 
80105648:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010564b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010564f:	89 14 24             	mov    %edx,(%esp)
80105652:	e8 4f 0b 00 00       	call   801061a6 <memmove>

  return 7 * sizeof(de);
80105657:	b8 70 00 00 00       	mov    $0x70,%eax
}
8010565c:	c9                   	leave  
8010565d:	c3                   	ret    

8010565e <procfsread>:



int
procfsread(struct inode *ip, char *dst, int off, int n) {
8010565e:	55                   	push   %ebp
8010565f:	89 e5                	mov    %esp,%ebp
80105661:	53                   	push   %ebx
80105662:	81 ec 34 04 00 00    	sub    $0x434,%esp
  char buf[1024];
  int size ,i ;

    // cprintf("***********    %d \n", ip->inum);
    if (first){
80105668:	a1 24 c0 10 80       	mov    0x8010c024,%eax
8010566d:	85 c0                	test   %eax,%eax
8010566f:	74 1e                	je     8010568f <procfsread+0x31>
      procfsInum= ip->inum;
80105671:	8b 45 08             	mov    0x8(%ebp),%eax
80105674:	8b 40 04             	mov    0x4(%eax),%eax
80105677:	a3 d4 6c 12 80       	mov    %eax,0x80126cd4
      ip->minor =0;
8010567c:	8b 45 08             	mov    0x8(%ebp),%eax
8010567f:	66 c7 40 14 00 00    	movw   $0x0,0x14(%eax)
      first= 0;
80105685:	c7 05 24 c0 10 80 00 	movl   $0x0,0x8010c024
8010568c:	00 00 00 
    }
    
	  if (ip->inum == procfsInum) {
8010568f:	8b 45 08             	mov    0x8(%ebp),%eax
80105692:	8b 50 04             	mov    0x4(%eax),%edx
80105695:	a1 d4 6c 12 80       	mov    0x80126cd4,%eax
8010569a:	39 c2                	cmp    %eax,%edx
8010569c:	75 18                	jne    801056b6 <procfsread+0x58>
		  size = getProcList(buf, ip);
8010569e:	8b 45 08             	mov    0x8(%ebp),%eax
801056a1:	89 44 24 04          	mov    %eax,0x4(%esp)
801056a5:	8d 85 dc fb ff ff    	lea    -0x424(%ebp),%eax
801056ab:	89 04 24             	mov    %eax,(%esp)
801056ae:	e8 3c fc ff ff       	call   801052ef <getProcList>
801056b3:	89 45 f4             	mov    %eax,-0xc(%ebp)
          
    }

    uint pid = PID_PART(ip->inum);
801056b6:	8b 45 08             	mov    0x8(%ebp),%eax
801056b9:	8b 40 04             	mov    0x4(%eax),%eax
801056bc:	89 04 24             	mov    %eax,(%esp)
801056bf:	e8 58 fb ff ff       	call   8010521c <PID_PART>
801056c4:	89 45 ec             	mov    %eax,-0x14(%ebp)

    struct proc * p= getProc(pid);
801056c7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801056ca:	89 04 24             	mov    %eax,(%esp)
801056cd:	e8 f3 fa ff ff       	call   801051c5 <getProc>
801056d2:	89 45 e8             	mov    %eax,-0x18(%ebp)
    
    //cprintf ("p.pid %d *** num %d, pid %d *** %s \n", p->pid, ip->inum ,pid, p->cmdline);

    if (ip->inum >= BASE_DIRENT_NUM && ip->inum<=BASE_DNUM_LIM ){
801056d5:	8b 45 08             	mov    0x8(%ebp),%eax
801056d8:	8b 40 04             	mov    0x4(%eax),%eax
801056db:	3d e7 03 00 00       	cmp    $0x3e7,%eax
801056e0:	76 2c                	jbe    8010570e <procfsread+0xb0>
801056e2:	8b 45 08             	mov    0x8(%ebp),%eax
801056e5:	8b 40 04             	mov    0x4(%eax),%eax
801056e8:	3d 28 04 00 00       	cmp    $0x428,%eax
801056ed:	77 1f                	ja     8010570e <procfsread+0xb0>
		     
         size = getProcEntry(pid,buf, ip);
801056ef:	8b 45 08             	mov    0x8(%ebp),%eax
801056f2:	89 44 24 08          	mov    %eax,0x8(%esp)
801056f6:	8d 85 dc fb ff ff    	lea    -0x424(%ebp),%eax
801056fc:	89 44 24 04          	mov    %eax,0x4(%esp)
80105700:	8b 45 ec             	mov    -0x14(%ebp),%eax
80105703:	89 04 24             	mov    %eax,(%esp)
80105706:	e8 23 fd ff ff       	call   8010542e <getProcEntry>
8010570b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    }

    if ( ip-> inum >= CMDLINE_DNUM) {
8010570e:	8b 45 08             	mov    0x8(%ebp),%eax
80105711:	8b 40 04             	mov    0x4(%eax),%eax
80105714:	3d cf 07 00 00       	cmp    $0x7cf,%eax
80105719:	0f 86 75 05 00 00    	jbe    80105c94 <procfsread+0x636>


        if(!p)
8010571f:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80105723:	75 0a                	jne    8010572f <procfsread+0xd1>
         return 0;
80105725:	b8 00 00 00 00       	mov    $0x0,%eax
8010572a:	e9 b2 05 00 00       	jmp    80105ce1 <procfsread+0x683>
//        char c [100];

        switch (ip->inum-pid){
8010572f:	8b 45 08             	mov    0x8(%ebp),%eax
80105732:	8b 40 04             	mov    0x4(%eax),%eax
80105735:	2b 45 ec             	sub    -0x14(%ebp),%eax
80105738:	3d 88 13 00 00       	cmp    $0x1388,%eax
8010573d:	0f 84 39 01 00 00    	je     8010587c <procfsread+0x21e>
80105743:	3d 70 17 00 00       	cmp    $0x1770,%eax
80105748:	0f 84 10 04 00 00    	je     80105b5e <procfsread+0x500>
8010574e:	3d d0 07 00 00       	cmp    $0x7d0,%eax
80105753:	0f 85 3b 05 00 00    	jne    80105c94 <procfsread+0x636>
         
              case CMDLINE_DNUM:
                            // cprintf("here p %d cmd %s\n", p->pid, p->cmdline);
                            size = strlen(p->cmdline);
80105759:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010575c:	83 e8 80             	sub    $0xffffff80,%eax
8010575f:	89 04 24             	mov    %eax,(%esp)
80105762:	e8 da 0b 00 00       	call   80106341 <strlen>
80105767:	89 45 f4             	mov    %eax,-0xc(%ebp)

                            memmove(buf, p->cmdline, size);
8010576a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010576d:	8b 55 e8             	mov    -0x18(%ebp),%edx
80105770:	83 ea 80             	sub    $0xffffff80,%edx
80105773:	89 44 24 08          	mov    %eax,0x8(%esp)
80105777:	89 54 24 04          	mov    %edx,0x4(%esp)
8010577b:	8d 85 dc fb ff ff    	lea    -0x424(%ebp),%eax
80105781:	89 04 24             	mov    %eax,(%esp)
80105784:	e8 1d 0a 00 00       	call   801061a6 <memmove>

                            for (i =1 ; i < MAXARGS; i++){
80105789:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
80105790:	e9 b1 00 00 00       	jmp    80105846 <procfsread+0x1e8>

                            	if (p->args[i]){
80105795:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105798:	6b c0 64             	imul   $0x64,%eax,%eax
8010579b:	8d 90 e0 00 00 00    	lea    0xe0(%eax),%edx
801057a1:	8b 45 e8             	mov    -0x18(%ebp),%eax
801057a4:	01 d0                	add    %edx,%eax
801057a6:	83 c0 04             	add    $0x4,%eax
801057a9:	85 c0                	test   %eax,%eax
801057ab:	0f 84 91 00 00 00    	je     80105842 <procfsread+0x1e4>
                            		memmove(buf+size, " ", 1);
801057b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057b4:	8d 95 dc fb ff ff    	lea    -0x424(%ebp),%edx
801057ba:	01 d0                	add    %edx,%eax
801057bc:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
801057c3:	00 
801057c4:	c7 44 24 04 8f 98 10 	movl   $0x8010988f,0x4(%esp)
801057cb:	80 
801057cc:	89 04 24             	mov    %eax,(%esp)
801057cf:	e8 d2 09 00 00       	call   801061a6 <memmove>
                            		size++ ;
801057d4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
                            		memmove(buf+size, p->args[i], strlen(p->args[i]));
801057d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057db:	6b c0 64             	imul   $0x64,%eax,%eax
801057de:	8d 90 e0 00 00 00    	lea    0xe0(%eax),%edx
801057e4:	8b 45 e8             	mov    -0x18(%ebp),%eax
801057e7:	01 d0                	add    %edx,%eax
801057e9:	83 c0 04             	add    $0x4,%eax
801057ec:	89 04 24             	mov    %eax,(%esp)
801057ef:	e8 4d 0b 00 00       	call   80106341 <strlen>
801057f4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801057f7:	6b d2 64             	imul   $0x64,%edx,%edx
801057fa:	8d 8a e0 00 00 00    	lea    0xe0(%edx),%ecx
80105800:	8b 55 e8             	mov    -0x18(%ebp),%edx
80105803:	01 ca                	add    %ecx,%edx
80105805:	8d 4a 04             	lea    0x4(%edx),%ecx
80105808:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010580b:	8d 9d dc fb ff ff    	lea    -0x424(%ebp),%ebx
80105811:	01 da                	add    %ebx,%edx
80105813:	89 44 24 08          	mov    %eax,0x8(%esp)
80105817:	89 4c 24 04          	mov    %ecx,0x4(%esp)
8010581b:	89 14 24             	mov    %edx,(%esp)
8010581e:	e8 83 09 00 00       	call   801061a6 <memmove>
                            		//cprintf("here %s \n",p->args[i]);
                            		size+= strlen(p->args[i]);
80105823:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105826:	6b c0 64             	imul   $0x64,%eax,%eax
80105829:	8d 90 e0 00 00 00    	lea    0xe0(%eax),%edx
8010582f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105832:	01 d0                	add    %edx,%eax
80105834:	83 c0 04             	add    $0x4,%eax
80105837:	89 04 24             	mov    %eax,(%esp)
8010583a:	e8 02 0b 00 00       	call   80106341 <strlen>
8010583f:	01 45 f4             	add    %eax,-0xc(%ebp)
                            // cprintf("here p %d cmd %s\n", p->pid, p->cmdline);
                            size = strlen(p->cmdline);

                            memmove(buf, p->cmdline, size);

                            for (i =1 ; i < MAXARGS; i++){
80105842:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80105846:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
8010584a:	0f 8e 45 ff ff ff    	jle    80105795 <procfsread+0x137>
                            		memmove(buf+size, p->args[i], strlen(p->args[i]));
                            		//cprintf("here %s \n",p->args[i]);
                            		size+= strlen(p->args[i]);
                            	}
                            }
							memmove(buf+size, "\n",1);
80105850:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105853:	8d 95 dc fb ff ff    	lea    -0x424(%ebp),%edx
80105859:	01 d0                	add    %edx,%eax
8010585b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80105862:	00 
80105863:	c7 44 24 04 91 98 10 	movl   $0x80109891,0x4(%esp)
8010586a:	80 
8010586b:	89 04 24             	mov    %eax,(%esp)
8010586e:	e8 33 09 00 00       	call   801061a6 <memmove>
							size++;
80105873:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
                            break;
80105877:	e9 18 04 00 00       	jmp    80105c94 <procfsread+0x636>
              case FDINFO_DNUM:
            	  	  	  	size= 0;
8010587c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
            	  	  	  	for (i =1 ; i < NOFILE; i++){
80105883:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
8010588a:	e9 c0 02 00 00       	jmp    80105b4f <procfsread+0x4f1>
            	  	  	  		if (p->ofile[i] && p->ofile[i]->ref>0){
8010588f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105892:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105895:	83 c2 0c             	add    $0xc,%edx
80105898:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010589c:	85 c0                	test   %eax,%eax
8010589e:	0f 84 a7 02 00 00    	je     80105b4b <procfsread+0x4ed>
801058a4:	8b 45 e8             	mov    -0x18(%ebp),%eax
801058a7:	8b 55 f0             	mov    -0x10(%ebp),%edx
801058aa:	83 c2 0c             	add    $0xc,%edx
801058ad:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801058b1:	8b 40 04             	mov    0x4(%eax),%eax
801058b4:	85 c0                	test   %eax,%eax
801058b6:	0f 8e 8f 02 00 00    	jle    80105b4b <procfsread+0x4ed>

            	  	  	  		   memmove(buf+size, "fd: ",4 );
801058bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058bf:	8d 95 dc fb ff ff    	lea    -0x424(%ebp),%edx
801058c5:	01 d0                	add    %edx,%eax
801058c7:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801058ce:	00 
801058cf:	c7 44 24 04 93 98 10 	movl   $0x80109893,0x4(%esp)
801058d6:	80 
801058d7:	89 04 24             	mov    %eax,(%esp)
801058da:	e8 c7 08 00 00       	call   801061a6 <memmove>
            	  	  	  		   size+=4;
801058df:	83 45 f4 04          	addl   $0x4,-0xc(%ebp)
            	  	  	  		   int k= itoa(i, buf+size);
801058e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058e6:	8d 95 dc fb ff ff    	lea    -0x424(%ebp),%edx
801058ec:	01 c2                	add    %eax,%edx
801058ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
801058f1:	89 54 24 04          	mov    %edx,0x4(%esp)
801058f5:	89 04 24             	mov    %eax,(%esp)
801058f8:	e8 24 04 00 00       	call   80105d21 <itoa>
801058fd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
            	  	  	  		   size+=k;
80105900:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105903:	01 45 f4             	add    %eax,-0xc(%ebp)
            	  	  	  		   //cprintf ("\n #### %d \n", itoa(i, buf+size));
            	  	  	  		   memmove(buf+size, " ", 1);
80105906:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105909:	8d 95 dc fb ff ff    	lea    -0x424(%ebp),%edx
8010590f:	01 d0                	add    %edx,%eax
80105911:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80105918:	00 
80105919:	c7 44 24 04 8f 98 10 	movl   $0x8010988f,0x4(%esp)
80105920:	80 
80105921:	89 04 24             	mov    %eax,(%esp)
80105924:	e8 7d 08 00 00       	call   801061a6 <memmove>
            	  	  	  		   size++ ;
80105929:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

            	  	  	  		   memmove(buf+size, "type: ",6);
8010592d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105930:	8d 95 dc fb ff ff    	lea    -0x424(%ebp),%edx
80105936:	01 d0                	add    %edx,%eax
80105938:	c7 44 24 08 06 00 00 	movl   $0x6,0x8(%esp)
8010593f:	00 
80105940:	c7 44 24 04 98 98 10 	movl   $0x80109898,0x4(%esp)
80105947:	80 
80105948:	89 04 24             	mov    %eax,(%esp)
8010594b:	e8 56 08 00 00       	call   801061a6 <memmove>
            	  	  	  	       size+=6;
80105950:	83 45 f4 06          	addl   $0x6,-0xc(%ebp)

            	  	  	  		   if (p->ofile[i]->type == FD_INODE){
80105954:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105957:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010595a:	83 c2 0c             	add    $0xc,%edx
8010595d:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105961:	8b 00                	mov    (%eax),%eax
80105963:	83 f8 02             	cmp    $0x2,%eax
80105966:	75 27                	jne    8010598f <procfsread+0x331>
            	  	  	  			   	   	memmove(buf+size, "INODE ",6);
80105968:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010596b:	8d 95 dc fb ff ff    	lea    -0x424(%ebp),%edx
80105971:	01 d0                	add    %edx,%eax
80105973:	c7 44 24 08 06 00 00 	movl   $0x6,0x8(%esp)
8010597a:	00 
8010597b:	c7 44 24 04 9f 98 10 	movl   $0x8010989f,0x4(%esp)
80105982:	80 
80105983:	89 04 24             	mov    %eax,(%esp)
80105986:	e8 1b 08 00 00       	call   801061a6 <memmove>
            	  	  	  		            size+=6;
8010598b:	83 45 f4 06          	addl   $0x6,-0xc(%ebp)
            	  	  	  		   }
            	  	  	  		   if (p->ofile[i]->type == FD_PIPE){
8010598f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105992:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105995:	83 c2 0c             	add    $0xc,%edx
80105998:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010599c:	8b 00                	mov    (%eax),%eax
8010599e:	83 f8 01             	cmp    $0x1,%eax
801059a1:	75 27                	jne    801059ca <procfsread+0x36c>
            	  	      	  	  	  	    memmove(buf+size, "PIPE ",5);
801059a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059a6:	8d 95 dc fb ff ff    	lea    -0x424(%ebp),%edx
801059ac:	01 d0                	add    %edx,%eax
801059ae:	c7 44 24 08 05 00 00 	movl   $0x5,0x8(%esp)
801059b5:	00 
801059b6:	c7 44 24 04 a6 98 10 	movl   $0x801098a6,0x4(%esp)
801059bd:	80 
801059be:	89 04 24             	mov    %eax,(%esp)
801059c1:	e8 e0 07 00 00       	call   801061a6 <memmove>
            	  	  	  	            	size+=5;
801059c6:	83 45 f4 05          	addl   $0x5,-0xc(%ebp)
            	  	  	  	       }
            	  	  	  		   if (p->ofile[i]->type == FD_NONE){
801059ca:	8b 45 e8             	mov    -0x18(%ebp),%eax
801059cd:	8b 55 f0             	mov    -0x10(%ebp),%edx
801059d0:	83 c2 0c             	add    $0xc,%edx
801059d3:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801059d7:	8b 00                	mov    (%eax),%eax
801059d9:	85 c0                	test   %eax,%eax
801059db:	75 27                	jne    80105a04 <procfsread+0x3a6>
											memmove(buf+size, "NONE ",5);
801059dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059e0:	8d 95 dc fb ff ff    	lea    -0x424(%ebp),%edx
801059e6:	01 d0                	add    %edx,%eax
801059e8:	c7 44 24 08 05 00 00 	movl   $0x5,0x8(%esp)
801059ef:	00 
801059f0:	c7 44 24 04 ac 98 10 	movl   $0x801098ac,0x4(%esp)
801059f7:	80 
801059f8:	89 04 24             	mov    %eax,(%esp)
801059fb:	e8 a6 07 00 00       	call   801061a6 <memmove>
											size+=5;
80105a00:	83 45 f4 05          	addl   $0x5,-0xc(%ebp)
								   }
            	  	  	  		   memmove(buf+size, "position: ",10);
80105a04:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a07:	8d 95 dc fb ff ff    	lea    -0x424(%ebp),%edx
80105a0d:	01 d0                	add    %edx,%eax
80105a0f:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
80105a16:	00 
80105a17:	c7 44 24 04 b2 98 10 	movl   $0x801098b2,0x4(%esp)
80105a1e:	80 
80105a1f:	89 04 24             	mov    %eax,(%esp)
80105a22:	e8 7f 07 00 00       	call   801061a6 <memmove>
								   size+=10;
80105a27:	83 45 f4 0a          	addl   $0xa,-0xc(%ebp)
								   k= itoa(p->ofile[i]->off, buf+size);
80105a2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a2e:	8d 95 dc fb ff ff    	lea    -0x424(%ebp),%edx
80105a34:	01 c2                	add    %eax,%edx
80105a36:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105a39:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105a3c:	83 c1 0c             	add    $0xc,%ecx
80105a3f:	8b 44 88 08          	mov    0x8(%eax,%ecx,4),%eax
80105a43:	8b 40 14             	mov    0x14(%eax),%eax
80105a46:	89 54 24 04          	mov    %edx,0x4(%esp)
80105a4a:	89 04 24             	mov    %eax,(%esp)
80105a4d:	e8 cf 02 00 00       	call   80105d21 <itoa>
80105a52:	89 45 e4             	mov    %eax,-0x1c(%ebp)
//								   k= itoa(p->ofile[i]->off, c);
//								   cprintf("\n  len: %d n: %d  s: %s ### \n",k,p->ofile[i]->off,c );

								   size+=k+1;
80105a55:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105a58:	83 c0 01             	add    $0x1,%eax
80105a5b:	01 45 f4             	add    %eax,-0xc(%ebp)
								   memmove(buf+size, " ", 1);
80105a5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a61:	8d 95 dc fb ff ff    	lea    -0x424(%ebp),%edx
80105a67:	01 d0                	add    %edx,%eax
80105a69:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80105a70:	00 
80105a71:	c7 44 24 04 8f 98 10 	movl   $0x8010988f,0x4(%esp)
80105a78:	80 
80105a79:	89 04 24             	mov    %eax,(%esp)
80105a7c:	e8 25 07 00 00       	call   801061a6 <memmove>
								   size++ ;
80105a81:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

								   memmove(buf+size, "flags: ",7);
80105a85:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a88:	8d 95 dc fb ff ff    	lea    -0x424(%ebp),%edx
80105a8e:	01 d0                	add    %edx,%eax
80105a90:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
80105a97:	00 
80105a98:	c7 44 24 04 bd 98 10 	movl   $0x801098bd,0x4(%esp)
80105a9f:	80 
80105aa0:	89 04 24             	mov    %eax,(%esp)
80105aa3:	e8 fe 06 00 00       	call   801061a6 <memmove>
								   size+=7;
80105aa8:	83 45 f4 07          	addl   $0x7,-0xc(%ebp)
								   if (p->ofile[i]->readable){
80105aac:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105aaf:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105ab2:	83 c2 0c             	add    $0xc,%edx
80105ab5:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105ab9:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80105abd:	84 c0                	test   %al,%al
80105abf:	74 27                	je     80105ae8 <procfsread+0x48a>
									   memmove(buf+size, "r ", 2);
80105ac1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ac4:	8d 95 dc fb ff ff    	lea    -0x424(%ebp),%edx
80105aca:	01 d0                	add    %edx,%eax
80105acc:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
80105ad3:	00 
80105ad4:	c7 44 24 04 c5 98 10 	movl   $0x801098c5,0x4(%esp)
80105adb:	80 
80105adc:	89 04 24             	mov    %eax,(%esp)
80105adf:	e8 c2 06 00 00       	call   801061a6 <memmove>
									   size+=2 ;
80105ae4:	83 45 f4 02          	addl   $0x2,-0xc(%ebp)
								   }
								   if (p->ofile[i]->writable){
80105ae8:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105aeb:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105aee:	83 c2 0c             	add    $0xc,%edx
80105af1:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105af5:	0f b6 40 09          	movzbl 0x9(%eax),%eax
80105af9:	84 c0                	test   %al,%al
80105afb:	74 27                	je     80105b24 <procfsread+0x4c6>
									   memmove(buf+size, "w ", 2);
80105afd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b00:	8d 95 dc fb ff ff    	lea    -0x424(%ebp),%edx
80105b06:	01 d0                	add    %edx,%eax
80105b08:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
80105b0f:	00 
80105b10:	c7 44 24 04 c8 98 10 	movl   $0x801098c8,0x4(%esp)
80105b17:	80 
80105b18:	89 04 24             	mov    %eax,(%esp)
80105b1b:	e8 86 06 00 00       	call   801061a6 <memmove>
									   size+=2 ;
80105b20:	83 45 f4 02          	addl   $0x2,-0xc(%ebp)
								   }
								   memmove(buf+size, "\n\0", 2);
80105b24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b27:	8d 95 dc fb ff ff    	lea    -0x424(%ebp),%edx
80105b2d:	01 d0                	add    %edx,%eax
80105b2f:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
80105b36:	00 
80105b37:	c7 44 24 04 cb 98 10 	movl   $0x801098cb,0x4(%esp)
80105b3e:	80 
80105b3f:	89 04 24             	mov    %eax,(%esp)
80105b42:	e8 5f 06 00 00       	call   801061a6 <memmove>
								   size++ ;
80105b47:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
							memmove(buf+size, "\n",1);
							size++;
                            break;
              case FDINFO_DNUM:
            	  	  	  	size= 0;
            	  	  	  	for (i =1 ; i < NOFILE; i++){
80105b4b:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80105b4f:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80105b53:	0f 8e 36 fd ff ff    	jle    8010588f <procfsread+0x231>
								   memmove(buf+size, "\n\0", 2);
								   size++ ;
            	  	  	  		}
            	  	  	  	}

            	  	  	    break;
80105b59:	e9 36 01 00 00       	jmp    80105c94 <procfsread+0x636>
              case STATUS_DNUM:
            	  	  	    size= 0;
80105b5e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
            	  	  	  	memmove(buf, "state: ",7);
80105b65:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
80105b6c:	00 
80105b6d:	c7 44 24 04 ce 98 10 	movl   $0x801098ce,0x4(%esp)
80105b74:	80 
80105b75:	8d 85 dc fb ff ff    	lea    -0x424(%ebp),%eax
80105b7b:	89 04 24             	mov    %eax,(%esp)
80105b7e:	e8 23 06 00 00       	call   801061a6 <memmove>
            	            size+=7;
80105b83:	83 45 f4 07          	addl   $0x7,-0xc(%ebp)

            	            if (p->state == SLEEPING){
80105b87:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105b8a:	8b 40 0c             	mov    0xc(%eax),%eax
80105b8d:	83 f8 02             	cmp    $0x2,%eax
80105b90:	75 27                	jne    80105bb9 <procfsread+0x55b>
							   memmove(buf+size, "SLEEPING ", 9);
80105b92:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b95:	8d 95 dc fb ff ff    	lea    -0x424(%ebp),%edx
80105b9b:	01 d0                	add    %edx,%eax
80105b9d:	c7 44 24 08 09 00 00 	movl   $0x9,0x8(%esp)
80105ba4:	00 
80105ba5:	c7 44 24 04 d6 98 10 	movl   $0x801098d6,0x4(%esp)
80105bac:	80 
80105bad:	89 04 24             	mov    %eax,(%esp)
80105bb0:	e8 f1 05 00 00       	call   801061a6 <memmove>
							   size+=9 ;
80105bb5:	83 45 f4 09          	addl   $0x9,-0xc(%ebp)
						    }
            	            if (p->state == RUNNING){
80105bb9:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105bbc:	8b 40 0c             	mov    0xc(%eax),%eax
80105bbf:	83 f8 04             	cmp    $0x4,%eax
80105bc2:	75 27                	jne    80105beb <procfsread+0x58d>
							   memmove(buf+size, "RUNNING ", 9);
80105bc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bc7:	8d 95 dc fb ff ff    	lea    -0x424(%ebp),%edx
80105bcd:	01 d0                	add    %edx,%eax
80105bcf:	c7 44 24 08 09 00 00 	movl   $0x9,0x8(%esp)
80105bd6:	00 
80105bd7:	c7 44 24 04 e0 98 10 	movl   $0x801098e0,0x4(%esp)
80105bde:	80 
80105bdf:	89 04 24             	mov    %eax,(%esp)
80105be2:	e8 bf 05 00 00       	call   801061a6 <memmove>
							   size+=9 ;
80105be7:	83 45 f4 09          	addl   $0x9,-0xc(%ebp)
						    }
            	            if (p->state == RUNNABLE){
80105beb:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105bee:	8b 40 0c             	mov    0xc(%eax),%eax
80105bf1:	83 f8 03             	cmp    $0x3,%eax
80105bf4:	75 27                	jne    80105c1d <procfsread+0x5bf>
							   memmove(buf+size, "RUNNABLE ", 10);
80105bf6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bf9:	8d 95 dc fb ff ff    	lea    -0x424(%ebp),%edx
80105bff:	01 d0                	add    %edx,%eax
80105c01:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
80105c08:	00 
80105c09:	c7 44 24 04 e9 98 10 	movl   $0x801098e9,0x4(%esp)
80105c10:	80 
80105c11:	89 04 24             	mov    %eax,(%esp)
80105c14:	e8 8d 05 00 00       	call   801061a6 <memmove>
							   size+=9 ;
80105c19:	83 45 f4 09          	addl   $0x9,-0xc(%ebp)
							}

            	            memmove(buf+size, "mem-size: ",10);
80105c1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c20:	8d 95 dc fb ff ff    	lea    -0x424(%ebp),%edx
80105c26:	01 d0                	add    %edx,%eax
80105c28:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
80105c2f:	00 
80105c30:	c7 44 24 04 f3 98 10 	movl   $0x801098f3,0x4(%esp)
80105c37:	80 
80105c38:	89 04 24             	mov    %eax,(%esp)
80105c3b:	e8 66 05 00 00       	call   801061a6 <memmove>
            	            size+=10;
80105c40:	83 45 f4 0a          	addl   $0xa,-0xc(%ebp)

            	            int k= itoa( p->sz, buf+size)+1;
80105c44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c47:	8d 95 dc fb ff ff    	lea    -0x424(%ebp),%edx
80105c4d:	01 c2                	add    %eax,%edx
80105c4f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105c52:	8b 00                	mov    (%eax),%eax
80105c54:	89 54 24 04          	mov    %edx,0x4(%esp)
80105c58:	89 04 24             	mov    %eax,(%esp)
80105c5b:	e8 c1 00 00 00       	call   80105d21 <itoa>
80105c60:	83 c0 01             	add    $0x1,%eax
80105c63:	89 45 e0             	mov    %eax,-0x20(%ebp)
							size+=k;
80105c66:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105c69:	01 45 f4             	add    %eax,-0xc(%ebp)
							memmove(buf+size, "\n\0", 2);
80105c6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c6f:	8d 95 dc fb ff ff    	lea    -0x424(%ebp),%edx
80105c75:	01 d0                	add    %edx,%eax
80105c77:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
80105c7e:	00 
80105c7f:	c7 44 24 04 cb 98 10 	movl   $0x801098cb,0x4(%esp)
80105c86:	80 
80105c87:	89 04 24             	mov    %eax,(%esp)
80105c8a:	e8 17 05 00 00       	call   801061a6 <memmove>
							size++ ;
80105c8f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
            	  	  	  	break;
80105c93:	90                   	nop


        }
    }

  if (off < size) {
80105c94:	8b 45 10             	mov    0x10(%ebp),%eax
80105c97:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80105c9a:	7d 40                	jge    80105cdc <procfsread+0x67e>
    int rr = size - off;
80105c9c:	8b 45 10             	mov    0x10(%ebp),%eax
80105c9f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105ca2:	29 c2                	sub    %eax,%edx
80105ca4:	89 d0                	mov    %edx,%eax
80105ca6:	89 45 dc             	mov    %eax,-0x24(%ebp)
    rr = rr < n ? rr : n;
80105ca9:	8b 45 dc             	mov    -0x24(%ebp),%eax
80105cac:	39 45 14             	cmp    %eax,0x14(%ebp)
80105caf:	0f 4e 45 14          	cmovle 0x14(%ebp),%eax
80105cb3:	89 45 dc             	mov    %eax,-0x24(%ebp)
    memmove(dst, buf + off, rr);
80105cb6:	8b 45 dc             	mov    -0x24(%ebp),%eax
80105cb9:	8b 55 10             	mov    0x10(%ebp),%edx
80105cbc:	8d 8d dc fb ff ff    	lea    -0x424(%ebp),%ecx
80105cc2:	01 ca                	add    %ecx,%edx
80105cc4:	89 44 24 08          	mov    %eax,0x8(%esp)
80105cc8:	89 54 24 04          	mov    %edx,0x4(%esp)
80105ccc:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ccf:	89 04 24             	mov    %eax,(%esp)
80105cd2:	e8 cf 04 00 00       	call   801061a6 <memmove>
    return rr;
80105cd7:	8b 45 dc             	mov    -0x24(%ebp),%eax
80105cda:	eb 05                	jmp    80105ce1 <procfsread+0x683>
  }

  return 0;
80105cdc:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105ce1:	81 c4 34 04 00 00    	add    $0x434,%esp
80105ce7:	5b                   	pop    %ebx
80105ce8:	5d                   	pop    %ebp
80105ce9:	c3                   	ret    

80105cea <procfswrite>:

int
procfswrite(struct inode *ip, char *buf, int n)
{
80105cea:	55                   	push   %ebp
80105ceb:	89 e5                	mov    %esp,%ebp
  return 0;
80105ced:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105cf2:	5d                   	pop    %ebp
80105cf3:	c3                   	ret    

80105cf4 <procfsinit>:

void
procfsinit(void)
{
80105cf4:	55                   	push   %ebp
80105cf5:	89 e5                	mov    %esp,%ebp
  devsw[PROCFS].isdir = procfsisdir;
80105cf7:	c7 05 00 22 11 80 3c 	movl   $0x8010523c,0x80112200
80105cfe:	52 10 80 
  devsw[PROCFS].iread = procfsiread;
80105d01:	c7 05 04 22 11 80 bd 	movl   $0x801052bd,0x80112204
80105d08:	52 10 80 
  devsw[PROCFS].write = procfswrite;
80105d0b:	c7 05 0c 22 11 80 ea 	movl   $0x80105cea,0x8011220c
80105d12:	5c 10 80 
  devsw[PROCFS].read = procfsread;
80105d15:	c7 05 08 22 11 80 5e 	movl   $0x8010565e,0x80112208
80105d1c:	56 10 80 
}
80105d1f:	5d                   	pop    %ebp
80105d20:	c3                   	ret    

80105d21 <itoa>:


//receives an integer and set stringNum to its string representation
// return the number of charachters in string num;

int  itoa(uint num , char *stringNum ){
80105d21:	55                   	push   %ebp
80105d22:	89 e5                	mov    %esp,%ebp
80105d24:	83 ec 10             	sub    $0x10,%esp

  int i, rem, len = 0, n;
80105d27:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  	if (num == 0){
80105d2e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80105d32:	75 0d                	jne    80105d41 <itoa+0x20>
  		stringNum[0]='0';
80105d34:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d37:	c6 00 30             	movb   $0x30,(%eax)
  		len=1;
80105d3a:	c7 45 f8 01 00 00 00 	movl   $0x1,-0x8(%ebp)
  	}
    n = num;
80105d41:	8b 45 08             	mov    0x8(%ebp),%eax
80105d44:	89 45 f4             	mov    %eax,-0xc(%ebp)
    while (n != 0)
80105d47:	eb 1f                	jmp    80105d68 <itoa+0x47>
    {
        len++;
80105d49:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
        n /= 10;
80105d4d:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80105d50:	ba 67 66 66 66       	mov    $0x66666667,%edx
80105d55:	89 c8                	mov    %ecx,%eax
80105d57:	f7 ea                	imul   %edx
80105d59:	c1 fa 02             	sar    $0x2,%edx
80105d5c:	89 c8                	mov    %ecx,%eax
80105d5e:	c1 f8 1f             	sar    $0x1f,%eax
80105d61:	29 c2                	sub    %eax,%edx
80105d63:	89 d0                	mov    %edx,%eax
80105d65:	89 45 f4             	mov    %eax,-0xc(%ebp)
  	if (num == 0){
  		stringNum[0]='0';
  		len=1;
  	}
    n = num;
    while (n != 0)
80105d68:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105d6c:	75 db                	jne    80105d49 <itoa+0x28>
    {
        len++;
        n /= 10;
    }
    for (i = 0; i < len; i++)
80105d6e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105d75:	eb 50                	jmp    80105dc7 <itoa+0xa6>
    {
        rem = num % 10;
80105d77:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105d7a:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
80105d7f:	89 c8                	mov    %ecx,%eax
80105d81:	f7 e2                	mul    %edx
80105d83:	c1 ea 03             	shr    $0x3,%edx
80105d86:	89 d0                	mov    %edx,%eax
80105d88:	c1 e0 02             	shl    $0x2,%eax
80105d8b:	01 d0                	add    %edx,%eax
80105d8d:	01 c0                	add    %eax,%eax
80105d8f:	29 c1                	sub    %eax,%ecx
80105d91:	89 ca                	mov    %ecx,%edx
80105d93:	89 55 f0             	mov    %edx,-0x10(%ebp)
        num = num / 10;
80105d96:	8b 45 08             	mov    0x8(%ebp),%eax
80105d99:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
80105d9e:	f7 e2                	mul    %edx
80105da0:	89 d0                	mov    %edx,%eax
80105da2:	c1 e8 03             	shr    $0x3,%eax
80105da5:	89 45 08             	mov    %eax,0x8(%ebp)
        stringNum[len - (i + 1)] = rem + '0';
80105da8:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105dab:	f7 d0                	not    %eax
80105dad:	89 c2                	mov    %eax,%edx
80105daf:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105db2:	01 d0                	add    %edx,%eax
80105db4:	89 c2                	mov    %eax,%edx
80105db6:	8b 45 0c             	mov    0xc(%ebp),%eax
80105db9:	01 c2                	add    %eax,%edx
80105dbb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dbe:	83 c0 30             	add    $0x30,%eax
80105dc1:	88 02                	mov    %al,(%edx)
    while (n != 0)
    {
        len++;
        n /= 10;
    }
    for (i = 0; i < len; i++)
80105dc3:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105dc7:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105dca:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105dcd:	7c a8                	jl     80105d77 <itoa+0x56>
    {
        rem = num % 10;
        num = num / 10;
        stringNum[len - (i + 1)] = rem + '0';
    }
    stringNum[len] = '\0';
80105dcf:	8b 55 f8             	mov    -0x8(%ebp),%edx
80105dd2:	8b 45 0c             	mov    0xc(%ebp),%eax
80105dd5:	01 d0                	add    %edx,%eax
80105dd7:	c6 00 00             	movb   $0x0,(%eax)
//    cprintf("%s %d \n", stringNum ,len);
    return len;
80105dda:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105ddd:	c9                   	leave  
80105dde:	c3                   	ret    

80105ddf <atoi>:

int atoi(const char *s)
{
80105ddf:	55                   	push   %ebp
80105de0:	89 e5                	mov    %esp,%ebp
80105de2:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
80105de5:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
80105dec:	eb 25                	jmp    80105e13 <atoi+0x34>
    n = n*10 + *s++ - '0';
80105dee:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105df1:	89 d0                	mov    %edx,%eax
80105df3:	c1 e0 02             	shl    $0x2,%eax
80105df6:	01 d0                	add    %edx,%eax
80105df8:	01 c0                	add    %eax,%eax
80105dfa:	89 c1                	mov    %eax,%ecx
80105dfc:	8b 45 08             	mov    0x8(%ebp),%eax
80105dff:	8d 50 01             	lea    0x1(%eax),%edx
80105e02:	89 55 08             	mov    %edx,0x8(%ebp)
80105e05:	0f b6 00             	movzbl (%eax),%eax
80105e08:	0f be c0             	movsbl %al,%eax
80105e0b:	01 c8                	add    %ecx,%eax
80105e0d:	83 e8 30             	sub    $0x30,%eax
80105e10:	89 45 fc             	mov    %eax,-0x4(%ebp)
int atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
80105e13:	8b 45 08             	mov    0x8(%ebp),%eax
80105e16:	0f b6 00             	movzbl (%eax),%eax
80105e19:	3c 2f                	cmp    $0x2f,%al
80105e1b:	7e 0a                	jle    80105e27 <atoi+0x48>
80105e1d:	8b 45 08             	mov    0x8(%ebp),%eax
80105e20:	0f b6 00             	movzbl (%eax),%eax
80105e23:	3c 39                	cmp    $0x39,%al
80105e25:	7e c7                	jle    80105dee <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
80105e27:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105e2a:	c9                   	leave  
80105e2b:	c3                   	ret    

80105e2c <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80105e2c:	55                   	push   %ebp
80105e2d:	89 e5                	mov    %esp,%ebp
80105e2f:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80105e32:	9c                   	pushf  
80105e33:	58                   	pop    %eax
80105e34:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80105e37:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105e3a:	c9                   	leave  
80105e3b:	c3                   	ret    

80105e3c <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80105e3c:	55                   	push   %ebp
80105e3d:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80105e3f:	fa                   	cli    
}
80105e40:	5d                   	pop    %ebp
80105e41:	c3                   	ret    

80105e42 <sti>:

static inline void
sti(void)
{
80105e42:	55                   	push   %ebp
80105e43:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105e45:	fb                   	sti    
}
80105e46:	5d                   	pop    %ebp
80105e47:	c3                   	ret    

80105e48 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105e48:	55                   	push   %ebp
80105e49:	89 e5                	mov    %esp,%ebp
80105e4b:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105e4e:	8b 55 08             	mov    0x8(%ebp),%edx
80105e51:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e54:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105e57:	f0 87 02             	lock xchg %eax,(%edx)
80105e5a:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80105e5d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105e60:	c9                   	leave  
80105e61:	c3                   	ret    

80105e62 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105e62:	55                   	push   %ebp
80105e63:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105e65:	8b 45 08             	mov    0x8(%ebp),%eax
80105e68:	8b 55 0c             	mov    0xc(%ebp),%edx
80105e6b:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80105e6e:	8b 45 08             	mov    0x8(%ebp),%eax
80105e71:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105e77:	8b 45 08             	mov    0x8(%ebp),%eax
80105e7a:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80105e81:	5d                   	pop    %ebp
80105e82:	c3                   	ret    

80105e83 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80105e83:	55                   	push   %ebp
80105e84:	89 e5                	mov    %esp,%ebp
80105e86:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80105e89:	e8 49 01 00 00       	call   80105fd7 <pushcli>
  if(holding(lk))
80105e8e:	8b 45 08             	mov    0x8(%ebp),%eax
80105e91:	89 04 24             	mov    %eax,(%esp)
80105e94:	e8 14 01 00 00       	call   80105fad <holding>
80105e99:	85 c0                	test   %eax,%eax
80105e9b:	74 0c                	je     80105ea9 <acquire+0x26>
    panic("acquire");
80105e9d:	c7 04 24 fe 98 10 80 	movl   $0x801098fe,(%esp)
80105ea4:	e8 91 a6 ff ff       	call   8010053a <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105ea9:	90                   	nop
80105eaa:	8b 45 08             	mov    0x8(%ebp),%eax
80105ead:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105eb4:	00 
80105eb5:	89 04 24             	mov    %eax,(%esp)
80105eb8:	e8 8b ff ff ff       	call   80105e48 <xchg>
80105ebd:	85 c0                	test   %eax,%eax
80105ebf:	75 e9                	jne    80105eaa <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80105ec1:	8b 45 08             	mov    0x8(%ebp),%eax
80105ec4:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105ecb:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105ece:	8b 45 08             	mov    0x8(%ebp),%eax
80105ed1:	83 c0 0c             	add    $0xc,%eax
80105ed4:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ed8:	8d 45 08             	lea    0x8(%ebp),%eax
80105edb:	89 04 24             	mov    %eax,(%esp)
80105ede:	e8 51 00 00 00       	call   80105f34 <getcallerpcs>
}
80105ee3:	c9                   	leave  
80105ee4:	c3                   	ret    

80105ee5 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105ee5:	55                   	push   %ebp
80105ee6:	89 e5                	mov    %esp,%ebp
80105ee8:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105eeb:	8b 45 08             	mov    0x8(%ebp),%eax
80105eee:	89 04 24             	mov    %eax,(%esp)
80105ef1:	e8 b7 00 00 00       	call   80105fad <holding>
80105ef6:	85 c0                	test   %eax,%eax
80105ef8:	75 0c                	jne    80105f06 <release+0x21>
    panic("release");
80105efa:	c7 04 24 06 99 10 80 	movl   $0x80109906,(%esp)
80105f01:	e8 34 a6 ff ff       	call   8010053a <panic>

  lk->pcs[0] = 0;
80105f06:	8b 45 08             	mov    0x8(%ebp),%eax
80105f09:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105f10:	8b 45 08             	mov    0x8(%ebp),%eax
80105f13:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105f1a:	8b 45 08             	mov    0x8(%ebp),%eax
80105f1d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105f24:	00 
80105f25:	89 04 24             	mov    %eax,(%esp)
80105f28:	e8 1b ff ff ff       	call   80105e48 <xchg>

  popcli();
80105f2d:	e8 e9 00 00 00       	call   8010601b <popcli>
}
80105f32:	c9                   	leave  
80105f33:	c3                   	ret    

80105f34 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105f34:	55                   	push   %ebp
80105f35:	89 e5                	mov    %esp,%ebp
80105f37:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80105f3a:	8b 45 08             	mov    0x8(%ebp),%eax
80105f3d:	83 e8 08             	sub    $0x8,%eax
80105f40:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105f43:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105f4a:	eb 38                	jmp    80105f84 <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105f4c:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105f50:	74 38                	je     80105f8a <getcallerpcs+0x56>
80105f52:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105f59:	76 2f                	jbe    80105f8a <getcallerpcs+0x56>
80105f5b:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105f5f:	74 29                	je     80105f8a <getcallerpcs+0x56>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105f61:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105f64:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105f6b:	8b 45 0c             	mov    0xc(%ebp),%eax
80105f6e:	01 c2                	add    %eax,%edx
80105f70:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f73:	8b 40 04             	mov    0x4(%eax),%eax
80105f76:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
80105f78:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f7b:	8b 00                	mov    (%eax),%eax
80105f7d:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105f80:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105f84:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105f88:	7e c2                	jle    80105f4c <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105f8a:	eb 19                	jmp    80105fa5 <getcallerpcs+0x71>
    pcs[i] = 0;
80105f8c:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105f8f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105f96:	8b 45 0c             	mov    0xc(%ebp),%eax
80105f99:	01 d0                	add    %edx,%eax
80105f9b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105fa1:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105fa5:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105fa9:	7e e1                	jle    80105f8c <getcallerpcs+0x58>
    pcs[i] = 0;
}
80105fab:	c9                   	leave  
80105fac:	c3                   	ret    

80105fad <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105fad:	55                   	push   %ebp
80105fae:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105fb0:	8b 45 08             	mov    0x8(%ebp),%eax
80105fb3:	8b 00                	mov    (%eax),%eax
80105fb5:	85 c0                	test   %eax,%eax
80105fb7:	74 17                	je     80105fd0 <holding+0x23>
80105fb9:	8b 45 08             	mov    0x8(%ebp),%eax
80105fbc:	8b 50 08             	mov    0x8(%eax),%edx
80105fbf:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105fc5:	39 c2                	cmp    %eax,%edx
80105fc7:	75 07                	jne    80105fd0 <holding+0x23>
80105fc9:	b8 01 00 00 00       	mov    $0x1,%eax
80105fce:	eb 05                	jmp    80105fd5 <holding+0x28>
80105fd0:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105fd5:	5d                   	pop    %ebp
80105fd6:	c3                   	ret    

80105fd7 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105fd7:	55                   	push   %ebp
80105fd8:	89 e5                	mov    %esp,%ebp
80105fda:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80105fdd:	e8 4a fe ff ff       	call   80105e2c <readeflags>
80105fe2:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105fe5:	e8 52 fe ff ff       	call   80105e3c <cli>
  if(cpu->ncli++ == 0)
80105fea:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105ff1:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
80105ff7:	8d 48 01             	lea    0x1(%eax),%ecx
80105ffa:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
80106000:	85 c0                	test   %eax,%eax
80106002:	75 15                	jne    80106019 <pushcli+0x42>
    cpu->intena = eflags & FL_IF;
80106004:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010600a:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010600d:	81 e2 00 02 00 00    	and    $0x200,%edx
80106013:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80106019:	c9                   	leave  
8010601a:	c3                   	ret    

8010601b <popcli>:

void
popcli(void)
{
8010601b:	55                   	push   %ebp
8010601c:	89 e5                	mov    %esp,%ebp
8010601e:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80106021:	e8 06 fe ff ff       	call   80105e2c <readeflags>
80106026:	25 00 02 00 00       	and    $0x200,%eax
8010602b:	85 c0                	test   %eax,%eax
8010602d:	74 0c                	je     8010603b <popcli+0x20>
    panic("popcli - interruptible");
8010602f:	c7 04 24 0e 99 10 80 	movl   $0x8010990e,(%esp)
80106036:	e8 ff a4 ff ff       	call   8010053a <panic>
  if(--cpu->ncli < 0)
8010603b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106041:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80106047:	83 ea 01             	sub    $0x1,%edx
8010604a:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80106050:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80106056:	85 c0                	test   %eax,%eax
80106058:	79 0c                	jns    80106066 <popcli+0x4b>
    panic("popcli");
8010605a:	c7 04 24 25 99 10 80 	movl   $0x80109925,(%esp)
80106061:	e8 d4 a4 ff ff       	call   8010053a <panic>
  if(cpu->ncli == 0 && cpu->intena)
80106066:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010606c:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80106072:	85 c0                	test   %eax,%eax
80106074:	75 15                	jne    8010608b <popcli+0x70>
80106076:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010607c:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80106082:	85 c0                	test   %eax,%eax
80106084:	74 05                	je     8010608b <popcli+0x70>
    sti();
80106086:	e8 b7 fd ff ff       	call   80105e42 <sti>
}
8010608b:	c9                   	leave  
8010608c:	c3                   	ret    

8010608d <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
8010608d:	55                   	push   %ebp
8010608e:	89 e5                	mov    %esp,%ebp
80106090:	57                   	push   %edi
80106091:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80106092:	8b 4d 08             	mov    0x8(%ebp),%ecx
80106095:	8b 55 10             	mov    0x10(%ebp),%edx
80106098:	8b 45 0c             	mov    0xc(%ebp),%eax
8010609b:	89 cb                	mov    %ecx,%ebx
8010609d:	89 df                	mov    %ebx,%edi
8010609f:	89 d1                	mov    %edx,%ecx
801060a1:	fc                   	cld    
801060a2:	f3 aa                	rep stos %al,%es:(%edi)
801060a4:	89 ca                	mov    %ecx,%edx
801060a6:	89 fb                	mov    %edi,%ebx
801060a8:	89 5d 08             	mov    %ebx,0x8(%ebp)
801060ab:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
801060ae:	5b                   	pop    %ebx
801060af:	5f                   	pop    %edi
801060b0:	5d                   	pop    %ebp
801060b1:	c3                   	ret    

801060b2 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
801060b2:	55                   	push   %ebp
801060b3:	89 e5                	mov    %esp,%ebp
801060b5:	57                   	push   %edi
801060b6:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
801060b7:	8b 4d 08             	mov    0x8(%ebp),%ecx
801060ba:	8b 55 10             	mov    0x10(%ebp),%edx
801060bd:	8b 45 0c             	mov    0xc(%ebp),%eax
801060c0:	89 cb                	mov    %ecx,%ebx
801060c2:	89 df                	mov    %ebx,%edi
801060c4:	89 d1                	mov    %edx,%ecx
801060c6:	fc                   	cld    
801060c7:	f3 ab                	rep stos %eax,%es:(%edi)
801060c9:	89 ca                	mov    %ecx,%edx
801060cb:	89 fb                	mov    %edi,%ebx
801060cd:	89 5d 08             	mov    %ebx,0x8(%ebp)
801060d0:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
801060d3:	5b                   	pop    %ebx
801060d4:	5f                   	pop    %edi
801060d5:	5d                   	pop    %ebp
801060d6:	c3                   	ret    

801060d7 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
801060d7:	55                   	push   %ebp
801060d8:	89 e5                	mov    %esp,%ebp
801060da:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
801060dd:	8b 45 08             	mov    0x8(%ebp),%eax
801060e0:	83 e0 03             	and    $0x3,%eax
801060e3:	85 c0                	test   %eax,%eax
801060e5:	75 49                	jne    80106130 <memset+0x59>
801060e7:	8b 45 10             	mov    0x10(%ebp),%eax
801060ea:	83 e0 03             	and    $0x3,%eax
801060ed:	85 c0                	test   %eax,%eax
801060ef:	75 3f                	jne    80106130 <memset+0x59>
    c &= 0xFF;
801060f1:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
801060f8:	8b 45 10             	mov    0x10(%ebp),%eax
801060fb:	c1 e8 02             	shr    $0x2,%eax
801060fe:	89 c2                	mov    %eax,%edx
80106100:	8b 45 0c             	mov    0xc(%ebp),%eax
80106103:	c1 e0 18             	shl    $0x18,%eax
80106106:	89 c1                	mov    %eax,%ecx
80106108:	8b 45 0c             	mov    0xc(%ebp),%eax
8010610b:	c1 e0 10             	shl    $0x10,%eax
8010610e:	09 c1                	or     %eax,%ecx
80106110:	8b 45 0c             	mov    0xc(%ebp),%eax
80106113:	c1 e0 08             	shl    $0x8,%eax
80106116:	09 c8                	or     %ecx,%eax
80106118:	0b 45 0c             	or     0xc(%ebp),%eax
8010611b:	89 54 24 08          	mov    %edx,0x8(%esp)
8010611f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106123:	8b 45 08             	mov    0x8(%ebp),%eax
80106126:	89 04 24             	mov    %eax,(%esp)
80106129:	e8 84 ff ff ff       	call   801060b2 <stosl>
8010612e:	eb 19                	jmp    80106149 <memset+0x72>
  } else
    stosb(dst, c, n);
80106130:	8b 45 10             	mov    0x10(%ebp),%eax
80106133:	89 44 24 08          	mov    %eax,0x8(%esp)
80106137:	8b 45 0c             	mov    0xc(%ebp),%eax
8010613a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010613e:	8b 45 08             	mov    0x8(%ebp),%eax
80106141:	89 04 24             	mov    %eax,(%esp)
80106144:	e8 44 ff ff ff       	call   8010608d <stosb>
  return dst;
80106149:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010614c:	c9                   	leave  
8010614d:	c3                   	ret    

8010614e <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
8010614e:	55                   	push   %ebp
8010614f:	89 e5                	mov    %esp,%ebp
80106151:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80106154:	8b 45 08             	mov    0x8(%ebp),%eax
80106157:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
8010615a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010615d:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80106160:	eb 30                	jmp    80106192 <memcmp+0x44>
    if(*s1 != *s2)
80106162:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106165:	0f b6 10             	movzbl (%eax),%edx
80106168:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010616b:	0f b6 00             	movzbl (%eax),%eax
8010616e:	38 c2                	cmp    %al,%dl
80106170:	74 18                	je     8010618a <memcmp+0x3c>
      return *s1 - *s2;
80106172:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106175:	0f b6 00             	movzbl (%eax),%eax
80106178:	0f b6 d0             	movzbl %al,%edx
8010617b:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010617e:	0f b6 00             	movzbl (%eax),%eax
80106181:	0f b6 c0             	movzbl %al,%eax
80106184:	29 c2                	sub    %eax,%edx
80106186:	89 d0                	mov    %edx,%eax
80106188:	eb 1a                	jmp    801061a4 <memcmp+0x56>
    s1++, s2++;
8010618a:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010618e:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80106192:	8b 45 10             	mov    0x10(%ebp),%eax
80106195:	8d 50 ff             	lea    -0x1(%eax),%edx
80106198:	89 55 10             	mov    %edx,0x10(%ebp)
8010619b:	85 c0                	test   %eax,%eax
8010619d:	75 c3                	jne    80106162 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
8010619f:	b8 00 00 00 00       	mov    $0x0,%eax
}
801061a4:	c9                   	leave  
801061a5:	c3                   	ret    

801061a6 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
801061a6:	55                   	push   %ebp
801061a7:	89 e5                	mov    %esp,%ebp
801061a9:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
801061ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801061af:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
801061b2:	8b 45 08             	mov    0x8(%ebp),%eax
801061b5:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
801061b8:	8b 45 fc             	mov    -0x4(%ebp),%eax
801061bb:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801061be:	73 3d                	jae    801061fd <memmove+0x57>
801061c0:	8b 45 10             	mov    0x10(%ebp),%eax
801061c3:	8b 55 fc             	mov    -0x4(%ebp),%edx
801061c6:	01 d0                	add    %edx,%eax
801061c8:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801061cb:	76 30                	jbe    801061fd <memmove+0x57>
    s += n;
801061cd:	8b 45 10             	mov    0x10(%ebp),%eax
801061d0:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
801061d3:	8b 45 10             	mov    0x10(%ebp),%eax
801061d6:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
801061d9:	eb 13                	jmp    801061ee <memmove+0x48>
      *--d = *--s;
801061db:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
801061df:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
801061e3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801061e6:	0f b6 10             	movzbl (%eax),%edx
801061e9:	8b 45 f8             	mov    -0x8(%ebp),%eax
801061ec:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
801061ee:	8b 45 10             	mov    0x10(%ebp),%eax
801061f1:	8d 50 ff             	lea    -0x1(%eax),%edx
801061f4:	89 55 10             	mov    %edx,0x10(%ebp)
801061f7:	85 c0                	test   %eax,%eax
801061f9:	75 e0                	jne    801061db <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
801061fb:	eb 26                	jmp    80106223 <memmove+0x7d>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
801061fd:	eb 17                	jmp    80106216 <memmove+0x70>
      *d++ = *s++;
801061ff:	8b 45 f8             	mov    -0x8(%ebp),%eax
80106202:	8d 50 01             	lea    0x1(%eax),%edx
80106205:	89 55 f8             	mov    %edx,-0x8(%ebp)
80106208:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010620b:	8d 4a 01             	lea    0x1(%edx),%ecx
8010620e:	89 4d fc             	mov    %ecx,-0x4(%ebp)
80106211:	0f b6 12             	movzbl (%edx),%edx
80106214:	88 10                	mov    %dl,(%eax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80106216:	8b 45 10             	mov    0x10(%ebp),%eax
80106219:	8d 50 ff             	lea    -0x1(%eax),%edx
8010621c:	89 55 10             	mov    %edx,0x10(%ebp)
8010621f:	85 c0                	test   %eax,%eax
80106221:	75 dc                	jne    801061ff <memmove+0x59>
      *d++ = *s++;

  return dst;
80106223:	8b 45 08             	mov    0x8(%ebp),%eax
}
80106226:	c9                   	leave  
80106227:	c3                   	ret    

80106228 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80106228:	55                   	push   %ebp
80106229:	89 e5                	mov    %esp,%ebp
8010622b:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
8010622e:	8b 45 10             	mov    0x10(%ebp),%eax
80106231:	89 44 24 08          	mov    %eax,0x8(%esp)
80106235:	8b 45 0c             	mov    0xc(%ebp),%eax
80106238:	89 44 24 04          	mov    %eax,0x4(%esp)
8010623c:	8b 45 08             	mov    0x8(%ebp),%eax
8010623f:	89 04 24             	mov    %eax,(%esp)
80106242:	e8 5f ff ff ff       	call   801061a6 <memmove>
}
80106247:	c9                   	leave  
80106248:	c3                   	ret    

80106249 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80106249:	55                   	push   %ebp
8010624a:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
8010624c:	eb 0c                	jmp    8010625a <strncmp+0x11>
    n--, p++, q++;
8010624e:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80106252:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80106256:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
8010625a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010625e:	74 1a                	je     8010627a <strncmp+0x31>
80106260:	8b 45 08             	mov    0x8(%ebp),%eax
80106263:	0f b6 00             	movzbl (%eax),%eax
80106266:	84 c0                	test   %al,%al
80106268:	74 10                	je     8010627a <strncmp+0x31>
8010626a:	8b 45 08             	mov    0x8(%ebp),%eax
8010626d:	0f b6 10             	movzbl (%eax),%edx
80106270:	8b 45 0c             	mov    0xc(%ebp),%eax
80106273:	0f b6 00             	movzbl (%eax),%eax
80106276:	38 c2                	cmp    %al,%dl
80106278:	74 d4                	je     8010624e <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
8010627a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010627e:	75 07                	jne    80106287 <strncmp+0x3e>
    return 0;
80106280:	b8 00 00 00 00       	mov    $0x0,%eax
80106285:	eb 16                	jmp    8010629d <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
80106287:	8b 45 08             	mov    0x8(%ebp),%eax
8010628a:	0f b6 00             	movzbl (%eax),%eax
8010628d:	0f b6 d0             	movzbl %al,%edx
80106290:	8b 45 0c             	mov    0xc(%ebp),%eax
80106293:	0f b6 00             	movzbl (%eax),%eax
80106296:	0f b6 c0             	movzbl %al,%eax
80106299:	29 c2                	sub    %eax,%edx
8010629b:	89 d0                	mov    %edx,%eax
}
8010629d:	5d                   	pop    %ebp
8010629e:	c3                   	ret    

8010629f <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
8010629f:	55                   	push   %ebp
801062a0:	89 e5                	mov    %esp,%ebp
801062a2:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
801062a5:	8b 45 08             	mov    0x8(%ebp),%eax
801062a8:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
801062ab:	90                   	nop
801062ac:	8b 45 10             	mov    0x10(%ebp),%eax
801062af:	8d 50 ff             	lea    -0x1(%eax),%edx
801062b2:	89 55 10             	mov    %edx,0x10(%ebp)
801062b5:	85 c0                	test   %eax,%eax
801062b7:	7e 1e                	jle    801062d7 <strncpy+0x38>
801062b9:	8b 45 08             	mov    0x8(%ebp),%eax
801062bc:	8d 50 01             	lea    0x1(%eax),%edx
801062bf:	89 55 08             	mov    %edx,0x8(%ebp)
801062c2:	8b 55 0c             	mov    0xc(%ebp),%edx
801062c5:	8d 4a 01             	lea    0x1(%edx),%ecx
801062c8:	89 4d 0c             	mov    %ecx,0xc(%ebp)
801062cb:	0f b6 12             	movzbl (%edx),%edx
801062ce:	88 10                	mov    %dl,(%eax)
801062d0:	0f b6 00             	movzbl (%eax),%eax
801062d3:	84 c0                	test   %al,%al
801062d5:	75 d5                	jne    801062ac <strncpy+0xd>
    ;
  while(n-- > 0)
801062d7:	eb 0c                	jmp    801062e5 <strncpy+0x46>
    *s++ = 0;
801062d9:	8b 45 08             	mov    0x8(%ebp),%eax
801062dc:	8d 50 01             	lea    0x1(%eax),%edx
801062df:	89 55 08             	mov    %edx,0x8(%ebp)
801062e2:	c6 00 00             	movb   $0x0,(%eax)
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
801062e5:	8b 45 10             	mov    0x10(%ebp),%eax
801062e8:	8d 50 ff             	lea    -0x1(%eax),%edx
801062eb:	89 55 10             	mov    %edx,0x10(%ebp)
801062ee:	85 c0                	test   %eax,%eax
801062f0:	7f e7                	jg     801062d9 <strncpy+0x3a>
    *s++ = 0;
  return os;
801062f2:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801062f5:	c9                   	leave  
801062f6:	c3                   	ret    

801062f7 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
801062f7:	55                   	push   %ebp
801062f8:	89 e5                	mov    %esp,%ebp
801062fa:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
801062fd:	8b 45 08             	mov    0x8(%ebp),%eax
80106300:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80106303:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106307:	7f 05                	jg     8010630e <safestrcpy+0x17>
    return os;
80106309:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010630c:	eb 31                	jmp    8010633f <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
8010630e:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80106312:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106316:	7e 1e                	jle    80106336 <safestrcpy+0x3f>
80106318:	8b 45 08             	mov    0x8(%ebp),%eax
8010631b:	8d 50 01             	lea    0x1(%eax),%edx
8010631e:	89 55 08             	mov    %edx,0x8(%ebp)
80106321:	8b 55 0c             	mov    0xc(%ebp),%edx
80106324:	8d 4a 01             	lea    0x1(%edx),%ecx
80106327:	89 4d 0c             	mov    %ecx,0xc(%ebp)
8010632a:	0f b6 12             	movzbl (%edx),%edx
8010632d:	88 10                	mov    %dl,(%eax)
8010632f:	0f b6 00             	movzbl (%eax),%eax
80106332:	84 c0                	test   %al,%al
80106334:	75 d8                	jne    8010630e <safestrcpy+0x17>
    ;
  *s = 0;
80106336:	8b 45 08             	mov    0x8(%ebp),%eax
80106339:	c6 00 00             	movb   $0x0,(%eax)
  return os;
8010633c:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010633f:	c9                   	leave  
80106340:	c3                   	ret    

80106341 <strlen>:

int
strlen(const char *s)
{
80106341:	55                   	push   %ebp
80106342:	89 e5                	mov    %esp,%ebp
80106344:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80106347:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010634e:	eb 04                	jmp    80106354 <strlen+0x13>
80106350:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80106354:	8b 55 fc             	mov    -0x4(%ebp),%edx
80106357:	8b 45 08             	mov    0x8(%ebp),%eax
8010635a:	01 d0                	add    %edx,%eax
8010635c:	0f b6 00             	movzbl (%eax),%eax
8010635f:	84 c0                	test   %al,%al
80106361:	75 ed                	jne    80106350 <strlen+0xf>
    ;
  return n;
80106363:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106366:	c9                   	leave  
80106367:	c3                   	ret    

80106368 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80106368:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
8010636c:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80106370:	55                   	push   %ebp
  pushl %ebx
80106371:	53                   	push   %ebx
  pushl %esi
80106372:	56                   	push   %esi
  pushl %edi
80106373:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80106374:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80106376:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80106378:	5f                   	pop    %edi
  popl %esi
80106379:	5e                   	pop    %esi
  popl %ebx
8010637a:	5b                   	pop    %ebx
  popl %ebp
8010637b:	5d                   	pop    %ebp
  ret
8010637c:	c3                   	ret    

8010637d <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
8010637d:	55                   	push   %ebp
8010637e:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
80106380:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106386:	8b 00                	mov    (%eax),%eax
80106388:	3b 45 08             	cmp    0x8(%ebp),%eax
8010638b:	76 12                	jbe    8010639f <fetchint+0x22>
8010638d:	8b 45 08             	mov    0x8(%ebp),%eax
80106390:	8d 50 04             	lea    0x4(%eax),%edx
80106393:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106399:	8b 00                	mov    (%eax),%eax
8010639b:	39 c2                	cmp    %eax,%edx
8010639d:	76 07                	jbe    801063a6 <fetchint+0x29>
    return -1;
8010639f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063a4:	eb 0f                	jmp    801063b5 <fetchint+0x38>
  *ip = *(int*)(addr);
801063a6:	8b 45 08             	mov    0x8(%ebp),%eax
801063a9:	8b 10                	mov    (%eax),%edx
801063ab:	8b 45 0c             	mov    0xc(%ebp),%eax
801063ae:	89 10                	mov    %edx,(%eax)
  return 0;
801063b0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801063b5:	5d                   	pop    %ebp
801063b6:	c3                   	ret    

801063b7 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
801063b7:	55                   	push   %ebp
801063b8:	89 e5                	mov    %esp,%ebp
801063ba:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
801063bd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801063c3:	8b 00                	mov    (%eax),%eax
801063c5:	3b 45 08             	cmp    0x8(%ebp),%eax
801063c8:	77 07                	ja     801063d1 <fetchstr+0x1a>
    return -1;
801063ca:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063cf:	eb 46                	jmp    80106417 <fetchstr+0x60>
  *pp = (char*)addr;
801063d1:	8b 55 08             	mov    0x8(%ebp),%edx
801063d4:	8b 45 0c             	mov    0xc(%ebp),%eax
801063d7:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
801063d9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801063df:	8b 00                	mov    (%eax),%eax
801063e1:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
801063e4:	8b 45 0c             	mov    0xc(%ebp),%eax
801063e7:	8b 00                	mov    (%eax),%eax
801063e9:	89 45 fc             	mov    %eax,-0x4(%ebp)
801063ec:	eb 1c                	jmp    8010640a <fetchstr+0x53>
    if(*s == 0)
801063ee:	8b 45 fc             	mov    -0x4(%ebp),%eax
801063f1:	0f b6 00             	movzbl (%eax),%eax
801063f4:	84 c0                	test   %al,%al
801063f6:	75 0e                	jne    80106406 <fetchstr+0x4f>
      return s - *pp;
801063f8:	8b 55 fc             	mov    -0x4(%ebp),%edx
801063fb:	8b 45 0c             	mov    0xc(%ebp),%eax
801063fe:	8b 00                	mov    (%eax),%eax
80106400:	29 c2                	sub    %eax,%edx
80106402:	89 d0                	mov    %edx,%eax
80106404:	eb 11                	jmp    80106417 <fetchstr+0x60>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
80106406:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010640a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010640d:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80106410:	72 dc                	jb     801063ee <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
80106412:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106417:	c9                   	leave  
80106418:	c3                   	ret    

80106419 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80106419:	55                   	push   %ebp
8010641a:	89 e5                	mov    %esp,%ebp
8010641c:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->tf->esp + 4 + 4*n, ip);
8010641f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106425:	8b 40 18             	mov    0x18(%eax),%eax
80106428:	8b 50 44             	mov    0x44(%eax),%edx
8010642b:	8b 45 08             	mov    0x8(%ebp),%eax
8010642e:	c1 e0 02             	shl    $0x2,%eax
80106431:	01 d0                	add    %edx,%eax
80106433:	8d 50 04             	lea    0x4(%eax),%edx
80106436:	8b 45 0c             	mov    0xc(%ebp),%eax
80106439:	89 44 24 04          	mov    %eax,0x4(%esp)
8010643d:	89 14 24             	mov    %edx,(%esp)
80106440:	e8 38 ff ff ff       	call   8010637d <fetchint>
}
80106445:	c9                   	leave  
80106446:	c3                   	ret    

80106447 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80106447:	55                   	push   %ebp
80106448:	89 e5                	mov    %esp,%ebp
8010644a:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
8010644d:	8d 45 fc             	lea    -0x4(%ebp),%eax
80106450:	89 44 24 04          	mov    %eax,0x4(%esp)
80106454:	8b 45 08             	mov    0x8(%ebp),%eax
80106457:	89 04 24             	mov    %eax,(%esp)
8010645a:	e8 ba ff ff ff       	call   80106419 <argint>
8010645f:	85 c0                	test   %eax,%eax
80106461:	79 07                	jns    8010646a <argptr+0x23>
    return -1;
80106463:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106468:	eb 3d                	jmp    801064a7 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
8010646a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010646d:	89 c2                	mov    %eax,%edx
8010646f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106475:	8b 00                	mov    (%eax),%eax
80106477:	39 c2                	cmp    %eax,%edx
80106479:	73 16                	jae    80106491 <argptr+0x4a>
8010647b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010647e:	89 c2                	mov    %eax,%edx
80106480:	8b 45 10             	mov    0x10(%ebp),%eax
80106483:	01 c2                	add    %eax,%edx
80106485:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010648b:	8b 00                	mov    (%eax),%eax
8010648d:	39 c2                	cmp    %eax,%edx
8010648f:	76 07                	jbe    80106498 <argptr+0x51>
    return -1;
80106491:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106496:	eb 0f                	jmp    801064a7 <argptr+0x60>
  *pp = (char*)i;
80106498:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010649b:	89 c2                	mov    %eax,%edx
8010649d:	8b 45 0c             	mov    0xc(%ebp),%eax
801064a0:	89 10                	mov    %edx,(%eax)
  return 0;
801064a2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801064a7:	c9                   	leave  
801064a8:	c3                   	ret    

801064a9 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
801064a9:	55                   	push   %ebp
801064aa:	89 e5                	mov    %esp,%ebp
801064ac:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
801064af:	8d 45 fc             	lea    -0x4(%ebp),%eax
801064b2:	89 44 24 04          	mov    %eax,0x4(%esp)
801064b6:	8b 45 08             	mov    0x8(%ebp),%eax
801064b9:	89 04 24             	mov    %eax,(%esp)
801064bc:	e8 58 ff ff ff       	call   80106419 <argint>
801064c1:	85 c0                	test   %eax,%eax
801064c3:	79 07                	jns    801064cc <argstr+0x23>
    return -1;
801064c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064ca:	eb 12                	jmp    801064de <argstr+0x35>
  return fetchstr(addr, pp);
801064cc:	8b 45 fc             	mov    -0x4(%ebp),%eax
801064cf:	8b 55 0c             	mov    0xc(%ebp),%edx
801064d2:	89 54 24 04          	mov    %edx,0x4(%esp)
801064d6:	89 04 24             	mov    %eax,(%esp)
801064d9:	e8 d9 fe ff ff       	call   801063b7 <fetchstr>
}
801064de:	c9                   	leave  
801064df:	c3                   	ret    

801064e0 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
801064e0:	55                   	push   %ebp
801064e1:	89 e5                	mov    %esp,%ebp
801064e3:	53                   	push   %ebx
801064e4:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
801064e7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064ed:	8b 40 18             	mov    0x18(%eax),%eax
801064f0:	8b 40 1c             	mov    0x1c(%eax),%eax
801064f3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
801064f6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801064fa:	7e 30                	jle    8010652c <syscall+0x4c>
801064fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064ff:	83 f8 15             	cmp    $0x15,%eax
80106502:	77 28                	ja     8010652c <syscall+0x4c>
80106504:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106507:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
8010650e:	85 c0                	test   %eax,%eax
80106510:	74 1a                	je     8010652c <syscall+0x4c>
    proc->tf->eax = syscalls[num]();
80106512:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106518:	8b 58 18             	mov    0x18(%eax),%ebx
8010651b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010651e:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80106525:	ff d0                	call   *%eax
80106527:	89 43 1c             	mov    %eax,0x1c(%ebx)
8010652a:	eb 3d                	jmp    80106569 <syscall+0x89>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
8010652c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106532:	8d 48 28             	lea    0x28(%eax),%ecx
80106535:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
8010653b:	8b 40 10             	mov    0x10(%eax),%eax
8010653e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106541:	89 54 24 0c          	mov    %edx,0xc(%esp)
80106545:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106549:	89 44 24 04          	mov    %eax,0x4(%esp)
8010654d:	c7 04 24 2c 99 10 80 	movl   $0x8010992c,(%esp)
80106554:	e8 47 9e ff ff       	call   801003a0 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80106559:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010655f:	8b 40 18             	mov    0x18(%eax),%eax
80106562:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80106569:	83 c4 24             	add    $0x24,%esp
8010656c:	5b                   	pop    %ebx
8010656d:	5d                   	pop    %ebp
8010656e:	c3                   	ret    

8010656f <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
8010656f:	55                   	push   %ebp
80106570:	89 e5                	mov    %esp,%ebp
80106572:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80106575:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106578:	89 44 24 04          	mov    %eax,0x4(%esp)
8010657c:	8b 45 08             	mov    0x8(%ebp),%eax
8010657f:	89 04 24             	mov    %eax,(%esp)
80106582:	e8 92 fe ff ff       	call   80106419 <argint>
80106587:	85 c0                	test   %eax,%eax
80106589:	79 07                	jns    80106592 <argfd+0x23>
    return -1;
8010658b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106590:	eb 50                	jmp    801065e2 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80106592:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106595:	85 c0                	test   %eax,%eax
80106597:	78 21                	js     801065ba <argfd+0x4b>
80106599:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010659c:	83 f8 0f             	cmp    $0xf,%eax
8010659f:	7f 19                	jg     801065ba <argfd+0x4b>
801065a1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801065a7:	8b 55 f0             	mov    -0x10(%ebp),%edx
801065aa:	83 c2 0c             	add    $0xc,%edx
801065ad:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801065b1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801065b4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801065b8:	75 07                	jne    801065c1 <argfd+0x52>
    return -1;
801065ba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065bf:	eb 21                	jmp    801065e2 <argfd+0x73>
  if(pfd)
801065c1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801065c5:	74 08                	je     801065cf <argfd+0x60>
    *pfd = fd;
801065c7:	8b 55 f0             	mov    -0x10(%ebp),%edx
801065ca:	8b 45 0c             	mov    0xc(%ebp),%eax
801065cd:	89 10                	mov    %edx,(%eax)
  if(pf)
801065cf:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801065d3:	74 08                	je     801065dd <argfd+0x6e>
    *pf = f;
801065d5:	8b 45 10             	mov    0x10(%ebp),%eax
801065d8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801065db:	89 10                	mov    %edx,(%eax)
  return 0;
801065dd:	b8 00 00 00 00       	mov    $0x0,%eax
}
801065e2:	c9                   	leave  
801065e3:	c3                   	ret    

801065e4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801065e4:	55                   	push   %ebp
801065e5:	89 e5                	mov    %esp,%ebp
801065e7:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801065ea:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801065f1:	eb 30                	jmp    80106623 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
801065f3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801065f9:	8b 55 fc             	mov    -0x4(%ebp),%edx
801065fc:	83 c2 0c             	add    $0xc,%edx
801065ff:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80106603:	85 c0                	test   %eax,%eax
80106605:	75 18                	jne    8010661f <fdalloc+0x3b>
      proc->ofile[fd] = f;
80106607:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010660d:	8b 55 fc             	mov    -0x4(%ebp),%edx
80106610:	8d 4a 0c             	lea    0xc(%edx),%ecx
80106613:	8b 55 08             	mov    0x8(%ebp),%edx
80106616:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
8010661a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010661d:	eb 0f                	jmp    8010662e <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
8010661f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80106623:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80106627:	7e ca                	jle    801065f3 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80106629:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010662e:	c9                   	leave  
8010662f:	c3                   	ret    

80106630 <sys_dup>:

int
sys_dup(void)
{
80106630:	55                   	push   %ebp
80106631:	89 e5                	mov    %esp,%ebp
80106633:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80106636:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106639:	89 44 24 08          	mov    %eax,0x8(%esp)
8010663d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106644:	00 
80106645:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010664c:	e8 1e ff ff ff       	call   8010656f <argfd>
80106651:	85 c0                	test   %eax,%eax
80106653:	79 07                	jns    8010665c <sys_dup+0x2c>
    return -1;
80106655:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010665a:	eb 29                	jmp    80106685 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
8010665c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010665f:	89 04 24             	mov    %eax,(%esp)
80106662:	e8 7d ff ff ff       	call   801065e4 <fdalloc>
80106667:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010666a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010666e:	79 07                	jns    80106677 <sys_dup+0x47>
    return -1;
80106670:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106675:	eb 0e                	jmp    80106685 <sys_dup+0x55>
  filedup(f);
80106677:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010667a:	89 04 24             	mov    %eax,(%esp)
8010667d:	e8 04 aa ff ff       	call   80101086 <filedup>
  return fd;
80106682:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106685:	c9                   	leave  
80106686:	c3                   	ret    

80106687 <sys_read>:

int
sys_read(void)
{
80106687:	55                   	push   %ebp
80106688:	89 e5                	mov    %esp,%ebp
8010668a:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010668d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106690:	89 44 24 08          	mov    %eax,0x8(%esp)
80106694:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010669b:	00 
8010669c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801066a3:	e8 c7 fe ff ff       	call   8010656f <argfd>
801066a8:	85 c0                	test   %eax,%eax
801066aa:	78 35                	js     801066e1 <sys_read+0x5a>
801066ac:	8d 45 f0             	lea    -0x10(%ebp),%eax
801066af:	89 44 24 04          	mov    %eax,0x4(%esp)
801066b3:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801066ba:	e8 5a fd ff ff       	call   80106419 <argint>
801066bf:	85 c0                	test   %eax,%eax
801066c1:	78 1e                	js     801066e1 <sys_read+0x5a>
801066c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066c6:	89 44 24 08          	mov    %eax,0x8(%esp)
801066ca:	8d 45 ec             	lea    -0x14(%ebp),%eax
801066cd:	89 44 24 04          	mov    %eax,0x4(%esp)
801066d1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801066d8:	e8 6a fd ff ff       	call   80106447 <argptr>
801066dd:	85 c0                	test   %eax,%eax
801066df:	79 07                	jns    801066e8 <sys_read+0x61>
    return -1;
801066e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801066e6:	eb 19                	jmp    80106701 <sys_read+0x7a>
  return fileread(f, p, n);
801066e8:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801066eb:	8b 55 ec             	mov    -0x14(%ebp),%edx
801066ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066f1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801066f5:	89 54 24 04          	mov    %edx,0x4(%esp)
801066f9:	89 04 24             	mov    %eax,(%esp)
801066fc:	e8 f2 aa ff ff       	call   801011f3 <fileread>
}
80106701:	c9                   	leave  
80106702:	c3                   	ret    

80106703 <sys_write>:

int
sys_write(void)
{
80106703:	55                   	push   %ebp
80106704:	89 e5                	mov    %esp,%ebp
80106706:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80106709:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010670c:	89 44 24 08          	mov    %eax,0x8(%esp)
80106710:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106717:	00 
80106718:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010671f:	e8 4b fe ff ff       	call   8010656f <argfd>
80106724:	85 c0                	test   %eax,%eax
80106726:	78 35                	js     8010675d <sys_write+0x5a>
80106728:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010672b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010672f:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106736:	e8 de fc ff ff       	call   80106419 <argint>
8010673b:	85 c0                	test   %eax,%eax
8010673d:	78 1e                	js     8010675d <sys_write+0x5a>
8010673f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106742:	89 44 24 08          	mov    %eax,0x8(%esp)
80106746:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106749:	89 44 24 04          	mov    %eax,0x4(%esp)
8010674d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106754:	e8 ee fc ff ff       	call   80106447 <argptr>
80106759:	85 c0                	test   %eax,%eax
8010675b:	79 07                	jns    80106764 <sys_write+0x61>
    return -1;
8010675d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106762:	eb 19                	jmp    8010677d <sys_write+0x7a>
  return filewrite(f, p, n);
80106764:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106767:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010676a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010676d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106771:	89 54 24 04          	mov    %edx,0x4(%esp)
80106775:	89 04 24             	mov    %eax,(%esp)
80106778:	e8 32 ab ff ff       	call   801012af <filewrite>
}
8010677d:	c9                   	leave  
8010677e:	c3                   	ret    

8010677f <sys_close>:

int
sys_close(void)
{
8010677f:	55                   	push   %ebp
80106780:	89 e5                	mov    %esp,%ebp
80106782:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
80106785:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106788:	89 44 24 08          	mov    %eax,0x8(%esp)
8010678c:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010678f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106793:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010679a:	e8 d0 fd ff ff       	call   8010656f <argfd>
8010679f:	85 c0                	test   %eax,%eax
801067a1:	79 07                	jns    801067aa <sys_close+0x2b>
    return -1;
801067a3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067a8:	eb 24                	jmp    801067ce <sys_close+0x4f>
  proc->ofile[fd] = 0;
801067aa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801067b0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801067b3:	83 c2 0c             	add    $0xc,%edx
801067b6:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801067bd:	00 
  fileclose(f);
801067be:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067c1:	89 04 24             	mov    %eax,(%esp)
801067c4:	e8 05 a9 ff ff       	call   801010ce <fileclose>
  return 0;
801067c9:	b8 00 00 00 00       	mov    $0x0,%eax
}
801067ce:	c9                   	leave  
801067cf:	c3                   	ret    

801067d0 <sys_fstat>:

int
sys_fstat(void)
{
801067d0:	55                   	push   %ebp
801067d1:	89 e5                	mov    %esp,%ebp
801067d3:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801067d6:	8d 45 f4             	lea    -0xc(%ebp),%eax
801067d9:	89 44 24 08          	mov    %eax,0x8(%esp)
801067dd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801067e4:	00 
801067e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801067ec:	e8 7e fd ff ff       	call   8010656f <argfd>
801067f1:	85 c0                	test   %eax,%eax
801067f3:	78 1f                	js     80106814 <sys_fstat+0x44>
801067f5:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801067fc:	00 
801067fd:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106800:	89 44 24 04          	mov    %eax,0x4(%esp)
80106804:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010680b:	e8 37 fc ff ff       	call   80106447 <argptr>
80106810:	85 c0                	test   %eax,%eax
80106812:	79 07                	jns    8010681b <sys_fstat+0x4b>
    return -1;
80106814:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106819:	eb 12                	jmp    8010682d <sys_fstat+0x5d>
  return filestat(f, st);
8010681b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010681e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106821:	89 54 24 04          	mov    %edx,0x4(%esp)
80106825:	89 04 24             	mov    %eax,(%esp)
80106828:	e8 77 a9 ff ff       	call   801011a4 <filestat>
}
8010682d:	c9                   	leave  
8010682e:	c3                   	ret    

8010682f <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
8010682f:	55                   	push   %ebp
80106830:	89 e5                	mov    %esp,%ebp
80106832:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80106835:	8d 45 d8             	lea    -0x28(%ebp),%eax
80106838:	89 44 24 04          	mov    %eax,0x4(%esp)
8010683c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106843:	e8 61 fc ff ff       	call   801064a9 <argstr>
80106848:	85 c0                	test   %eax,%eax
8010684a:	78 17                	js     80106863 <sys_link+0x34>
8010684c:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010684f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106853:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010685a:	e8 4a fc ff ff       	call   801064a9 <argstr>
8010685f:	85 c0                	test   %eax,%eax
80106861:	79 0a                	jns    8010686d <sys_link+0x3e>
    return -1;
80106863:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106868:	e9 42 01 00 00       	jmp    801069af <sys_link+0x180>

  begin_op();
8010686d:	e8 b9 cd ff ff       	call   8010362b <begin_op>
  if((ip = namei(old)) == 0){
80106872:	8b 45 d8             	mov    -0x28(%ebp),%eax
80106875:	89 04 24             	mov    %eax,(%esp)
80106878:	e8 a4 bd ff ff       	call   80102621 <namei>
8010687d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106880:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106884:	75 0f                	jne    80106895 <sys_link+0x66>
    end_op();
80106886:	e8 24 ce ff ff       	call   801036af <end_op>
    return -1;
8010688b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106890:	e9 1a 01 00 00       	jmp    801069af <sys_link+0x180>
  }

  ilock(ip);
80106895:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106898:	89 04 24             	mov    %eax,(%esp)
8010689b:	e8 bb b0 ff ff       	call   8010195b <ilock>
  if(ip->type == T_DIR){
801068a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068a3:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801068a7:	66 83 f8 01          	cmp    $0x1,%ax
801068ab:	75 1a                	jne    801068c7 <sys_link+0x98>
    iunlockput(ip);
801068ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068b0:	89 04 24             	mov    %eax,(%esp)
801068b3:	e8 27 b3 ff ff       	call   80101bdf <iunlockput>
    end_op();
801068b8:	e8 f2 cd ff ff       	call   801036af <end_op>
    return -1;
801068bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801068c2:	e9 e8 00 00 00       	jmp    801069af <sys_link+0x180>
  }

  ip->nlink++;
801068c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068ca:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801068ce:	8d 50 01             	lea    0x1(%eax),%edx
801068d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068d4:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801068d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068db:	89 04 24             	mov    %eax,(%esp)
801068de:	e8 bc ae ff ff       	call   8010179f <iupdate>
  iunlock(ip);
801068e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068e6:	89 04 24             	mov    %eax,(%esp)
801068e9:	e8 bb b1 ff ff       	call   80101aa9 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
801068ee:	8b 45 dc             	mov    -0x24(%ebp),%eax
801068f1:	8d 55 e2             	lea    -0x1e(%ebp),%edx
801068f4:	89 54 24 04          	mov    %edx,0x4(%esp)
801068f8:	89 04 24             	mov    %eax,(%esp)
801068fb:	e8 43 bd ff ff       	call   80102643 <nameiparent>
80106900:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106903:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106907:	75 02                	jne    8010690b <sys_link+0xdc>
    goto bad;
80106909:	eb 68                	jmp    80106973 <sys_link+0x144>
  ilock(dp);
8010690b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010690e:	89 04 24             	mov    %eax,(%esp)
80106911:	e8 45 b0 ff ff       	call   8010195b <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80106916:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106919:	8b 10                	mov    (%eax),%edx
8010691b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010691e:	8b 00                	mov    (%eax),%eax
80106920:	39 c2                	cmp    %eax,%edx
80106922:	75 20                	jne    80106944 <sys_link+0x115>
80106924:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106927:	8b 40 04             	mov    0x4(%eax),%eax
8010692a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010692e:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80106931:	89 44 24 04          	mov    %eax,0x4(%esp)
80106935:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106938:	89 04 24             	mov    %eax,(%esp)
8010693b:	e8 e0 b9 ff ff       	call   80102320 <dirlink>
80106940:	85 c0                	test   %eax,%eax
80106942:	79 0d                	jns    80106951 <sys_link+0x122>
    iunlockput(dp);
80106944:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106947:	89 04 24             	mov    %eax,(%esp)
8010694a:	e8 90 b2 ff ff       	call   80101bdf <iunlockput>
    goto bad;
8010694f:	eb 22                	jmp    80106973 <sys_link+0x144>
  }
  iunlockput(dp);
80106951:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106954:	89 04 24             	mov    %eax,(%esp)
80106957:	e8 83 b2 ff ff       	call   80101bdf <iunlockput>
  iput(ip);
8010695c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010695f:	89 04 24             	mov    %eax,(%esp)
80106962:	e8 a7 b1 ff ff       	call   80101b0e <iput>

  end_op();
80106967:	e8 43 cd ff ff       	call   801036af <end_op>

  return 0;
8010696c:	b8 00 00 00 00       	mov    $0x0,%eax
80106971:	eb 3c                	jmp    801069af <sys_link+0x180>

bad:
  ilock(ip);
80106973:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106976:	89 04 24             	mov    %eax,(%esp)
80106979:	e8 dd af ff ff       	call   8010195b <ilock>
  ip->nlink--;
8010697e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106981:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106985:	8d 50 ff             	lea    -0x1(%eax),%edx
80106988:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010698b:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
8010698f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106992:	89 04 24             	mov    %eax,(%esp)
80106995:	e8 05 ae ff ff       	call   8010179f <iupdate>
  iunlockput(ip);
8010699a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010699d:	89 04 24             	mov    %eax,(%esp)
801069a0:	e8 3a b2 ff ff       	call   80101bdf <iunlockput>
  end_op();
801069a5:	e8 05 cd ff ff       	call   801036af <end_op>
  return -1;
801069aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801069af:	c9                   	leave  
801069b0:	c3                   	ret    

801069b1 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
801069b1:	55                   	push   %ebp
801069b2:	89 e5                	mov    %esp,%ebp
801069b4:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801069b7:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
801069be:	eb 4b                	jmp    80106a0b <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801069c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069c3:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801069ca:	00 
801069cb:	89 44 24 08          	mov    %eax,0x8(%esp)
801069cf:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801069d2:	89 44 24 04          	mov    %eax,0x4(%esp)
801069d6:	8b 45 08             	mov    0x8(%ebp),%eax
801069d9:	89 04 24             	mov    %eax,(%esp)
801069dc:	e8 87 b4 ff ff       	call   80101e68 <readi>
801069e1:	83 f8 10             	cmp    $0x10,%eax
801069e4:	74 0c                	je     801069f2 <isdirempty+0x41>
      panic("isdirempty: readi");
801069e6:	c7 04 24 48 99 10 80 	movl   $0x80109948,(%esp)
801069ed:	e8 48 9b ff ff       	call   8010053a <panic>
    if(de.inum != 0)
801069f2:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
801069f6:	66 85 c0             	test   %ax,%ax
801069f9:	74 07                	je     80106a02 <isdirempty+0x51>
      return 0;
801069fb:	b8 00 00 00 00       	mov    $0x0,%eax
80106a00:	eb 1b                	jmp    80106a1d <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106a02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a05:	83 c0 10             	add    $0x10,%eax
80106a08:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106a0b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106a0e:	8b 45 08             	mov    0x8(%ebp),%eax
80106a11:	8b 40 18             	mov    0x18(%eax),%eax
80106a14:	39 c2                	cmp    %eax,%edx
80106a16:	72 a8                	jb     801069c0 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80106a18:	b8 01 00 00 00       	mov    $0x1,%eax
}
80106a1d:	c9                   	leave  
80106a1e:	c3                   	ret    

80106a1f <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80106a1f:	55                   	push   %ebp
80106a20:	89 e5                	mov    %esp,%ebp
80106a22:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80106a25:	8d 45 cc             	lea    -0x34(%ebp),%eax
80106a28:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a2c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106a33:	e8 71 fa ff ff       	call   801064a9 <argstr>
80106a38:	85 c0                	test   %eax,%eax
80106a3a:	79 0a                	jns    80106a46 <sys_unlink+0x27>
    return -1;
80106a3c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a41:	e9 af 01 00 00       	jmp    80106bf5 <sys_unlink+0x1d6>

  begin_op();
80106a46:	e8 e0 cb ff ff       	call   8010362b <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80106a4b:	8b 45 cc             	mov    -0x34(%ebp),%eax
80106a4e:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80106a51:	89 54 24 04          	mov    %edx,0x4(%esp)
80106a55:	89 04 24             	mov    %eax,(%esp)
80106a58:	e8 e6 bb ff ff       	call   80102643 <nameiparent>
80106a5d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106a60:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106a64:	75 0f                	jne    80106a75 <sys_unlink+0x56>
    end_op();
80106a66:	e8 44 cc ff ff       	call   801036af <end_op>
    return -1;
80106a6b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a70:	e9 80 01 00 00       	jmp    80106bf5 <sys_unlink+0x1d6>
  }

  ilock(dp);
80106a75:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a78:	89 04 24             	mov    %eax,(%esp)
80106a7b:	e8 db ae ff ff       	call   8010195b <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80106a80:	c7 44 24 04 5a 99 10 	movl   $0x8010995a,0x4(%esp)
80106a87:	80 
80106a88:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106a8b:	89 04 24             	mov    %eax,(%esp)
80106a8e:	e8 db b6 ff ff       	call   8010216e <namecmp>
80106a93:	85 c0                	test   %eax,%eax
80106a95:	0f 84 45 01 00 00    	je     80106be0 <sys_unlink+0x1c1>
80106a9b:	c7 44 24 04 5c 99 10 	movl   $0x8010995c,0x4(%esp)
80106aa2:	80 
80106aa3:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106aa6:	89 04 24             	mov    %eax,(%esp)
80106aa9:	e8 c0 b6 ff ff       	call   8010216e <namecmp>
80106aae:	85 c0                	test   %eax,%eax
80106ab0:	0f 84 2a 01 00 00    	je     80106be0 <sys_unlink+0x1c1>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80106ab6:	8d 45 c8             	lea    -0x38(%ebp),%eax
80106ab9:	89 44 24 08          	mov    %eax,0x8(%esp)
80106abd:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106ac0:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ac4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ac7:	89 04 24             	mov    %eax,(%esp)
80106aca:	e8 c1 b6 ff ff       	call   80102190 <dirlookup>
80106acf:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106ad2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106ad6:	75 05                	jne    80106add <sys_unlink+0xbe>
    goto bad;
80106ad8:	e9 03 01 00 00       	jmp    80106be0 <sys_unlink+0x1c1>
  ilock(ip);
80106add:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ae0:	89 04 24             	mov    %eax,(%esp)
80106ae3:	e8 73 ae ff ff       	call   8010195b <ilock>

  if(ip->nlink < 1)
80106ae8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106aeb:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106aef:	66 85 c0             	test   %ax,%ax
80106af2:	7f 0c                	jg     80106b00 <sys_unlink+0xe1>
    panic("unlink: nlink < 1");
80106af4:	c7 04 24 5f 99 10 80 	movl   $0x8010995f,(%esp)
80106afb:	e8 3a 9a ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80106b00:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b03:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106b07:	66 83 f8 01          	cmp    $0x1,%ax
80106b0b:	75 1f                	jne    80106b2c <sys_unlink+0x10d>
80106b0d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b10:	89 04 24             	mov    %eax,(%esp)
80106b13:	e8 99 fe ff ff       	call   801069b1 <isdirempty>
80106b18:	85 c0                	test   %eax,%eax
80106b1a:	75 10                	jne    80106b2c <sys_unlink+0x10d>
    iunlockput(ip);
80106b1c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b1f:	89 04 24             	mov    %eax,(%esp)
80106b22:	e8 b8 b0 ff ff       	call   80101bdf <iunlockput>
    goto bad;
80106b27:	e9 b4 00 00 00       	jmp    80106be0 <sys_unlink+0x1c1>
  }

  memset(&de, 0, sizeof(de));
80106b2c:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106b33:	00 
80106b34:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106b3b:	00 
80106b3c:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106b3f:	89 04 24             	mov    %eax,(%esp)
80106b42:	e8 90 f5 ff ff       	call   801060d7 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106b47:	8b 45 c8             	mov    -0x38(%ebp),%eax
80106b4a:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106b51:	00 
80106b52:	89 44 24 08          	mov    %eax,0x8(%esp)
80106b56:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106b59:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b60:	89 04 24             	mov    %eax,(%esp)
80106b63:	e8 71 b4 ff ff       	call   80101fd9 <writei>
80106b68:	83 f8 10             	cmp    $0x10,%eax
80106b6b:	74 0c                	je     80106b79 <sys_unlink+0x15a>
    panic("unlink: writei");
80106b6d:	c7 04 24 71 99 10 80 	movl   $0x80109971,(%esp)
80106b74:	e8 c1 99 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR){
80106b79:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b7c:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106b80:	66 83 f8 01          	cmp    $0x1,%ax
80106b84:	75 1c                	jne    80106ba2 <sys_unlink+0x183>
    dp->nlink--;
80106b86:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b89:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106b8d:	8d 50 ff             	lea    -0x1(%eax),%edx
80106b90:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b93:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106b97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b9a:	89 04 24             	mov    %eax,(%esp)
80106b9d:	e8 fd ab ff ff       	call   8010179f <iupdate>
  }
  iunlockput(dp);
80106ba2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ba5:	89 04 24             	mov    %eax,(%esp)
80106ba8:	e8 32 b0 ff ff       	call   80101bdf <iunlockput>

  ip->nlink--;
80106bad:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bb0:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106bb4:	8d 50 ff             	lea    -0x1(%eax),%edx
80106bb7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bba:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106bbe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bc1:	89 04 24             	mov    %eax,(%esp)
80106bc4:	e8 d6 ab ff ff       	call   8010179f <iupdate>
  iunlockput(ip);
80106bc9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bcc:	89 04 24             	mov    %eax,(%esp)
80106bcf:	e8 0b b0 ff ff       	call   80101bdf <iunlockput>

  end_op();
80106bd4:	e8 d6 ca ff ff       	call   801036af <end_op>

  return 0;
80106bd9:	b8 00 00 00 00       	mov    $0x0,%eax
80106bde:	eb 15                	jmp    80106bf5 <sys_unlink+0x1d6>

bad:
  iunlockput(dp);
80106be0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106be3:	89 04 24             	mov    %eax,(%esp)
80106be6:	e8 f4 af ff ff       	call   80101bdf <iunlockput>
  end_op();
80106beb:	e8 bf ca ff ff       	call   801036af <end_op>
  return -1;
80106bf0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106bf5:	c9                   	leave  
80106bf6:	c3                   	ret    

80106bf7 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80106bf7:	55                   	push   %ebp
80106bf8:	89 e5                	mov    %esp,%ebp
80106bfa:	83 ec 48             	sub    $0x48,%esp
80106bfd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80106c00:	8b 55 10             	mov    0x10(%ebp),%edx
80106c03:	8b 45 14             	mov    0x14(%ebp),%eax
80106c06:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80106c0a:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80106c0e:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80106c12:	8d 45 de             	lea    -0x22(%ebp),%eax
80106c15:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c19:	8b 45 08             	mov    0x8(%ebp),%eax
80106c1c:	89 04 24             	mov    %eax,(%esp)
80106c1f:	e8 1f ba ff ff       	call   80102643 <nameiparent>
80106c24:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106c27:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106c2b:	75 0a                	jne    80106c37 <create+0x40>
    return 0;
80106c2d:	b8 00 00 00 00       	mov    $0x0,%eax
80106c32:	e9 a0 01 00 00       	jmp    80106dd7 <create+0x1e0>
  ilock(dp);
80106c37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c3a:	89 04 24             	mov    %eax,(%esp)
80106c3d:	e8 19 ad ff ff       	call   8010195b <ilock>

  if (dp->type == T_DEV) {
80106c42:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c45:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106c49:	66 83 f8 03          	cmp    $0x3,%ax
80106c4d:	75 15                	jne    80106c64 <create+0x6d>
    iunlockput(dp);
80106c4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c52:	89 04 24             	mov    %eax,(%esp)
80106c55:	e8 85 af ff ff       	call   80101bdf <iunlockput>
    return 0;
80106c5a:	b8 00 00 00 00       	mov    $0x0,%eax
80106c5f:	e9 73 01 00 00       	jmp    80106dd7 <create+0x1e0>
  }

  if((ip = dirlookup(dp, name, &off)) != 0){
80106c64:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106c67:	89 44 24 08          	mov    %eax,0x8(%esp)
80106c6b:	8d 45 de             	lea    -0x22(%ebp),%eax
80106c6e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c72:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c75:	89 04 24             	mov    %eax,(%esp)
80106c78:	e8 13 b5 ff ff       	call   80102190 <dirlookup>
80106c7d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106c80:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106c84:	74 47                	je     80106ccd <create+0xd6>
    iunlockput(dp);
80106c86:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c89:	89 04 24             	mov    %eax,(%esp)
80106c8c:	e8 4e af ff ff       	call   80101bdf <iunlockput>
    ilock(ip);
80106c91:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c94:	89 04 24             	mov    %eax,(%esp)
80106c97:	e8 bf ac ff ff       	call   8010195b <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80106c9c:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80106ca1:	75 15                	jne    80106cb8 <create+0xc1>
80106ca3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ca6:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106caa:	66 83 f8 02          	cmp    $0x2,%ax
80106cae:	75 08                	jne    80106cb8 <create+0xc1>
      return ip;
80106cb0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cb3:	e9 1f 01 00 00       	jmp    80106dd7 <create+0x1e0>
    iunlockput(ip);
80106cb8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cbb:	89 04 24             	mov    %eax,(%esp)
80106cbe:	e8 1c af ff ff       	call   80101bdf <iunlockput>
    return 0;
80106cc3:	b8 00 00 00 00       	mov    $0x0,%eax
80106cc8:	e9 0a 01 00 00       	jmp    80106dd7 <create+0x1e0>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80106ccd:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80106cd1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106cd4:	8b 00                	mov    (%eax),%eax
80106cd6:	89 54 24 04          	mov    %edx,0x4(%esp)
80106cda:	89 04 24             	mov    %eax,(%esp)
80106cdd:	e8 de a9 ff ff       	call   801016c0 <ialloc>
80106ce2:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106ce5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106ce9:	75 0c                	jne    80106cf7 <create+0x100>
    panic("create: ialloc");
80106ceb:	c7 04 24 80 99 10 80 	movl   $0x80109980,(%esp)
80106cf2:	e8 43 98 ff ff       	call   8010053a <panic>

  ilock(ip);
80106cf7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cfa:	89 04 24             	mov    %eax,(%esp)
80106cfd:	e8 59 ac ff ff       	call   8010195b <ilock>
  ip->major = major;
80106d02:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d05:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80106d09:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80106d0d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d10:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80106d14:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80106d18:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d1b:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80106d21:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d24:	89 04 24             	mov    %eax,(%esp)
80106d27:	e8 73 aa ff ff       	call   8010179f <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80106d2c:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80106d31:	75 6a                	jne    80106d9d <create+0x1a6>
    dp->nlink++;  // for ".."
80106d33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d36:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106d3a:	8d 50 01             	lea    0x1(%eax),%edx
80106d3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d40:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106d44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d47:	89 04 24             	mov    %eax,(%esp)
80106d4a:	e8 50 aa ff ff       	call   8010179f <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80106d4f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d52:	8b 40 04             	mov    0x4(%eax),%eax
80106d55:	89 44 24 08          	mov    %eax,0x8(%esp)
80106d59:	c7 44 24 04 5a 99 10 	movl   $0x8010995a,0x4(%esp)
80106d60:	80 
80106d61:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d64:	89 04 24             	mov    %eax,(%esp)
80106d67:	e8 b4 b5 ff ff       	call   80102320 <dirlink>
80106d6c:	85 c0                	test   %eax,%eax
80106d6e:	78 21                	js     80106d91 <create+0x19a>
80106d70:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d73:	8b 40 04             	mov    0x4(%eax),%eax
80106d76:	89 44 24 08          	mov    %eax,0x8(%esp)
80106d7a:	c7 44 24 04 5c 99 10 	movl   $0x8010995c,0x4(%esp)
80106d81:	80 
80106d82:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d85:	89 04 24             	mov    %eax,(%esp)
80106d88:	e8 93 b5 ff ff       	call   80102320 <dirlink>
80106d8d:	85 c0                	test   %eax,%eax
80106d8f:	79 0c                	jns    80106d9d <create+0x1a6>
      panic("create dots");
80106d91:	c7 04 24 8f 99 10 80 	movl   $0x8010998f,(%esp)
80106d98:	e8 9d 97 ff ff       	call   8010053a <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80106d9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106da0:	8b 40 04             	mov    0x4(%eax),%eax
80106da3:	89 44 24 08          	mov    %eax,0x8(%esp)
80106da7:	8d 45 de             	lea    -0x22(%ebp),%eax
80106daa:	89 44 24 04          	mov    %eax,0x4(%esp)
80106dae:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106db1:	89 04 24             	mov    %eax,(%esp)
80106db4:	e8 67 b5 ff ff       	call   80102320 <dirlink>
80106db9:	85 c0                	test   %eax,%eax
80106dbb:	79 0c                	jns    80106dc9 <create+0x1d2>
    panic("create: dirlink");
80106dbd:	c7 04 24 9b 99 10 80 	movl   $0x8010999b,(%esp)
80106dc4:	e8 71 97 ff ff       	call   8010053a <panic>

  iunlockput(dp);
80106dc9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106dcc:	89 04 24             	mov    %eax,(%esp)
80106dcf:	e8 0b ae ff ff       	call   80101bdf <iunlockput>

  return ip;
80106dd4:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106dd7:	c9                   	leave  
80106dd8:	c3                   	ret    

80106dd9 <sys_open>:

int
sys_open(void)
{
80106dd9:	55                   	push   %ebp
80106dda:	89 e5                	mov    %esp,%ebp
80106ddc:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80106ddf:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106de2:	89 44 24 04          	mov    %eax,0x4(%esp)
80106de6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106ded:	e8 b7 f6 ff ff       	call   801064a9 <argstr>
80106df2:	85 c0                	test   %eax,%eax
80106df4:	78 17                	js     80106e0d <sys_open+0x34>
80106df6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106df9:	89 44 24 04          	mov    %eax,0x4(%esp)
80106dfd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106e04:	e8 10 f6 ff ff       	call   80106419 <argint>
80106e09:	85 c0                	test   %eax,%eax
80106e0b:	79 0a                	jns    80106e17 <sys_open+0x3e>
    return -1;
80106e0d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106e12:	e9 5c 01 00 00       	jmp    80106f73 <sys_open+0x19a>

  begin_op();
80106e17:	e8 0f c8 ff ff       	call   8010362b <begin_op>

  if(omode & O_CREATE){
80106e1c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106e1f:	25 00 02 00 00       	and    $0x200,%eax
80106e24:	85 c0                	test   %eax,%eax
80106e26:	74 3b                	je     80106e63 <sys_open+0x8a>
    ip = create(path, T_FILE, 0, 0);
80106e28:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106e2b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106e32:	00 
80106e33:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106e3a:	00 
80106e3b:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106e42:	00 
80106e43:	89 04 24             	mov    %eax,(%esp)
80106e46:	e8 ac fd ff ff       	call   80106bf7 <create>
80106e4b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
80106e4e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106e52:	75 6b                	jne    80106ebf <sys_open+0xe6>
      end_op();
80106e54:	e8 56 c8 ff ff       	call   801036af <end_op>
      return -1;
80106e59:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106e5e:	e9 10 01 00 00       	jmp    80106f73 <sys_open+0x19a>
    }
  } else {
    if((ip = namei(path)) == 0){
80106e63:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106e66:	89 04 24             	mov    %eax,(%esp)
80106e69:	e8 b3 b7 ff ff       	call   80102621 <namei>
80106e6e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106e71:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106e75:	75 0f                	jne    80106e86 <sys_open+0xad>
      end_op();
80106e77:	e8 33 c8 ff ff       	call   801036af <end_op>
      return -1;
80106e7c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106e81:	e9 ed 00 00 00       	jmp    80106f73 <sys_open+0x19a>
    }
    ilock(ip);
80106e86:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e89:	89 04 24             	mov    %eax,(%esp)
80106e8c:	e8 ca aa ff ff       	call   8010195b <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106e91:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e94:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106e98:	66 83 f8 01          	cmp    $0x1,%ax
80106e9c:	75 21                	jne    80106ebf <sys_open+0xe6>
80106e9e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106ea1:	85 c0                	test   %eax,%eax
80106ea3:	74 1a                	je     80106ebf <sys_open+0xe6>
      iunlockput(ip);
80106ea5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ea8:	89 04 24             	mov    %eax,(%esp)
80106eab:	e8 2f ad ff ff       	call   80101bdf <iunlockput>
      end_op();
80106eb0:	e8 fa c7 ff ff       	call   801036af <end_op>
      return -1;
80106eb5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106eba:	e9 b4 00 00 00       	jmp    80106f73 <sys_open+0x19a>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106ebf:	e8 62 a1 ff ff       	call   80101026 <filealloc>
80106ec4:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106ec7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106ecb:	74 14                	je     80106ee1 <sys_open+0x108>
80106ecd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ed0:	89 04 24             	mov    %eax,(%esp)
80106ed3:	e8 0c f7 ff ff       	call   801065e4 <fdalloc>
80106ed8:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106edb:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106edf:	79 28                	jns    80106f09 <sys_open+0x130>
    if(f)
80106ee1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106ee5:	74 0b                	je     80106ef2 <sys_open+0x119>
      fileclose(f);
80106ee7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106eea:	89 04 24             	mov    %eax,(%esp)
80106eed:	e8 dc a1 ff ff       	call   801010ce <fileclose>
    iunlockput(ip);
80106ef2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ef5:	89 04 24             	mov    %eax,(%esp)
80106ef8:	e8 e2 ac ff ff       	call   80101bdf <iunlockput>
    end_op();
80106efd:	e8 ad c7 ff ff       	call   801036af <end_op>
    return -1;
80106f02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f07:	eb 6a                	jmp    80106f73 <sys_open+0x19a>
  }
  iunlock(ip);
80106f09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f0c:	89 04 24             	mov    %eax,(%esp)
80106f0f:	e8 95 ab ff ff       	call   80101aa9 <iunlock>
  end_op();
80106f14:	e8 96 c7 ff ff       	call   801036af <end_op>

  f->type = FD_INODE;
80106f19:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f1c:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106f22:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f25:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106f28:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106f2b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f2e:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106f35:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106f38:	83 e0 01             	and    $0x1,%eax
80106f3b:	85 c0                	test   %eax,%eax
80106f3d:	0f 94 c0             	sete   %al
80106f40:	89 c2                	mov    %eax,%edx
80106f42:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f45:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106f48:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106f4b:	83 e0 01             	and    $0x1,%eax
80106f4e:	85 c0                	test   %eax,%eax
80106f50:	75 0a                	jne    80106f5c <sys_open+0x183>
80106f52:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106f55:	83 e0 02             	and    $0x2,%eax
80106f58:	85 c0                	test   %eax,%eax
80106f5a:	74 07                	je     80106f63 <sys_open+0x18a>
80106f5c:	b8 01 00 00 00       	mov    $0x1,%eax
80106f61:	eb 05                	jmp    80106f68 <sys_open+0x18f>
80106f63:	b8 00 00 00 00       	mov    $0x0,%eax
80106f68:	89 c2                	mov    %eax,%edx
80106f6a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f6d:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80106f70:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80106f73:	c9                   	leave  
80106f74:	c3                   	ret    

80106f75 <sys_mkdir>:

int
sys_mkdir(void)
{
80106f75:	55                   	push   %ebp
80106f76:	89 e5                	mov    %esp,%ebp
80106f78:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80106f7b:	e8 ab c6 ff ff       	call   8010362b <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80106f80:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106f83:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f87:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106f8e:	e8 16 f5 ff ff       	call   801064a9 <argstr>
80106f93:	85 c0                	test   %eax,%eax
80106f95:	78 2c                	js     80106fc3 <sys_mkdir+0x4e>
80106f97:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f9a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106fa1:	00 
80106fa2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106fa9:	00 
80106faa:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106fb1:	00 
80106fb2:	89 04 24             	mov    %eax,(%esp)
80106fb5:	e8 3d fc ff ff       	call   80106bf7 <create>
80106fba:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106fbd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106fc1:	75 0c                	jne    80106fcf <sys_mkdir+0x5a>
    end_op();
80106fc3:	e8 e7 c6 ff ff       	call   801036af <end_op>
    return -1;
80106fc8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106fcd:	eb 15                	jmp    80106fe4 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80106fcf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106fd2:	89 04 24             	mov    %eax,(%esp)
80106fd5:	e8 05 ac ff ff       	call   80101bdf <iunlockput>
  end_op();
80106fda:	e8 d0 c6 ff ff       	call   801036af <end_op>
  return 0;
80106fdf:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106fe4:	c9                   	leave  
80106fe5:	c3                   	ret    

80106fe6 <sys_mknod>:

int
sys_mknod(void)
{
80106fe6:	55                   	push   %ebp
80106fe7:	89 e5                	mov    %esp,%ebp
80106fe9:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_op();
80106fec:	e8 3a c6 ff ff       	call   8010362b <begin_op>
  if((len=argstr(0, &path)) < 0 ||
80106ff1:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106ff4:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ff8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106fff:	e8 a5 f4 ff ff       	call   801064a9 <argstr>
80107004:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107007:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010700b:	78 5e                	js     8010706b <sys_mknod+0x85>
     argint(1, &major) < 0 ||
8010700d:	8d 45 e8             	lea    -0x18(%ebp),%eax
80107010:	89 44 24 04          	mov    %eax,0x4(%esp)
80107014:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010701b:	e8 f9 f3 ff ff       	call   80106419 <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
80107020:	85 c0                	test   %eax,%eax
80107022:	78 47                	js     8010706b <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80107024:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80107027:	89 44 24 04          	mov    %eax,0x4(%esp)
8010702b:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80107032:	e8 e2 f3 ff ff       	call   80106419 <argint>
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80107037:	85 c0                	test   %eax,%eax
80107039:	78 30                	js     8010706b <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
8010703b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010703e:	0f bf c8             	movswl %ax,%ecx
80107041:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107044:	0f bf d0             	movswl %ax,%edx
80107047:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
8010704a:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010704e:	89 54 24 08          	mov    %edx,0x8(%esp)
80107052:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80107059:	00 
8010705a:	89 04 24             	mov    %eax,(%esp)
8010705d:	e8 95 fb ff ff       	call   80106bf7 <create>
80107062:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107065:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107069:	75 0c                	jne    80107077 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
8010706b:	e8 3f c6 ff ff       	call   801036af <end_op>
    return -1;
80107070:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107075:	eb 15                	jmp    8010708c <sys_mknod+0xa6>
  }
  iunlockput(ip);
80107077:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010707a:	89 04 24             	mov    %eax,(%esp)
8010707d:	e8 5d ab ff ff       	call   80101bdf <iunlockput>
  end_op();
80107082:	e8 28 c6 ff ff       	call   801036af <end_op>
  return 0;
80107087:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010708c:	c9                   	leave  
8010708d:	c3                   	ret    

8010708e <sys_chdir>:

int
sys_chdir(void)
{
8010708e:	55                   	push   %ebp
8010708f:	89 e5                	mov    %esp,%ebp
80107091:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80107094:	e8 92 c5 ff ff       	call   8010362b <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80107099:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010709c:	89 44 24 04          	mov    %eax,0x4(%esp)
801070a0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801070a7:	e8 fd f3 ff ff       	call   801064a9 <argstr>
801070ac:	85 c0                	test   %eax,%eax
801070ae:	78 14                	js     801070c4 <sys_chdir+0x36>
801070b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801070b3:	89 04 24             	mov    %eax,(%esp)
801070b6:	e8 66 b5 ff ff       	call   80102621 <namei>
801070bb:	89 45 f4             	mov    %eax,-0xc(%ebp)
801070be:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801070c2:	75 0f                	jne    801070d3 <sys_chdir+0x45>
    end_op();
801070c4:	e8 e6 c5 ff ff       	call   801036af <end_op>
    return -1;
801070c9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801070ce:	e9 a2 00 00 00       	jmp    80107175 <sys_chdir+0xe7>
  }
  ilock(ip);
801070d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801070d6:	89 04 24             	mov    %eax,(%esp)
801070d9:	e8 7d a8 ff ff       	call   8010195b <ilock>

  if(ip->type != T_DIR && !IS_DEV_DIR(ip)) {
801070de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801070e1:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801070e5:	66 83 f8 01          	cmp    $0x1,%ax
801070e9:	74 58                	je     80107143 <sys_chdir+0xb5>
801070eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801070ee:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801070f2:	66 83 f8 03          	cmp    $0x3,%ax
801070f6:	75 34                	jne    8010712c <sys_chdir+0x9e>
801070f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801070fb:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801070ff:	98                   	cwtl   
80107100:	c1 e0 04             	shl    $0x4,%eax
80107103:	05 e0 21 11 80       	add    $0x801121e0,%eax
80107108:	8b 00                	mov    (%eax),%eax
8010710a:	85 c0                	test   %eax,%eax
8010710c:	74 1e                	je     8010712c <sys_chdir+0x9e>
8010710e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107111:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80107115:	98                   	cwtl   
80107116:	c1 e0 04             	shl    $0x4,%eax
80107119:	05 e0 21 11 80       	add    $0x801121e0,%eax
8010711e:	8b 00                	mov    (%eax),%eax
80107120:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107123:	89 14 24             	mov    %edx,(%esp)
80107126:	ff d0                	call   *%eax
80107128:	85 c0                	test   %eax,%eax
8010712a:	75 17                	jne    80107143 <sys_chdir+0xb5>
    iunlockput(ip);
8010712c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010712f:	89 04 24             	mov    %eax,(%esp)
80107132:	e8 a8 aa ff ff       	call   80101bdf <iunlockput>
    end_op();
80107137:	e8 73 c5 ff ff       	call   801036af <end_op>
    return -1;
8010713c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107141:	eb 32                	jmp    80107175 <sys_chdir+0xe7>
  }
  
  iunlock(ip);
80107143:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107146:	89 04 24             	mov    %eax,(%esp)
80107149:	e8 5b a9 ff ff       	call   80101aa9 <iunlock>
  iput(proc->cwd);
8010714e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107154:	8b 40 78             	mov    0x78(%eax),%eax
80107157:	89 04 24             	mov    %eax,(%esp)
8010715a:	e8 af a9 ff ff       	call   80101b0e <iput>
  end_op();
8010715f:	e8 4b c5 ff ff       	call   801036af <end_op>
  proc->cwd = ip;
80107164:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010716a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010716d:	89 50 78             	mov    %edx,0x78(%eax)
  return 0;
80107170:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107175:	c9                   	leave  
80107176:	c3                   	ret    

80107177 <sys_exec>:

int
sys_exec(void)
{
80107177:	55                   	push   %ebp
80107178:	89 e5                	mov    %esp,%ebp
8010717a:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80107180:	8d 45 f0             	lea    -0x10(%ebp),%eax
80107183:	89 44 24 04          	mov    %eax,0x4(%esp)
80107187:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010718e:	e8 16 f3 ff ff       	call   801064a9 <argstr>
80107193:	85 c0                	test   %eax,%eax
80107195:	78 1a                	js     801071b1 <sys_exec+0x3a>
80107197:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
8010719d:	89 44 24 04          	mov    %eax,0x4(%esp)
801071a1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801071a8:	e8 6c f2 ff ff       	call   80106419 <argint>
801071ad:	85 c0                	test   %eax,%eax
801071af:	79 0a                	jns    801071bb <sys_exec+0x44>
    return -1;
801071b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801071b6:	e9 c8 00 00 00       	jmp    80107283 <sys_exec+0x10c>
  }
  memset(argv, 0, sizeof(argv));
801071bb:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801071c2:	00 
801071c3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801071ca:	00 
801071cb:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
801071d1:	89 04 24             	mov    %eax,(%esp)
801071d4:	e8 fe ee ff ff       	call   801060d7 <memset>
  for(i=0;; i++){
801071d9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
801071e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801071e3:	83 f8 1f             	cmp    $0x1f,%eax
801071e6:	76 0a                	jbe    801071f2 <sys_exec+0x7b>
      return -1;
801071e8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801071ed:	e9 91 00 00 00       	jmp    80107283 <sys_exec+0x10c>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
801071f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801071f5:	c1 e0 02             	shl    $0x2,%eax
801071f8:	89 c2                	mov    %eax,%edx
801071fa:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80107200:	01 c2                	add    %eax,%edx
80107202:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
80107208:	89 44 24 04          	mov    %eax,0x4(%esp)
8010720c:	89 14 24             	mov    %edx,(%esp)
8010720f:	e8 69 f1 ff ff       	call   8010637d <fetchint>
80107214:	85 c0                	test   %eax,%eax
80107216:	79 07                	jns    8010721f <sys_exec+0xa8>
      return -1;
80107218:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010721d:	eb 64                	jmp    80107283 <sys_exec+0x10c>
    if(uarg == 0){
8010721f:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80107225:	85 c0                	test   %eax,%eax
80107227:	75 26                	jne    8010724f <sys_exec+0xd8>
      argv[i] = 0;
80107229:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010722c:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80107233:	00 00 00 00 
      break;
80107237:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80107238:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010723b:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80107241:	89 54 24 04          	mov    %edx,0x4(%esp)
80107245:	89 04 24             	mov    %eax,(%esp)
80107248:	e8 a2 98 ff ff       	call   80100aef <exec>
8010724d:	eb 34                	jmp    80107283 <sys_exec+0x10c>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
8010724f:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80107255:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107258:	c1 e2 02             	shl    $0x2,%edx
8010725b:	01 c2                	add    %eax,%edx
8010725d:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80107263:	89 54 24 04          	mov    %edx,0x4(%esp)
80107267:	89 04 24             	mov    %eax,(%esp)
8010726a:	e8 48 f1 ff ff       	call   801063b7 <fetchstr>
8010726f:	85 c0                	test   %eax,%eax
80107271:	79 07                	jns    8010727a <sys_exec+0x103>
      return -1;
80107273:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107278:	eb 09                	jmp    80107283 <sys_exec+0x10c>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
8010727a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
8010727e:	e9 5d ff ff ff       	jmp    801071e0 <sys_exec+0x69>
  return exec(path, argv);
}
80107283:	c9                   	leave  
80107284:	c3                   	ret    

80107285 <sys_pipe>:

int
sys_pipe(void)
{
80107285:	55                   	push   %ebp
80107286:	89 e5                	mov    %esp,%ebp
80107288:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
8010728b:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80107292:	00 
80107293:	8d 45 ec             	lea    -0x14(%ebp),%eax
80107296:	89 44 24 04          	mov    %eax,0x4(%esp)
8010729a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801072a1:	e8 a1 f1 ff ff       	call   80106447 <argptr>
801072a6:	85 c0                	test   %eax,%eax
801072a8:	79 0a                	jns    801072b4 <sys_pipe+0x2f>
    return -1;
801072aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801072af:	e9 9b 00 00 00       	jmp    8010734f <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
801072b4:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801072b7:	89 44 24 04          	mov    %eax,0x4(%esp)
801072bb:	8d 45 e8             	lea    -0x18(%ebp),%eax
801072be:	89 04 24             	mov    %eax,(%esp)
801072c1:	e8 7b ce ff ff       	call   80104141 <pipealloc>
801072c6:	85 c0                	test   %eax,%eax
801072c8:	79 07                	jns    801072d1 <sys_pipe+0x4c>
    return -1;
801072ca:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801072cf:	eb 7e                	jmp    8010734f <sys_pipe+0xca>
  fd0 = -1;
801072d1:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
801072d8:	8b 45 e8             	mov    -0x18(%ebp),%eax
801072db:	89 04 24             	mov    %eax,(%esp)
801072de:	e8 01 f3 ff ff       	call   801065e4 <fdalloc>
801072e3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801072e6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801072ea:	78 14                	js     80107300 <sys_pipe+0x7b>
801072ec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801072ef:	89 04 24             	mov    %eax,(%esp)
801072f2:	e8 ed f2 ff ff       	call   801065e4 <fdalloc>
801072f7:	89 45 f0             	mov    %eax,-0x10(%ebp)
801072fa:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801072fe:	79 37                	jns    80107337 <sys_pipe+0xb2>
    if(fd0 >= 0)
80107300:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107304:	78 14                	js     8010731a <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80107306:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010730c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010730f:	83 c2 0c             	add    $0xc,%edx
80107312:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80107319:	00 
    fileclose(rf);
8010731a:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010731d:	89 04 24             	mov    %eax,(%esp)
80107320:	e8 a9 9d ff ff       	call   801010ce <fileclose>
    fileclose(wf);
80107325:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107328:	89 04 24             	mov    %eax,(%esp)
8010732b:	e8 9e 9d ff ff       	call   801010ce <fileclose>
    return -1;
80107330:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107335:	eb 18                	jmp    8010734f <sys_pipe+0xca>
  }
  fd[0] = fd0;
80107337:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010733a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010733d:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
8010733f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107342:	8d 50 04             	lea    0x4(%eax),%edx
80107345:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107348:	89 02                	mov    %eax,(%edx)
  return 0;
8010734a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010734f:	c9                   	leave  
80107350:	c3                   	ret    

80107351 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80107351:	55                   	push   %ebp
80107352:	89 e5                	mov    %esp,%ebp
80107354:	83 ec 08             	sub    $0x8,%esp
  return fork();
80107357:	e8 ce d4 ff ff       	call   8010482a <fork>
}
8010735c:	c9                   	leave  
8010735d:	c3                   	ret    

8010735e <sys_exit>:

int
sys_exit(void)
{
8010735e:	55                   	push   %ebp
8010735f:	89 e5                	mov    %esp,%ebp
80107361:	83 ec 08             	sub    $0x8,%esp
  exit();
80107364:	e8 39 d7 ff ff       	call   80104aa2 <exit>
  return 0;  // not reached
80107369:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010736e:	c9                   	leave  
8010736f:	c3                   	ret    

80107370 <sys_wait>:

int
sys_wait(void)
{
80107370:	55                   	push   %ebp
80107371:	89 e5                	mov    %esp,%ebp
80107373:	83 ec 08             	sub    $0x8,%esp
  return wait();
80107376:	e8 6a d8 ff ff       	call   80104be5 <wait>
}
8010737b:	c9                   	leave  
8010737c:	c3                   	ret    

8010737d <sys_kill>:

int
sys_kill(void)
{
8010737d:	55                   	push   %ebp
8010737e:	89 e5                	mov    %esp,%ebp
80107380:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80107383:	8d 45 f4             	lea    -0xc(%ebp),%eax
80107386:	89 44 24 04          	mov    %eax,0x4(%esp)
8010738a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107391:	e8 83 f0 ff ff       	call   80106419 <argint>
80107396:	85 c0                	test   %eax,%eax
80107398:	79 07                	jns    801073a1 <sys_kill+0x24>
    return -1;
8010739a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010739f:	eb 0b                	jmp    801073ac <sys_kill+0x2f>
  return kill(pid);
801073a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801073a4:	89 04 24             	mov    %eax,(%esp)
801073a7:	e8 fd db ff ff       	call   80104fa9 <kill>
}
801073ac:	c9                   	leave  
801073ad:	c3                   	ret    

801073ae <sys_getpid>:

int
sys_getpid(void)
{
801073ae:	55                   	push   %ebp
801073af:	89 e5                	mov    %esp,%ebp
  return proc->pid;
801073b1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801073b7:	8b 40 10             	mov    0x10(%eax),%eax
}
801073ba:	5d                   	pop    %ebp
801073bb:	c3                   	ret    

801073bc <sys_sbrk>:

int
sys_sbrk(void)
{
801073bc:	55                   	push   %ebp
801073bd:	89 e5                	mov    %esp,%ebp
801073bf:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
801073c2:	8d 45 f0             	lea    -0x10(%ebp),%eax
801073c5:	89 44 24 04          	mov    %eax,0x4(%esp)
801073c9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801073d0:	e8 44 f0 ff ff       	call   80106419 <argint>
801073d5:	85 c0                	test   %eax,%eax
801073d7:	79 07                	jns    801073e0 <sys_sbrk+0x24>
    return -1;
801073d9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801073de:	eb 24                	jmp    80107404 <sys_sbrk+0x48>
  addr = proc->sz;
801073e0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801073e6:	8b 00                	mov    (%eax),%eax
801073e8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
801073eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801073ee:	89 04 24             	mov    %eax,(%esp)
801073f1:	e8 8f d3 ff ff       	call   80104785 <growproc>
801073f6:	85 c0                	test   %eax,%eax
801073f8:	79 07                	jns    80107401 <sys_sbrk+0x45>
    return -1;
801073fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801073ff:	eb 03                	jmp    80107404 <sys_sbrk+0x48>
  return addr;
80107401:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80107404:	c9                   	leave  
80107405:	c3                   	ret    

80107406 <sys_sleep>:

int
sys_sleep(void)
{
80107406:	55                   	push   %ebp
80107407:	89 e5                	mov    %esp,%ebp
80107409:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
8010740c:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010740f:	89 44 24 04          	mov    %eax,0x4(%esp)
80107413:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010741a:	e8 fa ef ff ff       	call   80106419 <argint>
8010741f:	85 c0                	test   %eax,%eax
80107421:	79 07                	jns    8010742a <sys_sleep+0x24>
    return -1;
80107423:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107428:	eb 6c                	jmp    80107496 <sys_sleep+0x90>
  acquire(&tickslock);
8010742a:	c7 04 24 e0 6c 12 80 	movl   $0x80126ce0,(%esp)
80107431:	e8 4d ea ff ff       	call   80105e83 <acquire>
  ticks0 = ticks;
80107436:	a1 20 75 12 80       	mov    0x80127520,%eax
8010743b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
8010743e:	eb 34                	jmp    80107474 <sys_sleep+0x6e>
    if(proc->killed){
80107440:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107446:	8b 40 24             	mov    0x24(%eax),%eax
80107449:	85 c0                	test   %eax,%eax
8010744b:	74 13                	je     80107460 <sys_sleep+0x5a>
      release(&tickslock);
8010744d:	c7 04 24 e0 6c 12 80 	movl   $0x80126ce0,(%esp)
80107454:	e8 8c ea ff ff       	call   80105ee5 <release>
      return -1;
80107459:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010745e:	eb 36                	jmp    80107496 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80107460:	c7 44 24 04 e0 6c 12 	movl   $0x80126ce0,0x4(%esp)
80107467:	80 
80107468:	c7 04 24 20 75 12 80 	movl   $0x80127520,(%esp)
8010746f:	e8 2e da ff ff       	call   80104ea2 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80107474:	a1 20 75 12 80       	mov    0x80127520,%eax
80107479:	2b 45 f4             	sub    -0xc(%ebp),%eax
8010747c:	89 c2                	mov    %eax,%edx
8010747e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107481:	39 c2                	cmp    %eax,%edx
80107483:	72 bb                	jb     80107440 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80107485:	c7 04 24 e0 6c 12 80 	movl   $0x80126ce0,(%esp)
8010748c:	e8 54 ea ff ff       	call   80105ee5 <release>
  return 0;
80107491:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107496:	c9                   	leave  
80107497:	c3                   	ret    

80107498 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80107498:	55                   	push   %ebp
80107499:	89 e5                	mov    %esp,%ebp
8010749b:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
8010749e:	c7 04 24 e0 6c 12 80 	movl   $0x80126ce0,(%esp)
801074a5:	e8 d9 e9 ff ff       	call   80105e83 <acquire>
  xticks = ticks;
801074aa:	a1 20 75 12 80       	mov    0x80127520,%eax
801074af:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
801074b2:	c7 04 24 e0 6c 12 80 	movl   $0x80126ce0,(%esp)
801074b9:	e8 27 ea ff ff       	call   80105ee5 <release>
  return xticks;
801074be:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801074c1:	c9                   	leave  
801074c2:	c3                   	ret    

801074c3 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801074c3:	55                   	push   %ebp
801074c4:	89 e5                	mov    %esp,%ebp
801074c6:	83 ec 08             	sub    $0x8,%esp
801074c9:	8b 55 08             	mov    0x8(%ebp),%edx
801074cc:	8b 45 0c             	mov    0xc(%ebp),%eax
801074cf:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801074d3:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801074d6:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801074da:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801074de:	ee                   	out    %al,(%dx)
}
801074df:	c9                   	leave  
801074e0:	c3                   	ret    

801074e1 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
801074e1:	55                   	push   %ebp
801074e2:	89 e5                	mov    %esp,%ebp
801074e4:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
801074e7:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
801074ee:	00 
801074ef:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
801074f6:	e8 c8 ff ff ff       	call   801074c3 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
801074fb:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80107502:	00 
80107503:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010750a:	e8 b4 ff ff ff       	call   801074c3 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
8010750f:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80107516:	00 
80107517:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010751e:	e8 a0 ff ff ff       	call   801074c3 <outb>
  picenable(IRQ_TIMER);
80107523:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010752a:	e8 a5 ca ff ff       	call   80103fd4 <picenable>
}
8010752f:	c9                   	leave  
80107530:	c3                   	ret    

80107531 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80107531:	1e                   	push   %ds
  pushl %es
80107532:	06                   	push   %es
  pushl %fs
80107533:	0f a0                	push   %fs
  pushl %gs
80107535:	0f a8                	push   %gs
  pushal
80107537:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80107538:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
8010753c:	8e d8                	mov    %eax,%ds
  movw %ax, %es
8010753e:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80107540:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80107544:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80107546:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80107548:	54                   	push   %esp
  call trap
80107549:	e8 d8 01 00 00       	call   80107726 <trap>
  addl $4, %esp
8010754e:	83 c4 04             	add    $0x4,%esp

80107551 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80107551:	61                   	popa   
  popl %gs
80107552:	0f a9                	pop    %gs
  popl %fs
80107554:	0f a1                	pop    %fs
  popl %es
80107556:	07                   	pop    %es
  popl %ds
80107557:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80107558:	83 c4 08             	add    $0x8,%esp
  iret
8010755b:	cf                   	iret   

8010755c <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
8010755c:	55                   	push   %ebp
8010755d:	89 e5                	mov    %esp,%ebp
8010755f:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107562:	8b 45 0c             	mov    0xc(%ebp),%eax
80107565:	83 e8 01             	sub    $0x1,%eax
80107568:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
8010756c:	8b 45 08             	mov    0x8(%ebp),%eax
8010756f:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107573:	8b 45 08             	mov    0x8(%ebp),%eax
80107576:	c1 e8 10             	shr    $0x10,%eax
80107579:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
8010757d:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107580:	0f 01 18             	lidtl  (%eax)
}
80107583:	c9                   	leave  
80107584:	c3                   	ret    

80107585 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80107585:	55                   	push   %ebp
80107586:	89 e5                	mov    %esp,%ebp
80107588:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
8010758b:	0f 20 d0             	mov    %cr2,%eax
8010758e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
80107591:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80107594:	c9                   	leave  
80107595:	c3                   	ret    

80107596 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80107596:	55                   	push   %ebp
80107597:	89 e5                	mov    %esp,%ebp
80107599:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
8010759c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801075a3:	e9 c3 00 00 00       	jmp    8010766b <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801075a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075ab:	8b 04 85 98 c0 10 80 	mov    -0x7fef3f68(,%eax,4),%eax
801075b2:	89 c2                	mov    %eax,%edx
801075b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075b7:	66 89 14 c5 20 6d 12 	mov    %dx,-0x7fed92e0(,%eax,8)
801075be:	80 
801075bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075c2:	66 c7 04 c5 22 6d 12 	movw   $0x8,-0x7fed92de(,%eax,8)
801075c9:	80 08 00 
801075cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075cf:	0f b6 14 c5 24 6d 12 	movzbl -0x7fed92dc(,%eax,8),%edx
801075d6:	80 
801075d7:	83 e2 e0             	and    $0xffffffe0,%edx
801075da:	88 14 c5 24 6d 12 80 	mov    %dl,-0x7fed92dc(,%eax,8)
801075e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075e4:	0f b6 14 c5 24 6d 12 	movzbl -0x7fed92dc(,%eax,8),%edx
801075eb:	80 
801075ec:	83 e2 1f             	and    $0x1f,%edx
801075ef:	88 14 c5 24 6d 12 80 	mov    %dl,-0x7fed92dc(,%eax,8)
801075f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075f9:	0f b6 14 c5 25 6d 12 	movzbl -0x7fed92db(,%eax,8),%edx
80107600:	80 
80107601:	83 e2 f0             	and    $0xfffffff0,%edx
80107604:	83 ca 0e             	or     $0xe,%edx
80107607:	88 14 c5 25 6d 12 80 	mov    %dl,-0x7fed92db(,%eax,8)
8010760e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107611:	0f b6 14 c5 25 6d 12 	movzbl -0x7fed92db(,%eax,8),%edx
80107618:	80 
80107619:	83 e2 ef             	and    $0xffffffef,%edx
8010761c:	88 14 c5 25 6d 12 80 	mov    %dl,-0x7fed92db(,%eax,8)
80107623:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107626:	0f b6 14 c5 25 6d 12 	movzbl -0x7fed92db(,%eax,8),%edx
8010762d:	80 
8010762e:	83 e2 9f             	and    $0xffffff9f,%edx
80107631:	88 14 c5 25 6d 12 80 	mov    %dl,-0x7fed92db(,%eax,8)
80107638:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010763b:	0f b6 14 c5 25 6d 12 	movzbl -0x7fed92db(,%eax,8),%edx
80107642:	80 
80107643:	83 ca 80             	or     $0xffffff80,%edx
80107646:	88 14 c5 25 6d 12 80 	mov    %dl,-0x7fed92db(,%eax,8)
8010764d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107650:	8b 04 85 98 c0 10 80 	mov    -0x7fef3f68(,%eax,4),%eax
80107657:	c1 e8 10             	shr    $0x10,%eax
8010765a:	89 c2                	mov    %eax,%edx
8010765c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010765f:	66 89 14 c5 26 6d 12 	mov    %dx,-0x7fed92da(,%eax,8)
80107666:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80107667:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010766b:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80107672:	0f 8e 30 ff ff ff    	jle    801075a8 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80107678:	a1 98 c1 10 80       	mov    0x8010c198,%eax
8010767d:	66 a3 20 6f 12 80    	mov    %ax,0x80126f20
80107683:	66 c7 05 22 6f 12 80 	movw   $0x8,0x80126f22
8010768a:	08 00 
8010768c:	0f b6 05 24 6f 12 80 	movzbl 0x80126f24,%eax
80107693:	83 e0 e0             	and    $0xffffffe0,%eax
80107696:	a2 24 6f 12 80       	mov    %al,0x80126f24
8010769b:	0f b6 05 24 6f 12 80 	movzbl 0x80126f24,%eax
801076a2:	83 e0 1f             	and    $0x1f,%eax
801076a5:	a2 24 6f 12 80       	mov    %al,0x80126f24
801076aa:	0f b6 05 25 6f 12 80 	movzbl 0x80126f25,%eax
801076b1:	83 c8 0f             	or     $0xf,%eax
801076b4:	a2 25 6f 12 80       	mov    %al,0x80126f25
801076b9:	0f b6 05 25 6f 12 80 	movzbl 0x80126f25,%eax
801076c0:	83 e0 ef             	and    $0xffffffef,%eax
801076c3:	a2 25 6f 12 80       	mov    %al,0x80126f25
801076c8:	0f b6 05 25 6f 12 80 	movzbl 0x80126f25,%eax
801076cf:	83 c8 60             	or     $0x60,%eax
801076d2:	a2 25 6f 12 80       	mov    %al,0x80126f25
801076d7:	0f b6 05 25 6f 12 80 	movzbl 0x80126f25,%eax
801076de:	83 c8 80             	or     $0xffffff80,%eax
801076e1:	a2 25 6f 12 80       	mov    %al,0x80126f25
801076e6:	a1 98 c1 10 80       	mov    0x8010c198,%eax
801076eb:	c1 e8 10             	shr    $0x10,%eax
801076ee:	66 a3 26 6f 12 80    	mov    %ax,0x80126f26
  
  initlock(&tickslock, "time");
801076f4:	c7 44 24 04 ac 99 10 	movl   $0x801099ac,0x4(%esp)
801076fb:	80 
801076fc:	c7 04 24 e0 6c 12 80 	movl   $0x80126ce0,(%esp)
80107703:	e8 5a e7 ff ff       	call   80105e62 <initlock>
}
80107708:	c9                   	leave  
80107709:	c3                   	ret    

8010770a <idtinit>:

void
idtinit(void)
{
8010770a:	55                   	push   %ebp
8010770b:	89 e5                	mov    %esp,%ebp
8010770d:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80107710:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80107717:	00 
80107718:	c7 04 24 20 6d 12 80 	movl   $0x80126d20,(%esp)
8010771f:	e8 38 fe ff ff       	call   8010755c <lidt>
}
80107724:	c9                   	leave  
80107725:	c3                   	ret    

80107726 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80107726:	55                   	push   %ebp
80107727:	89 e5                	mov    %esp,%ebp
80107729:	57                   	push   %edi
8010772a:	56                   	push   %esi
8010772b:	53                   	push   %ebx
8010772c:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
8010772f:	8b 45 08             	mov    0x8(%ebp),%eax
80107732:	8b 40 30             	mov    0x30(%eax),%eax
80107735:	83 f8 40             	cmp    $0x40,%eax
80107738:	75 3f                	jne    80107779 <trap+0x53>
    if(proc->killed)
8010773a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107740:	8b 40 24             	mov    0x24(%eax),%eax
80107743:	85 c0                	test   %eax,%eax
80107745:	74 05                	je     8010774c <trap+0x26>
      exit();
80107747:	e8 56 d3 ff ff       	call   80104aa2 <exit>
    proc->tf = tf;
8010774c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107752:	8b 55 08             	mov    0x8(%ebp),%edx
80107755:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80107758:	e8 83 ed ff ff       	call   801064e0 <syscall>
    if(proc->killed)
8010775d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107763:	8b 40 24             	mov    0x24(%eax),%eax
80107766:	85 c0                	test   %eax,%eax
80107768:	74 0a                	je     80107774 <trap+0x4e>
      exit();
8010776a:	e8 33 d3 ff ff       	call   80104aa2 <exit>
    return;
8010776f:	e9 2d 02 00 00       	jmp    801079a1 <trap+0x27b>
80107774:	e9 28 02 00 00       	jmp    801079a1 <trap+0x27b>
  }

  switch(tf->trapno){
80107779:	8b 45 08             	mov    0x8(%ebp),%eax
8010777c:	8b 40 30             	mov    0x30(%eax),%eax
8010777f:	83 e8 20             	sub    $0x20,%eax
80107782:	83 f8 1f             	cmp    $0x1f,%eax
80107785:	0f 87 bc 00 00 00    	ja     80107847 <trap+0x121>
8010778b:	8b 04 85 54 9a 10 80 	mov    -0x7fef65ac(,%eax,4),%eax
80107792:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
80107794:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010779a:	0f b6 00             	movzbl (%eax),%eax
8010779d:	84 c0                	test   %al,%al
8010779f:	75 31                	jne    801077d2 <trap+0xac>
      acquire(&tickslock);
801077a1:	c7 04 24 e0 6c 12 80 	movl   $0x80126ce0,(%esp)
801077a8:	e8 d6 e6 ff ff       	call   80105e83 <acquire>
      ticks++;
801077ad:	a1 20 75 12 80       	mov    0x80127520,%eax
801077b2:	83 c0 01             	add    $0x1,%eax
801077b5:	a3 20 75 12 80       	mov    %eax,0x80127520
      wakeup(&ticks);
801077ba:	c7 04 24 20 75 12 80 	movl   $0x80127520,(%esp)
801077c1:	e8 b8 d7 ff ff       	call   80104f7e <wakeup>
      release(&tickslock);
801077c6:	c7 04 24 e0 6c 12 80 	movl   $0x80126ce0,(%esp)
801077cd:	e8 13 e7 ff ff       	call   80105ee5 <release>
    }
    lapiceoi();
801077d2:	e8 14 b9 ff ff       	call   801030eb <lapiceoi>
    break;
801077d7:	e9 41 01 00 00       	jmp    8010791d <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
801077dc:	e8 18 b1 ff ff       	call   801028f9 <ideintr>
    lapiceoi();
801077e1:	e8 05 b9 ff ff       	call   801030eb <lapiceoi>
    break;
801077e6:	e9 32 01 00 00       	jmp    8010791d <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
801077eb:	e8 ca b6 ff ff       	call   80102eba <kbdintr>
    lapiceoi();
801077f0:	e8 f6 b8 ff ff       	call   801030eb <lapiceoi>
    break;
801077f5:	e9 23 01 00 00       	jmp    8010791d <trap+0x1f7>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
801077fa:	e8 97 03 00 00       	call   80107b96 <uartintr>
    lapiceoi();
801077ff:	e8 e7 b8 ff ff       	call   801030eb <lapiceoi>
    break;
80107804:	e9 14 01 00 00       	jmp    8010791d <trap+0x1f7>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107809:	8b 45 08             	mov    0x8(%ebp),%eax
8010780c:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
8010780f:	8b 45 08             	mov    0x8(%ebp),%eax
80107812:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107816:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80107819:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010781f:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107822:	0f b6 c0             	movzbl %al,%eax
80107825:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107829:	89 54 24 08          	mov    %edx,0x8(%esp)
8010782d:	89 44 24 04          	mov    %eax,0x4(%esp)
80107831:	c7 04 24 b4 99 10 80 	movl   $0x801099b4,(%esp)
80107838:	e8 63 8b ff ff       	call   801003a0 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
8010783d:	e8 a9 b8 ff ff       	call   801030eb <lapiceoi>
    break;
80107842:	e9 d6 00 00 00       	jmp    8010791d <trap+0x1f7>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80107847:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010784d:	85 c0                	test   %eax,%eax
8010784f:	74 11                	je     80107862 <trap+0x13c>
80107851:	8b 45 08             	mov    0x8(%ebp),%eax
80107854:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107858:	0f b7 c0             	movzwl %ax,%eax
8010785b:	83 e0 03             	and    $0x3,%eax
8010785e:	85 c0                	test   %eax,%eax
80107860:	75 46                	jne    801078a8 <trap+0x182>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107862:	e8 1e fd ff ff       	call   80107585 <rcr2>
80107867:	8b 55 08             	mov    0x8(%ebp),%edx
8010786a:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
8010786d:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107874:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107877:	0f b6 ca             	movzbl %dl,%ecx
8010787a:	8b 55 08             	mov    0x8(%ebp),%edx
8010787d:	8b 52 30             	mov    0x30(%edx),%edx
80107880:	89 44 24 10          	mov    %eax,0x10(%esp)
80107884:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80107888:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010788c:	89 54 24 04          	mov    %edx,0x4(%esp)
80107890:	c7 04 24 d8 99 10 80 	movl   $0x801099d8,(%esp)
80107897:	e8 04 8b ff ff       	call   801003a0 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
8010789c:	c7 04 24 0a 9a 10 80 	movl   $0x80109a0a,(%esp)
801078a3:	e8 92 8c ff ff       	call   8010053a <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801078a8:	e8 d8 fc ff ff       	call   80107585 <rcr2>
801078ad:	89 c2                	mov    %eax,%edx
801078af:	8b 45 08             	mov    0x8(%ebp),%eax
801078b2:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801078b5:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801078bb:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801078be:	0f b6 f0             	movzbl %al,%esi
801078c1:	8b 45 08             	mov    0x8(%ebp),%eax
801078c4:	8b 58 34             	mov    0x34(%eax),%ebx
801078c7:	8b 45 08             	mov    0x8(%ebp),%eax
801078ca:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801078cd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801078d3:	83 c0 28             	add    $0x28,%eax
801078d6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801078d9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801078df:	8b 40 10             	mov    0x10(%eax),%eax
801078e2:	89 54 24 1c          	mov    %edx,0x1c(%esp)
801078e6:	89 7c 24 18          	mov    %edi,0x18(%esp)
801078ea:	89 74 24 14          	mov    %esi,0x14(%esp)
801078ee:	89 5c 24 10          	mov    %ebx,0x10(%esp)
801078f2:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801078f6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
801078f9:	89 74 24 08          	mov    %esi,0x8(%esp)
801078fd:	89 44 24 04          	mov    %eax,0x4(%esp)
80107901:	c7 04 24 10 9a 10 80 	movl   $0x80109a10,(%esp)
80107908:	e8 93 8a ff ff       	call   801003a0 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
8010790d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107913:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
8010791a:	eb 01                	jmp    8010791d <trap+0x1f7>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
8010791c:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
8010791d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107923:	85 c0                	test   %eax,%eax
80107925:	74 24                	je     8010794b <trap+0x225>
80107927:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010792d:	8b 40 24             	mov    0x24(%eax),%eax
80107930:	85 c0                	test   %eax,%eax
80107932:	74 17                	je     8010794b <trap+0x225>
80107934:	8b 45 08             	mov    0x8(%ebp),%eax
80107937:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010793b:	0f b7 c0             	movzwl %ax,%eax
8010793e:	83 e0 03             	and    $0x3,%eax
80107941:	83 f8 03             	cmp    $0x3,%eax
80107944:	75 05                	jne    8010794b <trap+0x225>
    exit();
80107946:	e8 57 d1 ff ff       	call   80104aa2 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
8010794b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107951:	85 c0                	test   %eax,%eax
80107953:	74 1e                	je     80107973 <trap+0x24d>
80107955:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010795b:	8b 40 0c             	mov    0xc(%eax),%eax
8010795e:	83 f8 04             	cmp    $0x4,%eax
80107961:	75 10                	jne    80107973 <trap+0x24d>
80107963:	8b 45 08             	mov    0x8(%ebp),%eax
80107966:	8b 40 30             	mov    0x30(%eax),%eax
80107969:	83 f8 20             	cmp    $0x20,%eax
8010796c:	75 05                	jne    80107973 <trap+0x24d>
    yield();
8010796e:	e8 d1 d4 ff ff       	call   80104e44 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107973:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107979:	85 c0                	test   %eax,%eax
8010797b:	74 24                	je     801079a1 <trap+0x27b>
8010797d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107983:	8b 40 24             	mov    0x24(%eax),%eax
80107986:	85 c0                	test   %eax,%eax
80107988:	74 17                	je     801079a1 <trap+0x27b>
8010798a:	8b 45 08             	mov    0x8(%ebp),%eax
8010798d:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107991:	0f b7 c0             	movzwl %ax,%eax
80107994:	83 e0 03             	and    $0x3,%eax
80107997:	83 f8 03             	cmp    $0x3,%eax
8010799a:	75 05                	jne    801079a1 <trap+0x27b>
    exit();
8010799c:	e8 01 d1 ff ff       	call   80104aa2 <exit>
}
801079a1:	83 c4 3c             	add    $0x3c,%esp
801079a4:	5b                   	pop    %ebx
801079a5:	5e                   	pop    %esi
801079a6:	5f                   	pop    %edi
801079a7:	5d                   	pop    %ebp
801079a8:	c3                   	ret    

801079a9 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801079a9:	55                   	push   %ebp
801079aa:	89 e5                	mov    %esp,%ebp
801079ac:	83 ec 14             	sub    $0x14,%esp
801079af:	8b 45 08             	mov    0x8(%ebp),%eax
801079b2:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801079b6:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801079ba:	89 c2                	mov    %eax,%edx
801079bc:	ec                   	in     (%dx),%al
801079bd:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801079c0:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801079c4:	c9                   	leave  
801079c5:	c3                   	ret    

801079c6 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801079c6:	55                   	push   %ebp
801079c7:	89 e5                	mov    %esp,%ebp
801079c9:	83 ec 08             	sub    $0x8,%esp
801079cc:	8b 55 08             	mov    0x8(%ebp),%edx
801079cf:	8b 45 0c             	mov    0xc(%ebp),%eax
801079d2:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801079d6:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801079d9:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801079dd:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801079e1:	ee                   	out    %al,(%dx)
}
801079e2:	c9                   	leave  
801079e3:	c3                   	ret    

801079e4 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
801079e4:	55                   	push   %ebp
801079e5:	89 e5                	mov    %esp,%ebp
801079e7:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
801079ea:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801079f1:	00 
801079f2:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
801079f9:	e8 c8 ff ff ff       	call   801079c6 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
801079fe:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80107a05:	00 
80107a06:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107a0d:	e8 b4 ff ff ff       	call   801079c6 <outb>
  outb(COM1+0, 115200/9600);
80107a12:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80107a19:	00 
80107a1a:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107a21:	e8 a0 ff ff ff       	call   801079c6 <outb>
  outb(COM1+1, 0);
80107a26:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107a2d:	00 
80107a2e:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107a35:	e8 8c ff ff ff       	call   801079c6 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80107a3a:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80107a41:	00 
80107a42:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107a49:	e8 78 ff ff ff       	call   801079c6 <outb>
  outb(COM1+4, 0);
80107a4e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107a55:	00 
80107a56:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80107a5d:	e8 64 ff ff ff       	call   801079c6 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80107a62:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80107a69:	00 
80107a6a:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107a71:	e8 50 ff ff ff       	call   801079c6 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80107a76:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107a7d:	e8 27 ff ff ff       	call   801079a9 <inb>
80107a82:	3c ff                	cmp    $0xff,%al
80107a84:	75 02                	jne    80107a88 <uartinit+0xa4>
    return;
80107a86:	eb 6a                	jmp    80107af2 <uartinit+0x10e>
  uart = 1;
80107a88:	c7 05 4c c6 10 80 01 	movl   $0x1,0x8010c64c
80107a8f:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80107a92:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107a99:	e8 0b ff ff ff       	call   801079a9 <inb>
  inb(COM1+0);
80107a9e:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107aa5:	e8 ff fe ff ff       	call   801079a9 <inb>
  picenable(IRQ_COM1);
80107aaa:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107ab1:	e8 1e c5 ff ff       	call   80103fd4 <picenable>
  ioapicenable(IRQ_COM1, 0);
80107ab6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107abd:	00 
80107abe:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107ac5:	e8 ae b0 ff ff       	call   80102b78 <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107aca:	c7 45 f4 d4 9a 10 80 	movl   $0x80109ad4,-0xc(%ebp)
80107ad1:	eb 15                	jmp    80107ae8 <uartinit+0x104>
    uartputc(*p);
80107ad3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ad6:	0f b6 00             	movzbl (%eax),%eax
80107ad9:	0f be c0             	movsbl %al,%eax
80107adc:	89 04 24             	mov    %eax,(%esp)
80107adf:	e8 10 00 00 00       	call   80107af4 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107ae4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107ae8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aeb:	0f b6 00             	movzbl (%eax),%eax
80107aee:	84 c0                	test   %al,%al
80107af0:	75 e1                	jne    80107ad3 <uartinit+0xef>
    uartputc(*p);
}
80107af2:	c9                   	leave  
80107af3:	c3                   	ret    

80107af4 <uartputc>:

void
uartputc(int c)
{
80107af4:	55                   	push   %ebp
80107af5:	89 e5                	mov    %esp,%ebp
80107af7:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80107afa:	a1 4c c6 10 80       	mov    0x8010c64c,%eax
80107aff:	85 c0                	test   %eax,%eax
80107b01:	75 02                	jne    80107b05 <uartputc+0x11>
    return;
80107b03:	eb 4b                	jmp    80107b50 <uartputc+0x5c>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107b05:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107b0c:	eb 10                	jmp    80107b1e <uartputc+0x2a>
    microdelay(10);
80107b0e:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80107b15:	e8 f6 b5 ff ff       	call   80103110 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107b1a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107b1e:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80107b22:	7f 16                	jg     80107b3a <uartputc+0x46>
80107b24:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107b2b:	e8 79 fe ff ff       	call   801079a9 <inb>
80107b30:	0f b6 c0             	movzbl %al,%eax
80107b33:	83 e0 20             	and    $0x20,%eax
80107b36:	85 c0                	test   %eax,%eax
80107b38:	74 d4                	je     80107b0e <uartputc+0x1a>
    microdelay(10);
  outb(COM1+0, c);
80107b3a:	8b 45 08             	mov    0x8(%ebp),%eax
80107b3d:	0f b6 c0             	movzbl %al,%eax
80107b40:	89 44 24 04          	mov    %eax,0x4(%esp)
80107b44:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107b4b:	e8 76 fe ff ff       	call   801079c6 <outb>
}
80107b50:	c9                   	leave  
80107b51:	c3                   	ret    

80107b52 <uartgetc>:

static int
uartgetc(void)
{
80107b52:	55                   	push   %ebp
80107b53:	89 e5                	mov    %esp,%ebp
80107b55:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80107b58:	a1 4c c6 10 80       	mov    0x8010c64c,%eax
80107b5d:	85 c0                	test   %eax,%eax
80107b5f:	75 07                	jne    80107b68 <uartgetc+0x16>
    return -1;
80107b61:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107b66:	eb 2c                	jmp    80107b94 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80107b68:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107b6f:	e8 35 fe ff ff       	call   801079a9 <inb>
80107b74:	0f b6 c0             	movzbl %al,%eax
80107b77:	83 e0 01             	and    $0x1,%eax
80107b7a:	85 c0                	test   %eax,%eax
80107b7c:	75 07                	jne    80107b85 <uartgetc+0x33>
    return -1;
80107b7e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107b83:	eb 0f                	jmp    80107b94 <uartgetc+0x42>
  return inb(COM1+0);
80107b85:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107b8c:	e8 18 fe ff ff       	call   801079a9 <inb>
80107b91:	0f b6 c0             	movzbl %al,%eax
}
80107b94:	c9                   	leave  
80107b95:	c3                   	ret    

80107b96 <uartintr>:

void
uartintr(void)
{
80107b96:	55                   	push   %ebp
80107b97:	89 e5                	mov    %esp,%ebp
80107b99:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80107b9c:	c7 04 24 52 7b 10 80 	movl   $0x80107b52,(%esp)
80107ba3:	e8 05 8c ff ff       	call   801007ad <consoleintr>
}
80107ba8:	c9                   	leave  
80107ba9:	c3                   	ret    

80107baa <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80107baa:	6a 00                	push   $0x0
  pushl $0
80107bac:	6a 00                	push   $0x0
  jmp alltraps
80107bae:	e9 7e f9 ff ff       	jmp    80107531 <alltraps>

80107bb3 <vector1>:
.globl vector1
vector1:
  pushl $0
80107bb3:	6a 00                	push   $0x0
  pushl $1
80107bb5:	6a 01                	push   $0x1
  jmp alltraps
80107bb7:	e9 75 f9 ff ff       	jmp    80107531 <alltraps>

80107bbc <vector2>:
.globl vector2
vector2:
  pushl $0
80107bbc:	6a 00                	push   $0x0
  pushl $2
80107bbe:	6a 02                	push   $0x2
  jmp alltraps
80107bc0:	e9 6c f9 ff ff       	jmp    80107531 <alltraps>

80107bc5 <vector3>:
.globl vector3
vector3:
  pushl $0
80107bc5:	6a 00                	push   $0x0
  pushl $3
80107bc7:	6a 03                	push   $0x3
  jmp alltraps
80107bc9:	e9 63 f9 ff ff       	jmp    80107531 <alltraps>

80107bce <vector4>:
.globl vector4
vector4:
  pushl $0
80107bce:	6a 00                	push   $0x0
  pushl $4
80107bd0:	6a 04                	push   $0x4
  jmp alltraps
80107bd2:	e9 5a f9 ff ff       	jmp    80107531 <alltraps>

80107bd7 <vector5>:
.globl vector5
vector5:
  pushl $0
80107bd7:	6a 00                	push   $0x0
  pushl $5
80107bd9:	6a 05                	push   $0x5
  jmp alltraps
80107bdb:	e9 51 f9 ff ff       	jmp    80107531 <alltraps>

80107be0 <vector6>:
.globl vector6
vector6:
  pushl $0
80107be0:	6a 00                	push   $0x0
  pushl $6
80107be2:	6a 06                	push   $0x6
  jmp alltraps
80107be4:	e9 48 f9 ff ff       	jmp    80107531 <alltraps>

80107be9 <vector7>:
.globl vector7
vector7:
  pushl $0
80107be9:	6a 00                	push   $0x0
  pushl $7
80107beb:	6a 07                	push   $0x7
  jmp alltraps
80107bed:	e9 3f f9 ff ff       	jmp    80107531 <alltraps>

80107bf2 <vector8>:
.globl vector8
vector8:
  pushl $8
80107bf2:	6a 08                	push   $0x8
  jmp alltraps
80107bf4:	e9 38 f9 ff ff       	jmp    80107531 <alltraps>

80107bf9 <vector9>:
.globl vector9
vector9:
  pushl $0
80107bf9:	6a 00                	push   $0x0
  pushl $9
80107bfb:	6a 09                	push   $0x9
  jmp alltraps
80107bfd:	e9 2f f9 ff ff       	jmp    80107531 <alltraps>

80107c02 <vector10>:
.globl vector10
vector10:
  pushl $10
80107c02:	6a 0a                	push   $0xa
  jmp alltraps
80107c04:	e9 28 f9 ff ff       	jmp    80107531 <alltraps>

80107c09 <vector11>:
.globl vector11
vector11:
  pushl $11
80107c09:	6a 0b                	push   $0xb
  jmp alltraps
80107c0b:	e9 21 f9 ff ff       	jmp    80107531 <alltraps>

80107c10 <vector12>:
.globl vector12
vector12:
  pushl $12
80107c10:	6a 0c                	push   $0xc
  jmp alltraps
80107c12:	e9 1a f9 ff ff       	jmp    80107531 <alltraps>

80107c17 <vector13>:
.globl vector13
vector13:
  pushl $13
80107c17:	6a 0d                	push   $0xd
  jmp alltraps
80107c19:	e9 13 f9 ff ff       	jmp    80107531 <alltraps>

80107c1e <vector14>:
.globl vector14
vector14:
  pushl $14
80107c1e:	6a 0e                	push   $0xe
  jmp alltraps
80107c20:	e9 0c f9 ff ff       	jmp    80107531 <alltraps>

80107c25 <vector15>:
.globl vector15
vector15:
  pushl $0
80107c25:	6a 00                	push   $0x0
  pushl $15
80107c27:	6a 0f                	push   $0xf
  jmp alltraps
80107c29:	e9 03 f9 ff ff       	jmp    80107531 <alltraps>

80107c2e <vector16>:
.globl vector16
vector16:
  pushl $0
80107c2e:	6a 00                	push   $0x0
  pushl $16
80107c30:	6a 10                	push   $0x10
  jmp alltraps
80107c32:	e9 fa f8 ff ff       	jmp    80107531 <alltraps>

80107c37 <vector17>:
.globl vector17
vector17:
  pushl $17
80107c37:	6a 11                	push   $0x11
  jmp alltraps
80107c39:	e9 f3 f8 ff ff       	jmp    80107531 <alltraps>

80107c3e <vector18>:
.globl vector18
vector18:
  pushl $0
80107c3e:	6a 00                	push   $0x0
  pushl $18
80107c40:	6a 12                	push   $0x12
  jmp alltraps
80107c42:	e9 ea f8 ff ff       	jmp    80107531 <alltraps>

80107c47 <vector19>:
.globl vector19
vector19:
  pushl $0
80107c47:	6a 00                	push   $0x0
  pushl $19
80107c49:	6a 13                	push   $0x13
  jmp alltraps
80107c4b:	e9 e1 f8 ff ff       	jmp    80107531 <alltraps>

80107c50 <vector20>:
.globl vector20
vector20:
  pushl $0
80107c50:	6a 00                	push   $0x0
  pushl $20
80107c52:	6a 14                	push   $0x14
  jmp alltraps
80107c54:	e9 d8 f8 ff ff       	jmp    80107531 <alltraps>

80107c59 <vector21>:
.globl vector21
vector21:
  pushl $0
80107c59:	6a 00                	push   $0x0
  pushl $21
80107c5b:	6a 15                	push   $0x15
  jmp alltraps
80107c5d:	e9 cf f8 ff ff       	jmp    80107531 <alltraps>

80107c62 <vector22>:
.globl vector22
vector22:
  pushl $0
80107c62:	6a 00                	push   $0x0
  pushl $22
80107c64:	6a 16                	push   $0x16
  jmp alltraps
80107c66:	e9 c6 f8 ff ff       	jmp    80107531 <alltraps>

80107c6b <vector23>:
.globl vector23
vector23:
  pushl $0
80107c6b:	6a 00                	push   $0x0
  pushl $23
80107c6d:	6a 17                	push   $0x17
  jmp alltraps
80107c6f:	e9 bd f8 ff ff       	jmp    80107531 <alltraps>

80107c74 <vector24>:
.globl vector24
vector24:
  pushl $0
80107c74:	6a 00                	push   $0x0
  pushl $24
80107c76:	6a 18                	push   $0x18
  jmp alltraps
80107c78:	e9 b4 f8 ff ff       	jmp    80107531 <alltraps>

80107c7d <vector25>:
.globl vector25
vector25:
  pushl $0
80107c7d:	6a 00                	push   $0x0
  pushl $25
80107c7f:	6a 19                	push   $0x19
  jmp alltraps
80107c81:	e9 ab f8 ff ff       	jmp    80107531 <alltraps>

80107c86 <vector26>:
.globl vector26
vector26:
  pushl $0
80107c86:	6a 00                	push   $0x0
  pushl $26
80107c88:	6a 1a                	push   $0x1a
  jmp alltraps
80107c8a:	e9 a2 f8 ff ff       	jmp    80107531 <alltraps>

80107c8f <vector27>:
.globl vector27
vector27:
  pushl $0
80107c8f:	6a 00                	push   $0x0
  pushl $27
80107c91:	6a 1b                	push   $0x1b
  jmp alltraps
80107c93:	e9 99 f8 ff ff       	jmp    80107531 <alltraps>

80107c98 <vector28>:
.globl vector28
vector28:
  pushl $0
80107c98:	6a 00                	push   $0x0
  pushl $28
80107c9a:	6a 1c                	push   $0x1c
  jmp alltraps
80107c9c:	e9 90 f8 ff ff       	jmp    80107531 <alltraps>

80107ca1 <vector29>:
.globl vector29
vector29:
  pushl $0
80107ca1:	6a 00                	push   $0x0
  pushl $29
80107ca3:	6a 1d                	push   $0x1d
  jmp alltraps
80107ca5:	e9 87 f8 ff ff       	jmp    80107531 <alltraps>

80107caa <vector30>:
.globl vector30
vector30:
  pushl $0
80107caa:	6a 00                	push   $0x0
  pushl $30
80107cac:	6a 1e                	push   $0x1e
  jmp alltraps
80107cae:	e9 7e f8 ff ff       	jmp    80107531 <alltraps>

80107cb3 <vector31>:
.globl vector31
vector31:
  pushl $0
80107cb3:	6a 00                	push   $0x0
  pushl $31
80107cb5:	6a 1f                	push   $0x1f
  jmp alltraps
80107cb7:	e9 75 f8 ff ff       	jmp    80107531 <alltraps>

80107cbc <vector32>:
.globl vector32
vector32:
  pushl $0
80107cbc:	6a 00                	push   $0x0
  pushl $32
80107cbe:	6a 20                	push   $0x20
  jmp alltraps
80107cc0:	e9 6c f8 ff ff       	jmp    80107531 <alltraps>

80107cc5 <vector33>:
.globl vector33
vector33:
  pushl $0
80107cc5:	6a 00                	push   $0x0
  pushl $33
80107cc7:	6a 21                	push   $0x21
  jmp alltraps
80107cc9:	e9 63 f8 ff ff       	jmp    80107531 <alltraps>

80107cce <vector34>:
.globl vector34
vector34:
  pushl $0
80107cce:	6a 00                	push   $0x0
  pushl $34
80107cd0:	6a 22                	push   $0x22
  jmp alltraps
80107cd2:	e9 5a f8 ff ff       	jmp    80107531 <alltraps>

80107cd7 <vector35>:
.globl vector35
vector35:
  pushl $0
80107cd7:	6a 00                	push   $0x0
  pushl $35
80107cd9:	6a 23                	push   $0x23
  jmp alltraps
80107cdb:	e9 51 f8 ff ff       	jmp    80107531 <alltraps>

80107ce0 <vector36>:
.globl vector36
vector36:
  pushl $0
80107ce0:	6a 00                	push   $0x0
  pushl $36
80107ce2:	6a 24                	push   $0x24
  jmp alltraps
80107ce4:	e9 48 f8 ff ff       	jmp    80107531 <alltraps>

80107ce9 <vector37>:
.globl vector37
vector37:
  pushl $0
80107ce9:	6a 00                	push   $0x0
  pushl $37
80107ceb:	6a 25                	push   $0x25
  jmp alltraps
80107ced:	e9 3f f8 ff ff       	jmp    80107531 <alltraps>

80107cf2 <vector38>:
.globl vector38
vector38:
  pushl $0
80107cf2:	6a 00                	push   $0x0
  pushl $38
80107cf4:	6a 26                	push   $0x26
  jmp alltraps
80107cf6:	e9 36 f8 ff ff       	jmp    80107531 <alltraps>

80107cfb <vector39>:
.globl vector39
vector39:
  pushl $0
80107cfb:	6a 00                	push   $0x0
  pushl $39
80107cfd:	6a 27                	push   $0x27
  jmp alltraps
80107cff:	e9 2d f8 ff ff       	jmp    80107531 <alltraps>

80107d04 <vector40>:
.globl vector40
vector40:
  pushl $0
80107d04:	6a 00                	push   $0x0
  pushl $40
80107d06:	6a 28                	push   $0x28
  jmp alltraps
80107d08:	e9 24 f8 ff ff       	jmp    80107531 <alltraps>

80107d0d <vector41>:
.globl vector41
vector41:
  pushl $0
80107d0d:	6a 00                	push   $0x0
  pushl $41
80107d0f:	6a 29                	push   $0x29
  jmp alltraps
80107d11:	e9 1b f8 ff ff       	jmp    80107531 <alltraps>

80107d16 <vector42>:
.globl vector42
vector42:
  pushl $0
80107d16:	6a 00                	push   $0x0
  pushl $42
80107d18:	6a 2a                	push   $0x2a
  jmp alltraps
80107d1a:	e9 12 f8 ff ff       	jmp    80107531 <alltraps>

80107d1f <vector43>:
.globl vector43
vector43:
  pushl $0
80107d1f:	6a 00                	push   $0x0
  pushl $43
80107d21:	6a 2b                	push   $0x2b
  jmp alltraps
80107d23:	e9 09 f8 ff ff       	jmp    80107531 <alltraps>

80107d28 <vector44>:
.globl vector44
vector44:
  pushl $0
80107d28:	6a 00                	push   $0x0
  pushl $44
80107d2a:	6a 2c                	push   $0x2c
  jmp alltraps
80107d2c:	e9 00 f8 ff ff       	jmp    80107531 <alltraps>

80107d31 <vector45>:
.globl vector45
vector45:
  pushl $0
80107d31:	6a 00                	push   $0x0
  pushl $45
80107d33:	6a 2d                	push   $0x2d
  jmp alltraps
80107d35:	e9 f7 f7 ff ff       	jmp    80107531 <alltraps>

80107d3a <vector46>:
.globl vector46
vector46:
  pushl $0
80107d3a:	6a 00                	push   $0x0
  pushl $46
80107d3c:	6a 2e                	push   $0x2e
  jmp alltraps
80107d3e:	e9 ee f7 ff ff       	jmp    80107531 <alltraps>

80107d43 <vector47>:
.globl vector47
vector47:
  pushl $0
80107d43:	6a 00                	push   $0x0
  pushl $47
80107d45:	6a 2f                	push   $0x2f
  jmp alltraps
80107d47:	e9 e5 f7 ff ff       	jmp    80107531 <alltraps>

80107d4c <vector48>:
.globl vector48
vector48:
  pushl $0
80107d4c:	6a 00                	push   $0x0
  pushl $48
80107d4e:	6a 30                	push   $0x30
  jmp alltraps
80107d50:	e9 dc f7 ff ff       	jmp    80107531 <alltraps>

80107d55 <vector49>:
.globl vector49
vector49:
  pushl $0
80107d55:	6a 00                	push   $0x0
  pushl $49
80107d57:	6a 31                	push   $0x31
  jmp alltraps
80107d59:	e9 d3 f7 ff ff       	jmp    80107531 <alltraps>

80107d5e <vector50>:
.globl vector50
vector50:
  pushl $0
80107d5e:	6a 00                	push   $0x0
  pushl $50
80107d60:	6a 32                	push   $0x32
  jmp alltraps
80107d62:	e9 ca f7 ff ff       	jmp    80107531 <alltraps>

80107d67 <vector51>:
.globl vector51
vector51:
  pushl $0
80107d67:	6a 00                	push   $0x0
  pushl $51
80107d69:	6a 33                	push   $0x33
  jmp alltraps
80107d6b:	e9 c1 f7 ff ff       	jmp    80107531 <alltraps>

80107d70 <vector52>:
.globl vector52
vector52:
  pushl $0
80107d70:	6a 00                	push   $0x0
  pushl $52
80107d72:	6a 34                	push   $0x34
  jmp alltraps
80107d74:	e9 b8 f7 ff ff       	jmp    80107531 <alltraps>

80107d79 <vector53>:
.globl vector53
vector53:
  pushl $0
80107d79:	6a 00                	push   $0x0
  pushl $53
80107d7b:	6a 35                	push   $0x35
  jmp alltraps
80107d7d:	e9 af f7 ff ff       	jmp    80107531 <alltraps>

80107d82 <vector54>:
.globl vector54
vector54:
  pushl $0
80107d82:	6a 00                	push   $0x0
  pushl $54
80107d84:	6a 36                	push   $0x36
  jmp alltraps
80107d86:	e9 a6 f7 ff ff       	jmp    80107531 <alltraps>

80107d8b <vector55>:
.globl vector55
vector55:
  pushl $0
80107d8b:	6a 00                	push   $0x0
  pushl $55
80107d8d:	6a 37                	push   $0x37
  jmp alltraps
80107d8f:	e9 9d f7 ff ff       	jmp    80107531 <alltraps>

80107d94 <vector56>:
.globl vector56
vector56:
  pushl $0
80107d94:	6a 00                	push   $0x0
  pushl $56
80107d96:	6a 38                	push   $0x38
  jmp alltraps
80107d98:	e9 94 f7 ff ff       	jmp    80107531 <alltraps>

80107d9d <vector57>:
.globl vector57
vector57:
  pushl $0
80107d9d:	6a 00                	push   $0x0
  pushl $57
80107d9f:	6a 39                	push   $0x39
  jmp alltraps
80107da1:	e9 8b f7 ff ff       	jmp    80107531 <alltraps>

80107da6 <vector58>:
.globl vector58
vector58:
  pushl $0
80107da6:	6a 00                	push   $0x0
  pushl $58
80107da8:	6a 3a                	push   $0x3a
  jmp alltraps
80107daa:	e9 82 f7 ff ff       	jmp    80107531 <alltraps>

80107daf <vector59>:
.globl vector59
vector59:
  pushl $0
80107daf:	6a 00                	push   $0x0
  pushl $59
80107db1:	6a 3b                	push   $0x3b
  jmp alltraps
80107db3:	e9 79 f7 ff ff       	jmp    80107531 <alltraps>

80107db8 <vector60>:
.globl vector60
vector60:
  pushl $0
80107db8:	6a 00                	push   $0x0
  pushl $60
80107dba:	6a 3c                	push   $0x3c
  jmp alltraps
80107dbc:	e9 70 f7 ff ff       	jmp    80107531 <alltraps>

80107dc1 <vector61>:
.globl vector61
vector61:
  pushl $0
80107dc1:	6a 00                	push   $0x0
  pushl $61
80107dc3:	6a 3d                	push   $0x3d
  jmp alltraps
80107dc5:	e9 67 f7 ff ff       	jmp    80107531 <alltraps>

80107dca <vector62>:
.globl vector62
vector62:
  pushl $0
80107dca:	6a 00                	push   $0x0
  pushl $62
80107dcc:	6a 3e                	push   $0x3e
  jmp alltraps
80107dce:	e9 5e f7 ff ff       	jmp    80107531 <alltraps>

80107dd3 <vector63>:
.globl vector63
vector63:
  pushl $0
80107dd3:	6a 00                	push   $0x0
  pushl $63
80107dd5:	6a 3f                	push   $0x3f
  jmp alltraps
80107dd7:	e9 55 f7 ff ff       	jmp    80107531 <alltraps>

80107ddc <vector64>:
.globl vector64
vector64:
  pushl $0
80107ddc:	6a 00                	push   $0x0
  pushl $64
80107dde:	6a 40                	push   $0x40
  jmp alltraps
80107de0:	e9 4c f7 ff ff       	jmp    80107531 <alltraps>

80107de5 <vector65>:
.globl vector65
vector65:
  pushl $0
80107de5:	6a 00                	push   $0x0
  pushl $65
80107de7:	6a 41                	push   $0x41
  jmp alltraps
80107de9:	e9 43 f7 ff ff       	jmp    80107531 <alltraps>

80107dee <vector66>:
.globl vector66
vector66:
  pushl $0
80107dee:	6a 00                	push   $0x0
  pushl $66
80107df0:	6a 42                	push   $0x42
  jmp alltraps
80107df2:	e9 3a f7 ff ff       	jmp    80107531 <alltraps>

80107df7 <vector67>:
.globl vector67
vector67:
  pushl $0
80107df7:	6a 00                	push   $0x0
  pushl $67
80107df9:	6a 43                	push   $0x43
  jmp alltraps
80107dfb:	e9 31 f7 ff ff       	jmp    80107531 <alltraps>

80107e00 <vector68>:
.globl vector68
vector68:
  pushl $0
80107e00:	6a 00                	push   $0x0
  pushl $68
80107e02:	6a 44                	push   $0x44
  jmp alltraps
80107e04:	e9 28 f7 ff ff       	jmp    80107531 <alltraps>

80107e09 <vector69>:
.globl vector69
vector69:
  pushl $0
80107e09:	6a 00                	push   $0x0
  pushl $69
80107e0b:	6a 45                	push   $0x45
  jmp alltraps
80107e0d:	e9 1f f7 ff ff       	jmp    80107531 <alltraps>

80107e12 <vector70>:
.globl vector70
vector70:
  pushl $0
80107e12:	6a 00                	push   $0x0
  pushl $70
80107e14:	6a 46                	push   $0x46
  jmp alltraps
80107e16:	e9 16 f7 ff ff       	jmp    80107531 <alltraps>

80107e1b <vector71>:
.globl vector71
vector71:
  pushl $0
80107e1b:	6a 00                	push   $0x0
  pushl $71
80107e1d:	6a 47                	push   $0x47
  jmp alltraps
80107e1f:	e9 0d f7 ff ff       	jmp    80107531 <alltraps>

80107e24 <vector72>:
.globl vector72
vector72:
  pushl $0
80107e24:	6a 00                	push   $0x0
  pushl $72
80107e26:	6a 48                	push   $0x48
  jmp alltraps
80107e28:	e9 04 f7 ff ff       	jmp    80107531 <alltraps>

80107e2d <vector73>:
.globl vector73
vector73:
  pushl $0
80107e2d:	6a 00                	push   $0x0
  pushl $73
80107e2f:	6a 49                	push   $0x49
  jmp alltraps
80107e31:	e9 fb f6 ff ff       	jmp    80107531 <alltraps>

80107e36 <vector74>:
.globl vector74
vector74:
  pushl $0
80107e36:	6a 00                	push   $0x0
  pushl $74
80107e38:	6a 4a                	push   $0x4a
  jmp alltraps
80107e3a:	e9 f2 f6 ff ff       	jmp    80107531 <alltraps>

80107e3f <vector75>:
.globl vector75
vector75:
  pushl $0
80107e3f:	6a 00                	push   $0x0
  pushl $75
80107e41:	6a 4b                	push   $0x4b
  jmp alltraps
80107e43:	e9 e9 f6 ff ff       	jmp    80107531 <alltraps>

80107e48 <vector76>:
.globl vector76
vector76:
  pushl $0
80107e48:	6a 00                	push   $0x0
  pushl $76
80107e4a:	6a 4c                	push   $0x4c
  jmp alltraps
80107e4c:	e9 e0 f6 ff ff       	jmp    80107531 <alltraps>

80107e51 <vector77>:
.globl vector77
vector77:
  pushl $0
80107e51:	6a 00                	push   $0x0
  pushl $77
80107e53:	6a 4d                	push   $0x4d
  jmp alltraps
80107e55:	e9 d7 f6 ff ff       	jmp    80107531 <alltraps>

80107e5a <vector78>:
.globl vector78
vector78:
  pushl $0
80107e5a:	6a 00                	push   $0x0
  pushl $78
80107e5c:	6a 4e                	push   $0x4e
  jmp alltraps
80107e5e:	e9 ce f6 ff ff       	jmp    80107531 <alltraps>

80107e63 <vector79>:
.globl vector79
vector79:
  pushl $0
80107e63:	6a 00                	push   $0x0
  pushl $79
80107e65:	6a 4f                	push   $0x4f
  jmp alltraps
80107e67:	e9 c5 f6 ff ff       	jmp    80107531 <alltraps>

80107e6c <vector80>:
.globl vector80
vector80:
  pushl $0
80107e6c:	6a 00                	push   $0x0
  pushl $80
80107e6e:	6a 50                	push   $0x50
  jmp alltraps
80107e70:	e9 bc f6 ff ff       	jmp    80107531 <alltraps>

80107e75 <vector81>:
.globl vector81
vector81:
  pushl $0
80107e75:	6a 00                	push   $0x0
  pushl $81
80107e77:	6a 51                	push   $0x51
  jmp alltraps
80107e79:	e9 b3 f6 ff ff       	jmp    80107531 <alltraps>

80107e7e <vector82>:
.globl vector82
vector82:
  pushl $0
80107e7e:	6a 00                	push   $0x0
  pushl $82
80107e80:	6a 52                	push   $0x52
  jmp alltraps
80107e82:	e9 aa f6 ff ff       	jmp    80107531 <alltraps>

80107e87 <vector83>:
.globl vector83
vector83:
  pushl $0
80107e87:	6a 00                	push   $0x0
  pushl $83
80107e89:	6a 53                	push   $0x53
  jmp alltraps
80107e8b:	e9 a1 f6 ff ff       	jmp    80107531 <alltraps>

80107e90 <vector84>:
.globl vector84
vector84:
  pushl $0
80107e90:	6a 00                	push   $0x0
  pushl $84
80107e92:	6a 54                	push   $0x54
  jmp alltraps
80107e94:	e9 98 f6 ff ff       	jmp    80107531 <alltraps>

80107e99 <vector85>:
.globl vector85
vector85:
  pushl $0
80107e99:	6a 00                	push   $0x0
  pushl $85
80107e9b:	6a 55                	push   $0x55
  jmp alltraps
80107e9d:	e9 8f f6 ff ff       	jmp    80107531 <alltraps>

80107ea2 <vector86>:
.globl vector86
vector86:
  pushl $0
80107ea2:	6a 00                	push   $0x0
  pushl $86
80107ea4:	6a 56                	push   $0x56
  jmp alltraps
80107ea6:	e9 86 f6 ff ff       	jmp    80107531 <alltraps>

80107eab <vector87>:
.globl vector87
vector87:
  pushl $0
80107eab:	6a 00                	push   $0x0
  pushl $87
80107ead:	6a 57                	push   $0x57
  jmp alltraps
80107eaf:	e9 7d f6 ff ff       	jmp    80107531 <alltraps>

80107eb4 <vector88>:
.globl vector88
vector88:
  pushl $0
80107eb4:	6a 00                	push   $0x0
  pushl $88
80107eb6:	6a 58                	push   $0x58
  jmp alltraps
80107eb8:	e9 74 f6 ff ff       	jmp    80107531 <alltraps>

80107ebd <vector89>:
.globl vector89
vector89:
  pushl $0
80107ebd:	6a 00                	push   $0x0
  pushl $89
80107ebf:	6a 59                	push   $0x59
  jmp alltraps
80107ec1:	e9 6b f6 ff ff       	jmp    80107531 <alltraps>

80107ec6 <vector90>:
.globl vector90
vector90:
  pushl $0
80107ec6:	6a 00                	push   $0x0
  pushl $90
80107ec8:	6a 5a                	push   $0x5a
  jmp alltraps
80107eca:	e9 62 f6 ff ff       	jmp    80107531 <alltraps>

80107ecf <vector91>:
.globl vector91
vector91:
  pushl $0
80107ecf:	6a 00                	push   $0x0
  pushl $91
80107ed1:	6a 5b                	push   $0x5b
  jmp alltraps
80107ed3:	e9 59 f6 ff ff       	jmp    80107531 <alltraps>

80107ed8 <vector92>:
.globl vector92
vector92:
  pushl $0
80107ed8:	6a 00                	push   $0x0
  pushl $92
80107eda:	6a 5c                	push   $0x5c
  jmp alltraps
80107edc:	e9 50 f6 ff ff       	jmp    80107531 <alltraps>

80107ee1 <vector93>:
.globl vector93
vector93:
  pushl $0
80107ee1:	6a 00                	push   $0x0
  pushl $93
80107ee3:	6a 5d                	push   $0x5d
  jmp alltraps
80107ee5:	e9 47 f6 ff ff       	jmp    80107531 <alltraps>

80107eea <vector94>:
.globl vector94
vector94:
  pushl $0
80107eea:	6a 00                	push   $0x0
  pushl $94
80107eec:	6a 5e                	push   $0x5e
  jmp alltraps
80107eee:	e9 3e f6 ff ff       	jmp    80107531 <alltraps>

80107ef3 <vector95>:
.globl vector95
vector95:
  pushl $0
80107ef3:	6a 00                	push   $0x0
  pushl $95
80107ef5:	6a 5f                	push   $0x5f
  jmp alltraps
80107ef7:	e9 35 f6 ff ff       	jmp    80107531 <alltraps>

80107efc <vector96>:
.globl vector96
vector96:
  pushl $0
80107efc:	6a 00                	push   $0x0
  pushl $96
80107efe:	6a 60                	push   $0x60
  jmp alltraps
80107f00:	e9 2c f6 ff ff       	jmp    80107531 <alltraps>

80107f05 <vector97>:
.globl vector97
vector97:
  pushl $0
80107f05:	6a 00                	push   $0x0
  pushl $97
80107f07:	6a 61                	push   $0x61
  jmp alltraps
80107f09:	e9 23 f6 ff ff       	jmp    80107531 <alltraps>

80107f0e <vector98>:
.globl vector98
vector98:
  pushl $0
80107f0e:	6a 00                	push   $0x0
  pushl $98
80107f10:	6a 62                	push   $0x62
  jmp alltraps
80107f12:	e9 1a f6 ff ff       	jmp    80107531 <alltraps>

80107f17 <vector99>:
.globl vector99
vector99:
  pushl $0
80107f17:	6a 00                	push   $0x0
  pushl $99
80107f19:	6a 63                	push   $0x63
  jmp alltraps
80107f1b:	e9 11 f6 ff ff       	jmp    80107531 <alltraps>

80107f20 <vector100>:
.globl vector100
vector100:
  pushl $0
80107f20:	6a 00                	push   $0x0
  pushl $100
80107f22:	6a 64                	push   $0x64
  jmp alltraps
80107f24:	e9 08 f6 ff ff       	jmp    80107531 <alltraps>

80107f29 <vector101>:
.globl vector101
vector101:
  pushl $0
80107f29:	6a 00                	push   $0x0
  pushl $101
80107f2b:	6a 65                	push   $0x65
  jmp alltraps
80107f2d:	e9 ff f5 ff ff       	jmp    80107531 <alltraps>

80107f32 <vector102>:
.globl vector102
vector102:
  pushl $0
80107f32:	6a 00                	push   $0x0
  pushl $102
80107f34:	6a 66                	push   $0x66
  jmp alltraps
80107f36:	e9 f6 f5 ff ff       	jmp    80107531 <alltraps>

80107f3b <vector103>:
.globl vector103
vector103:
  pushl $0
80107f3b:	6a 00                	push   $0x0
  pushl $103
80107f3d:	6a 67                	push   $0x67
  jmp alltraps
80107f3f:	e9 ed f5 ff ff       	jmp    80107531 <alltraps>

80107f44 <vector104>:
.globl vector104
vector104:
  pushl $0
80107f44:	6a 00                	push   $0x0
  pushl $104
80107f46:	6a 68                	push   $0x68
  jmp alltraps
80107f48:	e9 e4 f5 ff ff       	jmp    80107531 <alltraps>

80107f4d <vector105>:
.globl vector105
vector105:
  pushl $0
80107f4d:	6a 00                	push   $0x0
  pushl $105
80107f4f:	6a 69                	push   $0x69
  jmp alltraps
80107f51:	e9 db f5 ff ff       	jmp    80107531 <alltraps>

80107f56 <vector106>:
.globl vector106
vector106:
  pushl $0
80107f56:	6a 00                	push   $0x0
  pushl $106
80107f58:	6a 6a                	push   $0x6a
  jmp alltraps
80107f5a:	e9 d2 f5 ff ff       	jmp    80107531 <alltraps>

80107f5f <vector107>:
.globl vector107
vector107:
  pushl $0
80107f5f:	6a 00                	push   $0x0
  pushl $107
80107f61:	6a 6b                	push   $0x6b
  jmp alltraps
80107f63:	e9 c9 f5 ff ff       	jmp    80107531 <alltraps>

80107f68 <vector108>:
.globl vector108
vector108:
  pushl $0
80107f68:	6a 00                	push   $0x0
  pushl $108
80107f6a:	6a 6c                	push   $0x6c
  jmp alltraps
80107f6c:	e9 c0 f5 ff ff       	jmp    80107531 <alltraps>

80107f71 <vector109>:
.globl vector109
vector109:
  pushl $0
80107f71:	6a 00                	push   $0x0
  pushl $109
80107f73:	6a 6d                	push   $0x6d
  jmp alltraps
80107f75:	e9 b7 f5 ff ff       	jmp    80107531 <alltraps>

80107f7a <vector110>:
.globl vector110
vector110:
  pushl $0
80107f7a:	6a 00                	push   $0x0
  pushl $110
80107f7c:	6a 6e                	push   $0x6e
  jmp alltraps
80107f7e:	e9 ae f5 ff ff       	jmp    80107531 <alltraps>

80107f83 <vector111>:
.globl vector111
vector111:
  pushl $0
80107f83:	6a 00                	push   $0x0
  pushl $111
80107f85:	6a 6f                	push   $0x6f
  jmp alltraps
80107f87:	e9 a5 f5 ff ff       	jmp    80107531 <alltraps>

80107f8c <vector112>:
.globl vector112
vector112:
  pushl $0
80107f8c:	6a 00                	push   $0x0
  pushl $112
80107f8e:	6a 70                	push   $0x70
  jmp alltraps
80107f90:	e9 9c f5 ff ff       	jmp    80107531 <alltraps>

80107f95 <vector113>:
.globl vector113
vector113:
  pushl $0
80107f95:	6a 00                	push   $0x0
  pushl $113
80107f97:	6a 71                	push   $0x71
  jmp alltraps
80107f99:	e9 93 f5 ff ff       	jmp    80107531 <alltraps>

80107f9e <vector114>:
.globl vector114
vector114:
  pushl $0
80107f9e:	6a 00                	push   $0x0
  pushl $114
80107fa0:	6a 72                	push   $0x72
  jmp alltraps
80107fa2:	e9 8a f5 ff ff       	jmp    80107531 <alltraps>

80107fa7 <vector115>:
.globl vector115
vector115:
  pushl $0
80107fa7:	6a 00                	push   $0x0
  pushl $115
80107fa9:	6a 73                	push   $0x73
  jmp alltraps
80107fab:	e9 81 f5 ff ff       	jmp    80107531 <alltraps>

80107fb0 <vector116>:
.globl vector116
vector116:
  pushl $0
80107fb0:	6a 00                	push   $0x0
  pushl $116
80107fb2:	6a 74                	push   $0x74
  jmp alltraps
80107fb4:	e9 78 f5 ff ff       	jmp    80107531 <alltraps>

80107fb9 <vector117>:
.globl vector117
vector117:
  pushl $0
80107fb9:	6a 00                	push   $0x0
  pushl $117
80107fbb:	6a 75                	push   $0x75
  jmp alltraps
80107fbd:	e9 6f f5 ff ff       	jmp    80107531 <alltraps>

80107fc2 <vector118>:
.globl vector118
vector118:
  pushl $0
80107fc2:	6a 00                	push   $0x0
  pushl $118
80107fc4:	6a 76                	push   $0x76
  jmp alltraps
80107fc6:	e9 66 f5 ff ff       	jmp    80107531 <alltraps>

80107fcb <vector119>:
.globl vector119
vector119:
  pushl $0
80107fcb:	6a 00                	push   $0x0
  pushl $119
80107fcd:	6a 77                	push   $0x77
  jmp alltraps
80107fcf:	e9 5d f5 ff ff       	jmp    80107531 <alltraps>

80107fd4 <vector120>:
.globl vector120
vector120:
  pushl $0
80107fd4:	6a 00                	push   $0x0
  pushl $120
80107fd6:	6a 78                	push   $0x78
  jmp alltraps
80107fd8:	e9 54 f5 ff ff       	jmp    80107531 <alltraps>

80107fdd <vector121>:
.globl vector121
vector121:
  pushl $0
80107fdd:	6a 00                	push   $0x0
  pushl $121
80107fdf:	6a 79                	push   $0x79
  jmp alltraps
80107fe1:	e9 4b f5 ff ff       	jmp    80107531 <alltraps>

80107fe6 <vector122>:
.globl vector122
vector122:
  pushl $0
80107fe6:	6a 00                	push   $0x0
  pushl $122
80107fe8:	6a 7a                	push   $0x7a
  jmp alltraps
80107fea:	e9 42 f5 ff ff       	jmp    80107531 <alltraps>

80107fef <vector123>:
.globl vector123
vector123:
  pushl $0
80107fef:	6a 00                	push   $0x0
  pushl $123
80107ff1:	6a 7b                	push   $0x7b
  jmp alltraps
80107ff3:	e9 39 f5 ff ff       	jmp    80107531 <alltraps>

80107ff8 <vector124>:
.globl vector124
vector124:
  pushl $0
80107ff8:	6a 00                	push   $0x0
  pushl $124
80107ffa:	6a 7c                	push   $0x7c
  jmp alltraps
80107ffc:	e9 30 f5 ff ff       	jmp    80107531 <alltraps>

80108001 <vector125>:
.globl vector125
vector125:
  pushl $0
80108001:	6a 00                	push   $0x0
  pushl $125
80108003:	6a 7d                	push   $0x7d
  jmp alltraps
80108005:	e9 27 f5 ff ff       	jmp    80107531 <alltraps>

8010800a <vector126>:
.globl vector126
vector126:
  pushl $0
8010800a:	6a 00                	push   $0x0
  pushl $126
8010800c:	6a 7e                	push   $0x7e
  jmp alltraps
8010800e:	e9 1e f5 ff ff       	jmp    80107531 <alltraps>

80108013 <vector127>:
.globl vector127
vector127:
  pushl $0
80108013:	6a 00                	push   $0x0
  pushl $127
80108015:	6a 7f                	push   $0x7f
  jmp alltraps
80108017:	e9 15 f5 ff ff       	jmp    80107531 <alltraps>

8010801c <vector128>:
.globl vector128
vector128:
  pushl $0
8010801c:	6a 00                	push   $0x0
  pushl $128
8010801e:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80108023:	e9 09 f5 ff ff       	jmp    80107531 <alltraps>

80108028 <vector129>:
.globl vector129
vector129:
  pushl $0
80108028:	6a 00                	push   $0x0
  pushl $129
8010802a:	68 81 00 00 00       	push   $0x81
  jmp alltraps
8010802f:	e9 fd f4 ff ff       	jmp    80107531 <alltraps>

80108034 <vector130>:
.globl vector130
vector130:
  pushl $0
80108034:	6a 00                	push   $0x0
  pushl $130
80108036:	68 82 00 00 00       	push   $0x82
  jmp alltraps
8010803b:	e9 f1 f4 ff ff       	jmp    80107531 <alltraps>

80108040 <vector131>:
.globl vector131
vector131:
  pushl $0
80108040:	6a 00                	push   $0x0
  pushl $131
80108042:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80108047:	e9 e5 f4 ff ff       	jmp    80107531 <alltraps>

8010804c <vector132>:
.globl vector132
vector132:
  pushl $0
8010804c:	6a 00                	push   $0x0
  pushl $132
8010804e:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80108053:	e9 d9 f4 ff ff       	jmp    80107531 <alltraps>

80108058 <vector133>:
.globl vector133
vector133:
  pushl $0
80108058:	6a 00                	push   $0x0
  pushl $133
8010805a:	68 85 00 00 00       	push   $0x85
  jmp alltraps
8010805f:	e9 cd f4 ff ff       	jmp    80107531 <alltraps>

80108064 <vector134>:
.globl vector134
vector134:
  pushl $0
80108064:	6a 00                	push   $0x0
  pushl $134
80108066:	68 86 00 00 00       	push   $0x86
  jmp alltraps
8010806b:	e9 c1 f4 ff ff       	jmp    80107531 <alltraps>

80108070 <vector135>:
.globl vector135
vector135:
  pushl $0
80108070:	6a 00                	push   $0x0
  pushl $135
80108072:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80108077:	e9 b5 f4 ff ff       	jmp    80107531 <alltraps>

8010807c <vector136>:
.globl vector136
vector136:
  pushl $0
8010807c:	6a 00                	push   $0x0
  pushl $136
8010807e:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80108083:	e9 a9 f4 ff ff       	jmp    80107531 <alltraps>

80108088 <vector137>:
.globl vector137
vector137:
  pushl $0
80108088:	6a 00                	push   $0x0
  pushl $137
8010808a:	68 89 00 00 00       	push   $0x89
  jmp alltraps
8010808f:	e9 9d f4 ff ff       	jmp    80107531 <alltraps>

80108094 <vector138>:
.globl vector138
vector138:
  pushl $0
80108094:	6a 00                	push   $0x0
  pushl $138
80108096:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
8010809b:	e9 91 f4 ff ff       	jmp    80107531 <alltraps>

801080a0 <vector139>:
.globl vector139
vector139:
  pushl $0
801080a0:	6a 00                	push   $0x0
  pushl $139
801080a2:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801080a7:	e9 85 f4 ff ff       	jmp    80107531 <alltraps>

801080ac <vector140>:
.globl vector140
vector140:
  pushl $0
801080ac:	6a 00                	push   $0x0
  pushl $140
801080ae:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801080b3:	e9 79 f4 ff ff       	jmp    80107531 <alltraps>

801080b8 <vector141>:
.globl vector141
vector141:
  pushl $0
801080b8:	6a 00                	push   $0x0
  pushl $141
801080ba:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801080bf:	e9 6d f4 ff ff       	jmp    80107531 <alltraps>

801080c4 <vector142>:
.globl vector142
vector142:
  pushl $0
801080c4:	6a 00                	push   $0x0
  pushl $142
801080c6:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
801080cb:	e9 61 f4 ff ff       	jmp    80107531 <alltraps>

801080d0 <vector143>:
.globl vector143
vector143:
  pushl $0
801080d0:	6a 00                	push   $0x0
  pushl $143
801080d2:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
801080d7:	e9 55 f4 ff ff       	jmp    80107531 <alltraps>

801080dc <vector144>:
.globl vector144
vector144:
  pushl $0
801080dc:	6a 00                	push   $0x0
  pushl $144
801080de:	68 90 00 00 00       	push   $0x90
  jmp alltraps
801080e3:	e9 49 f4 ff ff       	jmp    80107531 <alltraps>

801080e8 <vector145>:
.globl vector145
vector145:
  pushl $0
801080e8:	6a 00                	push   $0x0
  pushl $145
801080ea:	68 91 00 00 00       	push   $0x91
  jmp alltraps
801080ef:	e9 3d f4 ff ff       	jmp    80107531 <alltraps>

801080f4 <vector146>:
.globl vector146
vector146:
  pushl $0
801080f4:	6a 00                	push   $0x0
  pushl $146
801080f6:	68 92 00 00 00       	push   $0x92
  jmp alltraps
801080fb:	e9 31 f4 ff ff       	jmp    80107531 <alltraps>

80108100 <vector147>:
.globl vector147
vector147:
  pushl $0
80108100:	6a 00                	push   $0x0
  pushl $147
80108102:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80108107:	e9 25 f4 ff ff       	jmp    80107531 <alltraps>

8010810c <vector148>:
.globl vector148
vector148:
  pushl $0
8010810c:	6a 00                	push   $0x0
  pushl $148
8010810e:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80108113:	e9 19 f4 ff ff       	jmp    80107531 <alltraps>

80108118 <vector149>:
.globl vector149
vector149:
  pushl $0
80108118:	6a 00                	push   $0x0
  pushl $149
8010811a:	68 95 00 00 00       	push   $0x95
  jmp alltraps
8010811f:	e9 0d f4 ff ff       	jmp    80107531 <alltraps>

80108124 <vector150>:
.globl vector150
vector150:
  pushl $0
80108124:	6a 00                	push   $0x0
  pushl $150
80108126:	68 96 00 00 00       	push   $0x96
  jmp alltraps
8010812b:	e9 01 f4 ff ff       	jmp    80107531 <alltraps>

80108130 <vector151>:
.globl vector151
vector151:
  pushl $0
80108130:	6a 00                	push   $0x0
  pushl $151
80108132:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80108137:	e9 f5 f3 ff ff       	jmp    80107531 <alltraps>

8010813c <vector152>:
.globl vector152
vector152:
  pushl $0
8010813c:	6a 00                	push   $0x0
  pushl $152
8010813e:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80108143:	e9 e9 f3 ff ff       	jmp    80107531 <alltraps>

80108148 <vector153>:
.globl vector153
vector153:
  pushl $0
80108148:	6a 00                	push   $0x0
  pushl $153
8010814a:	68 99 00 00 00       	push   $0x99
  jmp alltraps
8010814f:	e9 dd f3 ff ff       	jmp    80107531 <alltraps>

80108154 <vector154>:
.globl vector154
vector154:
  pushl $0
80108154:	6a 00                	push   $0x0
  pushl $154
80108156:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
8010815b:	e9 d1 f3 ff ff       	jmp    80107531 <alltraps>

80108160 <vector155>:
.globl vector155
vector155:
  pushl $0
80108160:	6a 00                	push   $0x0
  pushl $155
80108162:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80108167:	e9 c5 f3 ff ff       	jmp    80107531 <alltraps>

8010816c <vector156>:
.globl vector156
vector156:
  pushl $0
8010816c:	6a 00                	push   $0x0
  pushl $156
8010816e:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80108173:	e9 b9 f3 ff ff       	jmp    80107531 <alltraps>

80108178 <vector157>:
.globl vector157
vector157:
  pushl $0
80108178:	6a 00                	push   $0x0
  pushl $157
8010817a:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
8010817f:	e9 ad f3 ff ff       	jmp    80107531 <alltraps>

80108184 <vector158>:
.globl vector158
vector158:
  pushl $0
80108184:	6a 00                	push   $0x0
  pushl $158
80108186:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
8010818b:	e9 a1 f3 ff ff       	jmp    80107531 <alltraps>

80108190 <vector159>:
.globl vector159
vector159:
  pushl $0
80108190:	6a 00                	push   $0x0
  pushl $159
80108192:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80108197:	e9 95 f3 ff ff       	jmp    80107531 <alltraps>

8010819c <vector160>:
.globl vector160
vector160:
  pushl $0
8010819c:	6a 00                	push   $0x0
  pushl $160
8010819e:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
801081a3:	e9 89 f3 ff ff       	jmp    80107531 <alltraps>

801081a8 <vector161>:
.globl vector161
vector161:
  pushl $0
801081a8:	6a 00                	push   $0x0
  pushl $161
801081aa:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
801081af:	e9 7d f3 ff ff       	jmp    80107531 <alltraps>

801081b4 <vector162>:
.globl vector162
vector162:
  pushl $0
801081b4:	6a 00                	push   $0x0
  pushl $162
801081b6:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
801081bb:	e9 71 f3 ff ff       	jmp    80107531 <alltraps>

801081c0 <vector163>:
.globl vector163
vector163:
  pushl $0
801081c0:	6a 00                	push   $0x0
  pushl $163
801081c2:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
801081c7:	e9 65 f3 ff ff       	jmp    80107531 <alltraps>

801081cc <vector164>:
.globl vector164
vector164:
  pushl $0
801081cc:	6a 00                	push   $0x0
  pushl $164
801081ce:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
801081d3:	e9 59 f3 ff ff       	jmp    80107531 <alltraps>

801081d8 <vector165>:
.globl vector165
vector165:
  pushl $0
801081d8:	6a 00                	push   $0x0
  pushl $165
801081da:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
801081df:	e9 4d f3 ff ff       	jmp    80107531 <alltraps>

801081e4 <vector166>:
.globl vector166
vector166:
  pushl $0
801081e4:	6a 00                	push   $0x0
  pushl $166
801081e6:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
801081eb:	e9 41 f3 ff ff       	jmp    80107531 <alltraps>

801081f0 <vector167>:
.globl vector167
vector167:
  pushl $0
801081f0:	6a 00                	push   $0x0
  pushl $167
801081f2:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
801081f7:	e9 35 f3 ff ff       	jmp    80107531 <alltraps>

801081fc <vector168>:
.globl vector168
vector168:
  pushl $0
801081fc:	6a 00                	push   $0x0
  pushl $168
801081fe:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80108203:	e9 29 f3 ff ff       	jmp    80107531 <alltraps>

80108208 <vector169>:
.globl vector169
vector169:
  pushl $0
80108208:	6a 00                	push   $0x0
  pushl $169
8010820a:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
8010820f:	e9 1d f3 ff ff       	jmp    80107531 <alltraps>

80108214 <vector170>:
.globl vector170
vector170:
  pushl $0
80108214:	6a 00                	push   $0x0
  pushl $170
80108216:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
8010821b:	e9 11 f3 ff ff       	jmp    80107531 <alltraps>

80108220 <vector171>:
.globl vector171
vector171:
  pushl $0
80108220:	6a 00                	push   $0x0
  pushl $171
80108222:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80108227:	e9 05 f3 ff ff       	jmp    80107531 <alltraps>

8010822c <vector172>:
.globl vector172
vector172:
  pushl $0
8010822c:	6a 00                	push   $0x0
  pushl $172
8010822e:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80108233:	e9 f9 f2 ff ff       	jmp    80107531 <alltraps>

80108238 <vector173>:
.globl vector173
vector173:
  pushl $0
80108238:	6a 00                	push   $0x0
  pushl $173
8010823a:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
8010823f:	e9 ed f2 ff ff       	jmp    80107531 <alltraps>

80108244 <vector174>:
.globl vector174
vector174:
  pushl $0
80108244:	6a 00                	push   $0x0
  pushl $174
80108246:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
8010824b:	e9 e1 f2 ff ff       	jmp    80107531 <alltraps>

80108250 <vector175>:
.globl vector175
vector175:
  pushl $0
80108250:	6a 00                	push   $0x0
  pushl $175
80108252:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80108257:	e9 d5 f2 ff ff       	jmp    80107531 <alltraps>

8010825c <vector176>:
.globl vector176
vector176:
  pushl $0
8010825c:	6a 00                	push   $0x0
  pushl $176
8010825e:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80108263:	e9 c9 f2 ff ff       	jmp    80107531 <alltraps>

80108268 <vector177>:
.globl vector177
vector177:
  pushl $0
80108268:	6a 00                	push   $0x0
  pushl $177
8010826a:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
8010826f:	e9 bd f2 ff ff       	jmp    80107531 <alltraps>

80108274 <vector178>:
.globl vector178
vector178:
  pushl $0
80108274:	6a 00                	push   $0x0
  pushl $178
80108276:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
8010827b:	e9 b1 f2 ff ff       	jmp    80107531 <alltraps>

80108280 <vector179>:
.globl vector179
vector179:
  pushl $0
80108280:	6a 00                	push   $0x0
  pushl $179
80108282:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80108287:	e9 a5 f2 ff ff       	jmp    80107531 <alltraps>

8010828c <vector180>:
.globl vector180
vector180:
  pushl $0
8010828c:	6a 00                	push   $0x0
  pushl $180
8010828e:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80108293:	e9 99 f2 ff ff       	jmp    80107531 <alltraps>

80108298 <vector181>:
.globl vector181
vector181:
  pushl $0
80108298:	6a 00                	push   $0x0
  pushl $181
8010829a:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
8010829f:	e9 8d f2 ff ff       	jmp    80107531 <alltraps>

801082a4 <vector182>:
.globl vector182
vector182:
  pushl $0
801082a4:	6a 00                	push   $0x0
  pushl $182
801082a6:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
801082ab:	e9 81 f2 ff ff       	jmp    80107531 <alltraps>

801082b0 <vector183>:
.globl vector183
vector183:
  pushl $0
801082b0:	6a 00                	push   $0x0
  pushl $183
801082b2:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
801082b7:	e9 75 f2 ff ff       	jmp    80107531 <alltraps>

801082bc <vector184>:
.globl vector184
vector184:
  pushl $0
801082bc:	6a 00                	push   $0x0
  pushl $184
801082be:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
801082c3:	e9 69 f2 ff ff       	jmp    80107531 <alltraps>

801082c8 <vector185>:
.globl vector185
vector185:
  pushl $0
801082c8:	6a 00                	push   $0x0
  pushl $185
801082ca:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
801082cf:	e9 5d f2 ff ff       	jmp    80107531 <alltraps>

801082d4 <vector186>:
.globl vector186
vector186:
  pushl $0
801082d4:	6a 00                	push   $0x0
  pushl $186
801082d6:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
801082db:	e9 51 f2 ff ff       	jmp    80107531 <alltraps>

801082e0 <vector187>:
.globl vector187
vector187:
  pushl $0
801082e0:	6a 00                	push   $0x0
  pushl $187
801082e2:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
801082e7:	e9 45 f2 ff ff       	jmp    80107531 <alltraps>

801082ec <vector188>:
.globl vector188
vector188:
  pushl $0
801082ec:	6a 00                	push   $0x0
  pushl $188
801082ee:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
801082f3:	e9 39 f2 ff ff       	jmp    80107531 <alltraps>

801082f8 <vector189>:
.globl vector189
vector189:
  pushl $0
801082f8:	6a 00                	push   $0x0
  pushl $189
801082fa:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
801082ff:	e9 2d f2 ff ff       	jmp    80107531 <alltraps>

80108304 <vector190>:
.globl vector190
vector190:
  pushl $0
80108304:	6a 00                	push   $0x0
  pushl $190
80108306:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
8010830b:	e9 21 f2 ff ff       	jmp    80107531 <alltraps>

80108310 <vector191>:
.globl vector191
vector191:
  pushl $0
80108310:	6a 00                	push   $0x0
  pushl $191
80108312:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80108317:	e9 15 f2 ff ff       	jmp    80107531 <alltraps>

8010831c <vector192>:
.globl vector192
vector192:
  pushl $0
8010831c:	6a 00                	push   $0x0
  pushl $192
8010831e:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80108323:	e9 09 f2 ff ff       	jmp    80107531 <alltraps>

80108328 <vector193>:
.globl vector193
vector193:
  pushl $0
80108328:	6a 00                	push   $0x0
  pushl $193
8010832a:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
8010832f:	e9 fd f1 ff ff       	jmp    80107531 <alltraps>

80108334 <vector194>:
.globl vector194
vector194:
  pushl $0
80108334:	6a 00                	push   $0x0
  pushl $194
80108336:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
8010833b:	e9 f1 f1 ff ff       	jmp    80107531 <alltraps>

80108340 <vector195>:
.globl vector195
vector195:
  pushl $0
80108340:	6a 00                	push   $0x0
  pushl $195
80108342:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80108347:	e9 e5 f1 ff ff       	jmp    80107531 <alltraps>

8010834c <vector196>:
.globl vector196
vector196:
  pushl $0
8010834c:	6a 00                	push   $0x0
  pushl $196
8010834e:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80108353:	e9 d9 f1 ff ff       	jmp    80107531 <alltraps>

80108358 <vector197>:
.globl vector197
vector197:
  pushl $0
80108358:	6a 00                	push   $0x0
  pushl $197
8010835a:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
8010835f:	e9 cd f1 ff ff       	jmp    80107531 <alltraps>

80108364 <vector198>:
.globl vector198
vector198:
  pushl $0
80108364:	6a 00                	push   $0x0
  pushl $198
80108366:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
8010836b:	e9 c1 f1 ff ff       	jmp    80107531 <alltraps>

80108370 <vector199>:
.globl vector199
vector199:
  pushl $0
80108370:	6a 00                	push   $0x0
  pushl $199
80108372:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80108377:	e9 b5 f1 ff ff       	jmp    80107531 <alltraps>

8010837c <vector200>:
.globl vector200
vector200:
  pushl $0
8010837c:	6a 00                	push   $0x0
  pushl $200
8010837e:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80108383:	e9 a9 f1 ff ff       	jmp    80107531 <alltraps>

80108388 <vector201>:
.globl vector201
vector201:
  pushl $0
80108388:	6a 00                	push   $0x0
  pushl $201
8010838a:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
8010838f:	e9 9d f1 ff ff       	jmp    80107531 <alltraps>

80108394 <vector202>:
.globl vector202
vector202:
  pushl $0
80108394:	6a 00                	push   $0x0
  pushl $202
80108396:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
8010839b:	e9 91 f1 ff ff       	jmp    80107531 <alltraps>

801083a0 <vector203>:
.globl vector203
vector203:
  pushl $0
801083a0:	6a 00                	push   $0x0
  pushl $203
801083a2:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
801083a7:	e9 85 f1 ff ff       	jmp    80107531 <alltraps>

801083ac <vector204>:
.globl vector204
vector204:
  pushl $0
801083ac:	6a 00                	push   $0x0
  pushl $204
801083ae:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
801083b3:	e9 79 f1 ff ff       	jmp    80107531 <alltraps>

801083b8 <vector205>:
.globl vector205
vector205:
  pushl $0
801083b8:	6a 00                	push   $0x0
  pushl $205
801083ba:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
801083bf:	e9 6d f1 ff ff       	jmp    80107531 <alltraps>

801083c4 <vector206>:
.globl vector206
vector206:
  pushl $0
801083c4:	6a 00                	push   $0x0
  pushl $206
801083c6:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
801083cb:	e9 61 f1 ff ff       	jmp    80107531 <alltraps>

801083d0 <vector207>:
.globl vector207
vector207:
  pushl $0
801083d0:	6a 00                	push   $0x0
  pushl $207
801083d2:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
801083d7:	e9 55 f1 ff ff       	jmp    80107531 <alltraps>

801083dc <vector208>:
.globl vector208
vector208:
  pushl $0
801083dc:	6a 00                	push   $0x0
  pushl $208
801083de:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
801083e3:	e9 49 f1 ff ff       	jmp    80107531 <alltraps>

801083e8 <vector209>:
.globl vector209
vector209:
  pushl $0
801083e8:	6a 00                	push   $0x0
  pushl $209
801083ea:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
801083ef:	e9 3d f1 ff ff       	jmp    80107531 <alltraps>

801083f4 <vector210>:
.globl vector210
vector210:
  pushl $0
801083f4:	6a 00                	push   $0x0
  pushl $210
801083f6:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
801083fb:	e9 31 f1 ff ff       	jmp    80107531 <alltraps>

80108400 <vector211>:
.globl vector211
vector211:
  pushl $0
80108400:	6a 00                	push   $0x0
  pushl $211
80108402:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80108407:	e9 25 f1 ff ff       	jmp    80107531 <alltraps>

8010840c <vector212>:
.globl vector212
vector212:
  pushl $0
8010840c:	6a 00                	push   $0x0
  pushl $212
8010840e:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80108413:	e9 19 f1 ff ff       	jmp    80107531 <alltraps>

80108418 <vector213>:
.globl vector213
vector213:
  pushl $0
80108418:	6a 00                	push   $0x0
  pushl $213
8010841a:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
8010841f:	e9 0d f1 ff ff       	jmp    80107531 <alltraps>

80108424 <vector214>:
.globl vector214
vector214:
  pushl $0
80108424:	6a 00                	push   $0x0
  pushl $214
80108426:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
8010842b:	e9 01 f1 ff ff       	jmp    80107531 <alltraps>

80108430 <vector215>:
.globl vector215
vector215:
  pushl $0
80108430:	6a 00                	push   $0x0
  pushl $215
80108432:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80108437:	e9 f5 f0 ff ff       	jmp    80107531 <alltraps>

8010843c <vector216>:
.globl vector216
vector216:
  pushl $0
8010843c:	6a 00                	push   $0x0
  pushl $216
8010843e:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80108443:	e9 e9 f0 ff ff       	jmp    80107531 <alltraps>

80108448 <vector217>:
.globl vector217
vector217:
  pushl $0
80108448:	6a 00                	push   $0x0
  pushl $217
8010844a:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
8010844f:	e9 dd f0 ff ff       	jmp    80107531 <alltraps>

80108454 <vector218>:
.globl vector218
vector218:
  pushl $0
80108454:	6a 00                	push   $0x0
  pushl $218
80108456:	68 da 00 00 00       	push   $0xda
  jmp alltraps
8010845b:	e9 d1 f0 ff ff       	jmp    80107531 <alltraps>

80108460 <vector219>:
.globl vector219
vector219:
  pushl $0
80108460:	6a 00                	push   $0x0
  pushl $219
80108462:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80108467:	e9 c5 f0 ff ff       	jmp    80107531 <alltraps>

8010846c <vector220>:
.globl vector220
vector220:
  pushl $0
8010846c:	6a 00                	push   $0x0
  pushl $220
8010846e:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80108473:	e9 b9 f0 ff ff       	jmp    80107531 <alltraps>

80108478 <vector221>:
.globl vector221
vector221:
  pushl $0
80108478:	6a 00                	push   $0x0
  pushl $221
8010847a:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
8010847f:	e9 ad f0 ff ff       	jmp    80107531 <alltraps>

80108484 <vector222>:
.globl vector222
vector222:
  pushl $0
80108484:	6a 00                	push   $0x0
  pushl $222
80108486:	68 de 00 00 00       	push   $0xde
  jmp alltraps
8010848b:	e9 a1 f0 ff ff       	jmp    80107531 <alltraps>

80108490 <vector223>:
.globl vector223
vector223:
  pushl $0
80108490:	6a 00                	push   $0x0
  pushl $223
80108492:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80108497:	e9 95 f0 ff ff       	jmp    80107531 <alltraps>

8010849c <vector224>:
.globl vector224
vector224:
  pushl $0
8010849c:	6a 00                	push   $0x0
  pushl $224
8010849e:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
801084a3:	e9 89 f0 ff ff       	jmp    80107531 <alltraps>

801084a8 <vector225>:
.globl vector225
vector225:
  pushl $0
801084a8:	6a 00                	push   $0x0
  pushl $225
801084aa:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
801084af:	e9 7d f0 ff ff       	jmp    80107531 <alltraps>

801084b4 <vector226>:
.globl vector226
vector226:
  pushl $0
801084b4:	6a 00                	push   $0x0
  pushl $226
801084b6:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
801084bb:	e9 71 f0 ff ff       	jmp    80107531 <alltraps>

801084c0 <vector227>:
.globl vector227
vector227:
  pushl $0
801084c0:	6a 00                	push   $0x0
  pushl $227
801084c2:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
801084c7:	e9 65 f0 ff ff       	jmp    80107531 <alltraps>

801084cc <vector228>:
.globl vector228
vector228:
  pushl $0
801084cc:	6a 00                	push   $0x0
  pushl $228
801084ce:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
801084d3:	e9 59 f0 ff ff       	jmp    80107531 <alltraps>

801084d8 <vector229>:
.globl vector229
vector229:
  pushl $0
801084d8:	6a 00                	push   $0x0
  pushl $229
801084da:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
801084df:	e9 4d f0 ff ff       	jmp    80107531 <alltraps>

801084e4 <vector230>:
.globl vector230
vector230:
  pushl $0
801084e4:	6a 00                	push   $0x0
  pushl $230
801084e6:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
801084eb:	e9 41 f0 ff ff       	jmp    80107531 <alltraps>

801084f0 <vector231>:
.globl vector231
vector231:
  pushl $0
801084f0:	6a 00                	push   $0x0
  pushl $231
801084f2:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
801084f7:	e9 35 f0 ff ff       	jmp    80107531 <alltraps>

801084fc <vector232>:
.globl vector232
vector232:
  pushl $0
801084fc:	6a 00                	push   $0x0
  pushl $232
801084fe:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80108503:	e9 29 f0 ff ff       	jmp    80107531 <alltraps>

80108508 <vector233>:
.globl vector233
vector233:
  pushl $0
80108508:	6a 00                	push   $0x0
  pushl $233
8010850a:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
8010850f:	e9 1d f0 ff ff       	jmp    80107531 <alltraps>

80108514 <vector234>:
.globl vector234
vector234:
  pushl $0
80108514:	6a 00                	push   $0x0
  pushl $234
80108516:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
8010851b:	e9 11 f0 ff ff       	jmp    80107531 <alltraps>

80108520 <vector235>:
.globl vector235
vector235:
  pushl $0
80108520:	6a 00                	push   $0x0
  pushl $235
80108522:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80108527:	e9 05 f0 ff ff       	jmp    80107531 <alltraps>

8010852c <vector236>:
.globl vector236
vector236:
  pushl $0
8010852c:	6a 00                	push   $0x0
  pushl $236
8010852e:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80108533:	e9 f9 ef ff ff       	jmp    80107531 <alltraps>

80108538 <vector237>:
.globl vector237
vector237:
  pushl $0
80108538:	6a 00                	push   $0x0
  pushl $237
8010853a:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
8010853f:	e9 ed ef ff ff       	jmp    80107531 <alltraps>

80108544 <vector238>:
.globl vector238
vector238:
  pushl $0
80108544:	6a 00                	push   $0x0
  pushl $238
80108546:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
8010854b:	e9 e1 ef ff ff       	jmp    80107531 <alltraps>

80108550 <vector239>:
.globl vector239
vector239:
  pushl $0
80108550:	6a 00                	push   $0x0
  pushl $239
80108552:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80108557:	e9 d5 ef ff ff       	jmp    80107531 <alltraps>

8010855c <vector240>:
.globl vector240
vector240:
  pushl $0
8010855c:	6a 00                	push   $0x0
  pushl $240
8010855e:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80108563:	e9 c9 ef ff ff       	jmp    80107531 <alltraps>

80108568 <vector241>:
.globl vector241
vector241:
  pushl $0
80108568:	6a 00                	push   $0x0
  pushl $241
8010856a:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
8010856f:	e9 bd ef ff ff       	jmp    80107531 <alltraps>

80108574 <vector242>:
.globl vector242
vector242:
  pushl $0
80108574:	6a 00                	push   $0x0
  pushl $242
80108576:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
8010857b:	e9 b1 ef ff ff       	jmp    80107531 <alltraps>

80108580 <vector243>:
.globl vector243
vector243:
  pushl $0
80108580:	6a 00                	push   $0x0
  pushl $243
80108582:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80108587:	e9 a5 ef ff ff       	jmp    80107531 <alltraps>

8010858c <vector244>:
.globl vector244
vector244:
  pushl $0
8010858c:	6a 00                	push   $0x0
  pushl $244
8010858e:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80108593:	e9 99 ef ff ff       	jmp    80107531 <alltraps>

80108598 <vector245>:
.globl vector245
vector245:
  pushl $0
80108598:	6a 00                	push   $0x0
  pushl $245
8010859a:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
8010859f:	e9 8d ef ff ff       	jmp    80107531 <alltraps>

801085a4 <vector246>:
.globl vector246
vector246:
  pushl $0
801085a4:	6a 00                	push   $0x0
  pushl $246
801085a6:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
801085ab:	e9 81 ef ff ff       	jmp    80107531 <alltraps>

801085b0 <vector247>:
.globl vector247
vector247:
  pushl $0
801085b0:	6a 00                	push   $0x0
  pushl $247
801085b2:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
801085b7:	e9 75 ef ff ff       	jmp    80107531 <alltraps>

801085bc <vector248>:
.globl vector248
vector248:
  pushl $0
801085bc:	6a 00                	push   $0x0
  pushl $248
801085be:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
801085c3:	e9 69 ef ff ff       	jmp    80107531 <alltraps>

801085c8 <vector249>:
.globl vector249
vector249:
  pushl $0
801085c8:	6a 00                	push   $0x0
  pushl $249
801085ca:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
801085cf:	e9 5d ef ff ff       	jmp    80107531 <alltraps>

801085d4 <vector250>:
.globl vector250
vector250:
  pushl $0
801085d4:	6a 00                	push   $0x0
  pushl $250
801085d6:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
801085db:	e9 51 ef ff ff       	jmp    80107531 <alltraps>

801085e0 <vector251>:
.globl vector251
vector251:
  pushl $0
801085e0:	6a 00                	push   $0x0
  pushl $251
801085e2:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
801085e7:	e9 45 ef ff ff       	jmp    80107531 <alltraps>

801085ec <vector252>:
.globl vector252
vector252:
  pushl $0
801085ec:	6a 00                	push   $0x0
  pushl $252
801085ee:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
801085f3:	e9 39 ef ff ff       	jmp    80107531 <alltraps>

801085f8 <vector253>:
.globl vector253
vector253:
  pushl $0
801085f8:	6a 00                	push   $0x0
  pushl $253
801085fa:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
801085ff:	e9 2d ef ff ff       	jmp    80107531 <alltraps>

80108604 <vector254>:
.globl vector254
vector254:
  pushl $0
80108604:	6a 00                	push   $0x0
  pushl $254
80108606:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
8010860b:	e9 21 ef ff ff       	jmp    80107531 <alltraps>

80108610 <vector255>:
.globl vector255
vector255:
  pushl $0
80108610:	6a 00                	push   $0x0
  pushl $255
80108612:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80108617:	e9 15 ef ff ff       	jmp    80107531 <alltraps>

8010861c <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
8010861c:	55                   	push   %ebp
8010861d:	89 e5                	mov    %esp,%ebp
8010861f:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80108622:	8b 45 0c             	mov    0xc(%ebp),%eax
80108625:	83 e8 01             	sub    $0x1,%eax
80108628:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
8010862c:	8b 45 08             	mov    0x8(%ebp),%eax
8010862f:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80108633:	8b 45 08             	mov    0x8(%ebp),%eax
80108636:	c1 e8 10             	shr    $0x10,%eax
80108639:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
8010863d:	8d 45 fa             	lea    -0x6(%ebp),%eax
80108640:	0f 01 10             	lgdtl  (%eax)
}
80108643:	c9                   	leave  
80108644:	c3                   	ret    

80108645 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80108645:	55                   	push   %ebp
80108646:	89 e5                	mov    %esp,%ebp
80108648:	83 ec 04             	sub    $0x4,%esp
8010864b:	8b 45 08             	mov    0x8(%ebp),%eax
8010864e:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80108652:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80108656:	0f 00 d8             	ltr    %ax
}
80108659:	c9                   	leave  
8010865a:	c3                   	ret    

8010865b <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
8010865b:	55                   	push   %ebp
8010865c:	89 e5                	mov    %esp,%ebp
8010865e:	83 ec 04             	sub    $0x4,%esp
80108661:	8b 45 08             	mov    0x8(%ebp),%eax
80108664:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80108668:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010866c:	8e e8                	mov    %eax,%gs
}
8010866e:	c9                   	leave  
8010866f:	c3                   	ret    

80108670 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80108670:	55                   	push   %ebp
80108671:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80108673:	8b 45 08             	mov    0x8(%ebp),%eax
80108676:	0f 22 d8             	mov    %eax,%cr3
}
80108679:	5d                   	pop    %ebp
8010867a:	c3                   	ret    

8010867b <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
8010867b:	55                   	push   %ebp
8010867c:	89 e5                	mov    %esp,%ebp
8010867e:	8b 45 08             	mov    0x8(%ebp),%eax
80108681:	05 00 00 00 80       	add    $0x80000000,%eax
80108686:	5d                   	pop    %ebp
80108687:	c3                   	ret    

80108688 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80108688:	55                   	push   %ebp
80108689:	89 e5                	mov    %esp,%ebp
8010868b:	8b 45 08             	mov    0x8(%ebp),%eax
8010868e:	05 00 00 00 80       	add    $0x80000000,%eax
80108693:	5d                   	pop    %ebp
80108694:	c3                   	ret    

80108695 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80108695:	55                   	push   %ebp
80108696:	89 e5                	mov    %esp,%ebp
80108698:	53                   	push   %ebx
80108699:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
8010869c:	e8 f2 a9 ff ff       	call   80103093 <cpunum>
801086a1:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801086a7:	05 a0 33 11 80       	add    $0x801133a0,%eax
801086ac:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
801086af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086b2:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
801086b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086bb:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
801086c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086c4:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
801086c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086cb:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801086cf:	83 e2 f0             	and    $0xfffffff0,%edx
801086d2:	83 ca 0a             	or     $0xa,%edx
801086d5:	88 50 7d             	mov    %dl,0x7d(%eax)
801086d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086db:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801086df:	83 ca 10             	or     $0x10,%edx
801086e2:	88 50 7d             	mov    %dl,0x7d(%eax)
801086e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086e8:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801086ec:	83 e2 9f             	and    $0xffffff9f,%edx
801086ef:	88 50 7d             	mov    %dl,0x7d(%eax)
801086f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086f5:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801086f9:	83 ca 80             	or     $0xffffff80,%edx
801086fc:	88 50 7d             	mov    %dl,0x7d(%eax)
801086ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108702:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108706:	83 ca 0f             	or     $0xf,%edx
80108709:	88 50 7e             	mov    %dl,0x7e(%eax)
8010870c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010870f:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108713:	83 e2 ef             	and    $0xffffffef,%edx
80108716:	88 50 7e             	mov    %dl,0x7e(%eax)
80108719:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010871c:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108720:	83 e2 df             	and    $0xffffffdf,%edx
80108723:	88 50 7e             	mov    %dl,0x7e(%eax)
80108726:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108729:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010872d:	83 ca 40             	or     $0x40,%edx
80108730:	88 50 7e             	mov    %dl,0x7e(%eax)
80108733:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108736:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010873a:	83 ca 80             	or     $0xffffff80,%edx
8010873d:	88 50 7e             	mov    %dl,0x7e(%eax)
80108740:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108743:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80108747:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010874a:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80108751:	ff ff 
80108753:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108756:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
8010875d:	00 00 
8010875f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108762:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80108769:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010876c:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108773:	83 e2 f0             	and    $0xfffffff0,%edx
80108776:	83 ca 02             	or     $0x2,%edx
80108779:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010877f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108782:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108789:	83 ca 10             	or     $0x10,%edx
8010878c:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108792:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108795:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010879c:	83 e2 9f             	and    $0xffffff9f,%edx
8010879f:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801087a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087a8:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801087af:	83 ca 80             	or     $0xffffff80,%edx
801087b2:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801087b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087bb:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801087c2:	83 ca 0f             	or     $0xf,%edx
801087c5:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801087cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087ce:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801087d5:	83 e2 ef             	and    $0xffffffef,%edx
801087d8:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801087de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087e1:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801087e8:	83 e2 df             	and    $0xffffffdf,%edx
801087eb:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801087f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087f4:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801087fb:	83 ca 40             	or     $0x40,%edx
801087fe:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108804:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108807:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010880e:	83 ca 80             	or     $0xffffff80,%edx
80108811:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108817:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010881a:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80108821:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108824:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
8010882b:	ff ff 
8010882d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108830:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80108837:	00 00 
80108839:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010883c:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80108843:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108846:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010884d:	83 e2 f0             	and    $0xfffffff0,%edx
80108850:	83 ca 0a             	or     $0xa,%edx
80108853:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108859:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010885c:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108863:	83 ca 10             	or     $0x10,%edx
80108866:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010886c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010886f:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108876:	83 ca 60             	or     $0x60,%edx
80108879:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010887f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108882:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108889:	83 ca 80             	or     $0xffffff80,%edx
8010888c:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108892:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108895:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010889c:	83 ca 0f             	or     $0xf,%edx
8010889f:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801088a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088a8:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801088af:	83 e2 ef             	and    $0xffffffef,%edx
801088b2:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801088b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088bb:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801088c2:	83 e2 df             	and    $0xffffffdf,%edx
801088c5:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801088cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088ce:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801088d5:	83 ca 40             	or     $0x40,%edx
801088d8:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801088de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088e1:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801088e8:	83 ca 80             	or     $0xffffff80,%edx
801088eb:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801088f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088f4:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
801088fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088fe:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80108905:	ff ff 
80108907:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010890a:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80108911:	00 00 
80108913:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108916:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
8010891d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108920:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108927:	83 e2 f0             	and    $0xfffffff0,%edx
8010892a:	83 ca 02             	or     $0x2,%edx
8010892d:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108933:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108936:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010893d:	83 ca 10             	or     $0x10,%edx
80108940:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108946:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108949:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108950:	83 ca 60             	or     $0x60,%edx
80108953:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108959:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010895c:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108963:	83 ca 80             	or     $0xffffff80,%edx
80108966:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010896c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010896f:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108976:	83 ca 0f             	or     $0xf,%edx
80108979:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010897f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108982:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108989:	83 e2 ef             	and    $0xffffffef,%edx
8010898c:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108992:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108995:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010899c:	83 e2 df             	and    $0xffffffdf,%edx
8010899f:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801089a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089a8:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801089af:	83 ca 40             	or     $0x40,%edx
801089b2:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801089b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089bb:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801089c2:	83 ca 80             	or     $0xffffff80,%edx
801089c5:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801089cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089ce:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
801089d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089d8:	05 b4 00 00 00       	add    $0xb4,%eax
801089dd:	89 c3                	mov    %eax,%ebx
801089df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089e2:	05 b4 00 00 00       	add    $0xb4,%eax
801089e7:	c1 e8 10             	shr    $0x10,%eax
801089ea:	89 c1                	mov    %eax,%ecx
801089ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089ef:	05 b4 00 00 00       	add    $0xb4,%eax
801089f4:	c1 e8 18             	shr    $0x18,%eax
801089f7:	89 c2                	mov    %eax,%edx
801089f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089fc:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80108a03:	00 00 
80108a05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a08:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80108a0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a12:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80108a18:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a1b:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108a22:	83 e1 f0             	and    $0xfffffff0,%ecx
80108a25:	83 c9 02             	or     $0x2,%ecx
80108a28:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108a2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a31:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108a38:	83 c9 10             	or     $0x10,%ecx
80108a3b:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108a41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a44:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108a4b:	83 e1 9f             	and    $0xffffff9f,%ecx
80108a4e:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108a54:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a57:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108a5e:	83 c9 80             	or     $0xffffff80,%ecx
80108a61:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108a67:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a6a:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108a71:	83 e1 f0             	and    $0xfffffff0,%ecx
80108a74:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108a7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a7d:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108a84:	83 e1 ef             	and    $0xffffffef,%ecx
80108a87:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108a8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a90:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108a97:	83 e1 df             	and    $0xffffffdf,%ecx
80108a9a:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108aa0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108aa3:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108aaa:	83 c9 40             	or     $0x40,%ecx
80108aad:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108ab3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ab6:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108abd:	83 c9 80             	or     $0xffffff80,%ecx
80108ac0:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108ac6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ac9:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80108acf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ad2:	83 c0 70             	add    $0x70,%eax
80108ad5:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80108adc:	00 
80108add:	89 04 24             	mov    %eax,(%esp)
80108ae0:	e8 37 fb ff ff       	call   8010861c <lgdt>
  loadgs(SEG_KCPU << 3);
80108ae5:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80108aec:	e8 6a fb ff ff       	call   8010865b <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80108af1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108af4:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80108afa:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80108b01:	00 00 00 00 
}
80108b05:	83 c4 24             	add    $0x24,%esp
80108b08:	5b                   	pop    %ebx
80108b09:	5d                   	pop    %ebp
80108b0a:	c3                   	ret    

80108b0b <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80108b0b:	55                   	push   %ebp
80108b0c:	89 e5                	mov    %esp,%ebp
80108b0e:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80108b11:	8b 45 0c             	mov    0xc(%ebp),%eax
80108b14:	c1 e8 16             	shr    $0x16,%eax
80108b17:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108b1e:	8b 45 08             	mov    0x8(%ebp),%eax
80108b21:	01 d0                	add    %edx,%eax
80108b23:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80108b26:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108b29:	8b 00                	mov    (%eax),%eax
80108b2b:	83 e0 01             	and    $0x1,%eax
80108b2e:	85 c0                	test   %eax,%eax
80108b30:	74 17                	je     80108b49 <walkpgdir+0x3e>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80108b32:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108b35:	8b 00                	mov    (%eax),%eax
80108b37:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108b3c:	89 04 24             	mov    %eax,(%esp)
80108b3f:	e8 44 fb ff ff       	call   80108688 <p2v>
80108b44:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108b47:	eb 4b                	jmp    80108b94 <walkpgdir+0x89>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80108b49:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80108b4d:	74 0e                	je     80108b5d <walkpgdir+0x52>
80108b4f:	e8 a9 a1 ff ff       	call   80102cfd <kalloc>
80108b54:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108b57:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108b5b:	75 07                	jne    80108b64 <walkpgdir+0x59>
      return 0;
80108b5d:	b8 00 00 00 00       	mov    $0x0,%eax
80108b62:	eb 47                	jmp    80108bab <walkpgdir+0xa0>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80108b64:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108b6b:	00 
80108b6c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108b73:	00 
80108b74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b77:	89 04 24             	mov    %eax,(%esp)
80108b7a:	e8 58 d5 ff ff       	call   801060d7 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80108b7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b82:	89 04 24             	mov    %eax,(%esp)
80108b85:	e8 f1 fa ff ff       	call   8010867b <v2p>
80108b8a:	83 c8 07             	or     $0x7,%eax
80108b8d:	89 c2                	mov    %eax,%edx
80108b8f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108b92:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80108b94:	8b 45 0c             	mov    0xc(%ebp),%eax
80108b97:	c1 e8 0c             	shr    $0xc,%eax
80108b9a:	25 ff 03 00 00       	and    $0x3ff,%eax
80108b9f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108ba6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ba9:	01 d0                	add    %edx,%eax
}
80108bab:	c9                   	leave  
80108bac:	c3                   	ret    

80108bad <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80108bad:	55                   	push   %ebp
80108bae:	89 e5                	mov    %esp,%ebp
80108bb0:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80108bb3:	8b 45 0c             	mov    0xc(%ebp),%eax
80108bb6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108bbb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80108bbe:	8b 55 0c             	mov    0xc(%ebp),%edx
80108bc1:	8b 45 10             	mov    0x10(%ebp),%eax
80108bc4:	01 d0                	add    %edx,%eax
80108bc6:	83 e8 01             	sub    $0x1,%eax
80108bc9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108bce:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80108bd1:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80108bd8:	00 
80108bd9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bdc:	89 44 24 04          	mov    %eax,0x4(%esp)
80108be0:	8b 45 08             	mov    0x8(%ebp),%eax
80108be3:	89 04 24             	mov    %eax,(%esp)
80108be6:	e8 20 ff ff ff       	call   80108b0b <walkpgdir>
80108beb:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108bee:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108bf2:	75 07                	jne    80108bfb <mappages+0x4e>
      return -1;
80108bf4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108bf9:	eb 48                	jmp    80108c43 <mappages+0x96>
    if(*pte & PTE_P)
80108bfb:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108bfe:	8b 00                	mov    (%eax),%eax
80108c00:	83 e0 01             	and    $0x1,%eax
80108c03:	85 c0                	test   %eax,%eax
80108c05:	74 0c                	je     80108c13 <mappages+0x66>
      panic("remap");
80108c07:	c7 04 24 dc 9a 10 80 	movl   $0x80109adc,(%esp)
80108c0e:	e8 27 79 ff ff       	call   8010053a <panic>
    *pte = pa | perm | PTE_P;
80108c13:	8b 45 18             	mov    0x18(%ebp),%eax
80108c16:	0b 45 14             	or     0x14(%ebp),%eax
80108c19:	83 c8 01             	or     $0x1,%eax
80108c1c:	89 c2                	mov    %eax,%edx
80108c1e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108c21:	89 10                	mov    %edx,(%eax)
    if(a == last)
80108c23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c26:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108c29:	75 08                	jne    80108c33 <mappages+0x86>
      break;
80108c2b:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80108c2c:	b8 00 00 00 00       	mov    $0x0,%eax
80108c31:	eb 10                	jmp    80108c43 <mappages+0x96>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
80108c33:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80108c3a:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80108c41:	eb 8e                	jmp    80108bd1 <mappages+0x24>
  return 0;
}
80108c43:	c9                   	leave  
80108c44:	c3                   	ret    

80108c45 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
80108c45:	55                   	push   %ebp
80108c46:	89 e5                	mov    %esp,%ebp
80108c48:	53                   	push   %ebx
80108c49:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80108c4c:	e8 ac a0 ff ff       	call   80102cfd <kalloc>
80108c51:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108c54:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108c58:	75 0a                	jne    80108c64 <setupkvm+0x1f>
    return 0;
80108c5a:	b8 00 00 00 00       	mov    $0x0,%eax
80108c5f:	e9 98 00 00 00       	jmp    80108cfc <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80108c64:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108c6b:	00 
80108c6c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108c73:	00 
80108c74:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108c77:	89 04 24             	mov    %eax,(%esp)
80108c7a:	e8 58 d4 ff ff       	call   801060d7 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80108c7f:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80108c86:	e8 fd f9 ff ff       	call   80108688 <p2v>
80108c8b:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80108c90:	76 0c                	jbe    80108c9e <setupkvm+0x59>
    panic("PHYSTOP too high");
80108c92:	c7 04 24 e2 9a 10 80 	movl   $0x80109ae2,(%esp)
80108c99:	e8 9c 78 ff ff       	call   8010053a <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108c9e:	c7 45 f4 a0 c4 10 80 	movl   $0x8010c4a0,-0xc(%ebp)
80108ca5:	eb 49                	jmp    80108cf0 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108ca7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108caa:	8b 48 0c             	mov    0xc(%eax),%ecx
80108cad:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cb0:	8b 50 04             	mov    0x4(%eax),%edx
80108cb3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cb6:	8b 58 08             	mov    0x8(%eax),%ebx
80108cb9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cbc:	8b 40 04             	mov    0x4(%eax),%eax
80108cbf:	29 c3                	sub    %eax,%ebx
80108cc1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cc4:	8b 00                	mov    (%eax),%eax
80108cc6:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80108cca:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108cce:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108cd2:	89 44 24 04          	mov    %eax,0x4(%esp)
80108cd6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108cd9:	89 04 24             	mov    %eax,(%esp)
80108cdc:	e8 cc fe ff ff       	call   80108bad <mappages>
80108ce1:	85 c0                	test   %eax,%eax
80108ce3:	79 07                	jns    80108cec <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80108ce5:	b8 00 00 00 00       	mov    $0x0,%eax
80108cea:	eb 10                	jmp    80108cfc <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108cec:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80108cf0:	81 7d f4 e0 c4 10 80 	cmpl   $0x8010c4e0,-0xc(%ebp)
80108cf7:	72 ae                	jb     80108ca7 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80108cf9:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80108cfc:	83 c4 34             	add    $0x34,%esp
80108cff:	5b                   	pop    %ebx
80108d00:	5d                   	pop    %ebp
80108d01:	c3                   	ret    

80108d02 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80108d02:	55                   	push   %ebp
80108d03:	89 e5                	mov    %esp,%ebp
80108d05:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80108d08:	e8 38 ff ff ff       	call   80108c45 <setupkvm>
80108d0d:	a3 78 75 12 80       	mov    %eax,0x80127578
  switchkvm();
80108d12:	e8 02 00 00 00       	call   80108d19 <switchkvm>
}
80108d17:	c9                   	leave  
80108d18:	c3                   	ret    

80108d19 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80108d19:	55                   	push   %ebp
80108d1a:	89 e5                	mov    %esp,%ebp
80108d1c:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80108d1f:	a1 78 75 12 80       	mov    0x80127578,%eax
80108d24:	89 04 24             	mov    %eax,(%esp)
80108d27:	e8 4f f9 ff ff       	call   8010867b <v2p>
80108d2c:	89 04 24             	mov    %eax,(%esp)
80108d2f:	e8 3c f9 ff ff       	call   80108670 <lcr3>
}
80108d34:	c9                   	leave  
80108d35:	c3                   	ret    

80108d36 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80108d36:	55                   	push   %ebp
80108d37:	89 e5                	mov    %esp,%ebp
80108d39:	53                   	push   %ebx
80108d3a:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80108d3d:	e8 95 d2 ff ff       	call   80105fd7 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80108d42:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108d48:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108d4f:	83 c2 08             	add    $0x8,%edx
80108d52:	89 d3                	mov    %edx,%ebx
80108d54:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108d5b:	83 c2 08             	add    $0x8,%edx
80108d5e:	c1 ea 10             	shr    $0x10,%edx
80108d61:	89 d1                	mov    %edx,%ecx
80108d63:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108d6a:	83 c2 08             	add    $0x8,%edx
80108d6d:	c1 ea 18             	shr    $0x18,%edx
80108d70:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80108d77:	67 00 
80108d79:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80108d80:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80108d86:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108d8d:	83 e1 f0             	and    $0xfffffff0,%ecx
80108d90:	83 c9 09             	or     $0x9,%ecx
80108d93:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108d99:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108da0:	83 c9 10             	or     $0x10,%ecx
80108da3:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108da9:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108db0:	83 e1 9f             	and    $0xffffff9f,%ecx
80108db3:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108db9:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108dc0:	83 c9 80             	or     $0xffffff80,%ecx
80108dc3:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108dc9:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108dd0:	83 e1 f0             	and    $0xfffffff0,%ecx
80108dd3:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108dd9:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108de0:	83 e1 ef             	and    $0xffffffef,%ecx
80108de3:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108de9:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108df0:	83 e1 df             	and    $0xffffffdf,%ecx
80108df3:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108df9:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108e00:	83 c9 40             	or     $0x40,%ecx
80108e03:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108e09:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108e10:	83 e1 7f             	and    $0x7f,%ecx
80108e13:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108e19:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80108e1f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108e25:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80108e2c:	83 e2 ef             	and    $0xffffffef,%edx
80108e2f:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80108e35:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108e3b:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80108e41:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108e47:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80108e4e:	8b 52 08             	mov    0x8(%edx),%edx
80108e51:	81 c2 00 10 00 00    	add    $0x1000,%edx
80108e57:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80108e5a:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80108e61:	e8 df f7 ff ff       	call   80108645 <ltr>
  if(p->pgdir == 0)
80108e66:	8b 45 08             	mov    0x8(%ebp),%eax
80108e69:	8b 40 04             	mov    0x4(%eax),%eax
80108e6c:	85 c0                	test   %eax,%eax
80108e6e:	75 0c                	jne    80108e7c <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80108e70:	c7 04 24 f3 9a 10 80 	movl   $0x80109af3,(%esp)
80108e77:	e8 be 76 ff ff       	call   8010053a <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80108e7c:	8b 45 08             	mov    0x8(%ebp),%eax
80108e7f:	8b 40 04             	mov    0x4(%eax),%eax
80108e82:	89 04 24             	mov    %eax,(%esp)
80108e85:	e8 f1 f7 ff ff       	call   8010867b <v2p>
80108e8a:	89 04 24             	mov    %eax,(%esp)
80108e8d:	e8 de f7 ff ff       	call   80108670 <lcr3>
  popcli();
80108e92:	e8 84 d1 ff ff       	call   8010601b <popcli>
}
80108e97:	83 c4 14             	add    $0x14,%esp
80108e9a:	5b                   	pop    %ebx
80108e9b:	5d                   	pop    %ebp
80108e9c:	c3                   	ret    

80108e9d <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80108e9d:	55                   	push   %ebp
80108e9e:	89 e5                	mov    %esp,%ebp
80108ea0:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80108ea3:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80108eaa:	76 0c                	jbe    80108eb8 <inituvm+0x1b>
    panic("inituvm: more than a page");
80108eac:	c7 04 24 07 9b 10 80 	movl   $0x80109b07,(%esp)
80108eb3:	e8 82 76 ff ff       	call   8010053a <panic>
  mem = kalloc();
80108eb8:	e8 40 9e ff ff       	call   80102cfd <kalloc>
80108ebd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80108ec0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108ec7:	00 
80108ec8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108ecf:	00 
80108ed0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ed3:	89 04 24             	mov    %eax,(%esp)
80108ed6:	e8 fc d1 ff ff       	call   801060d7 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108edb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ede:	89 04 24             	mov    %eax,(%esp)
80108ee1:	e8 95 f7 ff ff       	call   8010867b <v2p>
80108ee6:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108eed:	00 
80108eee:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108ef2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108ef9:	00 
80108efa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108f01:	00 
80108f02:	8b 45 08             	mov    0x8(%ebp),%eax
80108f05:	89 04 24             	mov    %eax,(%esp)
80108f08:	e8 a0 fc ff ff       	call   80108bad <mappages>
  memmove(mem, init, sz);
80108f0d:	8b 45 10             	mov    0x10(%ebp),%eax
80108f10:	89 44 24 08          	mov    %eax,0x8(%esp)
80108f14:	8b 45 0c             	mov    0xc(%ebp),%eax
80108f17:	89 44 24 04          	mov    %eax,0x4(%esp)
80108f1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f1e:	89 04 24             	mov    %eax,(%esp)
80108f21:	e8 80 d2 ff ff       	call   801061a6 <memmove>
}
80108f26:	c9                   	leave  
80108f27:	c3                   	ret    

80108f28 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80108f28:	55                   	push   %ebp
80108f29:	89 e5                	mov    %esp,%ebp
80108f2b:	53                   	push   %ebx
80108f2c:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80108f2f:	8b 45 0c             	mov    0xc(%ebp),%eax
80108f32:	25 ff 0f 00 00       	and    $0xfff,%eax
80108f37:	85 c0                	test   %eax,%eax
80108f39:	74 0c                	je     80108f47 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80108f3b:	c7 04 24 24 9b 10 80 	movl   $0x80109b24,(%esp)
80108f42:	e8 f3 75 ff ff       	call   8010053a <panic>
  for(i = 0; i < sz; i += PGSIZE){
80108f47:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108f4e:	e9 a9 00 00 00       	jmp    80108ffc <loaduvm+0xd4>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80108f53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f56:	8b 55 0c             	mov    0xc(%ebp),%edx
80108f59:	01 d0                	add    %edx,%eax
80108f5b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108f62:	00 
80108f63:	89 44 24 04          	mov    %eax,0x4(%esp)
80108f67:	8b 45 08             	mov    0x8(%ebp),%eax
80108f6a:	89 04 24             	mov    %eax,(%esp)
80108f6d:	e8 99 fb ff ff       	call   80108b0b <walkpgdir>
80108f72:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108f75:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108f79:	75 0c                	jne    80108f87 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80108f7b:	c7 04 24 47 9b 10 80 	movl   $0x80109b47,(%esp)
80108f82:	e8 b3 75 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80108f87:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108f8a:	8b 00                	mov    (%eax),%eax
80108f8c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108f91:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80108f94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f97:	8b 55 18             	mov    0x18(%ebp),%edx
80108f9a:	29 c2                	sub    %eax,%edx
80108f9c:	89 d0                	mov    %edx,%eax
80108f9e:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80108fa3:	77 0f                	ja     80108fb4 <loaduvm+0x8c>
      n = sz - i;
80108fa5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fa8:	8b 55 18             	mov    0x18(%ebp),%edx
80108fab:	29 c2                	sub    %eax,%edx
80108fad:	89 d0                	mov    %edx,%eax
80108faf:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108fb2:	eb 07                	jmp    80108fbb <loaduvm+0x93>
    else
      n = PGSIZE;
80108fb4:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80108fbb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fbe:	8b 55 14             	mov    0x14(%ebp),%edx
80108fc1:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80108fc4:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108fc7:	89 04 24             	mov    %eax,(%esp)
80108fca:	e8 b9 f6 ff ff       	call   80108688 <p2v>
80108fcf:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108fd2:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108fd6:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108fda:	89 44 24 04          	mov    %eax,0x4(%esp)
80108fde:	8b 45 10             	mov    0x10(%ebp),%eax
80108fe1:	89 04 24             	mov    %eax,(%esp)
80108fe4:	e8 7f 8e ff ff       	call   80101e68 <readi>
80108fe9:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108fec:	74 07                	je     80108ff5 <loaduvm+0xcd>
      return -1;
80108fee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108ff3:	eb 18                	jmp    8010900d <loaduvm+0xe5>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80108ff5:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108ffc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fff:	3b 45 18             	cmp    0x18(%ebp),%eax
80109002:	0f 82 4b ff ff ff    	jb     80108f53 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80109008:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010900d:	83 c4 24             	add    $0x24,%esp
80109010:	5b                   	pop    %ebx
80109011:	5d                   	pop    %ebp
80109012:	c3                   	ret    

80109013 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80109013:	55                   	push   %ebp
80109014:	89 e5                	mov    %esp,%ebp
80109016:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80109019:	8b 45 10             	mov    0x10(%ebp),%eax
8010901c:	85 c0                	test   %eax,%eax
8010901e:	79 0a                	jns    8010902a <allocuvm+0x17>
    return 0;
80109020:	b8 00 00 00 00       	mov    $0x0,%eax
80109025:	e9 c1 00 00 00       	jmp    801090eb <allocuvm+0xd8>
  if(newsz < oldsz)
8010902a:	8b 45 10             	mov    0x10(%ebp),%eax
8010902d:	3b 45 0c             	cmp    0xc(%ebp),%eax
80109030:	73 08                	jae    8010903a <allocuvm+0x27>
    return oldsz;
80109032:	8b 45 0c             	mov    0xc(%ebp),%eax
80109035:	e9 b1 00 00 00       	jmp    801090eb <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
8010903a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010903d:	05 ff 0f 00 00       	add    $0xfff,%eax
80109042:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109047:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
8010904a:	e9 8d 00 00 00       	jmp    801090dc <allocuvm+0xc9>
    mem = kalloc();
8010904f:	e8 a9 9c ff ff       	call   80102cfd <kalloc>
80109054:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80109057:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010905b:	75 2c                	jne    80109089 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
8010905d:	c7 04 24 65 9b 10 80 	movl   $0x80109b65,(%esp)
80109064:	e8 37 73 ff ff       	call   801003a0 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80109069:	8b 45 0c             	mov    0xc(%ebp),%eax
8010906c:	89 44 24 08          	mov    %eax,0x8(%esp)
80109070:	8b 45 10             	mov    0x10(%ebp),%eax
80109073:	89 44 24 04          	mov    %eax,0x4(%esp)
80109077:	8b 45 08             	mov    0x8(%ebp),%eax
8010907a:	89 04 24             	mov    %eax,(%esp)
8010907d:	e8 6b 00 00 00       	call   801090ed <deallocuvm>
      return 0;
80109082:	b8 00 00 00 00       	mov    $0x0,%eax
80109087:	eb 62                	jmp    801090eb <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80109089:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109090:	00 
80109091:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80109098:	00 
80109099:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010909c:	89 04 24             	mov    %eax,(%esp)
8010909f:	e8 33 d0 ff ff       	call   801060d7 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
801090a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801090a7:	89 04 24             	mov    %eax,(%esp)
801090aa:	e8 cc f5 ff ff       	call   8010867b <v2p>
801090af:	8b 55 f4             	mov    -0xc(%ebp),%edx
801090b2:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801090b9:	00 
801090ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
801090be:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801090c5:	00 
801090c6:	89 54 24 04          	mov    %edx,0x4(%esp)
801090ca:	8b 45 08             	mov    0x8(%ebp),%eax
801090cd:	89 04 24             	mov    %eax,(%esp)
801090d0:	e8 d8 fa ff ff       	call   80108bad <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
801090d5:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801090dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801090df:	3b 45 10             	cmp    0x10(%ebp),%eax
801090e2:	0f 82 67 ff ff ff    	jb     8010904f <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
801090e8:	8b 45 10             	mov    0x10(%ebp),%eax
}
801090eb:	c9                   	leave  
801090ec:	c3                   	ret    

801090ed <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801090ed:	55                   	push   %ebp
801090ee:	89 e5                	mov    %esp,%ebp
801090f0:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801090f3:	8b 45 10             	mov    0x10(%ebp),%eax
801090f6:	3b 45 0c             	cmp    0xc(%ebp),%eax
801090f9:	72 08                	jb     80109103 <deallocuvm+0x16>
    return oldsz;
801090fb:	8b 45 0c             	mov    0xc(%ebp),%eax
801090fe:	e9 a4 00 00 00       	jmp    801091a7 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80109103:	8b 45 10             	mov    0x10(%ebp),%eax
80109106:	05 ff 0f 00 00       	add    $0xfff,%eax
8010910b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109110:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80109113:	e9 80 00 00 00       	jmp    80109198 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80109118:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010911b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109122:	00 
80109123:	89 44 24 04          	mov    %eax,0x4(%esp)
80109127:	8b 45 08             	mov    0x8(%ebp),%eax
8010912a:	89 04 24             	mov    %eax,(%esp)
8010912d:	e8 d9 f9 ff ff       	call   80108b0b <walkpgdir>
80109132:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80109135:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109139:	75 09                	jne    80109144 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
8010913b:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80109142:	eb 4d                	jmp    80109191 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80109144:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109147:	8b 00                	mov    (%eax),%eax
80109149:	83 e0 01             	and    $0x1,%eax
8010914c:	85 c0                	test   %eax,%eax
8010914e:	74 41                	je     80109191 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80109150:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109153:	8b 00                	mov    (%eax),%eax
80109155:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010915a:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
8010915d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80109161:	75 0c                	jne    8010916f <deallocuvm+0x82>
        panic("kfree");
80109163:	c7 04 24 7d 9b 10 80 	movl   $0x80109b7d,(%esp)
8010916a:	e8 cb 73 ff ff       	call   8010053a <panic>
      char *v = p2v(pa);
8010916f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109172:	89 04 24             	mov    %eax,(%esp)
80109175:	e8 0e f5 ff ff       	call   80108688 <p2v>
8010917a:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
8010917d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109180:	89 04 24             	mov    %eax,(%esp)
80109183:	e8 dc 9a ff ff       	call   80102c64 <kfree>
      *pte = 0;
80109188:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010918b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80109191:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80109198:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010919b:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010919e:	0f 82 74 ff ff ff    	jb     80109118 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
801091a4:	8b 45 10             	mov    0x10(%ebp),%eax
}
801091a7:	c9                   	leave  
801091a8:	c3                   	ret    

801091a9 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
801091a9:	55                   	push   %ebp
801091aa:	89 e5                	mov    %esp,%ebp
801091ac:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
801091af:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801091b3:	75 0c                	jne    801091c1 <freevm+0x18>
    panic("freevm: no pgdir");
801091b5:	c7 04 24 83 9b 10 80 	movl   $0x80109b83,(%esp)
801091bc:	e8 79 73 ff ff       	call   8010053a <panic>
  deallocuvm(pgdir, KERNBASE, 0);
801091c1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801091c8:	00 
801091c9:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
801091d0:	80 
801091d1:	8b 45 08             	mov    0x8(%ebp),%eax
801091d4:	89 04 24             	mov    %eax,(%esp)
801091d7:	e8 11 ff ff ff       	call   801090ed <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
801091dc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801091e3:	eb 48                	jmp    8010922d <freevm+0x84>
    if(pgdir[i] & PTE_P){
801091e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091e8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801091ef:	8b 45 08             	mov    0x8(%ebp),%eax
801091f2:	01 d0                	add    %edx,%eax
801091f4:	8b 00                	mov    (%eax),%eax
801091f6:	83 e0 01             	and    $0x1,%eax
801091f9:	85 c0                	test   %eax,%eax
801091fb:	74 2c                	je     80109229 <freevm+0x80>
      char * v = p2v(PTE_ADDR(pgdir[i]));
801091fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109200:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80109207:	8b 45 08             	mov    0x8(%ebp),%eax
8010920a:	01 d0                	add    %edx,%eax
8010920c:	8b 00                	mov    (%eax),%eax
8010920e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109213:	89 04 24             	mov    %eax,(%esp)
80109216:	e8 6d f4 ff ff       	call   80108688 <p2v>
8010921b:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
8010921e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109221:	89 04 24             	mov    %eax,(%esp)
80109224:	e8 3b 9a ff ff       	call   80102c64 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80109229:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010922d:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80109234:	76 af                	jbe    801091e5 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80109236:	8b 45 08             	mov    0x8(%ebp),%eax
80109239:	89 04 24             	mov    %eax,(%esp)
8010923c:	e8 23 9a ff ff       	call   80102c64 <kfree>
}
80109241:	c9                   	leave  
80109242:	c3                   	ret    

80109243 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80109243:	55                   	push   %ebp
80109244:	89 e5                	mov    %esp,%ebp
80109246:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80109249:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109250:	00 
80109251:	8b 45 0c             	mov    0xc(%ebp),%eax
80109254:	89 44 24 04          	mov    %eax,0x4(%esp)
80109258:	8b 45 08             	mov    0x8(%ebp),%eax
8010925b:	89 04 24             	mov    %eax,(%esp)
8010925e:	e8 a8 f8 ff ff       	call   80108b0b <walkpgdir>
80109263:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80109266:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010926a:	75 0c                	jne    80109278 <clearpteu+0x35>
    panic("clearpteu");
8010926c:	c7 04 24 94 9b 10 80 	movl   $0x80109b94,(%esp)
80109273:	e8 c2 72 ff ff       	call   8010053a <panic>
  *pte &= ~PTE_U;
80109278:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010927b:	8b 00                	mov    (%eax),%eax
8010927d:	83 e0 fb             	and    $0xfffffffb,%eax
80109280:	89 c2                	mov    %eax,%edx
80109282:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109285:	89 10                	mov    %edx,(%eax)
}
80109287:	c9                   	leave  
80109288:	c3                   	ret    

80109289 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80109289:	55                   	push   %ebp
8010928a:	89 e5                	mov    %esp,%ebp
8010928c:	53                   	push   %ebx
8010928d:	83 ec 44             	sub    $0x44,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80109290:	e8 b0 f9 ff ff       	call   80108c45 <setupkvm>
80109295:	89 45 f0             	mov    %eax,-0x10(%ebp)
80109298:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010929c:	75 0a                	jne    801092a8 <copyuvm+0x1f>
    return 0;
8010929e:	b8 00 00 00 00       	mov    $0x0,%eax
801092a3:	e9 fd 00 00 00       	jmp    801093a5 <copyuvm+0x11c>
  for(i = 0; i < sz; i += PGSIZE){
801092a8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801092af:	e9 d0 00 00 00       	jmp    80109384 <copyuvm+0xfb>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801092b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801092b7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801092be:	00 
801092bf:	89 44 24 04          	mov    %eax,0x4(%esp)
801092c3:	8b 45 08             	mov    0x8(%ebp),%eax
801092c6:	89 04 24             	mov    %eax,(%esp)
801092c9:	e8 3d f8 ff ff       	call   80108b0b <walkpgdir>
801092ce:	89 45 ec             	mov    %eax,-0x14(%ebp)
801092d1:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801092d5:	75 0c                	jne    801092e3 <copyuvm+0x5a>
      panic("copyuvm: pte should exist");
801092d7:	c7 04 24 9e 9b 10 80 	movl   $0x80109b9e,(%esp)
801092de:	e8 57 72 ff ff       	call   8010053a <panic>
    if(!(*pte & PTE_P))
801092e3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801092e6:	8b 00                	mov    (%eax),%eax
801092e8:	83 e0 01             	and    $0x1,%eax
801092eb:	85 c0                	test   %eax,%eax
801092ed:	75 0c                	jne    801092fb <copyuvm+0x72>
      panic("copyuvm: page not present");
801092ef:	c7 04 24 b8 9b 10 80 	movl   $0x80109bb8,(%esp)
801092f6:	e8 3f 72 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
801092fb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801092fe:	8b 00                	mov    (%eax),%eax
80109300:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109305:	89 45 e8             	mov    %eax,-0x18(%ebp)
    flags = PTE_FLAGS(*pte);
80109308:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010930b:	8b 00                	mov    (%eax),%eax
8010930d:	25 ff 0f 00 00       	and    $0xfff,%eax
80109312:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if((mem = kalloc()) == 0)
80109315:	e8 e3 99 ff ff       	call   80102cfd <kalloc>
8010931a:	89 45 e0             	mov    %eax,-0x20(%ebp)
8010931d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80109321:	75 02                	jne    80109325 <copyuvm+0x9c>
      goto bad;
80109323:	eb 70                	jmp    80109395 <copyuvm+0x10c>
    memmove(mem, (char*)p2v(pa), PGSIZE);
80109325:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109328:	89 04 24             	mov    %eax,(%esp)
8010932b:	e8 58 f3 ff ff       	call   80108688 <p2v>
80109330:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109337:	00 
80109338:	89 44 24 04          	mov    %eax,0x4(%esp)
8010933c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010933f:	89 04 24             	mov    %eax,(%esp)
80109342:	e8 5f ce ff ff       	call   801061a6 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
80109347:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
8010934a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010934d:	89 04 24             	mov    %eax,(%esp)
80109350:	e8 26 f3 ff ff       	call   8010867b <v2p>
80109355:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109358:	89 5c 24 10          	mov    %ebx,0x10(%esp)
8010935c:	89 44 24 0c          	mov    %eax,0xc(%esp)
80109360:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109367:	00 
80109368:	89 54 24 04          	mov    %edx,0x4(%esp)
8010936c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010936f:	89 04 24             	mov    %eax,(%esp)
80109372:	e8 36 f8 ff ff       	call   80108bad <mappages>
80109377:	85 c0                	test   %eax,%eax
80109379:	79 02                	jns    8010937d <copyuvm+0xf4>
      goto bad;
8010937b:	eb 18                	jmp    80109395 <copyuvm+0x10c>
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
8010937d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80109384:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109387:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010938a:	0f 82 24 ff ff ff    	jb     801092b4 <copyuvm+0x2b>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
      goto bad;
  }
  return d;
80109390:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109393:	eb 10                	jmp    801093a5 <copyuvm+0x11c>

bad:
  freevm(d);
80109395:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109398:	89 04 24             	mov    %eax,(%esp)
8010939b:	e8 09 fe ff ff       	call   801091a9 <freevm>
  return 0;
801093a0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801093a5:	83 c4 44             	add    $0x44,%esp
801093a8:	5b                   	pop    %ebx
801093a9:	5d                   	pop    %ebp
801093aa:	c3                   	ret    

801093ab <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801093ab:	55                   	push   %ebp
801093ac:	89 e5                	mov    %esp,%ebp
801093ae:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801093b1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801093b8:	00 
801093b9:	8b 45 0c             	mov    0xc(%ebp),%eax
801093bc:	89 44 24 04          	mov    %eax,0x4(%esp)
801093c0:	8b 45 08             	mov    0x8(%ebp),%eax
801093c3:	89 04 24             	mov    %eax,(%esp)
801093c6:	e8 40 f7 ff ff       	call   80108b0b <walkpgdir>
801093cb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801093ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801093d1:	8b 00                	mov    (%eax),%eax
801093d3:	83 e0 01             	and    $0x1,%eax
801093d6:	85 c0                	test   %eax,%eax
801093d8:	75 07                	jne    801093e1 <uva2ka+0x36>
    return 0;
801093da:	b8 00 00 00 00       	mov    $0x0,%eax
801093df:	eb 25                	jmp    80109406 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
801093e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801093e4:	8b 00                	mov    (%eax),%eax
801093e6:	83 e0 04             	and    $0x4,%eax
801093e9:	85 c0                	test   %eax,%eax
801093eb:	75 07                	jne    801093f4 <uva2ka+0x49>
    return 0;
801093ed:	b8 00 00 00 00       	mov    $0x0,%eax
801093f2:	eb 12                	jmp    80109406 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
801093f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801093f7:	8b 00                	mov    (%eax),%eax
801093f9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801093fe:	89 04 24             	mov    %eax,(%esp)
80109401:	e8 82 f2 ff ff       	call   80108688 <p2v>
}
80109406:	c9                   	leave  
80109407:	c3                   	ret    

80109408 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80109408:	55                   	push   %ebp
80109409:	89 e5                	mov    %esp,%ebp
8010940b:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
8010940e:	8b 45 10             	mov    0x10(%ebp),%eax
80109411:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80109414:	e9 87 00 00 00       	jmp    801094a0 <copyout+0x98>
    va0 = (uint)PGROUNDDOWN(va);
80109419:	8b 45 0c             	mov    0xc(%ebp),%eax
8010941c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109421:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80109424:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109427:	89 44 24 04          	mov    %eax,0x4(%esp)
8010942b:	8b 45 08             	mov    0x8(%ebp),%eax
8010942e:	89 04 24             	mov    %eax,(%esp)
80109431:	e8 75 ff ff ff       	call   801093ab <uva2ka>
80109436:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80109439:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010943d:	75 07                	jne    80109446 <copyout+0x3e>
      return -1;
8010943f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80109444:	eb 69                	jmp    801094af <copyout+0xa7>
    n = PGSIZE - (va - va0);
80109446:	8b 45 0c             	mov    0xc(%ebp),%eax
80109449:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010944c:	29 c2                	sub    %eax,%edx
8010944e:	89 d0                	mov    %edx,%eax
80109450:	05 00 10 00 00       	add    $0x1000,%eax
80109455:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80109458:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010945b:	3b 45 14             	cmp    0x14(%ebp),%eax
8010945e:	76 06                	jbe    80109466 <copyout+0x5e>
      n = len;
80109460:	8b 45 14             	mov    0x14(%ebp),%eax
80109463:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80109466:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109469:	8b 55 0c             	mov    0xc(%ebp),%edx
8010946c:	29 c2                	sub    %eax,%edx
8010946e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109471:	01 c2                	add    %eax,%edx
80109473:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109476:	89 44 24 08          	mov    %eax,0x8(%esp)
8010947a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010947d:	89 44 24 04          	mov    %eax,0x4(%esp)
80109481:	89 14 24             	mov    %edx,(%esp)
80109484:	e8 1d cd ff ff       	call   801061a6 <memmove>
    len -= n;
80109489:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010948c:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
8010948f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109492:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
80109495:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109498:	05 00 10 00 00       	add    $0x1000,%eax
8010949d:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801094a0:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801094a4:	0f 85 6f ff ff ff    	jne    80109419 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
801094aa:	b8 00 00 00 00       	mov    $0x0,%eax
}
801094af:	c9                   	leave  
801094b0:	c3                   	ret    
