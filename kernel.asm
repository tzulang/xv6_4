
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
8010002d:	b8 61 38 10 80       	mov    $0x80103861,%eax
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
8010003a:	c7 44 24 04 74 8d 10 	movl   $0x80108d74,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
80100049:	e8 d6 56 00 00       	call   80105724 <initlock>

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
801000bd:	e8 83 56 00 00       	call   80105745 <acquire>

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
80100104:	e8 9e 56 00 00       	call   801057a7 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 d6 10 	movl   $0x8010d660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 a0 4b 00 00       	call   80104cc4 <sleep>
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
8010017c:	e8 26 56 00 00       	call   801057a7 <release>
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
80100198:	c7 04 24 7b 8d 10 80 	movl   $0x80108d7b,(%esp)
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
801001d3:	e8 13 27 00 00       	call   801028eb <iderw>
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
801001ef:	c7 04 24 8c 8d 10 80 	movl   $0x80108d8c,(%esp)
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
80100210:	e8 d6 26 00 00       	call   801028eb <iderw>
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
80100229:	c7 04 24 93 8d 10 80 	movl   $0x80108d93,(%esp)
80100230:	e8 05 03 00 00       	call   8010053a <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
8010023c:	e8 04 55 00 00       	call   80105745 <acquire>

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
8010029d:	e8 fe 4a 00 00       	call   80104da0 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
801002a9:	e8 f9 54 00 00       	call   801057a7 <release>
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
801003bb:	e8 85 53 00 00       	call   80105745 <acquire>

  if (fmt == 0)
801003c0:	8b 45 08             	mov    0x8(%ebp),%eax
801003c3:	85 c0                	test   %eax,%eax
801003c5:	75 0c                	jne    801003d3 <cprintf+0x33>
    panic("null fmt");
801003c7:	c7 04 24 9a 8d 10 80 	movl   $0x80108d9a,(%esp)
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
801004b0:	c7 45 ec a3 8d 10 80 	movl   $0x80108da3,-0x14(%ebp)
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
80100533:	e8 6f 52 00 00       	call   801057a7 <release>
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
8010055f:	c7 04 24 aa 8d 10 80 	movl   $0x80108daa,(%esp)
80100566:	e8 35 fe ff ff       	call   801003a0 <cprintf>
  cprintf(s);
8010056b:	8b 45 08             	mov    0x8(%ebp),%eax
8010056e:	89 04 24             	mov    %eax,(%esp)
80100571:	e8 2a fe ff ff       	call   801003a0 <cprintf>
  cprintf("\n");
80100576:	c7 04 24 b9 8d 10 80 	movl   $0x80108db9,(%esp)
8010057d:	e8 1e fe ff ff       	call   801003a0 <cprintf>
  getcallerpcs(&s, pcs);
80100582:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100585:	89 44 24 04          	mov    %eax,0x4(%esp)
80100589:	8d 45 08             	lea    0x8(%ebp),%eax
8010058c:	89 04 24             	mov    %eax,(%esp)
8010058f:	e8 62 52 00 00       	call   801057f6 <getcallerpcs>
  for(i=0; i<10; i++)
80100594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059b:	eb 1b                	jmp    801005b8 <panic+0x7e>
    cprintf(" %p", pcs[i]);
8010059d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a0:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801005a8:	c7 04 24 bb 8d 10 80 	movl   $0x80108dbb,(%esp)
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
801006b2:	e8 b1 53 00 00       	call   80105a68 <memmove>
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
801006e1:	e8 b3 52 00 00       	call   80105999 <memset>
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
80100776:	e8 3b 6c 00 00       	call   801073b6 <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 2f 6c 00 00       	call   801073b6 <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 23 6c 00 00       	call   801073b6 <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 16 6c 00 00       	call   801073b6 <uartputc>
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
801007ba:	e8 86 4f 00 00       	call   80105745 <acquire>
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
801007ea:	e8 57 46 00 00       	call   80104e46 <procdump>
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
801008f3:	e8 a8 44 00 00       	call   80104da0 <wakeup>
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
80100914:	e8 8e 4e 00 00       	call   801057a7 <release>
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
80100927:	e8 ac 10 00 00       	call   801019d8 <iunlock>
  target = n;
8010092c:	8b 45 14             	mov    0x14(%ebp),%eax
8010092f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
80100932:	c7 04 24 80 17 11 80 	movl   $0x80111780,(%esp)
80100939:	e8 07 4e 00 00       	call   80105745 <acquire>
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
80100959:	e8 49 4e 00 00       	call   801057a7 <release>
        ilock(ip);
8010095e:	8b 45 08             	mov    0x8(%ebp),%eax
80100961:	89 04 24             	mov    %eax,(%esp)
80100964:	e8 21 0f 00 00       	call   8010188a <ilock>
        return -1;
80100969:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010096e:	e9 a5 00 00 00       	jmp    80100a18 <consoleread+0xfd>
      }
      sleep(&input.r, &input.lock);
80100973:	c7 44 24 04 80 17 11 	movl   $0x80111780,0x4(%esp)
8010097a:	80 
8010097b:	c7 04 24 34 18 11 80 	movl   $0x80111834,(%esp)
80100982:	e8 3d 43 00 00       	call   80104cc4 <sleep>

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
801009fe:	e8 a4 4d 00 00       	call   801057a7 <release>
  ilock(ip);
80100a03:	8b 45 08             	mov    0x8(%ebp),%eax
80100a06:	89 04 24             	mov    %eax,(%esp)
80100a09:	e8 7c 0e 00 00       	call   8010188a <ilock>

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
80100a26:	e8 ad 0f 00 00       	call   801019d8 <iunlock>
  acquire(&cons.lock);
80100a2b:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
80100a32:	e8 0e 4d 00 00       	call   80105745 <acquire>
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
80100a6c:	e8 36 4d 00 00       	call   801057a7 <release>
  ilock(ip);
80100a71:	8b 45 08             	mov    0x8(%ebp),%eax
80100a74:	89 04 24             	mov    %eax,(%esp)
80100a77:	e8 0e 0e 00 00       	call   8010188a <ilock>

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
80100a87:	c7 44 24 04 bf 8d 10 	movl   $0x80108dbf,0x4(%esp)
80100a8e:	80 
80100a8f:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
80100a96:	e8 89 4c 00 00       	call   80105724 <initlock>
  initlock(&input.lock, "input");
80100a9b:	c7 44 24 04 c7 8d 10 	movl   $0x80108dc7,0x4(%esp)
80100aa2:	80 
80100aa3:	c7 04 24 80 17 11 80 	movl   $0x80111780,(%esp)
80100aaa:	e8 75 4c 00 00       	call   80105724 <initlock>

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
80100ad4:	e8 2a 34 00 00       	call   80103f03 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ad9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100ae0:	00 
80100ae1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ae8:	e8 ba 1f 00 00       	call   80102aa7 <ioapicenable>
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
80100af8:	e8 5d 2a 00 00       	call   8010355a <begin_op>
  if((ip = namei(path)) == 0){
80100afd:	8b 45 08             	mov    0x8(%ebp),%eax
80100b00:	89 04 24             	mov    %eax,(%esp)
80100b03:	e8 48 1a 00 00       	call   80102550 <namei>
80100b08:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b0b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b0f:	75 0f                	jne    80100b20 <exec+0x31>
    end_op();
80100b11:	e8 c8 2a 00 00       	call   801035de <end_op>
    return -1;
80100b16:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b1b:	e9 17 04 00 00       	jmp    80100f37 <exec+0x448>
  }
  ilock(ip);
80100b20:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b23:	89 04 24             	mov    %eax,(%esp)
80100b26:	e8 5f 0d 00 00       	call   8010188a <ilock>
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
80100b52:	e8 40 12 00 00       	call   80101d97 <readi>
80100b57:	83 f8 33             	cmp    $0x33,%eax
80100b5a:	77 05                	ja     80100b61 <exec+0x72>
    goto bad;
80100b5c:	e9 aa 03 00 00       	jmp    80100f0b <exec+0x41c>
  if(elf.magic != ELF_MAGIC)
80100b61:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100b67:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b6c:	74 05                	je     80100b73 <exec+0x84>
    goto bad;
80100b6e:	e9 98 03 00 00       	jmp    80100f0b <exec+0x41c>

  if((pgdir = setupkvm()) == 0)
80100b73:	e8 8f 79 00 00       	call   80108507 <setupkvm>
80100b78:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100b7b:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100b7f:	75 05                	jne    80100b86 <exec+0x97>
    goto bad;
80100b81:	e9 85 03 00 00       	jmp    80100f0b <exec+0x41c>

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
80100bc1:	e8 d1 11 00 00       	call   80101d97 <readi>
80100bc6:	83 f8 20             	cmp    $0x20,%eax
80100bc9:	74 05                	je     80100bd0 <exec+0xe1>
      goto bad;
80100bcb:	e9 3b 03 00 00       	jmp    80100f0b <exec+0x41c>
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
80100bf0:	e9 16 03 00 00       	jmp    80100f0b <exec+0x41c>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100bf5:	8b 95 f4 fe ff ff    	mov    -0x10c(%ebp),%edx
80100bfb:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
80100c01:	01 d0                	add    %edx,%eax
80100c03:	89 44 24 08          	mov    %eax,0x8(%esp)
80100c07:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c0a:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c0e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c11:	89 04 24             	mov    %eax,(%esp)
80100c14:	e8 bc 7c 00 00       	call   801088d5 <allocuvm>
80100c19:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100c1c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100c20:	75 05                	jne    80100c27 <exec+0x138>
      goto bad;
80100c22:	e9 e4 02 00 00       	jmp    80100f0b <exec+0x41c>
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
80100c52:	e8 93 7b 00 00       	call   801087ea <loaduvm>
80100c57:	85 c0                	test   %eax,%eax
80100c59:	79 05                	jns    80100c60 <exec+0x171>
      goto bad;
80100c5b:	e9 ab 02 00 00       	jmp    80100f0b <exec+0x41c>
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
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }

  proc->exe= ip;
80100c80:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100c86:	8b 55 d8             	mov    -0x28(%ebp),%edx
80100c89:	89 50 7c             	mov    %edx,0x7c(%eax)

  iunlockput(ip);
80100c8c:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100c8f:	89 04 24             	mov    %eax,(%esp)
80100c92:	e8 77 0e 00 00       	call   80101b0e <iunlockput>
  end_op();
80100c97:	e8 42 29 00 00       	call   801035de <end_op>
  ip = 0;
80100c9c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100ca3:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100ca6:	05 ff 0f 00 00       	add    $0xfff,%eax
80100cab:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100cb0:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100cb3:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cb6:	05 00 20 00 00       	add    $0x2000,%eax
80100cbb:	89 44 24 08          	mov    %eax,0x8(%esp)
80100cbf:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cc2:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cc6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cc9:	89 04 24             	mov    %eax,(%esp)
80100ccc:	e8 04 7c 00 00       	call   801088d5 <allocuvm>
80100cd1:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100cd4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100cd8:	75 05                	jne    80100cdf <exec+0x1f0>
    goto bad;
80100cda:	e9 2c 02 00 00       	jmp    80100f0b <exec+0x41c>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100cdf:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100ce2:	2d 00 20 00 00       	sub    $0x2000,%eax
80100ce7:	89 44 24 04          	mov    %eax,0x4(%esp)
80100ceb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cee:	89 04 24             	mov    %eax,(%esp)
80100cf1:	e8 0f 7e 00 00       	call   80108b05 <clearpteu>
  sp = sz;
80100cf6:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cf9:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100cfc:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100d03:	e9 9a 00 00 00       	jmp    80100da2 <exec+0x2b3>
    if(argc >= MAXARG)
80100d08:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100d0c:	76 05                	jbe    80100d13 <exec+0x224>
      goto bad;
80100d0e:	e9 f8 01 00 00       	jmp    80100f0b <exec+0x41c>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100d13:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d16:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100d1d:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d20:	01 d0                	add    %edx,%eax
80100d22:	8b 00                	mov    (%eax),%eax
80100d24:	89 04 24             	mov    %eax,(%esp)
80100d27:	e8 d7 4e 00 00       	call   80105c03 <strlen>
80100d2c:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100d2f:	29 c2                	sub    %eax,%edx
80100d31:	89 d0                	mov    %edx,%eax
80100d33:	83 e8 01             	sub    $0x1,%eax
80100d36:	83 e0 fc             	and    $0xfffffffc,%eax
80100d39:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100d3c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d3f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100d46:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d49:	01 d0                	add    %edx,%eax
80100d4b:	8b 00                	mov    (%eax),%eax
80100d4d:	89 04 24             	mov    %eax,(%esp)
80100d50:	e8 ae 4e 00 00       	call   80105c03 <strlen>
80100d55:	83 c0 01             	add    $0x1,%eax
80100d58:	89 c2                	mov    %eax,%edx
80100d5a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d5d:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
80100d64:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d67:	01 c8                	add    %ecx,%eax
80100d69:	8b 00                	mov    (%eax),%eax
80100d6b:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100d6f:	89 44 24 08          	mov    %eax,0x8(%esp)
80100d73:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d76:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d7a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d7d:	89 04 24             	mov    %eax,(%esp)
80100d80:	e8 45 7f 00 00       	call   80108cca <copyout>
80100d85:	85 c0                	test   %eax,%eax
80100d87:	79 05                	jns    80100d8e <exec+0x29f>
      goto bad;
80100d89:	e9 7d 01 00 00       	jmp    80100f0b <exec+0x41c>
    ustack[3+argc] = sp;
80100d8e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d91:	8d 50 03             	lea    0x3(%eax),%edx
80100d94:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d97:	89 84 95 40 ff ff ff 	mov    %eax,-0xc0(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100d9e:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100da2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100da5:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100dac:	8b 45 0c             	mov    0xc(%ebp),%eax
80100daf:	01 d0                	add    %edx,%eax
80100db1:	8b 00                	mov    (%eax),%eax
80100db3:	85 c0                	test   %eax,%eax
80100db5:	0f 85 4d ff ff ff    	jne    80100d08 <exec+0x219>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80100dbb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dbe:	83 c0 03             	add    $0x3,%eax
80100dc1:	c7 84 85 40 ff ff ff 	movl   $0x0,-0xc0(%ebp,%eax,4)
80100dc8:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100dcc:	c7 85 40 ff ff ff ff 	movl   $0xffffffff,-0xc0(%ebp)
80100dd3:	ff ff ff 
  ustack[1] = argc;
80100dd6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dd9:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100ddf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100de2:	83 c0 01             	add    $0x1,%eax
80100de5:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100dec:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100def:	29 d0                	sub    %edx,%eax
80100df1:	89 85 48 ff ff ff    	mov    %eax,-0xb8(%ebp)

  sp -= (3+argc+1) * 4;
80100df7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dfa:	83 c0 04             	add    $0x4,%eax
80100dfd:	c1 e0 02             	shl    $0x2,%eax
80100e00:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100e03:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e06:	83 c0 04             	add    $0x4,%eax
80100e09:	c1 e0 02             	shl    $0x2,%eax
80100e0c:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100e10:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
80100e16:	89 44 24 08          	mov    %eax,0x8(%esp)
80100e1a:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e1d:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e21:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e24:	89 04 24             	mov    %eax,(%esp)
80100e27:	e8 9e 7e 00 00       	call   80108cca <copyout>
80100e2c:	85 c0                	test   %eax,%eax
80100e2e:	79 05                	jns    80100e35 <exec+0x346>
    goto bad;
80100e30:	e9 d6 00 00 00       	jmp    80100f0b <exec+0x41c>

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e35:	8b 45 08             	mov    0x8(%ebp),%eax
80100e38:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100e3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e3e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100e41:	eb 17                	jmp    80100e5a <exec+0x36b>
    if(*s == '/')
80100e43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e46:	0f b6 00             	movzbl (%eax),%eax
80100e49:	3c 2f                	cmp    $0x2f,%al
80100e4b:	75 09                	jne    80100e56 <exec+0x367>
      last = s+1;
80100e4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e50:	83 c0 01             	add    $0x1,%eax
80100e53:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e56:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100e5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e5d:	0f b6 00             	movzbl (%eax),%eax
80100e60:	84 c0                	test   %al,%al
80100e62:	75 df                	jne    80100e43 <exec+0x354>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80100e64:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e6a:	8d 50 28             	lea    0x28(%eax),%edx
80100e6d:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100e74:	00 
80100e75:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100e78:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e7c:	89 14 24             	mov    %edx,(%esp)
80100e7f:	e8 35 4d 00 00       	call   80105bb9 <safestrcpy>
  safestrcpy(proc->cmdline, path, sizeof(path));
80100e84:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e8a:	8d 90 80 00 00 00    	lea    0x80(%eax),%edx
80100e90:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80100e97:	00 
80100e98:	8b 45 08             	mov    0x8(%ebp),%eax
80100e9b:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e9f:	89 14 24             	mov    %edx,(%esp)
80100ea2:	e8 12 4d 00 00       	call   80105bb9 <safestrcpy>
  // Commit to the user image.
  oldpgdir = proc->pgdir;
80100ea7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ead:	8b 40 04             	mov    0x4(%eax),%eax
80100eb0:	89 45 d0             	mov    %eax,-0x30(%ebp)
  proc->pgdir = pgdir;
80100eb3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100eb9:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100ebc:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80100ebf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ec5:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100ec8:	89 10                	mov    %edx,(%eax)
  proc->tf->eip = elf.entry;  // main
80100eca:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ed0:	8b 40 18             	mov    0x18(%eax),%eax
80100ed3:	8b 95 24 ff ff ff    	mov    -0xdc(%ebp),%edx
80100ed9:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
80100edc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ee2:	8b 40 18             	mov    0x18(%eax),%eax
80100ee5:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100ee8:	89 50 44             	mov    %edx,0x44(%eax)
  
  switchuvm(proc);
80100eeb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ef1:	89 04 24             	mov    %eax,(%esp)
80100ef4:	e8 ff 76 00 00       	call   801085f8 <switchuvm>
  freevm(oldpgdir);
80100ef9:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100efc:	89 04 24             	mov    %eax,(%esp)
80100eff:	e8 67 7b 00 00       	call   80108a6b <freevm>
  return 0;
80100f04:	b8 00 00 00 00       	mov    $0x0,%eax
80100f09:	eb 2c                	jmp    80100f37 <exec+0x448>

 bad:
  if(pgdir)
80100f0b:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100f0f:	74 0b                	je     80100f1c <exec+0x42d>
    freevm(pgdir);
80100f11:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100f14:	89 04 24             	mov    %eax,(%esp)
80100f17:	e8 4f 7b 00 00       	call   80108a6b <freevm>
  if(ip){
80100f1c:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100f20:	74 10                	je     80100f32 <exec+0x443>
    iunlockput(ip);
80100f22:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100f25:	89 04 24             	mov    %eax,(%esp)
80100f28:	e8 e1 0b 00 00       	call   80101b0e <iunlockput>
    end_op();
80100f2d:	e8 ac 26 00 00       	call   801035de <end_op>
  }
  return -1;
80100f32:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100f37:	c9                   	leave  
80100f38:	c3                   	ret    

80100f39 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100f39:	55                   	push   %ebp
80100f3a:	89 e5                	mov    %esp,%ebp
80100f3c:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
80100f3f:	c7 44 24 04 cd 8d 10 	movl   $0x80108dcd,0x4(%esp)
80100f46:	80 
80100f47:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
80100f4e:	e8 d1 47 00 00       	call   80105724 <initlock>
}
80100f53:	c9                   	leave  
80100f54:	c3                   	ret    

80100f55 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100f55:	55                   	push   %ebp
80100f56:	89 e5                	mov    %esp,%ebp
80100f58:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
80100f5b:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
80100f62:	e8 de 47 00 00       	call   80105745 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f67:	c7 45 f4 74 18 11 80 	movl   $0x80111874,-0xc(%ebp)
80100f6e:	eb 29                	jmp    80100f99 <filealloc+0x44>
    if(f->ref == 0){
80100f70:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f73:	8b 40 04             	mov    0x4(%eax),%eax
80100f76:	85 c0                	test   %eax,%eax
80100f78:	75 1b                	jne    80100f95 <filealloc+0x40>
      f->ref = 1;
80100f7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f7d:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
80100f84:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
80100f8b:	e8 17 48 00 00       	call   801057a7 <release>
      return f;
80100f90:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f93:	eb 1e                	jmp    80100fb3 <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f95:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80100f99:	81 7d f4 d4 21 11 80 	cmpl   $0x801121d4,-0xc(%ebp)
80100fa0:	72 ce                	jb     80100f70 <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80100fa2:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
80100fa9:	e8 f9 47 00 00       	call   801057a7 <release>
  return 0;
80100fae:	b8 00 00 00 00       	mov    $0x0,%eax
}
80100fb3:	c9                   	leave  
80100fb4:	c3                   	ret    

80100fb5 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100fb5:	55                   	push   %ebp
80100fb6:	89 e5                	mov    %esp,%ebp
80100fb8:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
80100fbb:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
80100fc2:	e8 7e 47 00 00       	call   80105745 <acquire>
  if(f->ref < 1)
80100fc7:	8b 45 08             	mov    0x8(%ebp),%eax
80100fca:	8b 40 04             	mov    0x4(%eax),%eax
80100fcd:	85 c0                	test   %eax,%eax
80100fcf:	7f 0c                	jg     80100fdd <filedup+0x28>
    panic("filedup");
80100fd1:	c7 04 24 d4 8d 10 80 	movl   $0x80108dd4,(%esp)
80100fd8:	e8 5d f5 ff ff       	call   8010053a <panic>
  f->ref++;
80100fdd:	8b 45 08             	mov    0x8(%ebp),%eax
80100fe0:	8b 40 04             	mov    0x4(%eax),%eax
80100fe3:	8d 50 01             	lea    0x1(%eax),%edx
80100fe6:	8b 45 08             	mov    0x8(%ebp),%eax
80100fe9:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fec:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
80100ff3:	e8 af 47 00 00       	call   801057a7 <release>
  return f;
80100ff8:	8b 45 08             	mov    0x8(%ebp),%eax
}
80100ffb:	c9                   	leave  
80100ffc:	c3                   	ret    

80100ffd <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100ffd:	55                   	push   %ebp
80100ffe:	89 e5                	mov    %esp,%ebp
80101000:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
80101003:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
8010100a:	e8 36 47 00 00       	call   80105745 <acquire>
  if(f->ref < 1)
8010100f:	8b 45 08             	mov    0x8(%ebp),%eax
80101012:	8b 40 04             	mov    0x4(%eax),%eax
80101015:	85 c0                	test   %eax,%eax
80101017:	7f 0c                	jg     80101025 <fileclose+0x28>
    panic("fileclose");
80101019:	c7 04 24 dc 8d 10 80 	movl   $0x80108ddc,(%esp)
80101020:	e8 15 f5 ff ff       	call   8010053a <panic>
  if(--f->ref > 0){
80101025:	8b 45 08             	mov    0x8(%ebp),%eax
80101028:	8b 40 04             	mov    0x4(%eax),%eax
8010102b:	8d 50 ff             	lea    -0x1(%eax),%edx
8010102e:	8b 45 08             	mov    0x8(%ebp),%eax
80101031:	89 50 04             	mov    %edx,0x4(%eax)
80101034:	8b 45 08             	mov    0x8(%ebp),%eax
80101037:	8b 40 04             	mov    0x4(%eax),%eax
8010103a:	85 c0                	test   %eax,%eax
8010103c:	7e 11                	jle    8010104f <fileclose+0x52>
    release(&ftable.lock);
8010103e:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
80101045:	e8 5d 47 00 00       	call   801057a7 <release>
8010104a:	e9 82 00 00 00       	jmp    801010d1 <fileclose+0xd4>
    return;
  }
  ff = *f;
8010104f:	8b 45 08             	mov    0x8(%ebp),%eax
80101052:	8b 10                	mov    (%eax),%edx
80101054:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101057:	8b 50 04             	mov    0x4(%eax),%edx
8010105a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
8010105d:	8b 50 08             	mov    0x8(%eax),%edx
80101060:	89 55 e8             	mov    %edx,-0x18(%ebp)
80101063:	8b 50 0c             	mov    0xc(%eax),%edx
80101066:	89 55 ec             	mov    %edx,-0x14(%ebp)
80101069:	8b 50 10             	mov    0x10(%eax),%edx
8010106c:	89 55 f0             	mov    %edx,-0x10(%ebp)
8010106f:	8b 40 14             	mov    0x14(%eax),%eax
80101072:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
80101075:	8b 45 08             	mov    0x8(%ebp),%eax
80101078:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
8010107f:	8b 45 08             	mov    0x8(%ebp),%eax
80101082:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
80101088:	c7 04 24 40 18 11 80 	movl   $0x80111840,(%esp)
8010108f:	e8 13 47 00 00       	call   801057a7 <release>
  
  if(ff.type == FD_PIPE)
80101094:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101097:	83 f8 01             	cmp    $0x1,%eax
8010109a:	75 18                	jne    801010b4 <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
8010109c:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
801010a0:	0f be d0             	movsbl %al,%edx
801010a3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801010a6:	89 54 24 04          	mov    %edx,0x4(%esp)
801010aa:	89 04 24             	mov    %eax,(%esp)
801010ad:	e8 01 31 00 00       	call   801041b3 <pipeclose>
801010b2:	eb 1d                	jmp    801010d1 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
801010b4:	8b 45 e0             	mov    -0x20(%ebp),%eax
801010b7:	83 f8 02             	cmp    $0x2,%eax
801010ba:	75 15                	jne    801010d1 <fileclose+0xd4>
    begin_op();
801010bc:	e8 99 24 00 00       	call   8010355a <begin_op>
    iput(ff.ip);
801010c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801010c4:	89 04 24             	mov    %eax,(%esp)
801010c7:	e8 71 09 00 00       	call   80101a3d <iput>
    end_op();
801010cc:	e8 0d 25 00 00       	call   801035de <end_op>
  }
}
801010d1:	c9                   	leave  
801010d2:	c3                   	ret    

801010d3 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
801010d3:	55                   	push   %ebp
801010d4:	89 e5                	mov    %esp,%ebp
801010d6:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
801010d9:	8b 45 08             	mov    0x8(%ebp),%eax
801010dc:	8b 00                	mov    (%eax),%eax
801010de:	83 f8 02             	cmp    $0x2,%eax
801010e1:	75 38                	jne    8010111b <filestat+0x48>
    ilock(f->ip);
801010e3:	8b 45 08             	mov    0x8(%ebp),%eax
801010e6:	8b 40 10             	mov    0x10(%eax),%eax
801010e9:	89 04 24             	mov    %eax,(%esp)
801010ec:	e8 99 07 00 00       	call   8010188a <ilock>
    stati(f->ip, st);
801010f1:	8b 45 08             	mov    0x8(%ebp),%eax
801010f4:	8b 40 10             	mov    0x10(%eax),%eax
801010f7:	8b 55 0c             	mov    0xc(%ebp),%edx
801010fa:	89 54 24 04          	mov    %edx,0x4(%esp)
801010fe:	89 04 24             	mov    %eax,(%esp)
80101101:	e8 4c 0c 00 00       	call   80101d52 <stati>
    iunlock(f->ip);
80101106:	8b 45 08             	mov    0x8(%ebp),%eax
80101109:	8b 40 10             	mov    0x10(%eax),%eax
8010110c:	89 04 24             	mov    %eax,(%esp)
8010110f:	e8 c4 08 00 00       	call   801019d8 <iunlock>
    return 0;
80101114:	b8 00 00 00 00       	mov    $0x0,%eax
80101119:	eb 05                	jmp    80101120 <filestat+0x4d>
  }
  return -1;
8010111b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80101120:	c9                   	leave  
80101121:	c3                   	ret    

80101122 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
80101122:	55                   	push   %ebp
80101123:	89 e5                	mov    %esp,%ebp
80101125:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
80101128:	8b 45 08             	mov    0x8(%ebp),%eax
8010112b:	0f b6 40 08          	movzbl 0x8(%eax),%eax
8010112f:	84 c0                	test   %al,%al
80101131:	75 0a                	jne    8010113d <fileread+0x1b>
    return -1;
80101133:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101138:	e9 9f 00 00 00       	jmp    801011dc <fileread+0xba>
  if(f->type == FD_PIPE)
8010113d:	8b 45 08             	mov    0x8(%ebp),%eax
80101140:	8b 00                	mov    (%eax),%eax
80101142:	83 f8 01             	cmp    $0x1,%eax
80101145:	75 1e                	jne    80101165 <fileread+0x43>
    return piperead(f->pipe, addr, n);
80101147:	8b 45 08             	mov    0x8(%ebp),%eax
8010114a:	8b 40 0c             	mov    0xc(%eax),%eax
8010114d:	8b 55 10             	mov    0x10(%ebp),%edx
80101150:	89 54 24 08          	mov    %edx,0x8(%esp)
80101154:	8b 55 0c             	mov    0xc(%ebp),%edx
80101157:	89 54 24 04          	mov    %edx,0x4(%esp)
8010115b:	89 04 24             	mov    %eax,(%esp)
8010115e:	e8 d1 31 00 00       	call   80104334 <piperead>
80101163:	eb 77                	jmp    801011dc <fileread+0xba>
  if(f->type == FD_INODE){
80101165:	8b 45 08             	mov    0x8(%ebp),%eax
80101168:	8b 00                	mov    (%eax),%eax
8010116a:	83 f8 02             	cmp    $0x2,%eax
8010116d:	75 61                	jne    801011d0 <fileread+0xae>
    ilock(f->ip);
8010116f:	8b 45 08             	mov    0x8(%ebp),%eax
80101172:	8b 40 10             	mov    0x10(%eax),%eax
80101175:	89 04 24             	mov    %eax,(%esp)
80101178:	e8 0d 07 00 00       	call   8010188a <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
8010117d:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101180:	8b 45 08             	mov    0x8(%ebp),%eax
80101183:	8b 50 14             	mov    0x14(%eax),%edx
80101186:	8b 45 08             	mov    0x8(%ebp),%eax
80101189:	8b 40 10             	mov    0x10(%eax),%eax
8010118c:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101190:	89 54 24 08          	mov    %edx,0x8(%esp)
80101194:	8b 55 0c             	mov    0xc(%ebp),%edx
80101197:	89 54 24 04          	mov    %edx,0x4(%esp)
8010119b:	89 04 24             	mov    %eax,(%esp)
8010119e:	e8 f4 0b 00 00       	call   80101d97 <readi>
801011a3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801011a6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801011aa:	7e 11                	jle    801011bd <fileread+0x9b>
      f->off += r;
801011ac:	8b 45 08             	mov    0x8(%ebp),%eax
801011af:	8b 50 14             	mov    0x14(%eax),%edx
801011b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801011b5:	01 c2                	add    %eax,%edx
801011b7:	8b 45 08             	mov    0x8(%ebp),%eax
801011ba:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
801011bd:	8b 45 08             	mov    0x8(%ebp),%eax
801011c0:	8b 40 10             	mov    0x10(%eax),%eax
801011c3:	89 04 24             	mov    %eax,(%esp)
801011c6:	e8 0d 08 00 00       	call   801019d8 <iunlock>
    return r;
801011cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801011ce:	eb 0c                	jmp    801011dc <fileread+0xba>
  }
  panic("fileread");
801011d0:	c7 04 24 e6 8d 10 80 	movl   $0x80108de6,(%esp)
801011d7:	e8 5e f3 ff ff       	call   8010053a <panic>
}
801011dc:	c9                   	leave  
801011dd:	c3                   	ret    

801011de <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
801011de:	55                   	push   %ebp
801011df:	89 e5                	mov    %esp,%ebp
801011e1:	53                   	push   %ebx
801011e2:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
801011e5:	8b 45 08             	mov    0x8(%ebp),%eax
801011e8:	0f b6 40 09          	movzbl 0x9(%eax),%eax
801011ec:	84 c0                	test   %al,%al
801011ee:	75 0a                	jne    801011fa <filewrite+0x1c>
    return -1;
801011f0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801011f5:	e9 20 01 00 00       	jmp    8010131a <filewrite+0x13c>
  if(f->type == FD_PIPE)
801011fa:	8b 45 08             	mov    0x8(%ebp),%eax
801011fd:	8b 00                	mov    (%eax),%eax
801011ff:	83 f8 01             	cmp    $0x1,%eax
80101202:	75 21                	jne    80101225 <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
80101204:	8b 45 08             	mov    0x8(%ebp),%eax
80101207:	8b 40 0c             	mov    0xc(%eax),%eax
8010120a:	8b 55 10             	mov    0x10(%ebp),%edx
8010120d:	89 54 24 08          	mov    %edx,0x8(%esp)
80101211:	8b 55 0c             	mov    0xc(%ebp),%edx
80101214:	89 54 24 04          	mov    %edx,0x4(%esp)
80101218:	89 04 24             	mov    %eax,(%esp)
8010121b:	e8 25 30 00 00       	call   80104245 <pipewrite>
80101220:	e9 f5 00 00 00       	jmp    8010131a <filewrite+0x13c>
  if(f->type == FD_INODE){
80101225:	8b 45 08             	mov    0x8(%ebp),%eax
80101228:	8b 00                	mov    (%eax),%eax
8010122a:	83 f8 02             	cmp    $0x2,%eax
8010122d:	0f 85 db 00 00 00    	jne    8010130e <filewrite+0x130>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
80101233:	c7 45 ec 00 1a 00 00 	movl   $0x1a00,-0x14(%ebp)
    int i = 0;
8010123a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
80101241:	e9 a8 00 00 00       	jmp    801012ee <filewrite+0x110>
      int n1 = n - i;
80101246:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101249:	8b 55 10             	mov    0x10(%ebp),%edx
8010124c:	29 c2                	sub    %eax,%edx
8010124e:	89 d0                	mov    %edx,%eax
80101250:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
80101253:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101256:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80101259:	7e 06                	jle    80101261 <filewrite+0x83>
        n1 = max;
8010125b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010125e:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_op();
80101261:	e8 f4 22 00 00       	call   8010355a <begin_op>
      ilock(f->ip);
80101266:	8b 45 08             	mov    0x8(%ebp),%eax
80101269:	8b 40 10             	mov    0x10(%eax),%eax
8010126c:	89 04 24             	mov    %eax,(%esp)
8010126f:	e8 16 06 00 00       	call   8010188a <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80101274:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80101277:	8b 45 08             	mov    0x8(%ebp),%eax
8010127a:	8b 50 14             	mov    0x14(%eax),%edx
8010127d:	8b 5d f4             	mov    -0xc(%ebp),%ebx
80101280:	8b 45 0c             	mov    0xc(%ebp),%eax
80101283:	01 c3                	add    %eax,%ebx
80101285:	8b 45 08             	mov    0x8(%ebp),%eax
80101288:	8b 40 10             	mov    0x10(%eax),%eax
8010128b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010128f:	89 54 24 08          	mov    %edx,0x8(%esp)
80101293:	89 5c 24 04          	mov    %ebx,0x4(%esp)
80101297:	89 04 24             	mov    %eax,(%esp)
8010129a:	e8 69 0c 00 00       	call   80101f08 <writei>
8010129f:	89 45 e8             	mov    %eax,-0x18(%ebp)
801012a2:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801012a6:	7e 11                	jle    801012b9 <filewrite+0xdb>
        f->off += r;
801012a8:	8b 45 08             	mov    0x8(%ebp),%eax
801012ab:	8b 50 14             	mov    0x14(%eax),%edx
801012ae:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012b1:	01 c2                	add    %eax,%edx
801012b3:	8b 45 08             	mov    0x8(%ebp),%eax
801012b6:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
801012b9:	8b 45 08             	mov    0x8(%ebp),%eax
801012bc:	8b 40 10             	mov    0x10(%eax),%eax
801012bf:	89 04 24             	mov    %eax,(%esp)
801012c2:	e8 11 07 00 00       	call   801019d8 <iunlock>
      end_op();
801012c7:	e8 12 23 00 00       	call   801035de <end_op>

      if(r < 0)
801012cc:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801012d0:	79 02                	jns    801012d4 <filewrite+0xf6>
        break;
801012d2:	eb 26                	jmp    801012fa <filewrite+0x11c>
      if(r != n1)
801012d4:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012d7:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012da:	74 0c                	je     801012e8 <filewrite+0x10a>
        panic("short filewrite");
801012dc:	c7 04 24 ef 8d 10 80 	movl   $0x80108def,(%esp)
801012e3:	e8 52 f2 ff ff       	call   8010053a <panic>
      i += r;
801012e8:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012eb:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
801012ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012f1:	3b 45 10             	cmp    0x10(%ebp),%eax
801012f4:	0f 8c 4c ff ff ff    	jl     80101246 <filewrite+0x68>
        break;
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
801012fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012fd:	3b 45 10             	cmp    0x10(%ebp),%eax
80101300:	75 05                	jne    80101307 <filewrite+0x129>
80101302:	8b 45 10             	mov    0x10(%ebp),%eax
80101305:	eb 05                	jmp    8010130c <filewrite+0x12e>
80101307:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010130c:	eb 0c                	jmp    8010131a <filewrite+0x13c>
  }
  panic("filewrite");
8010130e:	c7 04 24 ff 8d 10 80 	movl   $0x80108dff,(%esp)
80101315:	e8 20 f2 ff ff       	call   8010053a <panic>
}
8010131a:	83 c4 24             	add    $0x24,%esp
8010131d:	5b                   	pop    %ebx
8010131e:	5d                   	pop    %ebp
8010131f:	c3                   	ret    

80101320 <readsb>:
static void itrunc(struct inode*);

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
80101320:	55                   	push   %ebp
80101321:	89 e5                	mov    %esp,%ebp
80101323:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
80101326:	8b 45 08             	mov    0x8(%ebp),%eax
80101329:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80101330:	00 
80101331:	89 04 24             	mov    %eax,(%esp)
80101334:	e8 6d ee ff ff       	call   801001a6 <bread>
80101339:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
8010133c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010133f:	83 c0 18             	add    $0x18,%eax
80101342:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80101349:	00 
8010134a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010134e:	8b 45 0c             	mov    0xc(%ebp),%eax
80101351:	89 04 24             	mov    %eax,(%esp)
80101354:	e8 0f 47 00 00       	call   80105a68 <memmove>
  brelse(bp);
80101359:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010135c:	89 04 24             	mov    %eax,(%esp)
8010135f:	e8 b3 ee ff ff       	call   80100217 <brelse>
}
80101364:	c9                   	leave  
80101365:	c3                   	ret    

80101366 <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80101366:	55                   	push   %ebp
80101367:	89 e5                	mov    %esp,%ebp
80101369:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
8010136c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010136f:	8b 45 08             	mov    0x8(%ebp),%eax
80101372:	89 54 24 04          	mov    %edx,0x4(%esp)
80101376:	89 04 24             	mov    %eax,(%esp)
80101379:	e8 28 ee ff ff       	call   801001a6 <bread>
8010137e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
80101381:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101384:	83 c0 18             	add    $0x18,%eax
80101387:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010138e:	00 
8010138f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101396:	00 
80101397:	89 04 24             	mov    %eax,(%esp)
8010139a:	e8 fa 45 00 00       	call   80105999 <memset>
  log_write(bp);
8010139f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013a2:	89 04 24             	mov    %eax,(%esp)
801013a5:	e8 bb 23 00 00       	call   80103765 <log_write>
  brelse(bp);
801013aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013ad:	89 04 24             	mov    %eax,(%esp)
801013b0:	e8 62 ee ff ff       	call   80100217 <brelse>
}
801013b5:	c9                   	leave  
801013b6:	c3                   	ret    

801013b7 <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
801013b7:	55                   	push   %ebp
801013b8:	89 e5                	mov    %esp,%ebp
801013ba:	83 ec 38             	sub    $0x38,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
801013bd:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
801013c4:	8b 45 08             	mov    0x8(%ebp),%eax
801013c7:	8d 55 d8             	lea    -0x28(%ebp),%edx
801013ca:	89 54 24 04          	mov    %edx,0x4(%esp)
801013ce:	89 04 24             	mov    %eax,(%esp)
801013d1:	e8 4a ff ff ff       	call   80101320 <readsb>
  for(b = 0; b < sb.size; b += BPB){
801013d6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801013dd:	e9 07 01 00 00       	jmp    801014e9 <balloc+0x132>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
801013e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013e5:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
801013eb:	85 c0                	test   %eax,%eax
801013ed:	0f 48 c2             	cmovs  %edx,%eax
801013f0:	c1 f8 0c             	sar    $0xc,%eax
801013f3:	8b 55 e0             	mov    -0x20(%ebp),%edx
801013f6:	c1 ea 03             	shr    $0x3,%edx
801013f9:	01 d0                	add    %edx,%eax
801013fb:	83 c0 03             	add    $0x3,%eax
801013fe:	89 44 24 04          	mov    %eax,0x4(%esp)
80101402:	8b 45 08             	mov    0x8(%ebp),%eax
80101405:	89 04 24             	mov    %eax,(%esp)
80101408:	e8 99 ed ff ff       	call   801001a6 <bread>
8010140d:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101410:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101417:	e9 9d 00 00 00       	jmp    801014b9 <balloc+0x102>
      m = 1 << (bi % 8);
8010141c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010141f:	99                   	cltd   
80101420:	c1 ea 1d             	shr    $0x1d,%edx
80101423:	01 d0                	add    %edx,%eax
80101425:	83 e0 07             	and    $0x7,%eax
80101428:	29 d0                	sub    %edx,%eax
8010142a:	ba 01 00 00 00       	mov    $0x1,%edx
8010142f:	89 c1                	mov    %eax,%ecx
80101431:	d3 e2                	shl    %cl,%edx
80101433:	89 d0                	mov    %edx,%eax
80101435:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
80101438:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010143b:	8d 50 07             	lea    0x7(%eax),%edx
8010143e:	85 c0                	test   %eax,%eax
80101440:	0f 48 c2             	cmovs  %edx,%eax
80101443:	c1 f8 03             	sar    $0x3,%eax
80101446:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101449:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
8010144e:	0f b6 c0             	movzbl %al,%eax
80101451:	23 45 e8             	and    -0x18(%ebp),%eax
80101454:	85 c0                	test   %eax,%eax
80101456:	75 5d                	jne    801014b5 <balloc+0xfe>
        bp->data[bi/8] |= m;  // Mark block in use.
80101458:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010145b:	8d 50 07             	lea    0x7(%eax),%edx
8010145e:	85 c0                	test   %eax,%eax
80101460:	0f 48 c2             	cmovs  %edx,%eax
80101463:	c1 f8 03             	sar    $0x3,%eax
80101466:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101469:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
8010146e:	89 d1                	mov    %edx,%ecx
80101470:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101473:	09 ca                	or     %ecx,%edx
80101475:	89 d1                	mov    %edx,%ecx
80101477:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010147a:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
8010147e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101481:	89 04 24             	mov    %eax,(%esp)
80101484:	e8 dc 22 00 00       	call   80103765 <log_write>
        brelse(bp);
80101489:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010148c:	89 04 24             	mov    %eax,(%esp)
8010148f:	e8 83 ed ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
80101494:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101497:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010149a:	01 c2                	add    %eax,%edx
8010149c:	8b 45 08             	mov    0x8(%ebp),%eax
8010149f:	89 54 24 04          	mov    %edx,0x4(%esp)
801014a3:	89 04 24             	mov    %eax,(%esp)
801014a6:	e8 bb fe ff ff       	call   80101366 <bzero>
        return b + bi;
801014ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014ae:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014b1:	01 d0                	add    %edx,%eax
801014b3:	eb 4e                	jmp    80101503 <balloc+0x14c>

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801014b5:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801014b9:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
801014c0:	7f 15                	jg     801014d7 <balloc+0x120>
801014c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014c5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014c8:	01 d0                	add    %edx,%eax
801014ca:	89 c2                	mov    %eax,%edx
801014cc:	8b 45 d8             	mov    -0x28(%ebp),%eax
801014cf:	39 c2                	cmp    %eax,%edx
801014d1:	0f 82 45 ff ff ff    	jb     8010141c <balloc+0x65>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
801014d7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801014da:	89 04 24             	mov    %eax,(%esp)
801014dd:	e8 35 ed ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
801014e2:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801014e9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014ec:	8b 45 d8             	mov    -0x28(%ebp),%eax
801014ef:	39 c2                	cmp    %eax,%edx
801014f1:	0f 82 eb fe ff ff    	jb     801013e2 <balloc+0x2b>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
801014f7:	c7 04 24 09 8e 10 80 	movl   $0x80108e09,(%esp)
801014fe:	e8 37 f0 ff ff       	call   8010053a <panic>
}
80101503:	c9                   	leave  
80101504:	c3                   	ret    

80101505 <bfree>:

// Free a disk block.
static void
bfree(int dev, uint b)
{
80101505:	55                   	push   %ebp
80101506:	89 e5                	mov    %esp,%ebp
80101508:	83 ec 38             	sub    $0x38,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
8010150b:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010150e:	89 44 24 04          	mov    %eax,0x4(%esp)
80101512:	8b 45 08             	mov    0x8(%ebp),%eax
80101515:	89 04 24             	mov    %eax,(%esp)
80101518:	e8 03 fe ff ff       	call   80101320 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
8010151d:	8b 45 0c             	mov    0xc(%ebp),%eax
80101520:	c1 e8 0c             	shr    $0xc,%eax
80101523:	89 c2                	mov    %eax,%edx
80101525:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101528:	c1 e8 03             	shr    $0x3,%eax
8010152b:	01 d0                	add    %edx,%eax
8010152d:	8d 50 03             	lea    0x3(%eax),%edx
80101530:	8b 45 08             	mov    0x8(%ebp),%eax
80101533:	89 54 24 04          	mov    %edx,0x4(%esp)
80101537:	89 04 24             	mov    %eax,(%esp)
8010153a:	e8 67 ec ff ff       	call   801001a6 <bread>
8010153f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80101542:	8b 45 0c             	mov    0xc(%ebp),%eax
80101545:	25 ff 0f 00 00       	and    $0xfff,%eax
8010154a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
8010154d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101550:	99                   	cltd   
80101551:	c1 ea 1d             	shr    $0x1d,%edx
80101554:	01 d0                	add    %edx,%eax
80101556:	83 e0 07             	and    $0x7,%eax
80101559:	29 d0                	sub    %edx,%eax
8010155b:	ba 01 00 00 00       	mov    $0x1,%edx
80101560:	89 c1                	mov    %eax,%ecx
80101562:	d3 e2                	shl    %cl,%edx
80101564:	89 d0                	mov    %edx,%eax
80101566:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
80101569:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010156c:	8d 50 07             	lea    0x7(%eax),%edx
8010156f:	85 c0                	test   %eax,%eax
80101571:	0f 48 c2             	cmovs  %edx,%eax
80101574:	c1 f8 03             	sar    $0x3,%eax
80101577:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010157a:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
8010157f:	0f b6 c0             	movzbl %al,%eax
80101582:	23 45 ec             	and    -0x14(%ebp),%eax
80101585:	85 c0                	test   %eax,%eax
80101587:	75 0c                	jne    80101595 <bfree+0x90>
    panic("freeing free block");
80101589:	c7 04 24 1f 8e 10 80 	movl   $0x80108e1f,(%esp)
80101590:	e8 a5 ef ff ff       	call   8010053a <panic>
  bp->data[bi/8] &= ~m;
80101595:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101598:	8d 50 07             	lea    0x7(%eax),%edx
8010159b:	85 c0                	test   %eax,%eax
8010159d:	0f 48 c2             	cmovs  %edx,%eax
801015a0:	c1 f8 03             	sar    $0x3,%eax
801015a3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015a6:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
801015ab:	8b 4d ec             	mov    -0x14(%ebp),%ecx
801015ae:	f7 d1                	not    %ecx
801015b0:	21 ca                	and    %ecx,%edx
801015b2:	89 d1                	mov    %edx,%ecx
801015b4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015b7:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
801015bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015be:	89 04 24             	mov    %eax,(%esp)
801015c1:	e8 9f 21 00 00       	call   80103765 <log_write>
  brelse(bp);
801015c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015c9:	89 04 24             	mov    %eax,(%esp)
801015cc:	e8 46 ec ff ff       	call   80100217 <brelse>
}
801015d1:	c9                   	leave  
801015d2:	c3                   	ret    

801015d3 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
801015d3:	55                   	push   %ebp
801015d4:	89 e5                	mov    %esp,%ebp
801015d6:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
801015d9:	c7 44 24 04 32 8e 10 	movl   $0x80108e32,0x4(%esp)
801015e0:	80 
801015e1:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
801015e8:	e8 37 41 00 00       	call   80105724 <initlock>
}
801015ed:	c9                   	leave  
801015ee:	c3                   	ret    

801015ef <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
801015ef:	55                   	push   %ebp
801015f0:	89 e5                	mov    %esp,%ebp
801015f2:	83 ec 38             	sub    $0x38,%esp
801015f5:	8b 45 0c             	mov    0xc(%ebp),%eax
801015f8:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
801015fc:	8b 45 08             	mov    0x8(%ebp),%eax
801015ff:	8d 55 dc             	lea    -0x24(%ebp),%edx
80101602:	89 54 24 04          	mov    %edx,0x4(%esp)
80101606:	89 04 24             	mov    %eax,(%esp)
80101609:	e8 12 fd ff ff       	call   80101320 <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
8010160e:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
80101615:	e9 98 00 00 00       	jmp    801016b2 <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
8010161a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010161d:	c1 e8 03             	shr    $0x3,%eax
80101620:	83 c0 02             	add    $0x2,%eax
80101623:	89 44 24 04          	mov    %eax,0x4(%esp)
80101627:	8b 45 08             	mov    0x8(%ebp),%eax
8010162a:	89 04 24             	mov    %eax,(%esp)
8010162d:	e8 74 eb ff ff       	call   801001a6 <bread>
80101632:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80101635:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101638:	8d 50 18             	lea    0x18(%eax),%edx
8010163b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010163e:	83 e0 07             	and    $0x7,%eax
80101641:	c1 e0 06             	shl    $0x6,%eax
80101644:	01 d0                	add    %edx,%eax
80101646:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
80101649:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010164c:	0f b7 00             	movzwl (%eax),%eax
8010164f:	66 85 c0             	test   %ax,%ax
80101652:	75 4f                	jne    801016a3 <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
80101654:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
8010165b:	00 
8010165c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101663:	00 
80101664:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101667:	89 04 24             	mov    %eax,(%esp)
8010166a:	e8 2a 43 00 00       	call   80105999 <memset>
      dip->type = type;
8010166f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101672:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
80101676:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80101679:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010167c:	89 04 24             	mov    %eax,(%esp)
8010167f:	e8 e1 20 00 00       	call   80103765 <log_write>
      brelse(bp);
80101684:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101687:	89 04 24             	mov    %eax,(%esp)
8010168a:	e8 88 eb ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
8010168f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101692:	89 44 24 04          	mov    %eax,0x4(%esp)
80101696:	8b 45 08             	mov    0x8(%ebp),%eax
80101699:	89 04 24             	mov    %eax,(%esp)
8010169c:	e8 e5 00 00 00       	call   80101786 <iget>
801016a1:	eb 29                	jmp    801016cc <ialloc+0xdd>
    }
    brelse(bp);
801016a3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016a6:	89 04 24             	mov    %eax,(%esp)
801016a9:	e8 69 eb ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
801016ae:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801016b2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801016b5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801016b8:	39 c2                	cmp    %eax,%edx
801016ba:	0f 82 5a ff ff ff    	jb     8010161a <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
801016c0:	c7 04 24 39 8e 10 80 	movl   $0x80108e39,(%esp)
801016c7:	e8 6e ee ff ff       	call   8010053a <panic>
}
801016cc:	c9                   	leave  
801016cd:	c3                   	ret    

801016ce <iupdate>:

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
801016ce:	55                   	push   %ebp
801016cf:	89 e5                	mov    %esp,%ebp
801016d1:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
801016d4:	8b 45 08             	mov    0x8(%ebp),%eax
801016d7:	8b 40 04             	mov    0x4(%eax),%eax
801016da:	c1 e8 03             	shr    $0x3,%eax
801016dd:	8d 50 02             	lea    0x2(%eax),%edx
801016e0:	8b 45 08             	mov    0x8(%ebp),%eax
801016e3:	8b 00                	mov    (%eax),%eax
801016e5:	89 54 24 04          	mov    %edx,0x4(%esp)
801016e9:	89 04 24             	mov    %eax,(%esp)
801016ec:	e8 b5 ea ff ff       	call   801001a6 <bread>
801016f1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
801016f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016f7:	8d 50 18             	lea    0x18(%eax),%edx
801016fa:	8b 45 08             	mov    0x8(%ebp),%eax
801016fd:	8b 40 04             	mov    0x4(%eax),%eax
80101700:	83 e0 07             	and    $0x7,%eax
80101703:	c1 e0 06             	shl    $0x6,%eax
80101706:	01 d0                	add    %edx,%eax
80101708:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
8010170b:	8b 45 08             	mov    0x8(%ebp),%eax
8010170e:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101712:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101715:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101718:	8b 45 08             	mov    0x8(%ebp),%eax
8010171b:	0f b7 50 12          	movzwl 0x12(%eax),%edx
8010171f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101722:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
80101726:	8b 45 08             	mov    0x8(%ebp),%eax
80101729:	0f b7 50 14          	movzwl 0x14(%eax),%edx
8010172d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101730:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101734:	8b 45 08             	mov    0x8(%ebp),%eax
80101737:	0f b7 50 16          	movzwl 0x16(%eax),%edx
8010173b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010173e:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
80101742:	8b 45 08             	mov    0x8(%ebp),%eax
80101745:	8b 50 18             	mov    0x18(%eax),%edx
80101748:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010174b:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
8010174e:	8b 45 08             	mov    0x8(%ebp),%eax
80101751:	8d 50 1c             	lea    0x1c(%eax),%edx
80101754:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101757:	83 c0 0c             	add    $0xc,%eax
8010175a:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101761:	00 
80101762:	89 54 24 04          	mov    %edx,0x4(%esp)
80101766:	89 04 24             	mov    %eax,(%esp)
80101769:	e8 fa 42 00 00       	call   80105a68 <memmove>
  log_write(bp);
8010176e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101771:	89 04 24             	mov    %eax,(%esp)
80101774:	e8 ec 1f 00 00       	call   80103765 <log_write>
  brelse(bp);
80101779:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010177c:	89 04 24             	mov    %eax,(%esp)
8010177f:	e8 93 ea ff ff       	call   80100217 <brelse>
}
80101784:	c9                   	leave  
80101785:	c3                   	ret    

80101786 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
80101786:	55                   	push   %ebp
80101787:	89 e5                	mov    %esp,%ebp
80101789:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
8010178c:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101793:	e8 ad 3f 00 00       	call   80105745 <acquire>

  // Is the inode already cached?
  empty = 0;
80101798:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010179f:	c7 45 f4 b4 22 11 80 	movl   $0x801122b4,-0xc(%ebp)
801017a6:	eb 59                	jmp    80101801 <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
801017a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017ab:	8b 40 08             	mov    0x8(%eax),%eax
801017ae:	85 c0                	test   %eax,%eax
801017b0:	7e 35                	jle    801017e7 <iget+0x61>
801017b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017b5:	8b 00                	mov    (%eax),%eax
801017b7:	3b 45 08             	cmp    0x8(%ebp),%eax
801017ba:	75 2b                	jne    801017e7 <iget+0x61>
801017bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017bf:	8b 40 04             	mov    0x4(%eax),%eax
801017c2:	3b 45 0c             	cmp    0xc(%ebp),%eax
801017c5:	75 20                	jne    801017e7 <iget+0x61>
      ip->ref++;
801017c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017ca:	8b 40 08             	mov    0x8(%eax),%eax
801017cd:	8d 50 01             	lea    0x1(%eax),%edx
801017d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017d3:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
801017d6:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
801017dd:	e8 c5 3f 00 00       	call   801057a7 <release>
      return ip;
801017e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017e5:	eb 6f                	jmp    80101856 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801017e7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801017eb:	75 10                	jne    801017fd <iget+0x77>
801017ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017f0:	8b 40 08             	mov    0x8(%eax),%eax
801017f3:	85 c0                	test   %eax,%eax
801017f5:	75 06                	jne    801017fd <iget+0x77>
      empty = ip;
801017f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017fa:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801017fd:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
80101801:	81 7d f4 54 32 11 80 	cmpl   $0x80113254,-0xc(%ebp)
80101808:	72 9e                	jb     801017a8 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
8010180a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010180e:	75 0c                	jne    8010181c <iget+0x96>
    panic("iget: no inodes");
80101810:	c7 04 24 4b 8e 10 80 	movl   $0x80108e4b,(%esp)
80101817:	e8 1e ed ff ff       	call   8010053a <panic>

  ip = empty;
8010181c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010181f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
80101822:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101825:	8b 55 08             	mov    0x8(%ebp),%edx
80101828:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
8010182a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010182d:	8b 55 0c             	mov    0xc(%ebp),%edx
80101830:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80101833:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101836:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
8010183d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101840:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
80101847:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
8010184e:	e8 54 3f 00 00       	call   801057a7 <release>

  return ip;
80101853:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80101856:	c9                   	leave  
80101857:	c3                   	ret    

80101858 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
80101858:	55                   	push   %ebp
80101859:	89 e5                	mov    %esp,%ebp
8010185b:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
8010185e:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101865:	e8 db 3e 00 00       	call   80105745 <acquire>
  ip->ref++;
8010186a:	8b 45 08             	mov    0x8(%ebp),%eax
8010186d:	8b 40 08             	mov    0x8(%eax),%eax
80101870:	8d 50 01             	lea    0x1(%eax),%edx
80101873:	8b 45 08             	mov    0x8(%ebp),%eax
80101876:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101879:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101880:	e8 22 3f 00 00       	call   801057a7 <release>
  return ip;
80101885:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101888:	c9                   	leave  
80101889:	c3                   	ret    

8010188a <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
8010188a:	55                   	push   %ebp
8010188b:	89 e5                	mov    %esp,%ebp
8010188d:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
80101890:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101894:	74 0a                	je     801018a0 <ilock+0x16>
80101896:	8b 45 08             	mov    0x8(%ebp),%eax
80101899:	8b 40 08             	mov    0x8(%eax),%eax
8010189c:	85 c0                	test   %eax,%eax
8010189e:	7f 0c                	jg     801018ac <ilock+0x22>
    panic("ilock");
801018a0:	c7 04 24 5b 8e 10 80 	movl   $0x80108e5b,(%esp)
801018a7:	e8 8e ec ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
801018ac:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
801018b3:	e8 8d 3e 00 00       	call   80105745 <acquire>
  while(ip->flags & I_BUSY)
801018b8:	eb 13                	jmp    801018cd <ilock+0x43>
    sleep(ip, &icache.lock);
801018ba:	c7 44 24 04 80 22 11 	movl   $0x80112280,0x4(%esp)
801018c1:	80 
801018c2:	8b 45 08             	mov    0x8(%ebp),%eax
801018c5:	89 04 24             	mov    %eax,(%esp)
801018c8:	e8 f7 33 00 00       	call   80104cc4 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
801018cd:	8b 45 08             	mov    0x8(%ebp),%eax
801018d0:	8b 40 0c             	mov    0xc(%eax),%eax
801018d3:	83 e0 01             	and    $0x1,%eax
801018d6:	85 c0                	test   %eax,%eax
801018d8:	75 e0                	jne    801018ba <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
801018da:	8b 45 08             	mov    0x8(%ebp),%eax
801018dd:	8b 40 0c             	mov    0xc(%eax),%eax
801018e0:	83 c8 01             	or     $0x1,%eax
801018e3:	89 c2                	mov    %eax,%edx
801018e5:	8b 45 08             	mov    0x8(%ebp),%eax
801018e8:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
801018eb:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
801018f2:	e8 b0 3e 00 00       	call   801057a7 <release>

  if(!(ip->flags & I_VALID)){
801018f7:	8b 45 08             	mov    0x8(%ebp),%eax
801018fa:	8b 40 0c             	mov    0xc(%eax),%eax
801018fd:	83 e0 02             	and    $0x2,%eax
80101900:	85 c0                	test   %eax,%eax
80101902:	0f 85 ce 00 00 00    	jne    801019d6 <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
80101908:	8b 45 08             	mov    0x8(%ebp),%eax
8010190b:	8b 40 04             	mov    0x4(%eax),%eax
8010190e:	c1 e8 03             	shr    $0x3,%eax
80101911:	8d 50 02             	lea    0x2(%eax),%edx
80101914:	8b 45 08             	mov    0x8(%ebp),%eax
80101917:	8b 00                	mov    (%eax),%eax
80101919:	89 54 24 04          	mov    %edx,0x4(%esp)
8010191d:	89 04 24             	mov    %eax,(%esp)
80101920:	e8 81 e8 ff ff       	call   801001a6 <bread>
80101925:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80101928:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010192b:	8d 50 18             	lea    0x18(%eax),%edx
8010192e:	8b 45 08             	mov    0x8(%ebp),%eax
80101931:	8b 40 04             	mov    0x4(%eax),%eax
80101934:	83 e0 07             	and    $0x7,%eax
80101937:	c1 e0 06             	shl    $0x6,%eax
8010193a:	01 d0                	add    %edx,%eax
8010193c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
8010193f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101942:	0f b7 10             	movzwl (%eax),%edx
80101945:	8b 45 08             	mov    0x8(%ebp),%eax
80101948:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
8010194c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010194f:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101953:	8b 45 08             	mov    0x8(%ebp),%eax
80101956:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
8010195a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010195d:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101961:	8b 45 08             	mov    0x8(%ebp),%eax
80101964:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
80101968:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010196b:	0f b7 50 06          	movzwl 0x6(%eax),%edx
8010196f:	8b 45 08             	mov    0x8(%ebp),%eax
80101972:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
80101976:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101979:	8b 50 08             	mov    0x8(%eax),%edx
8010197c:	8b 45 08             	mov    0x8(%ebp),%eax
8010197f:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101982:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101985:	8d 50 0c             	lea    0xc(%eax),%edx
80101988:	8b 45 08             	mov    0x8(%ebp),%eax
8010198b:	83 c0 1c             	add    $0x1c,%eax
8010198e:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101995:	00 
80101996:	89 54 24 04          	mov    %edx,0x4(%esp)
8010199a:	89 04 24             	mov    %eax,(%esp)
8010199d:	e8 c6 40 00 00       	call   80105a68 <memmove>
    brelse(bp);
801019a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019a5:	89 04 24             	mov    %eax,(%esp)
801019a8:	e8 6a e8 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
801019ad:	8b 45 08             	mov    0x8(%ebp),%eax
801019b0:	8b 40 0c             	mov    0xc(%eax),%eax
801019b3:	83 c8 02             	or     $0x2,%eax
801019b6:	89 c2                	mov    %eax,%edx
801019b8:	8b 45 08             	mov    0x8(%ebp),%eax
801019bb:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
801019be:	8b 45 08             	mov    0x8(%ebp),%eax
801019c1:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801019c5:	66 85 c0             	test   %ax,%ax
801019c8:	75 0c                	jne    801019d6 <ilock+0x14c>
      panic("ilock: no type");
801019ca:	c7 04 24 61 8e 10 80 	movl   $0x80108e61,(%esp)
801019d1:	e8 64 eb ff ff       	call   8010053a <panic>
  }
}
801019d6:	c9                   	leave  
801019d7:	c3                   	ret    

801019d8 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
801019d8:	55                   	push   %ebp
801019d9:	89 e5                	mov    %esp,%ebp
801019db:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
801019de:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801019e2:	74 17                	je     801019fb <iunlock+0x23>
801019e4:	8b 45 08             	mov    0x8(%ebp),%eax
801019e7:	8b 40 0c             	mov    0xc(%eax),%eax
801019ea:	83 e0 01             	and    $0x1,%eax
801019ed:	85 c0                	test   %eax,%eax
801019ef:	74 0a                	je     801019fb <iunlock+0x23>
801019f1:	8b 45 08             	mov    0x8(%ebp),%eax
801019f4:	8b 40 08             	mov    0x8(%eax),%eax
801019f7:	85 c0                	test   %eax,%eax
801019f9:	7f 0c                	jg     80101a07 <iunlock+0x2f>
    panic("iunlock");
801019fb:	c7 04 24 70 8e 10 80 	movl   $0x80108e70,(%esp)
80101a02:	e8 33 eb ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80101a07:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101a0e:	e8 32 3d 00 00       	call   80105745 <acquire>
  ip->flags &= ~I_BUSY;
80101a13:	8b 45 08             	mov    0x8(%ebp),%eax
80101a16:	8b 40 0c             	mov    0xc(%eax),%eax
80101a19:	83 e0 fe             	and    $0xfffffffe,%eax
80101a1c:	89 c2                	mov    %eax,%edx
80101a1e:	8b 45 08             	mov    0x8(%ebp),%eax
80101a21:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80101a24:	8b 45 08             	mov    0x8(%ebp),%eax
80101a27:	89 04 24             	mov    %eax,(%esp)
80101a2a:	e8 71 33 00 00       	call   80104da0 <wakeup>
  release(&icache.lock);
80101a2f:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101a36:	e8 6c 3d 00 00       	call   801057a7 <release>
}
80101a3b:	c9                   	leave  
80101a3c:	c3                   	ret    

80101a3d <iput>:
// to it, free the inode (and its content) on disk.
// All calls to iput() must be inside a transaction in
// case it has to free the inode.
void
iput(struct inode *ip)
{
80101a3d:	55                   	push   %ebp
80101a3e:	89 e5                	mov    %esp,%ebp
80101a40:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101a43:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101a4a:	e8 f6 3c 00 00       	call   80105745 <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101a4f:	8b 45 08             	mov    0x8(%ebp),%eax
80101a52:	8b 40 08             	mov    0x8(%eax),%eax
80101a55:	83 f8 01             	cmp    $0x1,%eax
80101a58:	0f 85 93 00 00 00    	jne    80101af1 <iput+0xb4>
80101a5e:	8b 45 08             	mov    0x8(%ebp),%eax
80101a61:	8b 40 0c             	mov    0xc(%eax),%eax
80101a64:	83 e0 02             	and    $0x2,%eax
80101a67:	85 c0                	test   %eax,%eax
80101a69:	0f 84 82 00 00 00    	je     80101af1 <iput+0xb4>
80101a6f:	8b 45 08             	mov    0x8(%ebp),%eax
80101a72:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101a76:	66 85 c0             	test   %ax,%ax
80101a79:	75 76                	jne    80101af1 <iput+0xb4>
    // inode has no links and no other references: truncate and free.
    if(ip->flags & I_BUSY)
80101a7b:	8b 45 08             	mov    0x8(%ebp),%eax
80101a7e:	8b 40 0c             	mov    0xc(%eax),%eax
80101a81:	83 e0 01             	and    $0x1,%eax
80101a84:	85 c0                	test   %eax,%eax
80101a86:	74 0c                	je     80101a94 <iput+0x57>
      panic("iput busy");
80101a88:	c7 04 24 78 8e 10 80 	movl   $0x80108e78,(%esp)
80101a8f:	e8 a6 ea ff ff       	call   8010053a <panic>
    ip->flags |= I_BUSY;
80101a94:	8b 45 08             	mov    0x8(%ebp),%eax
80101a97:	8b 40 0c             	mov    0xc(%eax),%eax
80101a9a:	83 c8 01             	or     $0x1,%eax
80101a9d:	89 c2                	mov    %eax,%edx
80101a9f:	8b 45 08             	mov    0x8(%ebp),%eax
80101aa2:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101aa5:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101aac:	e8 f6 3c 00 00       	call   801057a7 <release>
    itrunc(ip);
80101ab1:	8b 45 08             	mov    0x8(%ebp),%eax
80101ab4:	89 04 24             	mov    %eax,(%esp)
80101ab7:	e8 7d 01 00 00       	call   80101c39 <itrunc>
    ip->type = 0;
80101abc:	8b 45 08             	mov    0x8(%ebp),%eax
80101abf:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101ac5:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac8:	89 04 24             	mov    %eax,(%esp)
80101acb:	e8 fe fb ff ff       	call   801016ce <iupdate>
    acquire(&icache.lock);
80101ad0:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101ad7:	e8 69 3c 00 00       	call   80105745 <acquire>
    ip->flags = 0;
80101adc:	8b 45 08             	mov    0x8(%ebp),%eax
80101adf:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101ae6:	8b 45 08             	mov    0x8(%ebp),%eax
80101ae9:	89 04 24             	mov    %eax,(%esp)
80101aec:	e8 af 32 00 00       	call   80104da0 <wakeup>
  }
  ip->ref--;
80101af1:	8b 45 08             	mov    0x8(%ebp),%eax
80101af4:	8b 40 08             	mov    0x8(%eax),%eax
80101af7:	8d 50 ff             	lea    -0x1(%eax),%edx
80101afa:	8b 45 08             	mov    0x8(%ebp),%eax
80101afd:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101b00:	c7 04 24 80 22 11 80 	movl   $0x80112280,(%esp)
80101b07:	e8 9b 3c 00 00       	call   801057a7 <release>
}
80101b0c:	c9                   	leave  
80101b0d:	c3                   	ret    

80101b0e <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101b0e:	55                   	push   %ebp
80101b0f:	89 e5                	mov    %esp,%ebp
80101b11:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101b14:	8b 45 08             	mov    0x8(%ebp),%eax
80101b17:	89 04 24             	mov    %eax,(%esp)
80101b1a:	e8 b9 fe ff ff       	call   801019d8 <iunlock>
  iput(ip);
80101b1f:	8b 45 08             	mov    0x8(%ebp),%eax
80101b22:	89 04 24             	mov    %eax,(%esp)
80101b25:	e8 13 ff ff ff       	call   80101a3d <iput>
}
80101b2a:	c9                   	leave  
80101b2b:	c3                   	ret    

80101b2c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101b2c:	55                   	push   %ebp
80101b2d:	89 e5                	mov    %esp,%ebp
80101b2f:	53                   	push   %ebx
80101b30:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101b33:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101b37:	77 3e                	ja     80101b77 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101b39:	8b 45 08             	mov    0x8(%ebp),%eax
80101b3c:	8b 55 0c             	mov    0xc(%ebp),%edx
80101b3f:	83 c2 04             	add    $0x4,%edx
80101b42:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101b46:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b49:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101b4d:	75 20                	jne    80101b6f <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101b4f:	8b 45 08             	mov    0x8(%ebp),%eax
80101b52:	8b 00                	mov    (%eax),%eax
80101b54:	89 04 24             	mov    %eax,(%esp)
80101b57:	e8 5b f8 ff ff       	call   801013b7 <balloc>
80101b5c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b5f:	8b 45 08             	mov    0x8(%ebp),%eax
80101b62:	8b 55 0c             	mov    0xc(%ebp),%edx
80101b65:	8d 4a 04             	lea    0x4(%edx),%ecx
80101b68:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b6b:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101b6f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b72:	e9 bc 00 00 00       	jmp    80101c33 <bmap+0x107>
  }
  bn -= NDIRECT;
80101b77:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101b7b:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101b7f:	0f 87 a2 00 00 00    	ja     80101c27 <bmap+0xfb>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101b85:	8b 45 08             	mov    0x8(%ebp),%eax
80101b88:	8b 40 4c             	mov    0x4c(%eax),%eax
80101b8b:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b8e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101b92:	75 19                	jne    80101bad <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101b94:	8b 45 08             	mov    0x8(%ebp),%eax
80101b97:	8b 00                	mov    (%eax),%eax
80101b99:	89 04 24             	mov    %eax,(%esp)
80101b9c:	e8 16 f8 ff ff       	call   801013b7 <balloc>
80101ba1:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101ba4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ba7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101baa:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80101bad:	8b 45 08             	mov    0x8(%ebp),%eax
80101bb0:	8b 00                	mov    (%eax),%eax
80101bb2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101bb5:	89 54 24 04          	mov    %edx,0x4(%esp)
80101bb9:	89 04 24             	mov    %eax,(%esp)
80101bbc:	e8 e5 e5 ff ff       	call   801001a6 <bread>
80101bc1:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101bc4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101bc7:	83 c0 18             	add    $0x18,%eax
80101bca:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101bcd:	8b 45 0c             	mov    0xc(%ebp),%eax
80101bd0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101bd7:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101bda:	01 d0                	add    %edx,%eax
80101bdc:	8b 00                	mov    (%eax),%eax
80101bde:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101be1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101be5:	75 30                	jne    80101c17 <bmap+0xeb>
      a[bn] = addr = balloc(ip->dev);
80101be7:	8b 45 0c             	mov    0xc(%ebp),%eax
80101bea:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101bf1:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101bf4:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80101bf7:	8b 45 08             	mov    0x8(%ebp),%eax
80101bfa:	8b 00                	mov    (%eax),%eax
80101bfc:	89 04 24             	mov    %eax,(%esp)
80101bff:	e8 b3 f7 ff ff       	call   801013b7 <balloc>
80101c04:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c07:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c0a:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101c0c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c0f:	89 04 24             	mov    %eax,(%esp)
80101c12:	e8 4e 1b 00 00       	call   80103765 <log_write>
    }
    brelse(bp);
80101c17:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c1a:	89 04 24             	mov    %eax,(%esp)
80101c1d:	e8 f5 e5 ff ff       	call   80100217 <brelse>
    return addr;
80101c22:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c25:	eb 0c                	jmp    80101c33 <bmap+0x107>
  }

  panic("bmap: out of range");
80101c27:	c7 04 24 82 8e 10 80 	movl   $0x80108e82,(%esp)
80101c2e:	e8 07 e9 ff ff       	call   8010053a <panic>
}
80101c33:	83 c4 24             	add    $0x24,%esp
80101c36:	5b                   	pop    %ebx
80101c37:	5d                   	pop    %ebp
80101c38:	c3                   	ret    

80101c39 <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101c39:	55                   	push   %ebp
80101c3a:	89 e5                	mov    %esp,%ebp
80101c3c:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101c3f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101c46:	eb 44                	jmp    80101c8c <itrunc+0x53>
    if(ip->addrs[i]){
80101c48:	8b 45 08             	mov    0x8(%ebp),%eax
80101c4b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c4e:	83 c2 04             	add    $0x4,%edx
80101c51:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101c55:	85 c0                	test   %eax,%eax
80101c57:	74 2f                	je     80101c88 <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101c59:	8b 45 08             	mov    0x8(%ebp),%eax
80101c5c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c5f:	83 c2 04             	add    $0x4,%edx
80101c62:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101c66:	8b 45 08             	mov    0x8(%ebp),%eax
80101c69:	8b 00                	mov    (%eax),%eax
80101c6b:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c6f:	89 04 24             	mov    %eax,(%esp)
80101c72:	e8 8e f8 ff ff       	call   80101505 <bfree>
      ip->addrs[i] = 0;
80101c77:	8b 45 08             	mov    0x8(%ebp),%eax
80101c7a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c7d:	83 c2 04             	add    $0x4,%edx
80101c80:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101c87:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101c88:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101c8c:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101c90:	7e b6                	jle    80101c48 <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80101c92:	8b 45 08             	mov    0x8(%ebp),%eax
80101c95:	8b 40 4c             	mov    0x4c(%eax),%eax
80101c98:	85 c0                	test   %eax,%eax
80101c9a:	0f 84 9b 00 00 00    	je     80101d3b <itrunc+0x102>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101ca0:	8b 45 08             	mov    0x8(%ebp),%eax
80101ca3:	8b 50 4c             	mov    0x4c(%eax),%edx
80101ca6:	8b 45 08             	mov    0x8(%ebp),%eax
80101ca9:	8b 00                	mov    (%eax),%eax
80101cab:	89 54 24 04          	mov    %edx,0x4(%esp)
80101caf:	89 04 24             	mov    %eax,(%esp)
80101cb2:	e8 ef e4 ff ff       	call   801001a6 <bread>
80101cb7:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101cba:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101cbd:	83 c0 18             	add    $0x18,%eax
80101cc0:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101cc3:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101cca:	eb 3b                	jmp    80101d07 <itrunc+0xce>
      if(a[j])
80101ccc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ccf:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101cd6:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101cd9:	01 d0                	add    %edx,%eax
80101cdb:	8b 00                	mov    (%eax),%eax
80101cdd:	85 c0                	test   %eax,%eax
80101cdf:	74 22                	je     80101d03 <itrunc+0xca>
        bfree(ip->dev, a[j]);
80101ce1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ce4:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101ceb:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101cee:	01 d0                	add    %edx,%eax
80101cf0:	8b 10                	mov    (%eax),%edx
80101cf2:	8b 45 08             	mov    0x8(%ebp),%eax
80101cf5:	8b 00                	mov    (%eax),%eax
80101cf7:	89 54 24 04          	mov    %edx,0x4(%esp)
80101cfb:	89 04 24             	mov    %eax,(%esp)
80101cfe:	e8 02 f8 ff ff       	call   80101505 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101d03:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101d07:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d0a:	83 f8 7f             	cmp    $0x7f,%eax
80101d0d:	76 bd                	jbe    80101ccc <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101d0f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d12:	89 04 24             	mov    %eax,(%esp)
80101d15:	e8 fd e4 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101d1a:	8b 45 08             	mov    0x8(%ebp),%eax
80101d1d:	8b 50 4c             	mov    0x4c(%eax),%edx
80101d20:	8b 45 08             	mov    0x8(%ebp),%eax
80101d23:	8b 00                	mov    (%eax),%eax
80101d25:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d29:	89 04 24             	mov    %eax,(%esp)
80101d2c:	e8 d4 f7 ff ff       	call   80101505 <bfree>
    ip->addrs[NDIRECT] = 0;
80101d31:	8b 45 08             	mov    0x8(%ebp),%eax
80101d34:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80101d3b:	8b 45 08             	mov    0x8(%ebp),%eax
80101d3e:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80101d45:	8b 45 08             	mov    0x8(%ebp),%eax
80101d48:	89 04 24             	mov    %eax,(%esp)
80101d4b:	e8 7e f9 ff ff       	call   801016ce <iupdate>
}
80101d50:	c9                   	leave  
80101d51:	c3                   	ret    

80101d52 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80101d52:	55                   	push   %ebp
80101d53:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101d55:	8b 45 08             	mov    0x8(%ebp),%eax
80101d58:	8b 00                	mov    (%eax),%eax
80101d5a:	89 c2                	mov    %eax,%edx
80101d5c:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d5f:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101d62:	8b 45 08             	mov    0x8(%ebp),%eax
80101d65:	8b 50 04             	mov    0x4(%eax),%edx
80101d68:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d6b:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101d6e:	8b 45 08             	mov    0x8(%ebp),%eax
80101d71:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101d75:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d78:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101d7b:	8b 45 08             	mov    0x8(%ebp),%eax
80101d7e:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101d82:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d85:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101d89:	8b 45 08             	mov    0x8(%ebp),%eax
80101d8c:	8b 50 18             	mov    0x18(%eax),%edx
80101d8f:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d92:	89 50 10             	mov    %edx,0x10(%eax)
}
80101d95:	5d                   	pop    %ebp
80101d96:	c3                   	ret    

80101d97 <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101d97:	55                   	push   %ebp
80101d98:	89 e5                	mov    %esp,%ebp
80101d9a:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101d9d:	8b 45 08             	mov    0x8(%ebp),%eax
80101da0:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101da4:	66 83 f8 03          	cmp    $0x3,%ax
80101da8:	75 6d                	jne    80101e17 <readi+0x80>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101daa:	8b 45 08             	mov    0x8(%ebp),%eax
80101dad:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101db1:	66 85 c0             	test   %ax,%ax
80101db4:	78 23                	js     80101dd9 <readi+0x42>
80101db6:	8b 45 08             	mov    0x8(%ebp),%eax
80101db9:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101dbd:	66 83 f8 09          	cmp    $0x9,%ax
80101dc1:	7f 16                	jg     80101dd9 <readi+0x42>
80101dc3:	8b 45 08             	mov    0x8(%ebp),%eax
80101dc6:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101dca:	98                   	cwtl   
80101dcb:	c1 e0 04             	shl    $0x4,%eax
80101dce:	05 e8 21 11 80       	add    $0x801121e8,%eax
80101dd3:	8b 00                	mov    (%eax),%eax
80101dd5:	85 c0                	test   %eax,%eax
80101dd7:	75 0a                	jne    80101de3 <readi+0x4c>
      return -1;
80101dd9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101dde:	e9 23 01 00 00       	jmp    80101f06 <readi+0x16f>
    return devsw[ip->major].read(ip, dst, off, n);
80101de3:	8b 45 08             	mov    0x8(%ebp),%eax
80101de6:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101dea:	98                   	cwtl   
80101deb:	c1 e0 04             	shl    $0x4,%eax
80101dee:	05 e8 21 11 80       	add    $0x801121e8,%eax
80101df3:	8b 00                	mov    (%eax),%eax
80101df5:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101df8:	8b 55 10             	mov    0x10(%ebp),%edx
80101dfb:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101dff:	89 54 24 08          	mov    %edx,0x8(%esp)
80101e03:	8b 55 0c             	mov    0xc(%ebp),%edx
80101e06:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e0a:	8b 55 08             	mov    0x8(%ebp),%edx
80101e0d:	89 14 24             	mov    %edx,(%esp)
80101e10:	ff d0                	call   *%eax
80101e12:	e9 ef 00 00 00       	jmp    80101f06 <readi+0x16f>
  }

  if(off > ip->size || off + n < off)
80101e17:	8b 45 08             	mov    0x8(%ebp),%eax
80101e1a:	8b 40 18             	mov    0x18(%eax),%eax
80101e1d:	3b 45 10             	cmp    0x10(%ebp),%eax
80101e20:	72 0d                	jb     80101e2f <readi+0x98>
80101e22:	8b 45 14             	mov    0x14(%ebp),%eax
80101e25:	8b 55 10             	mov    0x10(%ebp),%edx
80101e28:	01 d0                	add    %edx,%eax
80101e2a:	3b 45 10             	cmp    0x10(%ebp),%eax
80101e2d:	73 0a                	jae    80101e39 <readi+0xa2>
    return -1;
80101e2f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101e34:	e9 cd 00 00 00       	jmp    80101f06 <readi+0x16f>
  if(off + n > ip->size)
80101e39:	8b 45 14             	mov    0x14(%ebp),%eax
80101e3c:	8b 55 10             	mov    0x10(%ebp),%edx
80101e3f:	01 c2                	add    %eax,%edx
80101e41:	8b 45 08             	mov    0x8(%ebp),%eax
80101e44:	8b 40 18             	mov    0x18(%eax),%eax
80101e47:	39 c2                	cmp    %eax,%edx
80101e49:	76 0c                	jbe    80101e57 <readi+0xc0>
    n = ip->size - off;
80101e4b:	8b 45 08             	mov    0x8(%ebp),%eax
80101e4e:	8b 40 18             	mov    0x18(%eax),%eax
80101e51:	2b 45 10             	sub    0x10(%ebp),%eax
80101e54:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101e57:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101e5e:	e9 94 00 00 00       	jmp    80101ef7 <readi+0x160>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101e63:	8b 45 10             	mov    0x10(%ebp),%eax
80101e66:	c1 e8 09             	shr    $0x9,%eax
80101e69:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e6d:	8b 45 08             	mov    0x8(%ebp),%eax
80101e70:	89 04 24             	mov    %eax,(%esp)
80101e73:	e8 b4 fc ff ff       	call   80101b2c <bmap>
80101e78:	8b 55 08             	mov    0x8(%ebp),%edx
80101e7b:	8b 12                	mov    (%edx),%edx
80101e7d:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e81:	89 14 24             	mov    %edx,(%esp)
80101e84:	e8 1d e3 ff ff       	call   801001a6 <bread>
80101e89:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101e8c:	8b 45 10             	mov    0x10(%ebp),%eax
80101e8f:	25 ff 01 00 00       	and    $0x1ff,%eax
80101e94:	89 c2                	mov    %eax,%edx
80101e96:	b8 00 02 00 00       	mov    $0x200,%eax
80101e9b:	29 d0                	sub    %edx,%eax
80101e9d:	89 c2                	mov    %eax,%edx
80101e9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ea2:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101ea5:	29 c1                	sub    %eax,%ecx
80101ea7:	89 c8                	mov    %ecx,%eax
80101ea9:	39 c2                	cmp    %eax,%edx
80101eab:	0f 46 c2             	cmovbe %edx,%eax
80101eae:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80101eb1:	8b 45 10             	mov    0x10(%ebp),%eax
80101eb4:	25 ff 01 00 00       	and    $0x1ff,%eax
80101eb9:	8d 50 10             	lea    0x10(%eax),%edx
80101ebc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ebf:	01 d0                	add    %edx,%eax
80101ec1:	8d 50 08             	lea    0x8(%eax),%edx
80101ec4:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ec7:	89 44 24 08          	mov    %eax,0x8(%esp)
80101ecb:	89 54 24 04          	mov    %edx,0x4(%esp)
80101ecf:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ed2:	89 04 24             	mov    %eax,(%esp)
80101ed5:	e8 8e 3b 00 00       	call   80105a68 <memmove>
    brelse(bp);
80101eda:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101edd:	89 04 24             	mov    %eax,(%esp)
80101ee0:	e8 32 e3 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101ee5:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ee8:	01 45 f4             	add    %eax,-0xc(%ebp)
80101eeb:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101eee:	01 45 10             	add    %eax,0x10(%ebp)
80101ef1:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ef4:	01 45 0c             	add    %eax,0xc(%ebp)
80101ef7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101efa:	3b 45 14             	cmp    0x14(%ebp),%eax
80101efd:	0f 82 60 ff ff ff    	jb     80101e63 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80101f03:	8b 45 14             	mov    0x14(%ebp),%eax
}
80101f06:	c9                   	leave  
80101f07:	c3                   	ret    

80101f08 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80101f08:	55                   	push   %ebp
80101f09:	89 e5                	mov    %esp,%ebp
80101f0b:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101f0e:	8b 45 08             	mov    0x8(%ebp),%eax
80101f11:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101f15:	66 83 f8 03          	cmp    $0x3,%ax
80101f19:	75 66                	jne    80101f81 <writei+0x79>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80101f1b:	8b 45 08             	mov    0x8(%ebp),%eax
80101f1e:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f22:	66 85 c0             	test   %ax,%ax
80101f25:	78 23                	js     80101f4a <writei+0x42>
80101f27:	8b 45 08             	mov    0x8(%ebp),%eax
80101f2a:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f2e:	66 83 f8 09          	cmp    $0x9,%ax
80101f32:	7f 16                	jg     80101f4a <writei+0x42>
80101f34:	8b 45 08             	mov    0x8(%ebp),%eax
80101f37:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f3b:	98                   	cwtl   
80101f3c:	c1 e0 04             	shl    $0x4,%eax
80101f3f:	05 ec 21 11 80       	add    $0x801121ec,%eax
80101f44:	8b 00                	mov    (%eax),%eax
80101f46:	85 c0                	test   %eax,%eax
80101f48:	75 0a                	jne    80101f54 <writei+0x4c>
      return -1;
80101f4a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f4f:	e9 47 01 00 00       	jmp    8010209b <writei+0x193>
    return devsw[ip->major].write(ip, src, n);
80101f54:	8b 45 08             	mov    0x8(%ebp),%eax
80101f57:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f5b:	98                   	cwtl   
80101f5c:	c1 e0 04             	shl    $0x4,%eax
80101f5f:	05 ec 21 11 80       	add    $0x801121ec,%eax
80101f64:	8b 00                	mov    (%eax),%eax
80101f66:	8b 55 14             	mov    0x14(%ebp),%edx
80101f69:	89 54 24 08          	mov    %edx,0x8(%esp)
80101f6d:	8b 55 0c             	mov    0xc(%ebp),%edx
80101f70:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f74:	8b 55 08             	mov    0x8(%ebp),%edx
80101f77:	89 14 24             	mov    %edx,(%esp)
80101f7a:	ff d0                	call   *%eax
80101f7c:	e9 1a 01 00 00       	jmp    8010209b <writei+0x193>
  }

  if(off > ip->size || off + n < off)
80101f81:	8b 45 08             	mov    0x8(%ebp),%eax
80101f84:	8b 40 18             	mov    0x18(%eax),%eax
80101f87:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f8a:	72 0d                	jb     80101f99 <writei+0x91>
80101f8c:	8b 45 14             	mov    0x14(%ebp),%eax
80101f8f:	8b 55 10             	mov    0x10(%ebp),%edx
80101f92:	01 d0                	add    %edx,%eax
80101f94:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f97:	73 0a                	jae    80101fa3 <writei+0x9b>
    return -1;
80101f99:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f9e:	e9 f8 00 00 00       	jmp    8010209b <writei+0x193>
  if(off + n > MAXFILE*BSIZE)
80101fa3:	8b 45 14             	mov    0x14(%ebp),%eax
80101fa6:	8b 55 10             	mov    0x10(%ebp),%edx
80101fa9:	01 d0                	add    %edx,%eax
80101fab:	3d 00 18 01 00       	cmp    $0x11800,%eax
80101fb0:	76 0a                	jbe    80101fbc <writei+0xb4>
    return -1;
80101fb2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101fb7:	e9 df 00 00 00       	jmp    8010209b <writei+0x193>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80101fbc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101fc3:	e9 9f 00 00 00       	jmp    80102067 <writei+0x15f>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101fc8:	8b 45 10             	mov    0x10(%ebp),%eax
80101fcb:	c1 e8 09             	shr    $0x9,%eax
80101fce:	89 44 24 04          	mov    %eax,0x4(%esp)
80101fd2:	8b 45 08             	mov    0x8(%ebp),%eax
80101fd5:	89 04 24             	mov    %eax,(%esp)
80101fd8:	e8 4f fb ff ff       	call   80101b2c <bmap>
80101fdd:	8b 55 08             	mov    0x8(%ebp),%edx
80101fe0:	8b 12                	mov    (%edx),%edx
80101fe2:	89 44 24 04          	mov    %eax,0x4(%esp)
80101fe6:	89 14 24             	mov    %edx,(%esp)
80101fe9:	e8 b8 e1 ff ff       	call   801001a6 <bread>
80101fee:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101ff1:	8b 45 10             	mov    0x10(%ebp),%eax
80101ff4:	25 ff 01 00 00       	and    $0x1ff,%eax
80101ff9:	89 c2                	mov    %eax,%edx
80101ffb:	b8 00 02 00 00       	mov    $0x200,%eax
80102000:	29 d0                	sub    %edx,%eax
80102002:	89 c2                	mov    %eax,%edx
80102004:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102007:	8b 4d 14             	mov    0x14(%ebp),%ecx
8010200a:	29 c1                	sub    %eax,%ecx
8010200c:	89 c8                	mov    %ecx,%eax
8010200e:	39 c2                	cmp    %eax,%edx
80102010:	0f 46 c2             	cmovbe %edx,%eax
80102013:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80102016:	8b 45 10             	mov    0x10(%ebp),%eax
80102019:	25 ff 01 00 00       	and    $0x1ff,%eax
8010201e:	8d 50 10             	lea    0x10(%eax),%edx
80102021:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102024:	01 d0                	add    %edx,%eax
80102026:	8d 50 08             	lea    0x8(%eax),%edx
80102029:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010202c:	89 44 24 08          	mov    %eax,0x8(%esp)
80102030:	8b 45 0c             	mov    0xc(%ebp),%eax
80102033:	89 44 24 04          	mov    %eax,0x4(%esp)
80102037:	89 14 24             	mov    %edx,(%esp)
8010203a:	e8 29 3a 00 00       	call   80105a68 <memmove>
    log_write(bp);
8010203f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102042:	89 04 24             	mov    %eax,(%esp)
80102045:	e8 1b 17 00 00       	call   80103765 <log_write>
    brelse(bp);
8010204a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010204d:	89 04 24             	mov    %eax,(%esp)
80102050:	e8 c2 e1 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102055:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102058:	01 45 f4             	add    %eax,-0xc(%ebp)
8010205b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010205e:	01 45 10             	add    %eax,0x10(%ebp)
80102061:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102064:	01 45 0c             	add    %eax,0xc(%ebp)
80102067:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010206a:	3b 45 14             	cmp    0x14(%ebp),%eax
8010206d:	0f 82 55 ff ff ff    	jb     80101fc8 <writei+0xc0>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
80102073:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80102077:	74 1f                	je     80102098 <writei+0x190>
80102079:	8b 45 08             	mov    0x8(%ebp),%eax
8010207c:	8b 40 18             	mov    0x18(%eax),%eax
8010207f:	3b 45 10             	cmp    0x10(%ebp),%eax
80102082:	73 14                	jae    80102098 <writei+0x190>
    ip->size = off;
80102084:	8b 45 08             	mov    0x8(%ebp),%eax
80102087:	8b 55 10             	mov    0x10(%ebp),%edx
8010208a:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
8010208d:	8b 45 08             	mov    0x8(%ebp),%eax
80102090:	89 04 24             	mov    %eax,(%esp)
80102093:	e8 36 f6 ff ff       	call   801016ce <iupdate>
  }
  return n;
80102098:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010209b:	c9                   	leave  
8010209c:	c3                   	ret    

8010209d <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
8010209d:	55                   	push   %ebp
8010209e:	89 e5                	mov    %esp,%ebp
801020a0:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
801020a3:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801020aa:	00 
801020ab:	8b 45 0c             	mov    0xc(%ebp),%eax
801020ae:	89 44 24 04          	mov    %eax,0x4(%esp)
801020b2:	8b 45 08             	mov    0x8(%ebp),%eax
801020b5:	89 04 24             	mov    %eax,(%esp)
801020b8:	e8 4e 3a 00 00       	call   80105b0b <strncmp>
}
801020bd:	c9                   	leave  
801020be:	c3                   	ret    

801020bf <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
801020bf:	55                   	push   %ebp
801020c0:	89 e5                	mov    %esp,%ebp
801020c2:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;
  struct inode *ip;

  if(dp->type != T_DIR && !IS_DEV_DIR(dp))
801020c5:	8b 45 08             	mov    0x8(%ebp),%eax
801020c8:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801020cc:	66 83 f8 01          	cmp    $0x1,%ax
801020d0:	74 4d                	je     8010211f <dirlookup+0x60>
801020d2:	8b 45 08             	mov    0x8(%ebp),%eax
801020d5:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801020d9:	66 83 f8 03          	cmp    $0x3,%ax
801020dd:	75 34                	jne    80102113 <dirlookup+0x54>
801020df:	8b 45 08             	mov    0x8(%ebp),%eax
801020e2:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801020e6:	98                   	cwtl   
801020e7:	c1 e0 04             	shl    $0x4,%eax
801020ea:	05 e0 21 11 80       	add    $0x801121e0,%eax
801020ef:	8b 00                	mov    (%eax),%eax
801020f1:	85 c0                	test   %eax,%eax
801020f3:	74 1e                	je     80102113 <dirlookup+0x54>
801020f5:	8b 45 08             	mov    0x8(%ebp),%eax
801020f8:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801020fc:	98                   	cwtl   
801020fd:	c1 e0 04             	shl    $0x4,%eax
80102100:	05 e0 21 11 80       	add    $0x801121e0,%eax
80102105:	8b 00                	mov    (%eax),%eax
80102107:	8b 55 08             	mov    0x8(%ebp),%edx
8010210a:	89 14 24             	mov    %edx,(%esp)
8010210d:	ff d0                	call   *%eax
8010210f:	85 c0                	test   %eax,%eax
80102111:	75 0c                	jne    8010211f <dirlookup+0x60>
    panic("dirlookup not DIR");
80102113:	c7 04 24 95 8e 10 80 	movl   $0x80108e95,(%esp)
8010211a:	e8 1b e4 ff ff       	call   8010053a <panic>

  for(off = 0; off < dp->size || dp->type == T_DEV; off += sizeof(de)){
8010211f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102126:	e9 fd 00 00 00       	jmp    80102228 <dirlookup+0x169>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de)) {
8010212b:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102132:	00 
80102133:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102136:	89 44 24 08          	mov    %eax,0x8(%esp)
8010213a:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010213d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102141:	8b 45 08             	mov    0x8(%ebp),%eax
80102144:	89 04 24             	mov    %eax,(%esp)
80102147:	e8 4b fc ff ff       	call   80101d97 <readi>
8010214c:	83 f8 10             	cmp    $0x10,%eax
8010214f:	74 23                	je     80102174 <dirlookup+0xb5>
      if (dp->type == T_DEV)
80102151:	8b 45 08             	mov    0x8(%ebp),%eax
80102154:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102158:	66 83 f8 03          	cmp    $0x3,%ax
8010215c:	75 0a                	jne    80102168 <dirlookup+0xa9>
        return 0;
8010215e:	b8 00 00 00 00       	mov    $0x0,%eax
80102163:	e9 e5 00 00 00       	jmp    8010224d <dirlookup+0x18e>
      else
        panic("dirlink read");
80102168:	c7 04 24 a7 8e 10 80 	movl   $0x80108ea7,(%esp)
8010216f:	e8 c6 e3 ff ff       	call   8010053a <panic>
    }
    if(de.inum == 0)
80102174:	0f b7 45 dc          	movzwl -0x24(%ebp),%eax
80102178:	66 85 c0             	test   %ax,%ax
8010217b:	75 05                	jne    80102182 <dirlookup+0xc3>
      continue;
8010217d:	e9 a2 00 00 00       	jmp    80102224 <dirlookup+0x165>
    if(namecmp(name, de.name) == 0){
80102182:	8d 45 dc             	lea    -0x24(%ebp),%eax
80102185:	83 c0 02             	add    $0x2,%eax
80102188:	89 44 24 04          	mov    %eax,0x4(%esp)
8010218c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010218f:	89 04 24             	mov    %eax,(%esp)
80102192:	e8 06 ff ff ff       	call   8010209d <namecmp>
80102197:	85 c0                	test   %eax,%eax
80102199:	0f 85 85 00 00 00    	jne    80102224 <dirlookup+0x165>
      // entry matches path element
      if(poff)
8010219f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801021a3:	74 08                	je     801021ad <dirlookup+0xee>
        *poff = off;
801021a5:	8b 45 10             	mov    0x10(%ebp),%eax
801021a8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801021ab:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
801021ad:	0f b7 45 dc          	movzwl -0x24(%ebp),%eax
801021b1:	0f b7 c0             	movzwl %ax,%eax
801021b4:	89 45 f0             	mov    %eax,-0x10(%ebp)
      ip = iget(dp->dev, inum);
801021b7:	8b 45 08             	mov    0x8(%ebp),%eax
801021ba:	8b 00                	mov    (%eax),%eax
801021bc:	8b 55 f0             	mov    -0x10(%ebp),%edx
801021bf:	89 54 24 04          	mov    %edx,0x4(%esp)
801021c3:	89 04 24             	mov    %eax,(%esp)
801021c6:	e8 bb f5 ff ff       	call   80101786 <iget>
801021cb:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if (!(ip->flags & I_VALID) && dp->type == T_DEV && devsw[dp->major].iread) {
801021ce:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021d1:	8b 40 0c             	mov    0xc(%eax),%eax
801021d4:	83 e0 02             	and    $0x2,%eax
801021d7:	85 c0                	test   %eax,%eax
801021d9:	75 44                	jne    8010221f <dirlookup+0x160>
801021db:	8b 45 08             	mov    0x8(%ebp),%eax
801021de:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801021e2:	66 83 f8 03          	cmp    $0x3,%ax
801021e6:	75 37                	jne    8010221f <dirlookup+0x160>
801021e8:	8b 45 08             	mov    0x8(%ebp),%eax
801021eb:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801021ef:	98                   	cwtl   
801021f0:	c1 e0 04             	shl    $0x4,%eax
801021f3:	05 e4 21 11 80       	add    $0x801121e4,%eax
801021f8:	8b 00                	mov    (%eax),%eax
801021fa:	85 c0                	test   %eax,%eax
801021fc:	74 21                	je     8010221f <dirlookup+0x160>
        devsw[dp->major].iread(dp, ip);
801021fe:	8b 45 08             	mov    0x8(%ebp),%eax
80102201:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102205:	98                   	cwtl   
80102206:	c1 e0 04             	shl    $0x4,%eax
80102209:	05 e4 21 11 80       	add    $0x801121e4,%eax
8010220e:	8b 00                	mov    (%eax),%eax
80102210:	8b 55 ec             	mov    -0x14(%ebp),%edx
80102213:	89 54 24 04          	mov    %edx,0x4(%esp)
80102217:	8b 55 08             	mov    0x8(%ebp),%edx
8010221a:	89 14 24             	mov    %edx,(%esp)
8010221d:	ff d0                	call   *%eax
      }
      return ip;
8010221f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102222:	eb 29                	jmp    8010224d <dirlookup+0x18e>
  struct inode *ip;

  if(dp->type != T_DIR && !IS_DEV_DIR(dp))
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size || dp->type == T_DEV; off += sizeof(de)){
80102224:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80102228:	8b 45 08             	mov    0x8(%ebp),%eax
8010222b:	8b 40 18             	mov    0x18(%eax),%eax
8010222e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80102231:	0f 87 f4 fe ff ff    	ja     8010212b <dirlookup+0x6c>
80102237:	8b 45 08             	mov    0x8(%ebp),%eax
8010223a:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010223e:	66 83 f8 03          	cmp    $0x3,%ax
80102242:	0f 84 e3 fe ff ff    	je     8010212b <dirlookup+0x6c>
      }
      return ip;
    }
  }

  return 0;
80102248:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010224d:	c9                   	leave  
8010224e:	c3                   	ret    

8010224f <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
8010224f:	55                   	push   %ebp
80102250:	89 e5                	mov    %esp,%ebp
80102252:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
80102255:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010225c:	00 
8010225d:	8b 45 0c             	mov    0xc(%ebp),%eax
80102260:	89 44 24 04          	mov    %eax,0x4(%esp)
80102264:	8b 45 08             	mov    0x8(%ebp),%eax
80102267:	89 04 24             	mov    %eax,(%esp)
8010226a:	e8 50 fe ff ff       	call   801020bf <dirlookup>
8010226f:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102272:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102276:	74 15                	je     8010228d <dirlink+0x3e>
    iput(ip);
80102278:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010227b:	89 04 24             	mov    %eax,(%esp)
8010227e:	e8 ba f7 ff ff       	call   80101a3d <iput>
    return -1;
80102283:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102288:	e9 b7 00 00 00       	jmp    80102344 <dirlink+0xf5>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
8010228d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102294:	eb 46                	jmp    801022dc <dirlink+0x8d>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102296:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102299:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801022a0:	00 
801022a1:	89 44 24 08          	mov    %eax,0x8(%esp)
801022a5:	8d 45 e0             	lea    -0x20(%ebp),%eax
801022a8:	89 44 24 04          	mov    %eax,0x4(%esp)
801022ac:	8b 45 08             	mov    0x8(%ebp),%eax
801022af:	89 04 24             	mov    %eax,(%esp)
801022b2:	e8 e0 fa ff ff       	call   80101d97 <readi>
801022b7:	83 f8 10             	cmp    $0x10,%eax
801022ba:	74 0c                	je     801022c8 <dirlink+0x79>
      panic("dirlink read");
801022bc:	c7 04 24 a7 8e 10 80 	movl   $0x80108ea7,(%esp)
801022c3:	e8 72 e2 ff ff       	call   8010053a <panic>
    if(de.inum == 0)
801022c8:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801022cc:	66 85 c0             	test   %ax,%ax
801022cf:	75 02                	jne    801022d3 <dirlink+0x84>
      break;
801022d1:	eb 16                	jmp    801022e9 <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801022d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022d6:	83 c0 10             	add    $0x10,%eax
801022d9:	89 45 f4             	mov    %eax,-0xc(%ebp)
801022dc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801022df:	8b 45 08             	mov    0x8(%ebp),%eax
801022e2:	8b 40 18             	mov    0x18(%eax),%eax
801022e5:	39 c2                	cmp    %eax,%edx
801022e7:	72 ad                	jb     80102296 <dirlink+0x47>
      panic("dirlink read");
    if(de.inum == 0)
      break;
  }

  strncpy(de.name, name, DIRSIZ);
801022e9:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801022f0:	00 
801022f1:	8b 45 0c             	mov    0xc(%ebp),%eax
801022f4:	89 44 24 04          	mov    %eax,0x4(%esp)
801022f8:	8d 45 e0             	lea    -0x20(%ebp),%eax
801022fb:	83 c0 02             	add    $0x2,%eax
801022fe:	89 04 24             	mov    %eax,(%esp)
80102301:	e8 5b 38 00 00       	call   80105b61 <strncpy>
  de.inum = inum;
80102306:	8b 45 10             	mov    0x10(%ebp),%eax
80102309:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010230d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102310:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102317:	00 
80102318:	89 44 24 08          	mov    %eax,0x8(%esp)
8010231c:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010231f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102323:	8b 45 08             	mov    0x8(%ebp),%eax
80102326:	89 04 24             	mov    %eax,(%esp)
80102329:	e8 da fb ff ff       	call   80101f08 <writei>
8010232e:	83 f8 10             	cmp    $0x10,%eax
80102331:	74 0c                	je     8010233f <dirlink+0xf0>
    panic("dirlink");
80102333:	c7 04 24 b4 8e 10 80 	movl   $0x80108eb4,(%esp)
8010233a:	e8 fb e1 ff ff       	call   8010053a <panic>
  
  return 0;
8010233f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102344:	c9                   	leave  
80102345:	c3                   	ret    

80102346 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80102346:	55                   	push   %ebp
80102347:	89 e5                	mov    %esp,%ebp
80102349:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
8010234c:	eb 04                	jmp    80102352 <skipelem+0xc>
    path++;
8010234e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
80102352:	8b 45 08             	mov    0x8(%ebp),%eax
80102355:	0f b6 00             	movzbl (%eax),%eax
80102358:	3c 2f                	cmp    $0x2f,%al
8010235a:	74 f2                	je     8010234e <skipelem+0x8>
    path++;
  if(*path == 0)
8010235c:	8b 45 08             	mov    0x8(%ebp),%eax
8010235f:	0f b6 00             	movzbl (%eax),%eax
80102362:	84 c0                	test   %al,%al
80102364:	75 0a                	jne    80102370 <skipelem+0x2a>
    return 0;
80102366:	b8 00 00 00 00       	mov    $0x0,%eax
8010236b:	e9 86 00 00 00       	jmp    801023f6 <skipelem+0xb0>
  s = path;
80102370:	8b 45 08             	mov    0x8(%ebp),%eax
80102373:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
80102376:	eb 04                	jmp    8010237c <skipelem+0x36>
    path++;
80102378:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
8010237c:	8b 45 08             	mov    0x8(%ebp),%eax
8010237f:	0f b6 00             	movzbl (%eax),%eax
80102382:	3c 2f                	cmp    $0x2f,%al
80102384:	74 0a                	je     80102390 <skipelem+0x4a>
80102386:	8b 45 08             	mov    0x8(%ebp),%eax
80102389:	0f b6 00             	movzbl (%eax),%eax
8010238c:	84 c0                	test   %al,%al
8010238e:	75 e8                	jne    80102378 <skipelem+0x32>
    path++;
  len = path - s;
80102390:	8b 55 08             	mov    0x8(%ebp),%edx
80102393:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102396:	29 c2                	sub    %eax,%edx
80102398:	89 d0                	mov    %edx,%eax
8010239a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
8010239d:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
801023a1:	7e 1c                	jle    801023bf <skipelem+0x79>
    memmove(name, s, DIRSIZ);
801023a3:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801023aa:	00 
801023ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023ae:	89 44 24 04          	mov    %eax,0x4(%esp)
801023b2:	8b 45 0c             	mov    0xc(%ebp),%eax
801023b5:	89 04 24             	mov    %eax,(%esp)
801023b8:	e8 ab 36 00 00       	call   80105a68 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801023bd:	eb 2a                	jmp    801023e9 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
801023bf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023c2:	89 44 24 08          	mov    %eax,0x8(%esp)
801023c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023c9:	89 44 24 04          	mov    %eax,0x4(%esp)
801023cd:	8b 45 0c             	mov    0xc(%ebp),%eax
801023d0:	89 04 24             	mov    %eax,(%esp)
801023d3:	e8 90 36 00 00       	call   80105a68 <memmove>
    name[len] = 0;
801023d8:	8b 55 f0             	mov    -0x10(%ebp),%edx
801023db:	8b 45 0c             	mov    0xc(%ebp),%eax
801023de:	01 d0                	add    %edx,%eax
801023e0:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
801023e3:	eb 04                	jmp    801023e9 <skipelem+0xa3>
    path++;
801023e5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801023e9:	8b 45 08             	mov    0x8(%ebp),%eax
801023ec:	0f b6 00             	movzbl (%eax),%eax
801023ef:	3c 2f                	cmp    $0x2f,%al
801023f1:	74 f2                	je     801023e5 <skipelem+0x9f>
    path++;
  return path;
801023f3:	8b 45 08             	mov    0x8(%ebp),%eax
}
801023f6:	c9                   	leave  
801023f7:	c3                   	ret    

801023f8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
801023f8:	55                   	push   %ebp
801023f9:	89 e5                	mov    %esp,%ebp
801023fb:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
801023fe:	8b 45 08             	mov    0x8(%ebp),%eax
80102401:	0f b6 00             	movzbl (%eax),%eax
80102404:	3c 2f                	cmp    $0x2f,%al
80102406:	75 1c                	jne    80102424 <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
80102408:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010240f:	00 
80102410:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102417:	e8 6a f3 ff ff       	call   80101786 <iget>
8010241c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
8010241f:	e9 f0 00 00 00       	jmp    80102514 <namex+0x11c>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
80102424:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010242a:	8b 40 78             	mov    0x78(%eax),%eax
8010242d:	89 04 24             	mov    %eax,(%esp)
80102430:	e8 23 f4 ff ff       	call   80101858 <idup>
80102435:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
80102438:	e9 d7 00 00 00       	jmp    80102514 <namex+0x11c>
    ilock(ip);
8010243d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102440:	89 04 24             	mov    %eax,(%esp)
80102443:	e8 42 f4 ff ff       	call   8010188a <ilock>
    if(ip->type != T_DIR && !IS_DEV_DIR(ip)){
80102448:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010244b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010244f:	66 83 f8 01          	cmp    $0x1,%ax
80102453:	74 56                	je     801024ab <namex+0xb3>
80102455:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102458:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010245c:	66 83 f8 03          	cmp    $0x3,%ax
80102460:	75 34                	jne    80102496 <namex+0x9e>
80102462:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102465:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102469:	98                   	cwtl   
8010246a:	c1 e0 04             	shl    $0x4,%eax
8010246d:	05 e0 21 11 80       	add    $0x801121e0,%eax
80102472:	8b 00                	mov    (%eax),%eax
80102474:	85 c0                	test   %eax,%eax
80102476:	74 1e                	je     80102496 <namex+0x9e>
80102478:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010247b:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010247f:	98                   	cwtl   
80102480:	c1 e0 04             	shl    $0x4,%eax
80102483:	05 e0 21 11 80       	add    $0x801121e0,%eax
80102488:	8b 00                	mov    (%eax),%eax
8010248a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010248d:	89 14 24             	mov    %edx,(%esp)
80102490:	ff d0                	call   *%eax
80102492:	85 c0                	test   %eax,%eax
80102494:	75 15                	jne    801024ab <namex+0xb3>
      iunlockput(ip);
80102496:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102499:	89 04 24             	mov    %eax,(%esp)
8010249c:	e8 6d f6 ff ff       	call   80101b0e <iunlockput>
      return 0;
801024a1:	b8 00 00 00 00       	mov    $0x0,%eax
801024a6:	e9 a3 00 00 00       	jmp    8010254e <namex+0x156>
    }
    if(nameiparent && *path == '\0'){
801024ab:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801024af:	74 1d                	je     801024ce <namex+0xd6>
801024b1:	8b 45 08             	mov    0x8(%ebp),%eax
801024b4:	0f b6 00             	movzbl (%eax),%eax
801024b7:	84 c0                	test   %al,%al
801024b9:	75 13                	jne    801024ce <namex+0xd6>
      // Stop one level early.
      iunlock(ip);
801024bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024be:	89 04 24             	mov    %eax,(%esp)
801024c1:	e8 12 f5 ff ff       	call   801019d8 <iunlock>
      return ip;
801024c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024c9:	e9 80 00 00 00       	jmp    8010254e <namex+0x156>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
801024ce:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801024d5:	00 
801024d6:	8b 45 10             	mov    0x10(%ebp),%eax
801024d9:	89 44 24 04          	mov    %eax,0x4(%esp)
801024dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024e0:	89 04 24             	mov    %eax,(%esp)
801024e3:	e8 d7 fb ff ff       	call   801020bf <dirlookup>
801024e8:	89 45 f0             	mov    %eax,-0x10(%ebp)
801024eb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801024ef:	75 12                	jne    80102503 <namex+0x10b>
      iunlockput(ip);
801024f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024f4:	89 04 24             	mov    %eax,(%esp)
801024f7:	e8 12 f6 ff ff       	call   80101b0e <iunlockput>
      return 0;
801024fc:	b8 00 00 00 00       	mov    $0x0,%eax
80102501:	eb 4b                	jmp    8010254e <namex+0x156>
    }
    iunlockput(ip);
80102503:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102506:	89 04 24             	mov    %eax,(%esp)
80102509:	e8 00 f6 ff ff       	call   80101b0e <iunlockput>
    ip = next;
8010250e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102511:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102514:	8b 45 10             	mov    0x10(%ebp),%eax
80102517:	89 44 24 04          	mov    %eax,0x4(%esp)
8010251b:	8b 45 08             	mov    0x8(%ebp),%eax
8010251e:	89 04 24             	mov    %eax,(%esp)
80102521:	e8 20 fe ff ff       	call   80102346 <skipelem>
80102526:	89 45 08             	mov    %eax,0x8(%ebp)
80102529:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010252d:	0f 85 0a ff ff ff    	jne    8010243d <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
80102533:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102537:	74 12                	je     8010254b <namex+0x153>
    iput(ip);
80102539:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010253c:	89 04 24             	mov    %eax,(%esp)
8010253f:	e8 f9 f4 ff ff       	call   80101a3d <iput>
    return 0;
80102544:	b8 00 00 00 00       	mov    $0x0,%eax
80102549:	eb 03                	jmp    8010254e <namex+0x156>
  }
  return ip;
8010254b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010254e:	c9                   	leave  
8010254f:	c3                   	ret    

80102550 <namei>:

struct inode*
namei(char *path)
{
80102550:	55                   	push   %ebp
80102551:	89 e5                	mov    %esp,%ebp
80102553:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80102556:	8d 45 ea             	lea    -0x16(%ebp),%eax
80102559:	89 44 24 08          	mov    %eax,0x8(%esp)
8010255d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102564:	00 
80102565:	8b 45 08             	mov    0x8(%ebp),%eax
80102568:	89 04 24             	mov    %eax,(%esp)
8010256b:	e8 88 fe ff ff       	call   801023f8 <namex>
}
80102570:	c9                   	leave  
80102571:	c3                   	ret    

80102572 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80102572:	55                   	push   %ebp
80102573:	89 e5                	mov    %esp,%ebp
80102575:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
80102578:	8b 45 0c             	mov    0xc(%ebp),%eax
8010257b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010257f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102586:	00 
80102587:	8b 45 08             	mov    0x8(%ebp),%eax
8010258a:	89 04 24             	mov    %eax,(%esp)
8010258d:	e8 66 fe ff ff       	call   801023f8 <namex>
}
80102592:	c9                   	leave  
80102593:	c3                   	ret    

80102594 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102594:	55                   	push   %ebp
80102595:	89 e5                	mov    %esp,%ebp
80102597:	83 ec 14             	sub    $0x14,%esp
8010259a:	8b 45 08             	mov    0x8(%ebp),%eax
8010259d:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801025a1:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801025a5:	89 c2                	mov    %eax,%edx
801025a7:	ec                   	in     (%dx),%al
801025a8:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801025ab:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801025af:	c9                   	leave  
801025b0:	c3                   	ret    

801025b1 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
801025b1:	55                   	push   %ebp
801025b2:	89 e5                	mov    %esp,%ebp
801025b4:	57                   	push   %edi
801025b5:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
801025b6:	8b 55 08             	mov    0x8(%ebp),%edx
801025b9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801025bc:	8b 45 10             	mov    0x10(%ebp),%eax
801025bf:	89 cb                	mov    %ecx,%ebx
801025c1:	89 df                	mov    %ebx,%edi
801025c3:	89 c1                	mov    %eax,%ecx
801025c5:	fc                   	cld    
801025c6:	f3 6d                	rep insl (%dx),%es:(%edi)
801025c8:	89 c8                	mov    %ecx,%eax
801025ca:	89 fb                	mov    %edi,%ebx
801025cc:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801025cf:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
801025d2:	5b                   	pop    %ebx
801025d3:	5f                   	pop    %edi
801025d4:	5d                   	pop    %ebp
801025d5:	c3                   	ret    

801025d6 <outb>:

static inline void
outb(ushort port, uchar data)
{
801025d6:	55                   	push   %ebp
801025d7:	89 e5                	mov    %esp,%ebp
801025d9:	83 ec 08             	sub    $0x8,%esp
801025dc:	8b 55 08             	mov    0x8(%ebp),%edx
801025df:	8b 45 0c             	mov    0xc(%ebp),%eax
801025e2:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801025e6:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801025e9:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801025ed:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801025f1:	ee                   	out    %al,(%dx)
}
801025f2:	c9                   	leave  
801025f3:	c3                   	ret    

801025f4 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
801025f4:	55                   	push   %ebp
801025f5:	89 e5                	mov    %esp,%ebp
801025f7:	56                   	push   %esi
801025f8:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
801025f9:	8b 55 08             	mov    0x8(%ebp),%edx
801025fc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801025ff:	8b 45 10             	mov    0x10(%ebp),%eax
80102602:	89 cb                	mov    %ecx,%ebx
80102604:	89 de                	mov    %ebx,%esi
80102606:	89 c1                	mov    %eax,%ecx
80102608:	fc                   	cld    
80102609:	f3 6f                	rep outsl %ds:(%esi),(%dx)
8010260b:	89 c8                	mov    %ecx,%eax
8010260d:	89 f3                	mov    %esi,%ebx
8010260f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102612:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
80102615:	5b                   	pop    %ebx
80102616:	5e                   	pop    %esi
80102617:	5d                   	pop    %ebp
80102618:	c3                   	ret    

80102619 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80102619:	55                   	push   %ebp
8010261a:	89 e5                	mov    %esp,%ebp
8010261c:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
8010261f:	90                   	nop
80102620:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102627:	e8 68 ff ff ff       	call   80102594 <inb>
8010262c:	0f b6 c0             	movzbl %al,%eax
8010262f:	89 45 fc             	mov    %eax,-0x4(%ebp)
80102632:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102635:	25 c0 00 00 00       	and    $0xc0,%eax
8010263a:	83 f8 40             	cmp    $0x40,%eax
8010263d:	75 e1                	jne    80102620 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
8010263f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102643:	74 11                	je     80102656 <idewait+0x3d>
80102645:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102648:	83 e0 21             	and    $0x21,%eax
8010264b:	85 c0                	test   %eax,%eax
8010264d:	74 07                	je     80102656 <idewait+0x3d>
    return -1;
8010264f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102654:	eb 05                	jmp    8010265b <idewait+0x42>
  return 0;
80102656:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010265b:	c9                   	leave  
8010265c:	c3                   	ret    

8010265d <ideinit>:

void
ideinit(void)
{
8010265d:	55                   	push   %ebp
8010265e:	89 e5                	mov    %esp,%ebp
80102660:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
80102663:	c7 44 24 04 bc 8e 10 	movl   $0x80108ebc,0x4(%esp)
8010266a:	80 
8010266b:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102672:	e8 ad 30 00 00       	call   80105724 <initlock>
  picenable(IRQ_IDE);
80102677:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
8010267e:	e8 80 18 00 00       	call   80103f03 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102683:	a1 80 39 11 80       	mov    0x80113980,%eax
80102688:	83 e8 01             	sub    $0x1,%eax
8010268b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010268f:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102696:	e8 0c 04 00 00       	call   80102aa7 <ioapicenable>
  idewait(0);
8010269b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801026a2:	e8 72 ff ff ff       	call   80102619 <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
801026a7:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
801026ae:	00 
801026af:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801026b6:	e8 1b ff ff ff       	call   801025d6 <outb>
  for(i=0; i<1000; i++){
801026bb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801026c2:	eb 20                	jmp    801026e4 <ideinit+0x87>
    if(inb(0x1f7) != 0){
801026c4:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801026cb:	e8 c4 fe ff ff       	call   80102594 <inb>
801026d0:	84 c0                	test   %al,%al
801026d2:	74 0c                	je     801026e0 <ideinit+0x83>
      havedisk1 = 1;
801026d4:	c7 05 38 c6 10 80 01 	movl   $0x1,0x8010c638
801026db:	00 00 00 
      break;
801026de:	eb 0d                	jmp    801026ed <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
801026e0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801026e4:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
801026eb:	7e d7                	jle    801026c4 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
801026ed:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
801026f4:	00 
801026f5:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801026fc:	e8 d5 fe ff ff       	call   801025d6 <outb>
}
80102701:	c9                   	leave  
80102702:	c3                   	ret    

80102703 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80102703:	55                   	push   %ebp
80102704:	89 e5                	mov    %esp,%ebp
80102706:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
80102709:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010270d:	75 0c                	jne    8010271b <idestart+0x18>
    panic("idestart");
8010270f:	c7 04 24 c0 8e 10 80 	movl   $0x80108ec0,(%esp)
80102716:	e8 1f de ff ff       	call   8010053a <panic>

  idewait(0);
8010271b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102722:	e8 f2 fe ff ff       	call   80102619 <idewait>
  outb(0x3f6, 0);  // generate interrupt
80102727:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010272e:	00 
8010272f:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
80102736:	e8 9b fe ff ff       	call   801025d6 <outb>
  outb(0x1f2, 1);  // number of sectors
8010273b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102742:	00 
80102743:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
8010274a:	e8 87 fe ff ff       	call   801025d6 <outb>
  outb(0x1f3, b->sector & 0xff);
8010274f:	8b 45 08             	mov    0x8(%ebp),%eax
80102752:	8b 40 08             	mov    0x8(%eax),%eax
80102755:	0f b6 c0             	movzbl %al,%eax
80102758:	89 44 24 04          	mov    %eax,0x4(%esp)
8010275c:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80102763:	e8 6e fe ff ff       	call   801025d6 <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
80102768:	8b 45 08             	mov    0x8(%ebp),%eax
8010276b:	8b 40 08             	mov    0x8(%eax),%eax
8010276e:	c1 e8 08             	shr    $0x8,%eax
80102771:	0f b6 c0             	movzbl %al,%eax
80102774:	89 44 24 04          	mov    %eax,0x4(%esp)
80102778:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
8010277f:	e8 52 fe ff ff       	call   801025d6 <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
80102784:	8b 45 08             	mov    0x8(%ebp),%eax
80102787:	8b 40 08             	mov    0x8(%eax),%eax
8010278a:	c1 e8 10             	shr    $0x10,%eax
8010278d:	0f b6 c0             	movzbl %al,%eax
80102790:	89 44 24 04          	mov    %eax,0x4(%esp)
80102794:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
8010279b:	e8 36 fe ff ff       	call   801025d6 <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
801027a0:	8b 45 08             	mov    0x8(%ebp),%eax
801027a3:	8b 40 04             	mov    0x4(%eax),%eax
801027a6:	83 e0 01             	and    $0x1,%eax
801027a9:	c1 e0 04             	shl    $0x4,%eax
801027ac:	89 c2                	mov    %eax,%edx
801027ae:	8b 45 08             	mov    0x8(%ebp),%eax
801027b1:	8b 40 08             	mov    0x8(%eax),%eax
801027b4:	c1 e8 18             	shr    $0x18,%eax
801027b7:	83 e0 0f             	and    $0xf,%eax
801027ba:	09 d0                	or     %edx,%eax
801027bc:	83 c8 e0             	or     $0xffffffe0,%eax
801027bf:	0f b6 c0             	movzbl %al,%eax
801027c2:	89 44 24 04          	mov    %eax,0x4(%esp)
801027c6:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801027cd:	e8 04 fe ff ff       	call   801025d6 <outb>
  if(b->flags & B_DIRTY){
801027d2:	8b 45 08             	mov    0x8(%ebp),%eax
801027d5:	8b 00                	mov    (%eax),%eax
801027d7:	83 e0 04             	and    $0x4,%eax
801027da:	85 c0                	test   %eax,%eax
801027dc:	74 34                	je     80102812 <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
801027de:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
801027e5:	00 
801027e6:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801027ed:	e8 e4 fd ff ff       	call   801025d6 <outb>
    outsl(0x1f0, b->data, 512/4);
801027f2:	8b 45 08             	mov    0x8(%ebp),%eax
801027f5:	83 c0 18             	add    $0x18,%eax
801027f8:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801027ff:	00 
80102800:	89 44 24 04          	mov    %eax,0x4(%esp)
80102804:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
8010280b:	e8 e4 fd ff ff       	call   801025f4 <outsl>
80102810:	eb 14                	jmp    80102826 <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
80102812:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80102819:	00 
8010281a:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102821:	e8 b0 fd ff ff       	call   801025d6 <outb>
  }
}
80102826:	c9                   	leave  
80102827:	c3                   	ret    

80102828 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80102828:	55                   	push   %ebp
80102829:	89 e5                	mov    %esp,%ebp
8010282b:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
8010282e:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102835:	e8 0b 2f 00 00       	call   80105745 <acquire>
  if((b = idequeue) == 0){
8010283a:	a1 34 c6 10 80       	mov    0x8010c634,%eax
8010283f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102842:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102846:	75 11                	jne    80102859 <ideintr+0x31>
    release(&idelock);
80102848:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
8010284f:	e8 53 2f 00 00       	call   801057a7 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80102854:	e9 90 00 00 00       	jmp    801028e9 <ideintr+0xc1>
  }
  idequeue = b->qnext;
80102859:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010285c:	8b 40 14             	mov    0x14(%eax),%eax
8010285f:	a3 34 c6 10 80       	mov    %eax,0x8010c634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80102864:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102867:	8b 00                	mov    (%eax),%eax
80102869:	83 e0 04             	and    $0x4,%eax
8010286c:	85 c0                	test   %eax,%eax
8010286e:	75 2e                	jne    8010289e <ideintr+0x76>
80102870:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102877:	e8 9d fd ff ff       	call   80102619 <idewait>
8010287c:	85 c0                	test   %eax,%eax
8010287e:	78 1e                	js     8010289e <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
80102880:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102883:	83 c0 18             	add    $0x18,%eax
80102886:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010288d:	00 
8010288e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102892:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102899:	e8 13 fd ff ff       	call   801025b1 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
8010289e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028a1:	8b 00                	mov    (%eax),%eax
801028a3:	83 c8 02             	or     $0x2,%eax
801028a6:	89 c2                	mov    %eax,%edx
801028a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028ab:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
801028ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028b0:	8b 00                	mov    (%eax),%eax
801028b2:	83 e0 fb             	and    $0xfffffffb,%eax
801028b5:	89 c2                	mov    %eax,%edx
801028b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028ba:	89 10                	mov    %edx,(%eax)
  wakeup(b);
801028bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028bf:	89 04 24             	mov    %eax,(%esp)
801028c2:	e8 d9 24 00 00       	call   80104da0 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
801028c7:	a1 34 c6 10 80       	mov    0x8010c634,%eax
801028cc:	85 c0                	test   %eax,%eax
801028ce:	74 0d                	je     801028dd <ideintr+0xb5>
    idestart(idequeue);
801028d0:	a1 34 c6 10 80       	mov    0x8010c634,%eax
801028d5:	89 04 24             	mov    %eax,(%esp)
801028d8:	e8 26 fe ff ff       	call   80102703 <idestart>

  release(&idelock);
801028dd:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
801028e4:	e8 be 2e 00 00       	call   801057a7 <release>
}
801028e9:	c9                   	leave  
801028ea:	c3                   	ret    

801028eb <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
801028eb:	55                   	push   %ebp
801028ec:	89 e5                	mov    %esp,%ebp
801028ee:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
801028f1:	8b 45 08             	mov    0x8(%ebp),%eax
801028f4:	8b 00                	mov    (%eax),%eax
801028f6:	83 e0 01             	and    $0x1,%eax
801028f9:	85 c0                	test   %eax,%eax
801028fb:	75 0c                	jne    80102909 <iderw+0x1e>
    panic("iderw: buf not busy");
801028fd:	c7 04 24 c9 8e 10 80 	movl   $0x80108ec9,(%esp)
80102904:	e8 31 dc ff ff       	call   8010053a <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80102909:	8b 45 08             	mov    0x8(%ebp),%eax
8010290c:	8b 00                	mov    (%eax),%eax
8010290e:	83 e0 06             	and    $0x6,%eax
80102911:	83 f8 02             	cmp    $0x2,%eax
80102914:	75 0c                	jne    80102922 <iderw+0x37>
    panic("iderw: nothing to do");
80102916:	c7 04 24 dd 8e 10 80 	movl   $0x80108edd,(%esp)
8010291d:	e8 18 dc ff ff       	call   8010053a <panic>
  if(b->dev != 0 && !havedisk1)
80102922:	8b 45 08             	mov    0x8(%ebp),%eax
80102925:	8b 40 04             	mov    0x4(%eax),%eax
80102928:	85 c0                	test   %eax,%eax
8010292a:	74 15                	je     80102941 <iderw+0x56>
8010292c:	a1 38 c6 10 80       	mov    0x8010c638,%eax
80102931:	85 c0                	test   %eax,%eax
80102933:	75 0c                	jne    80102941 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
80102935:	c7 04 24 f2 8e 10 80 	movl   $0x80108ef2,(%esp)
8010293c:	e8 f9 db ff ff       	call   8010053a <panic>

  acquire(&idelock);  //DOC:acquire-lock
80102941:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102948:	e8 f8 2d 00 00       	call   80105745 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
8010294d:	8b 45 08             	mov    0x8(%ebp),%eax
80102950:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80102957:	c7 45 f4 34 c6 10 80 	movl   $0x8010c634,-0xc(%ebp)
8010295e:	eb 0b                	jmp    8010296b <iderw+0x80>
80102960:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102963:	8b 00                	mov    (%eax),%eax
80102965:	83 c0 14             	add    $0x14,%eax
80102968:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010296b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010296e:	8b 00                	mov    (%eax),%eax
80102970:	85 c0                	test   %eax,%eax
80102972:	75 ec                	jne    80102960 <iderw+0x75>
    ;
  *pp = b;
80102974:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102977:	8b 55 08             	mov    0x8(%ebp),%edx
8010297a:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
8010297c:	a1 34 c6 10 80       	mov    0x8010c634,%eax
80102981:	3b 45 08             	cmp    0x8(%ebp),%eax
80102984:	75 0d                	jne    80102993 <iderw+0xa8>
    idestart(b);
80102986:	8b 45 08             	mov    0x8(%ebp),%eax
80102989:	89 04 24             	mov    %eax,(%esp)
8010298c:	e8 72 fd ff ff       	call   80102703 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102991:	eb 15                	jmp    801029a8 <iderw+0xbd>
80102993:	eb 13                	jmp    801029a8 <iderw+0xbd>
    sleep(b, &idelock);
80102995:	c7 44 24 04 00 c6 10 	movl   $0x8010c600,0x4(%esp)
8010299c:	80 
8010299d:	8b 45 08             	mov    0x8(%ebp),%eax
801029a0:	89 04 24             	mov    %eax,(%esp)
801029a3:	e8 1c 23 00 00       	call   80104cc4 <sleep>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
801029a8:	8b 45 08             	mov    0x8(%ebp),%eax
801029ab:	8b 00                	mov    (%eax),%eax
801029ad:	83 e0 06             	and    $0x6,%eax
801029b0:	83 f8 02             	cmp    $0x2,%eax
801029b3:	75 e0                	jne    80102995 <iderw+0xaa>
    sleep(b, &idelock);
  }

  release(&idelock);
801029b5:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
801029bc:	e8 e6 2d 00 00       	call   801057a7 <release>
}
801029c1:	c9                   	leave  
801029c2:	c3                   	ret    

801029c3 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
801029c3:	55                   	push   %ebp
801029c4:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
801029c6:	a1 54 32 11 80       	mov    0x80113254,%eax
801029cb:	8b 55 08             	mov    0x8(%ebp),%edx
801029ce:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
801029d0:	a1 54 32 11 80       	mov    0x80113254,%eax
801029d5:	8b 40 10             	mov    0x10(%eax),%eax
}
801029d8:	5d                   	pop    %ebp
801029d9:	c3                   	ret    

801029da <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
801029da:	55                   	push   %ebp
801029db:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
801029dd:	a1 54 32 11 80       	mov    0x80113254,%eax
801029e2:	8b 55 08             	mov    0x8(%ebp),%edx
801029e5:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
801029e7:	a1 54 32 11 80       	mov    0x80113254,%eax
801029ec:	8b 55 0c             	mov    0xc(%ebp),%edx
801029ef:	89 50 10             	mov    %edx,0x10(%eax)
}
801029f2:	5d                   	pop    %ebp
801029f3:	c3                   	ret    

801029f4 <ioapicinit>:

void
ioapicinit(void)
{
801029f4:	55                   	push   %ebp
801029f5:	89 e5                	mov    %esp,%ebp
801029f7:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
801029fa:	a1 84 33 11 80       	mov    0x80113384,%eax
801029ff:	85 c0                	test   %eax,%eax
80102a01:	75 05                	jne    80102a08 <ioapicinit+0x14>
    return;
80102a03:	e9 9d 00 00 00       	jmp    80102aa5 <ioapicinit+0xb1>

  ioapic = (volatile struct ioapic*)IOAPIC;
80102a08:	c7 05 54 32 11 80 00 	movl   $0xfec00000,0x80113254
80102a0f:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80102a12:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102a19:	e8 a5 ff ff ff       	call   801029c3 <ioapicread>
80102a1e:	c1 e8 10             	shr    $0x10,%eax
80102a21:	25 ff 00 00 00       	and    $0xff,%eax
80102a26:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80102a29:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102a30:	e8 8e ff ff ff       	call   801029c3 <ioapicread>
80102a35:	c1 e8 18             	shr    $0x18,%eax
80102a38:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80102a3b:	0f b6 05 80 33 11 80 	movzbl 0x80113380,%eax
80102a42:	0f b6 c0             	movzbl %al,%eax
80102a45:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102a48:	74 0c                	je     80102a56 <ioapicinit+0x62>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102a4a:	c7 04 24 10 8f 10 80 	movl   $0x80108f10,(%esp)
80102a51:	e8 4a d9 ff ff       	call   801003a0 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102a56:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102a5d:	eb 3e                	jmp    80102a9d <ioapicinit+0xa9>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80102a5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a62:	83 c0 20             	add    $0x20,%eax
80102a65:	0d 00 00 01 00       	or     $0x10000,%eax
80102a6a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102a6d:	83 c2 08             	add    $0x8,%edx
80102a70:	01 d2                	add    %edx,%edx
80102a72:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a76:	89 14 24             	mov    %edx,(%esp)
80102a79:	e8 5c ff ff ff       	call   801029da <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102a7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a81:	83 c0 08             	add    $0x8,%eax
80102a84:	01 c0                	add    %eax,%eax
80102a86:	83 c0 01             	add    $0x1,%eax
80102a89:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102a90:	00 
80102a91:	89 04 24             	mov    %eax,(%esp)
80102a94:	e8 41 ff ff ff       	call   801029da <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102a99:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102a9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102aa0:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80102aa3:	7e ba                	jle    80102a5f <ioapicinit+0x6b>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80102aa5:	c9                   	leave  
80102aa6:	c3                   	ret    

80102aa7 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102aa7:	55                   	push   %ebp
80102aa8:	89 e5                	mov    %esp,%ebp
80102aaa:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80102aad:	a1 84 33 11 80       	mov    0x80113384,%eax
80102ab2:	85 c0                	test   %eax,%eax
80102ab4:	75 02                	jne    80102ab8 <ioapicenable+0x11>
    return;
80102ab6:	eb 37                	jmp    80102aef <ioapicenable+0x48>

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80102ab8:	8b 45 08             	mov    0x8(%ebp),%eax
80102abb:	83 c0 20             	add    $0x20,%eax
80102abe:	8b 55 08             	mov    0x8(%ebp),%edx
80102ac1:	83 c2 08             	add    $0x8,%edx
80102ac4:	01 d2                	add    %edx,%edx
80102ac6:	89 44 24 04          	mov    %eax,0x4(%esp)
80102aca:	89 14 24             	mov    %edx,(%esp)
80102acd:	e8 08 ff ff ff       	call   801029da <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80102ad2:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ad5:	c1 e0 18             	shl    $0x18,%eax
80102ad8:	8b 55 08             	mov    0x8(%ebp),%edx
80102adb:	83 c2 08             	add    $0x8,%edx
80102ade:	01 d2                	add    %edx,%edx
80102ae0:	83 c2 01             	add    $0x1,%edx
80102ae3:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ae7:	89 14 24             	mov    %edx,(%esp)
80102aea:	e8 eb fe ff ff       	call   801029da <ioapicwrite>
}
80102aef:	c9                   	leave  
80102af0:	c3                   	ret    

80102af1 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80102af1:	55                   	push   %ebp
80102af2:	89 e5                	mov    %esp,%ebp
80102af4:	8b 45 08             	mov    0x8(%ebp),%eax
80102af7:	05 00 00 00 80       	add    $0x80000000,%eax
80102afc:	5d                   	pop    %ebp
80102afd:	c3                   	ret    

80102afe <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80102afe:	55                   	push   %ebp
80102aff:	89 e5                	mov    %esp,%ebp
80102b01:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80102b04:	c7 44 24 04 42 8f 10 	movl   $0x80108f42,0x4(%esp)
80102b0b:	80 
80102b0c:	c7 04 24 60 32 11 80 	movl   $0x80113260,(%esp)
80102b13:	e8 0c 2c 00 00       	call   80105724 <initlock>
  kmem.use_lock = 0;
80102b18:	c7 05 94 32 11 80 00 	movl   $0x0,0x80113294
80102b1f:	00 00 00 
  freerange(vstart, vend);
80102b22:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b25:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b29:	8b 45 08             	mov    0x8(%ebp),%eax
80102b2c:	89 04 24             	mov    %eax,(%esp)
80102b2f:	e8 26 00 00 00       	call   80102b5a <freerange>
}
80102b34:	c9                   	leave  
80102b35:	c3                   	ret    

80102b36 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102b36:	55                   	push   %ebp
80102b37:	89 e5                	mov    %esp,%ebp
80102b39:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80102b3c:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b3f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b43:	8b 45 08             	mov    0x8(%ebp),%eax
80102b46:	89 04 24             	mov    %eax,(%esp)
80102b49:	e8 0c 00 00 00       	call   80102b5a <freerange>
  kmem.use_lock = 1;
80102b4e:	c7 05 94 32 11 80 01 	movl   $0x1,0x80113294
80102b55:	00 00 00 
}
80102b58:	c9                   	leave  
80102b59:	c3                   	ret    

80102b5a <freerange>:

void
freerange(void *vstart, void *vend)
{
80102b5a:	55                   	push   %ebp
80102b5b:	89 e5                	mov    %esp,%ebp
80102b5d:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102b60:	8b 45 08             	mov    0x8(%ebp),%eax
80102b63:	05 ff 0f 00 00       	add    $0xfff,%eax
80102b68:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102b6d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102b70:	eb 12                	jmp    80102b84 <freerange+0x2a>
    kfree(p);
80102b72:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b75:	89 04 24             	mov    %eax,(%esp)
80102b78:	e8 16 00 00 00       	call   80102b93 <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102b7d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102b84:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b87:	05 00 10 00 00       	add    $0x1000,%eax
80102b8c:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102b8f:	76 e1                	jbe    80102b72 <freerange+0x18>
    kfree(p);
}
80102b91:	c9                   	leave  
80102b92:	c3                   	ret    

80102b93 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102b93:	55                   	push   %ebp
80102b94:	89 e5                	mov    %esp,%ebp
80102b96:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80102b99:	8b 45 08             	mov    0x8(%ebp),%eax
80102b9c:	25 ff 0f 00 00       	and    $0xfff,%eax
80102ba1:	85 c0                	test   %eax,%eax
80102ba3:	75 1b                	jne    80102bc0 <kfree+0x2d>
80102ba5:	81 7d 08 7c 7b 11 80 	cmpl   $0x80117b7c,0x8(%ebp)
80102bac:	72 12                	jb     80102bc0 <kfree+0x2d>
80102bae:	8b 45 08             	mov    0x8(%ebp),%eax
80102bb1:	89 04 24             	mov    %eax,(%esp)
80102bb4:	e8 38 ff ff ff       	call   80102af1 <v2p>
80102bb9:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102bbe:	76 0c                	jbe    80102bcc <kfree+0x39>
    panic("kfree");
80102bc0:	c7 04 24 47 8f 10 80 	movl   $0x80108f47,(%esp)
80102bc7:	e8 6e d9 ff ff       	call   8010053a <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102bcc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102bd3:	00 
80102bd4:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102bdb:	00 
80102bdc:	8b 45 08             	mov    0x8(%ebp),%eax
80102bdf:	89 04 24             	mov    %eax,(%esp)
80102be2:	e8 b2 2d 00 00       	call   80105999 <memset>

  if(kmem.use_lock)
80102be7:	a1 94 32 11 80       	mov    0x80113294,%eax
80102bec:	85 c0                	test   %eax,%eax
80102bee:	74 0c                	je     80102bfc <kfree+0x69>
    acquire(&kmem.lock);
80102bf0:	c7 04 24 60 32 11 80 	movl   $0x80113260,(%esp)
80102bf7:	e8 49 2b 00 00       	call   80105745 <acquire>
  r = (struct run*)v;
80102bfc:	8b 45 08             	mov    0x8(%ebp),%eax
80102bff:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102c02:	8b 15 98 32 11 80    	mov    0x80113298,%edx
80102c08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c0b:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102c0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c10:	a3 98 32 11 80       	mov    %eax,0x80113298
  if(kmem.use_lock)
80102c15:	a1 94 32 11 80       	mov    0x80113294,%eax
80102c1a:	85 c0                	test   %eax,%eax
80102c1c:	74 0c                	je     80102c2a <kfree+0x97>
    release(&kmem.lock);
80102c1e:	c7 04 24 60 32 11 80 	movl   $0x80113260,(%esp)
80102c25:	e8 7d 2b 00 00       	call   801057a7 <release>
}
80102c2a:	c9                   	leave  
80102c2b:	c3                   	ret    

80102c2c <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102c2c:	55                   	push   %ebp
80102c2d:	89 e5                	mov    %esp,%ebp
80102c2f:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80102c32:	a1 94 32 11 80       	mov    0x80113294,%eax
80102c37:	85 c0                	test   %eax,%eax
80102c39:	74 0c                	je     80102c47 <kalloc+0x1b>
    acquire(&kmem.lock);
80102c3b:	c7 04 24 60 32 11 80 	movl   $0x80113260,(%esp)
80102c42:	e8 fe 2a 00 00       	call   80105745 <acquire>
  r = kmem.freelist;
80102c47:	a1 98 32 11 80       	mov    0x80113298,%eax
80102c4c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102c4f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102c53:	74 0a                	je     80102c5f <kalloc+0x33>
    kmem.freelist = r->next;
80102c55:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c58:	8b 00                	mov    (%eax),%eax
80102c5a:	a3 98 32 11 80       	mov    %eax,0x80113298
  if(kmem.use_lock)
80102c5f:	a1 94 32 11 80       	mov    0x80113294,%eax
80102c64:	85 c0                	test   %eax,%eax
80102c66:	74 0c                	je     80102c74 <kalloc+0x48>
    release(&kmem.lock);
80102c68:	c7 04 24 60 32 11 80 	movl   $0x80113260,(%esp)
80102c6f:	e8 33 2b 00 00       	call   801057a7 <release>
  return (char*)r;
80102c74:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102c77:	c9                   	leave  
80102c78:	c3                   	ret    

80102c79 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102c79:	55                   	push   %ebp
80102c7a:	89 e5                	mov    %esp,%ebp
80102c7c:	83 ec 14             	sub    $0x14,%esp
80102c7f:	8b 45 08             	mov    0x8(%ebp),%eax
80102c82:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102c86:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102c8a:	89 c2                	mov    %eax,%edx
80102c8c:	ec                   	in     (%dx),%al
80102c8d:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102c90:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102c94:	c9                   	leave  
80102c95:	c3                   	ret    

80102c96 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102c96:	55                   	push   %ebp
80102c97:	89 e5                	mov    %esp,%ebp
80102c99:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102c9c:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102ca3:	e8 d1 ff ff ff       	call   80102c79 <inb>
80102ca8:	0f b6 c0             	movzbl %al,%eax
80102cab:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102cae:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102cb1:	83 e0 01             	and    $0x1,%eax
80102cb4:	85 c0                	test   %eax,%eax
80102cb6:	75 0a                	jne    80102cc2 <kbdgetc+0x2c>
    return -1;
80102cb8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102cbd:	e9 25 01 00 00       	jmp    80102de7 <kbdgetc+0x151>
  data = inb(KBDATAP);
80102cc2:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80102cc9:	e8 ab ff ff ff       	call   80102c79 <inb>
80102cce:	0f b6 c0             	movzbl %al,%eax
80102cd1:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102cd4:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102cdb:	75 17                	jne    80102cf4 <kbdgetc+0x5e>
    shift |= E0ESC;
80102cdd:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102ce2:	83 c8 40             	or     $0x40,%eax
80102ce5:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
    return 0;
80102cea:	b8 00 00 00 00       	mov    $0x0,%eax
80102cef:	e9 f3 00 00 00       	jmp    80102de7 <kbdgetc+0x151>
  } else if(data & 0x80){
80102cf4:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102cf7:	25 80 00 00 00       	and    $0x80,%eax
80102cfc:	85 c0                	test   %eax,%eax
80102cfe:	74 45                	je     80102d45 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102d00:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102d05:	83 e0 40             	and    $0x40,%eax
80102d08:	85 c0                	test   %eax,%eax
80102d0a:	75 08                	jne    80102d14 <kbdgetc+0x7e>
80102d0c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d0f:	83 e0 7f             	and    $0x7f,%eax
80102d12:	eb 03                	jmp    80102d17 <kbdgetc+0x81>
80102d14:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d17:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102d1a:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d1d:	05 20 a0 10 80       	add    $0x8010a020,%eax
80102d22:	0f b6 00             	movzbl (%eax),%eax
80102d25:	83 c8 40             	or     $0x40,%eax
80102d28:	0f b6 c0             	movzbl %al,%eax
80102d2b:	f7 d0                	not    %eax
80102d2d:	89 c2                	mov    %eax,%edx
80102d2f:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102d34:	21 d0                	and    %edx,%eax
80102d36:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
    return 0;
80102d3b:	b8 00 00 00 00       	mov    $0x0,%eax
80102d40:	e9 a2 00 00 00       	jmp    80102de7 <kbdgetc+0x151>
  } else if(shift & E0ESC){
80102d45:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102d4a:	83 e0 40             	and    $0x40,%eax
80102d4d:	85 c0                	test   %eax,%eax
80102d4f:	74 14                	je     80102d65 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102d51:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102d58:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102d5d:	83 e0 bf             	and    $0xffffffbf,%eax
80102d60:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
  }

  shift |= shiftcode[data];
80102d65:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d68:	05 20 a0 10 80       	add    $0x8010a020,%eax
80102d6d:	0f b6 00             	movzbl (%eax),%eax
80102d70:	0f b6 d0             	movzbl %al,%edx
80102d73:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102d78:	09 d0                	or     %edx,%eax
80102d7a:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
  shift ^= togglecode[data];
80102d7f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d82:	05 20 a1 10 80       	add    $0x8010a120,%eax
80102d87:	0f b6 00             	movzbl (%eax),%eax
80102d8a:	0f b6 d0             	movzbl %al,%edx
80102d8d:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102d92:	31 d0                	xor    %edx,%eax
80102d94:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
  c = charcode[shift & (CTL | SHIFT)][data];
80102d99:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102d9e:	83 e0 03             	and    $0x3,%eax
80102da1:	8b 14 85 20 a5 10 80 	mov    -0x7fef5ae0(,%eax,4),%edx
80102da8:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102dab:	01 d0                	add    %edx,%eax
80102dad:	0f b6 00             	movzbl (%eax),%eax
80102db0:	0f b6 c0             	movzbl %al,%eax
80102db3:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102db6:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102dbb:	83 e0 08             	and    $0x8,%eax
80102dbe:	85 c0                	test   %eax,%eax
80102dc0:	74 22                	je     80102de4 <kbdgetc+0x14e>
    if('a' <= c && c <= 'z')
80102dc2:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102dc6:	76 0c                	jbe    80102dd4 <kbdgetc+0x13e>
80102dc8:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102dcc:	77 06                	ja     80102dd4 <kbdgetc+0x13e>
      c += 'A' - 'a';
80102dce:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102dd2:	eb 10                	jmp    80102de4 <kbdgetc+0x14e>
    else if('A' <= c && c <= 'Z')
80102dd4:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102dd8:	76 0a                	jbe    80102de4 <kbdgetc+0x14e>
80102dda:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102dde:	77 04                	ja     80102de4 <kbdgetc+0x14e>
      c += 'a' - 'A';
80102de0:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102de4:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102de7:	c9                   	leave  
80102de8:	c3                   	ret    

80102de9 <kbdintr>:

void
kbdintr(void)
{
80102de9:	55                   	push   %ebp
80102dea:	89 e5                	mov    %esp,%ebp
80102dec:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80102def:	c7 04 24 96 2c 10 80 	movl   $0x80102c96,(%esp)
80102df6:	e8 b2 d9 ff ff       	call   801007ad <consoleintr>
}
80102dfb:	c9                   	leave  
80102dfc:	c3                   	ret    

80102dfd <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102dfd:	55                   	push   %ebp
80102dfe:	89 e5                	mov    %esp,%ebp
80102e00:	83 ec 14             	sub    $0x14,%esp
80102e03:	8b 45 08             	mov    0x8(%ebp),%eax
80102e06:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102e0a:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102e0e:	89 c2                	mov    %eax,%edx
80102e10:	ec                   	in     (%dx),%al
80102e11:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102e14:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102e18:	c9                   	leave  
80102e19:	c3                   	ret    

80102e1a <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80102e1a:	55                   	push   %ebp
80102e1b:	89 e5                	mov    %esp,%ebp
80102e1d:	83 ec 08             	sub    $0x8,%esp
80102e20:	8b 55 08             	mov    0x8(%ebp),%edx
80102e23:	8b 45 0c             	mov    0xc(%ebp),%eax
80102e26:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102e2a:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102e2d:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102e31:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102e35:	ee                   	out    %al,(%dx)
}
80102e36:	c9                   	leave  
80102e37:	c3                   	ret    

80102e38 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80102e38:	55                   	push   %ebp
80102e39:	89 e5                	mov    %esp,%ebp
80102e3b:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80102e3e:	9c                   	pushf  
80102e3f:	58                   	pop    %eax
80102e40:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80102e43:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80102e46:	c9                   	leave  
80102e47:	c3                   	ret    

80102e48 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102e48:	55                   	push   %ebp
80102e49:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102e4b:	a1 9c 32 11 80       	mov    0x8011329c,%eax
80102e50:	8b 55 08             	mov    0x8(%ebp),%edx
80102e53:	c1 e2 02             	shl    $0x2,%edx
80102e56:	01 c2                	add    %eax,%edx
80102e58:	8b 45 0c             	mov    0xc(%ebp),%eax
80102e5b:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102e5d:	a1 9c 32 11 80       	mov    0x8011329c,%eax
80102e62:	83 c0 20             	add    $0x20,%eax
80102e65:	8b 00                	mov    (%eax),%eax
}
80102e67:	5d                   	pop    %ebp
80102e68:	c3                   	ret    

80102e69 <lapicinit>:
//PAGEBREAK!

void
lapicinit(void)
{
80102e69:	55                   	push   %ebp
80102e6a:	89 e5                	mov    %esp,%ebp
80102e6c:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80102e6f:	a1 9c 32 11 80       	mov    0x8011329c,%eax
80102e74:	85 c0                	test   %eax,%eax
80102e76:	75 05                	jne    80102e7d <lapicinit+0x14>
    return;
80102e78:	e9 43 01 00 00       	jmp    80102fc0 <lapicinit+0x157>

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102e7d:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80102e84:	00 
80102e85:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80102e8c:	e8 b7 ff ff ff       	call   80102e48 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102e91:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80102e98:	00 
80102e99:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80102ea0:	e8 a3 ff ff ff       	call   80102e48 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102ea5:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80102eac:	00 
80102ead:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102eb4:	e8 8f ff ff ff       	call   80102e48 <lapicw>
  lapicw(TICR, 10000000); 
80102eb9:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80102ec0:	00 
80102ec1:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80102ec8:	e8 7b ff ff ff       	call   80102e48 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102ecd:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102ed4:	00 
80102ed5:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80102edc:	e8 67 ff ff ff       	call   80102e48 <lapicw>
  lapicw(LINT1, MASKED);
80102ee1:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102ee8:	00 
80102ee9:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80102ef0:	e8 53 ff ff ff       	call   80102e48 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102ef5:	a1 9c 32 11 80       	mov    0x8011329c,%eax
80102efa:	83 c0 30             	add    $0x30,%eax
80102efd:	8b 00                	mov    (%eax),%eax
80102eff:	c1 e8 10             	shr    $0x10,%eax
80102f02:	0f b6 c0             	movzbl %al,%eax
80102f05:	83 f8 03             	cmp    $0x3,%eax
80102f08:	76 14                	jbe    80102f1e <lapicinit+0xb5>
    lapicw(PCINT, MASKED);
80102f0a:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102f11:	00 
80102f12:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80102f19:	e8 2a ff ff ff       	call   80102e48 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102f1e:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80102f25:	00 
80102f26:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80102f2d:	e8 16 ff ff ff       	call   80102e48 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80102f32:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f39:	00 
80102f3a:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102f41:	e8 02 ff ff ff       	call   80102e48 <lapicw>
  lapicw(ESR, 0);
80102f46:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f4d:	00 
80102f4e:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102f55:	e8 ee fe ff ff       	call   80102e48 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80102f5a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f61:	00 
80102f62:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102f69:	e8 da fe ff ff       	call   80102e48 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80102f6e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f75:	00 
80102f76:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102f7d:	e8 c6 fe ff ff       	call   80102e48 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102f82:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80102f89:	00 
80102f8a:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102f91:	e8 b2 fe ff ff       	call   80102e48 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102f96:	90                   	nop
80102f97:	a1 9c 32 11 80       	mov    0x8011329c,%eax
80102f9c:	05 00 03 00 00       	add    $0x300,%eax
80102fa1:	8b 00                	mov    (%eax),%eax
80102fa3:	25 00 10 00 00       	and    $0x1000,%eax
80102fa8:	85 c0                	test   %eax,%eax
80102faa:	75 eb                	jne    80102f97 <lapicinit+0x12e>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80102fac:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102fb3:	00 
80102fb4:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80102fbb:	e8 88 fe ff ff       	call   80102e48 <lapicw>
}
80102fc0:	c9                   	leave  
80102fc1:	c3                   	ret    

80102fc2 <cpunum>:

int
cpunum(void)
{
80102fc2:	55                   	push   %ebp
80102fc3:	89 e5                	mov    %esp,%ebp
80102fc5:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80102fc8:	e8 6b fe ff ff       	call   80102e38 <readeflags>
80102fcd:	25 00 02 00 00       	and    $0x200,%eax
80102fd2:	85 c0                	test   %eax,%eax
80102fd4:	74 25                	je     80102ffb <cpunum+0x39>
    static int n;
    if(n++ == 0)
80102fd6:	a1 40 c6 10 80       	mov    0x8010c640,%eax
80102fdb:	8d 50 01             	lea    0x1(%eax),%edx
80102fde:	89 15 40 c6 10 80    	mov    %edx,0x8010c640
80102fe4:	85 c0                	test   %eax,%eax
80102fe6:	75 13                	jne    80102ffb <cpunum+0x39>
      cprintf("cpu called from %x with interrupts enabled\n",
80102fe8:	8b 45 04             	mov    0x4(%ebp),%eax
80102feb:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fef:	c7 04 24 50 8f 10 80 	movl   $0x80108f50,(%esp)
80102ff6:	e8 a5 d3 ff ff       	call   801003a0 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80102ffb:	a1 9c 32 11 80       	mov    0x8011329c,%eax
80103000:	85 c0                	test   %eax,%eax
80103002:	74 0f                	je     80103013 <cpunum+0x51>
    return lapic[ID]>>24;
80103004:	a1 9c 32 11 80       	mov    0x8011329c,%eax
80103009:	83 c0 20             	add    $0x20,%eax
8010300c:	8b 00                	mov    (%eax),%eax
8010300e:	c1 e8 18             	shr    $0x18,%eax
80103011:	eb 05                	jmp    80103018 <cpunum+0x56>
  return 0;
80103013:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103018:	c9                   	leave  
80103019:	c3                   	ret    

8010301a <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
8010301a:	55                   	push   %ebp
8010301b:	89 e5                	mov    %esp,%ebp
8010301d:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80103020:	a1 9c 32 11 80       	mov    0x8011329c,%eax
80103025:	85 c0                	test   %eax,%eax
80103027:	74 14                	je     8010303d <lapiceoi+0x23>
    lapicw(EOI, 0);
80103029:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103030:	00 
80103031:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103038:	e8 0b fe ff ff       	call   80102e48 <lapicw>
}
8010303d:	c9                   	leave  
8010303e:	c3                   	ret    

8010303f <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
8010303f:	55                   	push   %ebp
80103040:	89 e5                	mov    %esp,%ebp
}
80103042:	5d                   	pop    %ebp
80103043:	c3                   	ret    

80103044 <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
80103044:	55                   	push   %ebp
80103045:	89 e5                	mov    %esp,%ebp
80103047:	83 ec 1c             	sub    $0x1c,%esp
8010304a:	8b 45 08             	mov    0x8(%ebp),%eax
8010304d:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
80103050:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80103057:	00 
80103058:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
8010305f:	e8 b6 fd ff ff       	call   80102e1a <outb>
  outb(CMOS_PORT+1, 0x0A);
80103064:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
8010306b:	00 
8010306c:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80103073:	e8 a2 fd ff ff       	call   80102e1a <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80103078:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
8010307f:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103082:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80103087:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010308a:	8d 50 02             	lea    0x2(%eax),%edx
8010308d:	8b 45 0c             	mov    0xc(%ebp),%eax
80103090:	c1 e8 04             	shr    $0x4,%eax
80103093:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80103096:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
8010309a:	c1 e0 18             	shl    $0x18,%eax
8010309d:	89 44 24 04          	mov    %eax,0x4(%esp)
801030a1:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801030a8:	e8 9b fd ff ff       	call   80102e48 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801030ad:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
801030b4:	00 
801030b5:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801030bc:	e8 87 fd ff ff       	call   80102e48 <lapicw>
  microdelay(200);
801030c1:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801030c8:	e8 72 ff ff ff       	call   8010303f <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
801030cd:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
801030d4:	00 
801030d5:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801030dc:	e8 67 fd ff ff       	call   80102e48 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
801030e1:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
801030e8:	e8 52 ff ff ff       	call   8010303f <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801030ed:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801030f4:	eb 40                	jmp    80103136 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
801030f6:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801030fa:	c1 e0 18             	shl    $0x18,%eax
801030fd:	89 44 24 04          	mov    %eax,0x4(%esp)
80103101:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103108:	e8 3b fd ff ff       	call   80102e48 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
8010310d:	8b 45 0c             	mov    0xc(%ebp),%eax
80103110:	c1 e8 0c             	shr    $0xc,%eax
80103113:	80 cc 06             	or     $0x6,%ah
80103116:	89 44 24 04          	mov    %eax,0x4(%esp)
8010311a:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103121:	e8 22 fd ff ff       	call   80102e48 <lapicw>
    microdelay(200);
80103126:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010312d:	e8 0d ff ff ff       	call   8010303f <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103132:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103136:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
8010313a:	7e ba                	jle    801030f6 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
8010313c:	c9                   	leave  
8010313d:	c3                   	ret    

8010313e <cmos_read>:
#define DAY     0x07
#define MONTH   0x08
#define YEAR    0x09

static uint cmos_read(uint reg)
{
8010313e:	55                   	push   %ebp
8010313f:	89 e5                	mov    %esp,%ebp
80103141:	83 ec 08             	sub    $0x8,%esp
  outb(CMOS_PORT,  reg);
80103144:	8b 45 08             	mov    0x8(%ebp),%eax
80103147:	0f b6 c0             	movzbl %al,%eax
8010314a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010314e:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80103155:	e8 c0 fc ff ff       	call   80102e1a <outb>
  microdelay(200);
8010315a:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103161:	e8 d9 fe ff ff       	call   8010303f <microdelay>

  return inb(CMOS_RETURN);
80103166:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
8010316d:	e8 8b fc ff ff       	call   80102dfd <inb>
80103172:	0f b6 c0             	movzbl %al,%eax
}
80103175:	c9                   	leave  
80103176:	c3                   	ret    

80103177 <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
80103177:	55                   	push   %ebp
80103178:	89 e5                	mov    %esp,%ebp
8010317a:	83 ec 04             	sub    $0x4,%esp
  r->second = cmos_read(SECS);
8010317d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80103184:	e8 b5 ff ff ff       	call   8010313e <cmos_read>
80103189:	8b 55 08             	mov    0x8(%ebp),%edx
8010318c:	89 02                	mov    %eax,(%edx)
  r->minute = cmos_read(MINS);
8010318e:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80103195:	e8 a4 ff ff ff       	call   8010313e <cmos_read>
8010319a:	8b 55 08             	mov    0x8(%ebp),%edx
8010319d:	89 42 04             	mov    %eax,0x4(%edx)
  r->hour   = cmos_read(HOURS);
801031a0:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801031a7:	e8 92 ff ff ff       	call   8010313e <cmos_read>
801031ac:	8b 55 08             	mov    0x8(%ebp),%edx
801031af:	89 42 08             	mov    %eax,0x8(%edx)
  r->day    = cmos_read(DAY);
801031b2:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
801031b9:	e8 80 ff ff ff       	call   8010313e <cmos_read>
801031be:	8b 55 08             	mov    0x8(%ebp),%edx
801031c1:	89 42 0c             	mov    %eax,0xc(%edx)
  r->month  = cmos_read(MONTH);
801031c4:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
801031cb:	e8 6e ff ff ff       	call   8010313e <cmos_read>
801031d0:	8b 55 08             	mov    0x8(%ebp),%edx
801031d3:	89 42 10             	mov    %eax,0x10(%edx)
  r->year   = cmos_read(YEAR);
801031d6:	c7 04 24 09 00 00 00 	movl   $0x9,(%esp)
801031dd:	e8 5c ff ff ff       	call   8010313e <cmos_read>
801031e2:	8b 55 08             	mov    0x8(%ebp),%edx
801031e5:	89 42 14             	mov    %eax,0x14(%edx)
}
801031e8:	c9                   	leave  
801031e9:	c3                   	ret    

801031ea <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
801031ea:	55                   	push   %ebp
801031eb:	89 e5                	mov    %esp,%ebp
801031ed:	83 ec 58             	sub    $0x58,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
801031f0:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
801031f7:	e8 42 ff ff ff       	call   8010313e <cmos_read>
801031fc:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
801031ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103202:	83 e0 04             	and    $0x4,%eax
80103205:	85 c0                	test   %eax,%eax
80103207:	0f 94 c0             	sete   %al
8010320a:	0f b6 c0             	movzbl %al,%eax
8010320d:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
80103210:	8d 45 d8             	lea    -0x28(%ebp),%eax
80103213:	89 04 24             	mov    %eax,(%esp)
80103216:	e8 5c ff ff ff       	call   80103177 <fill_rtcdate>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
8010321b:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80103222:	e8 17 ff ff ff       	call   8010313e <cmos_read>
80103227:	25 80 00 00 00       	and    $0x80,%eax
8010322c:	85 c0                	test   %eax,%eax
8010322e:	74 02                	je     80103232 <cmostime+0x48>
        continue;
80103230:	eb 36                	jmp    80103268 <cmostime+0x7e>
    fill_rtcdate(&t2);
80103232:	8d 45 c0             	lea    -0x40(%ebp),%eax
80103235:	89 04 24             	mov    %eax,(%esp)
80103238:	e8 3a ff ff ff       	call   80103177 <fill_rtcdate>
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
8010323d:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
80103244:	00 
80103245:	8d 45 c0             	lea    -0x40(%ebp),%eax
80103248:	89 44 24 04          	mov    %eax,0x4(%esp)
8010324c:	8d 45 d8             	lea    -0x28(%ebp),%eax
8010324f:	89 04 24             	mov    %eax,(%esp)
80103252:	e8 b9 27 00 00       	call   80105a10 <memcmp>
80103257:	85 c0                	test   %eax,%eax
80103259:	75 0d                	jne    80103268 <cmostime+0x7e>
      break;
8010325b:	90                   	nop
  }

  // convert
  if (bcd) {
8010325c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103260:	0f 84 ac 00 00 00    	je     80103312 <cmostime+0x128>
80103266:	eb 02                	jmp    8010326a <cmostime+0x80>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
80103268:	eb a6                	jmp    80103210 <cmostime+0x26>

  // convert
  if (bcd) {
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
8010326a:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010326d:	c1 e8 04             	shr    $0x4,%eax
80103270:	89 c2                	mov    %eax,%edx
80103272:	89 d0                	mov    %edx,%eax
80103274:	c1 e0 02             	shl    $0x2,%eax
80103277:	01 d0                	add    %edx,%eax
80103279:	01 c0                	add    %eax,%eax
8010327b:	8b 55 d8             	mov    -0x28(%ebp),%edx
8010327e:	83 e2 0f             	and    $0xf,%edx
80103281:	01 d0                	add    %edx,%eax
80103283:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
80103286:	8b 45 dc             	mov    -0x24(%ebp),%eax
80103289:	c1 e8 04             	shr    $0x4,%eax
8010328c:	89 c2                	mov    %eax,%edx
8010328e:	89 d0                	mov    %edx,%eax
80103290:	c1 e0 02             	shl    $0x2,%eax
80103293:	01 d0                	add    %edx,%eax
80103295:	01 c0                	add    %eax,%eax
80103297:	8b 55 dc             	mov    -0x24(%ebp),%edx
8010329a:	83 e2 0f             	and    $0xf,%edx
8010329d:	01 d0                	add    %edx,%eax
8010329f:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
801032a2:	8b 45 e0             	mov    -0x20(%ebp),%eax
801032a5:	c1 e8 04             	shr    $0x4,%eax
801032a8:	89 c2                	mov    %eax,%edx
801032aa:	89 d0                	mov    %edx,%eax
801032ac:	c1 e0 02             	shl    $0x2,%eax
801032af:	01 d0                	add    %edx,%eax
801032b1:	01 c0                	add    %eax,%eax
801032b3:	8b 55 e0             	mov    -0x20(%ebp),%edx
801032b6:	83 e2 0f             	and    $0xf,%edx
801032b9:	01 d0                	add    %edx,%eax
801032bb:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
801032be:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801032c1:	c1 e8 04             	shr    $0x4,%eax
801032c4:	89 c2                	mov    %eax,%edx
801032c6:	89 d0                	mov    %edx,%eax
801032c8:	c1 e0 02             	shl    $0x2,%eax
801032cb:	01 d0                	add    %edx,%eax
801032cd:	01 c0                	add    %eax,%eax
801032cf:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801032d2:	83 e2 0f             	and    $0xf,%edx
801032d5:	01 d0                	add    %edx,%eax
801032d7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
801032da:	8b 45 e8             	mov    -0x18(%ebp),%eax
801032dd:	c1 e8 04             	shr    $0x4,%eax
801032e0:	89 c2                	mov    %eax,%edx
801032e2:	89 d0                	mov    %edx,%eax
801032e4:	c1 e0 02             	shl    $0x2,%eax
801032e7:	01 d0                	add    %edx,%eax
801032e9:	01 c0                	add    %eax,%eax
801032eb:	8b 55 e8             	mov    -0x18(%ebp),%edx
801032ee:	83 e2 0f             	and    $0xf,%edx
801032f1:	01 d0                	add    %edx,%eax
801032f3:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
801032f6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801032f9:	c1 e8 04             	shr    $0x4,%eax
801032fc:	89 c2                	mov    %eax,%edx
801032fe:	89 d0                	mov    %edx,%eax
80103300:	c1 e0 02             	shl    $0x2,%eax
80103303:	01 d0                	add    %edx,%eax
80103305:	01 c0                	add    %eax,%eax
80103307:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010330a:	83 e2 0f             	and    $0xf,%edx
8010330d:	01 d0                	add    %edx,%eax
8010330f:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
80103312:	8b 45 08             	mov    0x8(%ebp),%eax
80103315:	8b 55 d8             	mov    -0x28(%ebp),%edx
80103318:	89 10                	mov    %edx,(%eax)
8010331a:	8b 55 dc             	mov    -0x24(%ebp),%edx
8010331d:	89 50 04             	mov    %edx,0x4(%eax)
80103320:	8b 55 e0             	mov    -0x20(%ebp),%edx
80103323:	89 50 08             	mov    %edx,0x8(%eax)
80103326:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103329:	89 50 0c             	mov    %edx,0xc(%eax)
8010332c:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010332f:	89 50 10             	mov    %edx,0x10(%eax)
80103332:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103335:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
80103338:	8b 45 08             	mov    0x8(%ebp),%eax
8010333b:	8b 40 14             	mov    0x14(%eax),%eax
8010333e:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
80103344:	8b 45 08             	mov    0x8(%ebp),%eax
80103347:	89 50 14             	mov    %edx,0x14(%eax)
}
8010334a:	c9                   	leave  
8010334b:	c3                   	ret    

8010334c <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(void)
{
8010334c:	55                   	push   %ebp
8010334d:	89 e5                	mov    %esp,%ebp
8010334f:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
80103352:	c7 44 24 04 7c 8f 10 	movl   $0x80108f7c,0x4(%esp)
80103359:	80 
8010335a:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
80103361:	e8 be 23 00 00       	call   80105724 <initlock>
  readsb(ROOTDEV, &sb);
80103366:	8d 45 e8             	lea    -0x18(%ebp),%eax
80103369:	89 44 24 04          	mov    %eax,0x4(%esp)
8010336d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103374:	e8 a7 df ff ff       	call   80101320 <readsb>
  log.start = sb.size - sb.nlog;
80103379:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010337c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010337f:	29 c2                	sub    %eax,%edx
80103381:	89 d0                	mov    %edx,%eax
80103383:	a3 d4 32 11 80       	mov    %eax,0x801132d4
  log.size = sb.nlog;
80103388:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010338b:	a3 d8 32 11 80       	mov    %eax,0x801132d8
  log.dev = ROOTDEV;
80103390:	c7 05 e4 32 11 80 01 	movl   $0x1,0x801132e4
80103397:	00 00 00 
  recover_from_log();
8010339a:	e8 9a 01 00 00       	call   80103539 <recover_from_log>
}
8010339f:	c9                   	leave  
801033a0:	c3                   	ret    

801033a1 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
801033a1:	55                   	push   %ebp
801033a2:	89 e5                	mov    %esp,%ebp
801033a4:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801033a7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801033ae:	e9 8c 00 00 00       	jmp    8010343f <install_trans+0x9e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801033b3:	8b 15 d4 32 11 80    	mov    0x801132d4,%edx
801033b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033bc:	01 d0                	add    %edx,%eax
801033be:	83 c0 01             	add    $0x1,%eax
801033c1:	89 c2                	mov    %eax,%edx
801033c3:	a1 e4 32 11 80       	mov    0x801132e4,%eax
801033c8:	89 54 24 04          	mov    %edx,0x4(%esp)
801033cc:	89 04 24             	mov    %eax,(%esp)
801033cf:	e8 d2 cd ff ff       	call   801001a6 <bread>
801033d4:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
801033d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033da:	83 c0 10             	add    $0x10,%eax
801033dd:	8b 04 85 ac 32 11 80 	mov    -0x7feecd54(,%eax,4),%eax
801033e4:	89 c2                	mov    %eax,%edx
801033e6:	a1 e4 32 11 80       	mov    0x801132e4,%eax
801033eb:	89 54 24 04          	mov    %edx,0x4(%esp)
801033ef:	89 04 24             	mov    %eax,(%esp)
801033f2:	e8 af cd ff ff       	call   801001a6 <bread>
801033f7:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801033fa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033fd:	8d 50 18             	lea    0x18(%eax),%edx
80103400:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103403:	83 c0 18             	add    $0x18,%eax
80103406:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010340d:	00 
8010340e:	89 54 24 04          	mov    %edx,0x4(%esp)
80103412:	89 04 24             	mov    %eax,(%esp)
80103415:	e8 4e 26 00 00       	call   80105a68 <memmove>
    bwrite(dbuf);  // write dst to disk
8010341a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010341d:	89 04 24             	mov    %eax,(%esp)
80103420:	e8 b8 cd ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80103425:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103428:	89 04 24             	mov    %eax,(%esp)
8010342b:	e8 e7 cd ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80103430:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103433:	89 04 24             	mov    %eax,(%esp)
80103436:	e8 dc cd ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010343b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010343f:	a1 e8 32 11 80       	mov    0x801132e8,%eax
80103444:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103447:	0f 8f 66 ff ff ff    	jg     801033b3 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
8010344d:	c9                   	leave  
8010344e:	c3                   	ret    

8010344f <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010344f:	55                   	push   %ebp
80103450:	89 e5                	mov    %esp,%ebp
80103452:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103455:	a1 d4 32 11 80       	mov    0x801132d4,%eax
8010345a:	89 c2                	mov    %eax,%edx
8010345c:	a1 e4 32 11 80       	mov    0x801132e4,%eax
80103461:	89 54 24 04          	mov    %edx,0x4(%esp)
80103465:	89 04 24             	mov    %eax,(%esp)
80103468:	e8 39 cd ff ff       	call   801001a6 <bread>
8010346d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103470:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103473:	83 c0 18             	add    $0x18,%eax
80103476:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103479:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010347c:	8b 00                	mov    (%eax),%eax
8010347e:	a3 e8 32 11 80       	mov    %eax,0x801132e8
  for (i = 0; i < log.lh.n; i++) {
80103483:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010348a:	eb 1b                	jmp    801034a7 <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
8010348c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010348f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103492:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103496:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103499:	83 c2 10             	add    $0x10,%edx
8010349c:	89 04 95 ac 32 11 80 	mov    %eax,-0x7feecd54(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
801034a3:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801034a7:	a1 e8 32 11 80       	mov    0x801132e8,%eax
801034ac:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801034af:	7f db                	jg     8010348c <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
801034b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801034b4:	89 04 24             	mov    %eax,(%esp)
801034b7:	e8 5b cd ff ff       	call   80100217 <brelse>
}
801034bc:	c9                   	leave  
801034bd:	c3                   	ret    

801034be <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
801034be:	55                   	push   %ebp
801034bf:	89 e5                	mov    %esp,%ebp
801034c1:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
801034c4:	a1 d4 32 11 80       	mov    0x801132d4,%eax
801034c9:	89 c2                	mov    %eax,%edx
801034cb:	a1 e4 32 11 80       	mov    0x801132e4,%eax
801034d0:	89 54 24 04          	mov    %edx,0x4(%esp)
801034d4:	89 04 24             	mov    %eax,(%esp)
801034d7:	e8 ca cc ff ff       	call   801001a6 <bread>
801034dc:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
801034df:	8b 45 f0             	mov    -0x10(%ebp),%eax
801034e2:	83 c0 18             	add    $0x18,%eax
801034e5:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
801034e8:	8b 15 e8 32 11 80    	mov    0x801132e8,%edx
801034ee:	8b 45 ec             	mov    -0x14(%ebp),%eax
801034f1:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
801034f3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801034fa:	eb 1b                	jmp    80103517 <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
801034fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801034ff:	83 c0 10             	add    $0x10,%eax
80103502:	8b 0c 85 ac 32 11 80 	mov    -0x7feecd54(,%eax,4),%ecx
80103509:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010350c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010350f:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
80103513:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103517:	a1 e8 32 11 80       	mov    0x801132e8,%eax
8010351c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010351f:	7f db                	jg     801034fc <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
80103521:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103524:	89 04 24             	mov    %eax,(%esp)
80103527:	e8 b1 cc ff ff       	call   801001dd <bwrite>
  brelse(buf);
8010352c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010352f:	89 04 24             	mov    %eax,(%esp)
80103532:	e8 e0 cc ff ff       	call   80100217 <brelse>
}
80103537:	c9                   	leave  
80103538:	c3                   	ret    

80103539 <recover_from_log>:

static void
recover_from_log(void)
{
80103539:	55                   	push   %ebp
8010353a:	89 e5                	mov    %esp,%ebp
8010353c:	83 ec 08             	sub    $0x8,%esp
  read_head();      
8010353f:	e8 0b ff ff ff       	call   8010344f <read_head>
  install_trans(); // if committed, copy from log to disk
80103544:	e8 58 fe ff ff       	call   801033a1 <install_trans>
  log.lh.n = 0;
80103549:	c7 05 e8 32 11 80 00 	movl   $0x0,0x801132e8
80103550:	00 00 00 
  write_head(); // clear the log
80103553:	e8 66 ff ff ff       	call   801034be <write_head>
}
80103558:	c9                   	leave  
80103559:	c3                   	ret    

8010355a <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
8010355a:	55                   	push   %ebp
8010355b:	89 e5                	mov    %esp,%ebp
8010355d:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103560:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
80103567:	e8 d9 21 00 00       	call   80105745 <acquire>
  while(1){
    if(log.committing){
8010356c:	a1 e0 32 11 80       	mov    0x801132e0,%eax
80103571:	85 c0                	test   %eax,%eax
80103573:	74 16                	je     8010358b <begin_op+0x31>
      sleep(&log, &log.lock);
80103575:	c7 44 24 04 a0 32 11 	movl   $0x801132a0,0x4(%esp)
8010357c:	80 
8010357d:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
80103584:	e8 3b 17 00 00       	call   80104cc4 <sleep>
80103589:	eb 4f                	jmp    801035da <begin_op+0x80>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
8010358b:	8b 0d e8 32 11 80    	mov    0x801132e8,%ecx
80103591:	a1 dc 32 11 80       	mov    0x801132dc,%eax
80103596:	8d 50 01             	lea    0x1(%eax),%edx
80103599:	89 d0                	mov    %edx,%eax
8010359b:	c1 e0 02             	shl    $0x2,%eax
8010359e:	01 d0                	add    %edx,%eax
801035a0:	01 c0                	add    %eax,%eax
801035a2:	01 c8                	add    %ecx,%eax
801035a4:	83 f8 1e             	cmp    $0x1e,%eax
801035a7:	7e 16                	jle    801035bf <begin_op+0x65>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
801035a9:	c7 44 24 04 a0 32 11 	movl   $0x801132a0,0x4(%esp)
801035b0:	80 
801035b1:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
801035b8:	e8 07 17 00 00       	call   80104cc4 <sleep>
801035bd:	eb 1b                	jmp    801035da <begin_op+0x80>
    } else {
      log.outstanding += 1;
801035bf:	a1 dc 32 11 80       	mov    0x801132dc,%eax
801035c4:	83 c0 01             	add    $0x1,%eax
801035c7:	a3 dc 32 11 80       	mov    %eax,0x801132dc
      release(&log.lock);
801035cc:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
801035d3:	e8 cf 21 00 00       	call   801057a7 <release>
      break;
801035d8:	eb 02                	jmp    801035dc <begin_op+0x82>
    }
  }
801035da:	eb 90                	jmp    8010356c <begin_op+0x12>
}
801035dc:	c9                   	leave  
801035dd:	c3                   	ret    

801035de <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
801035de:	55                   	push   %ebp
801035df:	89 e5                	mov    %esp,%ebp
801035e1:	83 ec 28             	sub    $0x28,%esp
  int do_commit = 0;
801035e4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
801035eb:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
801035f2:	e8 4e 21 00 00       	call   80105745 <acquire>
  log.outstanding -= 1;
801035f7:	a1 dc 32 11 80       	mov    0x801132dc,%eax
801035fc:	83 e8 01             	sub    $0x1,%eax
801035ff:	a3 dc 32 11 80       	mov    %eax,0x801132dc
  if(log.committing)
80103604:	a1 e0 32 11 80       	mov    0x801132e0,%eax
80103609:	85 c0                	test   %eax,%eax
8010360b:	74 0c                	je     80103619 <end_op+0x3b>
    panic("log.committing");
8010360d:	c7 04 24 80 8f 10 80 	movl   $0x80108f80,(%esp)
80103614:	e8 21 cf ff ff       	call   8010053a <panic>
  if(log.outstanding == 0){
80103619:	a1 dc 32 11 80       	mov    0x801132dc,%eax
8010361e:	85 c0                	test   %eax,%eax
80103620:	75 13                	jne    80103635 <end_op+0x57>
    do_commit = 1;
80103622:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
80103629:	c7 05 e0 32 11 80 01 	movl   $0x1,0x801132e0
80103630:	00 00 00 
80103633:	eb 0c                	jmp    80103641 <end_op+0x63>
  } else {
    // begin_op() may be waiting for log space.
    wakeup(&log);
80103635:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
8010363c:	e8 5f 17 00 00       	call   80104da0 <wakeup>
  }
  release(&log.lock);
80103641:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
80103648:	e8 5a 21 00 00       	call   801057a7 <release>

  if(do_commit){
8010364d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103651:	74 33                	je     80103686 <end_op+0xa8>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
80103653:	e8 de 00 00 00       	call   80103736 <commit>
    acquire(&log.lock);
80103658:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
8010365f:	e8 e1 20 00 00       	call   80105745 <acquire>
    log.committing = 0;
80103664:	c7 05 e0 32 11 80 00 	movl   $0x0,0x801132e0
8010366b:	00 00 00 
    wakeup(&log);
8010366e:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
80103675:	e8 26 17 00 00       	call   80104da0 <wakeup>
    release(&log.lock);
8010367a:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
80103681:	e8 21 21 00 00       	call   801057a7 <release>
  }
}
80103686:	c9                   	leave  
80103687:	c3                   	ret    

80103688 <write_log>:

// Copy modified blocks from cache to log.
static void 
write_log(void)
{
80103688:	55                   	push   %ebp
80103689:	89 e5                	mov    %esp,%ebp
8010368b:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010368e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103695:	e9 8c 00 00 00       	jmp    80103726 <write_log+0x9e>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
8010369a:	8b 15 d4 32 11 80    	mov    0x801132d4,%edx
801036a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036a3:	01 d0                	add    %edx,%eax
801036a5:	83 c0 01             	add    $0x1,%eax
801036a8:	89 c2                	mov    %eax,%edx
801036aa:	a1 e4 32 11 80       	mov    0x801132e4,%eax
801036af:	89 54 24 04          	mov    %edx,0x4(%esp)
801036b3:	89 04 24             	mov    %eax,(%esp)
801036b6:	e8 eb ca ff ff       	call   801001a6 <bread>
801036bb:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.sector[tail]); // cache block
801036be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036c1:	83 c0 10             	add    $0x10,%eax
801036c4:	8b 04 85 ac 32 11 80 	mov    -0x7feecd54(,%eax,4),%eax
801036cb:	89 c2                	mov    %eax,%edx
801036cd:	a1 e4 32 11 80       	mov    0x801132e4,%eax
801036d2:	89 54 24 04          	mov    %edx,0x4(%esp)
801036d6:	89 04 24             	mov    %eax,(%esp)
801036d9:	e8 c8 ca ff ff       	call   801001a6 <bread>
801036de:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
801036e1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801036e4:	8d 50 18             	lea    0x18(%eax),%edx
801036e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801036ea:	83 c0 18             	add    $0x18,%eax
801036ed:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801036f4:	00 
801036f5:	89 54 24 04          	mov    %edx,0x4(%esp)
801036f9:	89 04 24             	mov    %eax,(%esp)
801036fc:	e8 67 23 00 00       	call   80105a68 <memmove>
    bwrite(to);  // write the log
80103701:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103704:	89 04 24             	mov    %eax,(%esp)
80103707:	e8 d1 ca ff ff       	call   801001dd <bwrite>
    brelse(from); 
8010370c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010370f:	89 04 24             	mov    %eax,(%esp)
80103712:	e8 00 cb ff ff       	call   80100217 <brelse>
    brelse(to);
80103717:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010371a:	89 04 24             	mov    %eax,(%esp)
8010371d:	e8 f5 ca ff ff       	call   80100217 <brelse>
static void 
write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103722:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103726:	a1 e8 32 11 80       	mov    0x801132e8,%eax
8010372b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010372e:	0f 8f 66 ff ff ff    	jg     8010369a <write_log+0x12>
    memmove(to->data, from->data, BSIZE);
    bwrite(to);  // write the log
    brelse(from); 
    brelse(to);
  }
}
80103734:	c9                   	leave  
80103735:	c3                   	ret    

80103736 <commit>:

static void
commit()
{
80103736:	55                   	push   %ebp
80103737:	89 e5                	mov    %esp,%ebp
80103739:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
8010373c:	a1 e8 32 11 80       	mov    0x801132e8,%eax
80103741:	85 c0                	test   %eax,%eax
80103743:	7e 1e                	jle    80103763 <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
80103745:	e8 3e ff ff ff       	call   80103688 <write_log>
    write_head();    // Write header to disk -- the real commit
8010374a:	e8 6f fd ff ff       	call   801034be <write_head>
    install_trans(); // Now install writes to home locations
8010374f:	e8 4d fc ff ff       	call   801033a1 <install_trans>
    log.lh.n = 0; 
80103754:	c7 05 e8 32 11 80 00 	movl   $0x0,0x801132e8
8010375b:	00 00 00 
    write_head();    // Erase the transaction from the log
8010375e:	e8 5b fd ff ff       	call   801034be <write_head>
  }
}
80103763:	c9                   	leave  
80103764:	c3                   	ret    

80103765 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103765:	55                   	push   %ebp
80103766:	89 e5                	mov    %esp,%ebp
80103768:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
8010376b:	a1 e8 32 11 80       	mov    0x801132e8,%eax
80103770:	83 f8 1d             	cmp    $0x1d,%eax
80103773:	7f 12                	jg     80103787 <log_write+0x22>
80103775:	a1 e8 32 11 80       	mov    0x801132e8,%eax
8010377a:	8b 15 d8 32 11 80    	mov    0x801132d8,%edx
80103780:	83 ea 01             	sub    $0x1,%edx
80103783:	39 d0                	cmp    %edx,%eax
80103785:	7c 0c                	jl     80103793 <log_write+0x2e>
    panic("too big a transaction");
80103787:	c7 04 24 8f 8f 10 80 	movl   $0x80108f8f,(%esp)
8010378e:	e8 a7 cd ff ff       	call   8010053a <panic>
  if (log.outstanding < 1)
80103793:	a1 dc 32 11 80       	mov    0x801132dc,%eax
80103798:	85 c0                	test   %eax,%eax
8010379a:	7f 0c                	jg     801037a8 <log_write+0x43>
    panic("log_write outside of trans");
8010379c:	c7 04 24 a5 8f 10 80 	movl   $0x80108fa5,(%esp)
801037a3:	e8 92 cd ff ff       	call   8010053a <panic>

  acquire(&log.lock);
801037a8:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
801037af:	e8 91 1f 00 00       	call   80105745 <acquire>
  for (i = 0; i < log.lh.n; i++) {
801037b4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801037bb:	eb 1f                	jmp    801037dc <log_write+0x77>
    if (log.lh.sector[i] == b->sector)   // log absorbtion
801037bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037c0:	83 c0 10             	add    $0x10,%eax
801037c3:	8b 04 85 ac 32 11 80 	mov    -0x7feecd54(,%eax,4),%eax
801037ca:	89 c2                	mov    %eax,%edx
801037cc:	8b 45 08             	mov    0x8(%ebp),%eax
801037cf:	8b 40 08             	mov    0x8(%eax),%eax
801037d2:	39 c2                	cmp    %eax,%edx
801037d4:	75 02                	jne    801037d8 <log_write+0x73>
      break;
801037d6:	eb 0e                	jmp    801037e6 <log_write+0x81>
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
801037d8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801037dc:	a1 e8 32 11 80       	mov    0x801132e8,%eax
801037e1:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801037e4:	7f d7                	jg     801037bd <log_write+0x58>
    if (log.lh.sector[i] == b->sector)   // log absorbtion
      break;
  }
  log.lh.sector[i] = b->sector;
801037e6:	8b 45 08             	mov    0x8(%ebp),%eax
801037e9:	8b 40 08             	mov    0x8(%eax),%eax
801037ec:	8b 55 f4             	mov    -0xc(%ebp),%edx
801037ef:	83 c2 10             	add    $0x10,%edx
801037f2:	89 04 95 ac 32 11 80 	mov    %eax,-0x7feecd54(,%edx,4)
  if (i == log.lh.n)
801037f9:	a1 e8 32 11 80       	mov    0x801132e8,%eax
801037fe:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103801:	75 0d                	jne    80103810 <log_write+0xab>
    log.lh.n++;
80103803:	a1 e8 32 11 80       	mov    0x801132e8,%eax
80103808:	83 c0 01             	add    $0x1,%eax
8010380b:	a3 e8 32 11 80       	mov    %eax,0x801132e8
  b->flags |= B_DIRTY; // prevent eviction
80103810:	8b 45 08             	mov    0x8(%ebp),%eax
80103813:	8b 00                	mov    (%eax),%eax
80103815:	83 c8 04             	or     $0x4,%eax
80103818:	89 c2                	mov    %eax,%edx
8010381a:	8b 45 08             	mov    0x8(%ebp),%eax
8010381d:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
8010381f:	c7 04 24 a0 32 11 80 	movl   $0x801132a0,(%esp)
80103826:	e8 7c 1f 00 00       	call   801057a7 <release>
}
8010382b:	c9                   	leave  
8010382c:	c3                   	ret    

8010382d <v2p>:
8010382d:	55                   	push   %ebp
8010382e:	89 e5                	mov    %esp,%ebp
80103830:	8b 45 08             	mov    0x8(%ebp),%eax
80103833:	05 00 00 00 80       	add    $0x80000000,%eax
80103838:	5d                   	pop    %ebp
80103839:	c3                   	ret    

8010383a <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
8010383a:	55                   	push   %ebp
8010383b:	89 e5                	mov    %esp,%ebp
8010383d:	8b 45 08             	mov    0x8(%ebp),%eax
80103840:	05 00 00 00 80       	add    $0x80000000,%eax
80103845:	5d                   	pop    %ebp
80103846:	c3                   	ret    

80103847 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103847:	55                   	push   %ebp
80103848:	89 e5                	mov    %esp,%ebp
8010384a:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
8010384d:	8b 55 08             	mov    0x8(%ebp),%edx
80103850:	8b 45 0c             	mov    0xc(%ebp),%eax
80103853:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103856:	f0 87 02             	lock xchg %eax,(%edx)
80103859:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
8010385c:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010385f:	c9                   	leave  
80103860:	c3                   	ret    

80103861 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103861:	55                   	push   %ebp
80103862:	89 e5                	mov    %esp,%ebp
80103864:	83 e4 f0             	and    $0xfffffff0,%esp
80103867:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
8010386a:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103871:	80 
80103872:	c7 04 24 7c 7b 11 80 	movl   $0x80117b7c,(%esp)
80103879:	e8 80 f2 ff ff       	call   80102afe <kinit1>
  kvmalloc();      // kernel page table
8010387e:	e8 41 4d 00 00       	call   801085c4 <kvmalloc>
  mpinit();        // collect info about this machine
80103883:	e8 4b 04 00 00       	call   80103cd3 <mpinit>
  lapicinit();
80103888:	e8 dc f5 ff ff       	call   80102e69 <lapicinit>
  seginit();       // set up segments
8010388d:	e8 c5 46 00 00       	call   80107f57 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103892:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103898:	0f b6 00             	movzbl (%eax),%eax
8010389b:	0f b6 c0             	movzbl %al,%eax
8010389e:	89 44 24 04          	mov    %eax,0x4(%esp)
801038a2:	c7 04 24 c0 8f 10 80 	movl   $0x80108fc0,(%esp)
801038a9:	e8 f2 ca ff ff       	call   801003a0 <cprintf>
  picinit();       // interrupt controller
801038ae:	e8 7e 06 00 00       	call   80103f31 <picinit>
  ioapicinit();    // another interrupt controller
801038b3:	e8 3c f1 ff ff       	call   801029f4 <ioapicinit>
  procfsinit();
801038b8:	e8 fc 1c 00 00       	call   801055b9 <procfsinit>
  consoleinit();   // I/O devices & their interrupts
801038bd:	e8 bf d1 ff ff       	call   80100a81 <consoleinit>
  uartinit();      // serial port
801038c2:	e8 df 39 00 00       	call   801072a6 <uartinit>
  pinit();         // process table
801038c7:	e8 6f 0b 00 00       	call   8010443b <pinit>
  tvinit();        // trap vectors
801038cc:	e8 87 35 00 00       	call   80106e58 <tvinit>
  binit();         // buffer cache
801038d1:	e8 5e c7 ff ff       	call   80100034 <binit>
  fileinit();      // file table
801038d6:	e8 5e d6 ff ff       	call   80100f39 <fileinit>
  iinit();         // inode cache
801038db:	e8 f3 dc ff ff       	call   801015d3 <iinit>
  ideinit();       // disk
801038e0:	e8 78 ed ff ff       	call   8010265d <ideinit>
  if(!ismp)
801038e5:	a1 84 33 11 80       	mov    0x80113384,%eax
801038ea:	85 c0                	test   %eax,%eax
801038ec:	75 05                	jne    801038f3 <main+0x92>
    timerinit();   // uniprocessor timer
801038ee:	e8 b0 34 00 00       	call   80106da3 <timerinit>
  startothers();   // start other processors
801038f3:	e8 7f 00 00 00       	call   80103977 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
801038f8:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
801038ff:	8e 
80103900:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103907:	e8 2a f2 ff ff       	call   80102b36 <kinit2>
  userinit();      // first user process
8010390c:	e8 48 0c 00 00       	call   80104559 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80103911:	e8 1a 00 00 00       	call   80103930 <mpmain>

80103916 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80103916:	55                   	push   %ebp
80103917:	89 e5                	mov    %esp,%ebp
80103919:	83 ec 08             	sub    $0x8,%esp
  switchkvm(); 
8010391c:	e8 ba 4c 00 00       	call   801085db <switchkvm>
  seginit();
80103921:	e8 31 46 00 00       	call   80107f57 <seginit>
  lapicinit();
80103926:	e8 3e f5 ff ff       	call   80102e69 <lapicinit>
  mpmain();
8010392b:	e8 00 00 00 00       	call   80103930 <mpmain>

80103930 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103930:	55                   	push   %ebp
80103931:	89 e5                	mov    %esp,%ebp
80103933:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
80103936:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010393c:	0f b6 00             	movzbl (%eax),%eax
8010393f:	0f b6 c0             	movzbl %al,%eax
80103942:	89 44 24 04          	mov    %eax,0x4(%esp)
80103946:	c7 04 24 d7 8f 10 80 	movl   $0x80108fd7,(%esp)
8010394d:	e8 4e ca ff ff       	call   801003a0 <cprintf>
  idtinit();       // load idt register
80103952:	e8 75 36 00 00       	call   80106fcc <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103957:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010395d:	05 a8 00 00 00       	add    $0xa8,%eax
80103962:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103969:	00 
8010396a:	89 04 24             	mov    %eax,(%esp)
8010396d:	e8 d5 fe ff ff       	call   80103847 <xchg>
  scheduler();     // start running processes
80103972:	e8 a2 11 00 00       	call   80104b19 <scheduler>

80103977 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103977:	55                   	push   %ebp
80103978:	89 e5                	mov    %esp,%ebp
8010397a:	53                   	push   %ebx
8010397b:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
8010397e:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103985:	e8 b0 fe ff ff       	call   8010383a <p2v>
8010398a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
8010398d:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103992:	89 44 24 08          	mov    %eax,0x8(%esp)
80103996:	c7 44 24 04 0c c5 10 	movl   $0x8010c50c,0x4(%esp)
8010399d:	80 
8010399e:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039a1:	89 04 24             	mov    %eax,(%esp)
801039a4:	e8 bf 20 00 00       	call   80105a68 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
801039a9:	c7 45 f4 a0 33 11 80 	movl   $0x801133a0,-0xc(%ebp)
801039b0:	e9 85 00 00 00       	jmp    80103a3a <startothers+0xc3>
    if(c == cpus+cpunum())  // We've started already.
801039b5:	e8 08 f6 ff ff       	call   80102fc2 <cpunum>
801039ba:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801039c0:	05 a0 33 11 80       	add    $0x801133a0,%eax
801039c5:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801039c8:	75 02                	jne    801039cc <startothers+0x55>
      continue;
801039ca:	eb 67                	jmp    80103a33 <startothers+0xbc>

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
801039cc:	e8 5b f2 ff ff       	call   80102c2c <kalloc>
801039d1:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
801039d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039d7:	83 e8 04             	sub    $0x4,%eax
801039da:	8b 55 ec             	mov    -0x14(%ebp),%edx
801039dd:	81 c2 00 10 00 00    	add    $0x1000,%edx
801039e3:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
801039e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039e8:	83 e8 08             	sub    $0x8,%eax
801039eb:	c7 00 16 39 10 80    	movl   $0x80103916,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
801039f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039f4:	8d 58 f4             	lea    -0xc(%eax),%ebx
801039f7:	c7 04 24 00 b0 10 80 	movl   $0x8010b000,(%esp)
801039fe:	e8 2a fe ff ff       	call   8010382d <v2p>
80103a03:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80103a05:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a08:	89 04 24             	mov    %eax,(%esp)
80103a0b:	e8 1d fe ff ff       	call   8010382d <v2p>
80103a10:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103a13:	0f b6 12             	movzbl (%edx),%edx
80103a16:	0f b6 d2             	movzbl %dl,%edx
80103a19:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a1d:	89 14 24             	mov    %edx,(%esp)
80103a20:	e8 1f f6 ff ff       	call   80103044 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80103a25:	90                   	nop
80103a26:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a29:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80103a2f:	85 c0                	test   %eax,%eax
80103a31:	74 f3                	je     80103a26 <startothers+0xaf>
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80103a33:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80103a3a:	a1 80 39 11 80       	mov    0x80113980,%eax
80103a3f:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103a45:	05 a0 33 11 80       	add    $0x801133a0,%eax
80103a4a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103a4d:	0f 87 62 ff ff ff    	ja     801039b5 <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103a53:	83 c4 24             	add    $0x24,%esp
80103a56:	5b                   	pop    %ebx
80103a57:	5d                   	pop    %ebp
80103a58:	c3                   	ret    

80103a59 <p2v>:
80103a59:	55                   	push   %ebp
80103a5a:	89 e5                	mov    %esp,%ebp
80103a5c:	8b 45 08             	mov    0x8(%ebp),%eax
80103a5f:	05 00 00 00 80       	add    $0x80000000,%eax
80103a64:	5d                   	pop    %ebp
80103a65:	c3                   	ret    

80103a66 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103a66:	55                   	push   %ebp
80103a67:	89 e5                	mov    %esp,%ebp
80103a69:	83 ec 14             	sub    $0x14,%esp
80103a6c:	8b 45 08             	mov    0x8(%ebp),%eax
80103a6f:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103a73:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80103a77:	89 c2                	mov    %eax,%edx
80103a79:	ec                   	in     (%dx),%al
80103a7a:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80103a7d:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80103a81:	c9                   	leave  
80103a82:	c3                   	ret    

80103a83 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103a83:	55                   	push   %ebp
80103a84:	89 e5                	mov    %esp,%ebp
80103a86:	83 ec 08             	sub    $0x8,%esp
80103a89:	8b 55 08             	mov    0x8(%ebp),%edx
80103a8c:	8b 45 0c             	mov    0xc(%ebp),%eax
80103a8f:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103a93:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103a96:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103a9a:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103a9e:	ee                   	out    %al,(%dx)
}
80103a9f:	c9                   	leave  
80103aa0:	c3                   	ret    

80103aa1 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80103aa1:	55                   	push   %ebp
80103aa2:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
80103aa4:	a1 44 c6 10 80       	mov    0x8010c644,%eax
80103aa9:	89 c2                	mov    %eax,%edx
80103aab:	b8 a0 33 11 80       	mov    $0x801133a0,%eax
80103ab0:	29 c2                	sub    %eax,%edx
80103ab2:	89 d0                	mov    %edx,%eax
80103ab4:	c1 f8 02             	sar    $0x2,%eax
80103ab7:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80103abd:	5d                   	pop    %ebp
80103abe:	c3                   	ret    

80103abf <sum>:

static uchar
sum(uchar *addr, int len)
{
80103abf:	55                   	push   %ebp
80103ac0:	89 e5                	mov    %esp,%ebp
80103ac2:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
80103ac5:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80103acc:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103ad3:	eb 15                	jmp    80103aea <sum+0x2b>
    sum += addr[i];
80103ad5:	8b 55 fc             	mov    -0x4(%ebp),%edx
80103ad8:	8b 45 08             	mov    0x8(%ebp),%eax
80103adb:	01 d0                	add    %edx,%eax
80103add:	0f b6 00             	movzbl (%eax),%eax
80103ae0:	0f b6 c0             	movzbl %al,%eax
80103ae3:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
80103ae6:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103aea:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103aed:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103af0:	7c e3                	jl     80103ad5 <sum+0x16>
    sum += addr[i];
  return sum;
80103af2:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103af5:	c9                   	leave  
80103af6:	c3                   	ret    

80103af7 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80103af7:	55                   	push   %ebp
80103af8:	89 e5                	mov    %esp,%ebp
80103afa:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80103afd:	8b 45 08             	mov    0x8(%ebp),%eax
80103b00:	89 04 24             	mov    %eax,(%esp)
80103b03:	e8 51 ff ff ff       	call   80103a59 <p2v>
80103b08:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80103b0b:	8b 55 0c             	mov    0xc(%ebp),%edx
80103b0e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b11:	01 d0                	add    %edx,%eax
80103b13:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80103b16:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b19:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103b1c:	eb 3f                	jmp    80103b5d <mpsearch1+0x66>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103b1e:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103b25:	00 
80103b26:	c7 44 24 04 e8 8f 10 	movl   $0x80108fe8,0x4(%esp)
80103b2d:	80 
80103b2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b31:	89 04 24             	mov    %eax,(%esp)
80103b34:	e8 d7 1e 00 00       	call   80105a10 <memcmp>
80103b39:	85 c0                	test   %eax,%eax
80103b3b:	75 1c                	jne    80103b59 <mpsearch1+0x62>
80103b3d:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80103b44:	00 
80103b45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b48:	89 04 24             	mov    %eax,(%esp)
80103b4b:	e8 6f ff ff ff       	call   80103abf <sum>
80103b50:	84 c0                	test   %al,%al
80103b52:	75 05                	jne    80103b59 <mpsearch1+0x62>
      return (struct mp*)p;
80103b54:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b57:	eb 11                	jmp    80103b6a <mpsearch1+0x73>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80103b59:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103b5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b60:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103b63:	72 b9                	jb     80103b1e <mpsearch1+0x27>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
80103b65:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103b6a:	c9                   	leave  
80103b6b:	c3                   	ret    

80103b6c <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103b6c:	55                   	push   %ebp
80103b6d:	89 e5                	mov    %esp,%ebp
80103b6f:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103b72:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80103b79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b7c:	83 c0 0f             	add    $0xf,%eax
80103b7f:	0f b6 00             	movzbl (%eax),%eax
80103b82:	0f b6 c0             	movzbl %al,%eax
80103b85:	c1 e0 08             	shl    $0x8,%eax
80103b88:	89 c2                	mov    %eax,%edx
80103b8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b8d:	83 c0 0e             	add    $0xe,%eax
80103b90:	0f b6 00             	movzbl (%eax),%eax
80103b93:	0f b6 c0             	movzbl %al,%eax
80103b96:	09 d0                	or     %edx,%eax
80103b98:	c1 e0 04             	shl    $0x4,%eax
80103b9b:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103b9e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103ba2:	74 21                	je     80103bc5 <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80103ba4:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103bab:	00 
80103bac:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103baf:	89 04 24             	mov    %eax,(%esp)
80103bb2:	e8 40 ff ff ff       	call   80103af7 <mpsearch1>
80103bb7:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103bba:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103bbe:	74 50                	je     80103c10 <mpsearch+0xa4>
      return mp;
80103bc0:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103bc3:	eb 5f                	jmp    80103c24 <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80103bc5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bc8:	83 c0 14             	add    $0x14,%eax
80103bcb:	0f b6 00             	movzbl (%eax),%eax
80103bce:	0f b6 c0             	movzbl %al,%eax
80103bd1:	c1 e0 08             	shl    $0x8,%eax
80103bd4:	89 c2                	mov    %eax,%edx
80103bd6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bd9:	83 c0 13             	add    $0x13,%eax
80103bdc:	0f b6 00             	movzbl (%eax),%eax
80103bdf:	0f b6 c0             	movzbl %al,%eax
80103be2:	09 d0                	or     %edx,%eax
80103be4:	c1 e0 0a             	shl    $0xa,%eax
80103be7:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103bea:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bed:	2d 00 04 00 00       	sub    $0x400,%eax
80103bf2:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103bf9:	00 
80103bfa:	89 04 24             	mov    %eax,(%esp)
80103bfd:	e8 f5 fe ff ff       	call   80103af7 <mpsearch1>
80103c02:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103c05:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103c09:	74 05                	je     80103c10 <mpsearch+0xa4>
      return mp;
80103c0b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c0e:	eb 14                	jmp    80103c24 <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80103c10:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103c17:	00 
80103c18:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80103c1f:	e8 d3 fe ff ff       	call   80103af7 <mpsearch1>
}
80103c24:	c9                   	leave  
80103c25:	c3                   	ret    

80103c26 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80103c26:	55                   	push   %ebp
80103c27:	89 e5                	mov    %esp,%ebp
80103c29:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80103c2c:	e8 3b ff ff ff       	call   80103b6c <mpsearch>
80103c31:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103c34:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103c38:	74 0a                	je     80103c44 <mpconfig+0x1e>
80103c3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c3d:	8b 40 04             	mov    0x4(%eax),%eax
80103c40:	85 c0                	test   %eax,%eax
80103c42:	75 0a                	jne    80103c4e <mpconfig+0x28>
    return 0;
80103c44:	b8 00 00 00 00       	mov    $0x0,%eax
80103c49:	e9 83 00 00 00       	jmp    80103cd1 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80103c4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c51:	8b 40 04             	mov    0x4(%eax),%eax
80103c54:	89 04 24             	mov    %eax,(%esp)
80103c57:	e8 fd fd ff ff       	call   80103a59 <p2v>
80103c5c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103c5f:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103c66:	00 
80103c67:	c7 44 24 04 ed 8f 10 	movl   $0x80108fed,0x4(%esp)
80103c6e:	80 
80103c6f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c72:	89 04 24             	mov    %eax,(%esp)
80103c75:	e8 96 1d 00 00       	call   80105a10 <memcmp>
80103c7a:	85 c0                	test   %eax,%eax
80103c7c:	74 07                	je     80103c85 <mpconfig+0x5f>
    return 0;
80103c7e:	b8 00 00 00 00       	mov    $0x0,%eax
80103c83:	eb 4c                	jmp    80103cd1 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
80103c85:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c88:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103c8c:	3c 01                	cmp    $0x1,%al
80103c8e:	74 12                	je     80103ca2 <mpconfig+0x7c>
80103c90:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c93:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103c97:	3c 04                	cmp    $0x4,%al
80103c99:	74 07                	je     80103ca2 <mpconfig+0x7c>
    return 0;
80103c9b:	b8 00 00 00 00       	mov    $0x0,%eax
80103ca0:	eb 2f                	jmp    80103cd1 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80103ca2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ca5:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103ca9:	0f b7 c0             	movzwl %ax,%eax
80103cac:	89 44 24 04          	mov    %eax,0x4(%esp)
80103cb0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103cb3:	89 04 24             	mov    %eax,(%esp)
80103cb6:	e8 04 fe ff ff       	call   80103abf <sum>
80103cbb:	84 c0                	test   %al,%al
80103cbd:	74 07                	je     80103cc6 <mpconfig+0xa0>
    return 0;
80103cbf:	b8 00 00 00 00       	mov    $0x0,%eax
80103cc4:	eb 0b                	jmp    80103cd1 <mpconfig+0xab>
  *pmp = mp;
80103cc6:	8b 45 08             	mov    0x8(%ebp),%eax
80103cc9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103ccc:	89 10                	mov    %edx,(%eax)
  return conf;
80103cce:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80103cd1:	c9                   	leave  
80103cd2:	c3                   	ret    

80103cd3 <mpinit>:

void
mpinit(void)
{
80103cd3:	55                   	push   %ebp
80103cd4:	89 e5                	mov    %esp,%ebp
80103cd6:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80103cd9:	c7 05 44 c6 10 80 a0 	movl   $0x801133a0,0x8010c644
80103ce0:	33 11 80 
  if((conf = mpconfig(&mp)) == 0)
80103ce3:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103ce6:	89 04 24             	mov    %eax,(%esp)
80103ce9:	e8 38 ff ff ff       	call   80103c26 <mpconfig>
80103cee:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103cf1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103cf5:	75 05                	jne    80103cfc <mpinit+0x29>
    return;
80103cf7:	e9 9c 01 00 00       	jmp    80103e98 <mpinit+0x1c5>
  ismp = 1;
80103cfc:	c7 05 84 33 11 80 01 	movl   $0x1,0x80113384
80103d03:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80103d06:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d09:	8b 40 24             	mov    0x24(%eax),%eax
80103d0c:	a3 9c 32 11 80       	mov    %eax,0x8011329c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103d11:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d14:	83 c0 2c             	add    $0x2c,%eax
80103d17:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103d1a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d1d:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103d21:	0f b7 d0             	movzwl %ax,%edx
80103d24:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d27:	01 d0                	add    %edx,%eax
80103d29:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103d2c:	e9 f4 00 00 00       	jmp    80103e25 <mpinit+0x152>
    switch(*p){
80103d31:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d34:	0f b6 00             	movzbl (%eax),%eax
80103d37:	0f b6 c0             	movzbl %al,%eax
80103d3a:	83 f8 04             	cmp    $0x4,%eax
80103d3d:	0f 87 bf 00 00 00    	ja     80103e02 <mpinit+0x12f>
80103d43:	8b 04 85 30 90 10 80 	mov    -0x7fef6fd0(,%eax,4),%eax
80103d4a:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103d4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d4f:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80103d52:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103d55:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103d59:	0f b6 d0             	movzbl %al,%edx
80103d5c:	a1 80 39 11 80       	mov    0x80113980,%eax
80103d61:	39 c2                	cmp    %eax,%edx
80103d63:	74 2d                	je     80103d92 <mpinit+0xbf>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80103d65:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103d68:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103d6c:	0f b6 d0             	movzbl %al,%edx
80103d6f:	a1 80 39 11 80       	mov    0x80113980,%eax
80103d74:	89 54 24 08          	mov    %edx,0x8(%esp)
80103d78:	89 44 24 04          	mov    %eax,0x4(%esp)
80103d7c:	c7 04 24 f2 8f 10 80 	movl   $0x80108ff2,(%esp)
80103d83:	e8 18 c6 ff ff       	call   801003a0 <cprintf>
        ismp = 0;
80103d88:	c7 05 84 33 11 80 00 	movl   $0x0,0x80113384
80103d8f:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80103d92:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103d95:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80103d99:	0f b6 c0             	movzbl %al,%eax
80103d9c:	83 e0 02             	and    $0x2,%eax
80103d9f:	85 c0                	test   %eax,%eax
80103da1:	74 15                	je     80103db8 <mpinit+0xe5>
        bcpu = &cpus[ncpu];
80103da3:	a1 80 39 11 80       	mov    0x80113980,%eax
80103da8:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103dae:	05 a0 33 11 80       	add    $0x801133a0,%eax
80103db3:	a3 44 c6 10 80       	mov    %eax,0x8010c644
      cpus[ncpu].id = ncpu;
80103db8:	8b 15 80 39 11 80    	mov    0x80113980,%edx
80103dbe:	a1 80 39 11 80       	mov    0x80113980,%eax
80103dc3:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80103dc9:	81 c2 a0 33 11 80    	add    $0x801133a0,%edx
80103dcf:	88 02                	mov    %al,(%edx)
      ncpu++;
80103dd1:	a1 80 39 11 80       	mov    0x80113980,%eax
80103dd6:	83 c0 01             	add    $0x1,%eax
80103dd9:	a3 80 39 11 80       	mov    %eax,0x80113980
      p += sizeof(struct mpproc);
80103dde:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80103de2:	eb 41                	jmp    80103e25 <mpinit+0x152>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80103de4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103de7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80103dea:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103ded:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103df1:	a2 80 33 11 80       	mov    %al,0x80113380
      p += sizeof(struct mpioapic);
80103df6:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103dfa:	eb 29                	jmp    80103e25 <mpinit+0x152>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103dfc:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103e00:	eb 23                	jmp    80103e25 <mpinit+0x152>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80103e02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e05:	0f b6 00             	movzbl (%eax),%eax
80103e08:	0f b6 c0             	movzbl %al,%eax
80103e0b:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e0f:	c7 04 24 10 90 10 80 	movl   $0x80109010,(%esp)
80103e16:	e8 85 c5 ff ff       	call   801003a0 <cprintf>
      ismp = 0;
80103e1b:	c7 05 84 33 11 80 00 	movl   $0x0,0x80113384
80103e22:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103e25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e28:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103e2b:	0f 82 00 ff ff ff    	jb     80103d31 <mpinit+0x5e>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80103e31:	a1 84 33 11 80       	mov    0x80113384,%eax
80103e36:	85 c0                	test   %eax,%eax
80103e38:	75 1d                	jne    80103e57 <mpinit+0x184>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80103e3a:	c7 05 80 39 11 80 01 	movl   $0x1,0x80113980
80103e41:	00 00 00 
    lapic = 0;
80103e44:	c7 05 9c 32 11 80 00 	movl   $0x0,0x8011329c
80103e4b:	00 00 00 
    ioapicid = 0;
80103e4e:	c6 05 80 33 11 80 00 	movb   $0x0,0x80113380
    return;
80103e55:	eb 41                	jmp    80103e98 <mpinit+0x1c5>
  }

  if(mp->imcrp){
80103e57:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103e5a:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103e5e:	84 c0                	test   %al,%al
80103e60:	74 36                	je     80103e98 <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103e62:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80103e69:	00 
80103e6a:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80103e71:	e8 0d fc ff ff       	call   80103a83 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103e76:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103e7d:	e8 e4 fb ff ff       	call   80103a66 <inb>
80103e82:	83 c8 01             	or     $0x1,%eax
80103e85:	0f b6 c0             	movzbl %al,%eax
80103e88:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e8c:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103e93:	e8 eb fb ff ff       	call   80103a83 <outb>
  }
}
80103e98:	c9                   	leave  
80103e99:	c3                   	ret    

80103e9a <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103e9a:	55                   	push   %ebp
80103e9b:	89 e5                	mov    %esp,%ebp
80103e9d:	83 ec 08             	sub    $0x8,%esp
80103ea0:	8b 55 08             	mov    0x8(%ebp),%edx
80103ea3:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ea6:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103eaa:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103ead:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103eb1:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103eb5:	ee                   	out    %al,(%dx)
}
80103eb6:	c9                   	leave  
80103eb7:	c3                   	ret    

80103eb8 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80103eb8:	55                   	push   %ebp
80103eb9:	89 e5                	mov    %esp,%ebp
80103ebb:	83 ec 0c             	sub    $0xc,%esp
80103ebe:	8b 45 08             	mov    0x8(%ebp),%eax
80103ec1:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80103ec5:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103ec9:	66 a3 00 c0 10 80    	mov    %ax,0x8010c000
  outb(IO_PIC1+1, mask);
80103ecf:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103ed3:	0f b6 c0             	movzbl %al,%eax
80103ed6:	89 44 24 04          	mov    %eax,0x4(%esp)
80103eda:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103ee1:	e8 b4 ff ff ff       	call   80103e9a <outb>
  outb(IO_PIC2+1, mask >> 8);
80103ee6:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103eea:	66 c1 e8 08          	shr    $0x8,%ax
80103eee:	0f b6 c0             	movzbl %al,%eax
80103ef1:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ef5:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103efc:	e8 99 ff ff ff       	call   80103e9a <outb>
}
80103f01:	c9                   	leave  
80103f02:	c3                   	ret    

80103f03 <picenable>:

void
picenable(int irq)
{
80103f03:	55                   	push   %ebp
80103f04:	89 e5                	mov    %esp,%ebp
80103f06:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80103f09:	8b 45 08             	mov    0x8(%ebp),%eax
80103f0c:	ba 01 00 00 00       	mov    $0x1,%edx
80103f11:	89 c1                	mov    %eax,%ecx
80103f13:	d3 e2                	shl    %cl,%edx
80103f15:	89 d0                	mov    %edx,%eax
80103f17:	f7 d0                	not    %eax
80103f19:	89 c2                	mov    %eax,%edx
80103f1b:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80103f22:	21 d0                	and    %edx,%eax
80103f24:	0f b7 c0             	movzwl %ax,%eax
80103f27:	89 04 24             	mov    %eax,(%esp)
80103f2a:	e8 89 ff ff ff       	call   80103eb8 <picsetmask>
}
80103f2f:	c9                   	leave  
80103f30:	c3                   	ret    

80103f31 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80103f31:	55                   	push   %ebp
80103f32:	89 e5                	mov    %esp,%ebp
80103f34:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103f37:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103f3e:	00 
80103f3f:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103f46:	e8 4f ff ff ff       	call   80103e9a <outb>
  outb(IO_PIC2+1, 0xFF);
80103f4b:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103f52:	00 
80103f53:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103f5a:	e8 3b ff ff ff       	call   80103e9a <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80103f5f:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103f66:	00 
80103f67:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103f6e:	e8 27 ff ff ff       	call   80103e9a <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80103f73:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80103f7a:	00 
80103f7b:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103f82:	e8 13 ff ff ff       	call   80103e9a <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80103f87:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80103f8e:	00 
80103f8f:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103f96:	e8 ff fe ff ff       	call   80103e9a <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80103f9b:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103fa2:	00 
80103fa3:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103faa:	e8 eb fe ff ff       	call   80103e9a <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80103faf:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103fb6:	00 
80103fb7:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103fbe:	e8 d7 fe ff ff       	call   80103e9a <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80103fc3:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80103fca:	00 
80103fcb:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103fd2:	e8 c3 fe ff ff       	call   80103e9a <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80103fd7:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80103fde:	00 
80103fdf:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103fe6:	e8 af fe ff ff       	call   80103e9a <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80103feb:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103ff2:	00 
80103ff3:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103ffa:	e8 9b fe ff ff       	call   80103e9a <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80103fff:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104006:	00 
80104007:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010400e:	e8 87 fe ff ff       	call   80103e9a <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80104013:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
8010401a:	00 
8010401b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104022:	e8 73 fe ff ff       	call   80103e9a <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80104027:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
8010402e:	00 
8010402f:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104036:	e8 5f fe ff ff       	call   80103e9a <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
8010403b:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104042:	00 
80104043:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010404a:	e8 4b fe ff ff       	call   80103e9a <outb>

  if(irqmask != 0xFFFF)
8010404f:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104056:	66 83 f8 ff          	cmp    $0xffff,%ax
8010405a:	74 12                	je     8010406e <picinit+0x13d>
    picsetmask(irqmask);
8010405c:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104063:	0f b7 c0             	movzwl %ax,%eax
80104066:	89 04 24             	mov    %eax,(%esp)
80104069:	e8 4a fe ff ff       	call   80103eb8 <picsetmask>
}
8010406e:	c9                   	leave  
8010406f:	c3                   	ret    

80104070 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80104070:	55                   	push   %ebp
80104071:	89 e5                	mov    %esp,%ebp
80104073:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80104076:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
8010407d:	8b 45 0c             	mov    0xc(%ebp),%eax
80104080:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80104086:	8b 45 0c             	mov    0xc(%ebp),%eax
80104089:	8b 10                	mov    (%eax),%edx
8010408b:	8b 45 08             	mov    0x8(%ebp),%eax
8010408e:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80104090:	e8 c0 ce ff ff       	call   80100f55 <filealloc>
80104095:	8b 55 08             	mov    0x8(%ebp),%edx
80104098:	89 02                	mov    %eax,(%edx)
8010409a:	8b 45 08             	mov    0x8(%ebp),%eax
8010409d:	8b 00                	mov    (%eax),%eax
8010409f:	85 c0                	test   %eax,%eax
801040a1:	0f 84 c8 00 00 00    	je     8010416f <pipealloc+0xff>
801040a7:	e8 a9 ce ff ff       	call   80100f55 <filealloc>
801040ac:	8b 55 0c             	mov    0xc(%ebp),%edx
801040af:	89 02                	mov    %eax,(%edx)
801040b1:	8b 45 0c             	mov    0xc(%ebp),%eax
801040b4:	8b 00                	mov    (%eax),%eax
801040b6:	85 c0                	test   %eax,%eax
801040b8:	0f 84 b1 00 00 00    	je     8010416f <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
801040be:	e8 69 eb ff ff       	call   80102c2c <kalloc>
801040c3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801040c6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801040ca:	75 05                	jne    801040d1 <pipealloc+0x61>
    goto bad;
801040cc:	e9 9e 00 00 00       	jmp    8010416f <pipealloc+0xff>
  p->readopen = 1;
801040d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040d4:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
801040db:	00 00 00 
  p->writeopen = 1;
801040de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040e1:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
801040e8:	00 00 00 
  p->nwrite = 0;
801040eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040ee:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
801040f5:	00 00 00 
  p->nread = 0;
801040f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040fb:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80104102:	00 00 00 
  initlock(&p->lock, "pipe");
80104105:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104108:	c7 44 24 04 44 90 10 	movl   $0x80109044,0x4(%esp)
8010410f:	80 
80104110:	89 04 24             	mov    %eax,(%esp)
80104113:	e8 0c 16 00 00       	call   80105724 <initlock>
  (*f0)->type = FD_PIPE;
80104118:	8b 45 08             	mov    0x8(%ebp),%eax
8010411b:	8b 00                	mov    (%eax),%eax
8010411d:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80104123:	8b 45 08             	mov    0x8(%ebp),%eax
80104126:	8b 00                	mov    (%eax),%eax
80104128:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
8010412c:	8b 45 08             	mov    0x8(%ebp),%eax
8010412f:	8b 00                	mov    (%eax),%eax
80104131:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80104135:	8b 45 08             	mov    0x8(%ebp),%eax
80104138:	8b 00                	mov    (%eax),%eax
8010413a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010413d:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80104140:	8b 45 0c             	mov    0xc(%ebp),%eax
80104143:	8b 00                	mov    (%eax),%eax
80104145:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
8010414b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010414e:	8b 00                	mov    (%eax),%eax
80104150:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80104154:	8b 45 0c             	mov    0xc(%ebp),%eax
80104157:	8b 00                	mov    (%eax),%eax
80104159:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
8010415d:	8b 45 0c             	mov    0xc(%ebp),%eax
80104160:	8b 00                	mov    (%eax),%eax
80104162:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104165:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80104168:	b8 00 00 00 00       	mov    $0x0,%eax
8010416d:	eb 42                	jmp    801041b1 <pipealloc+0x141>

//PAGEBREAK: 20
 bad:
  if(p)
8010416f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104173:	74 0b                	je     80104180 <pipealloc+0x110>
    kfree((char*)p);
80104175:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104178:	89 04 24             	mov    %eax,(%esp)
8010417b:	e8 13 ea ff ff       	call   80102b93 <kfree>
  if(*f0)
80104180:	8b 45 08             	mov    0x8(%ebp),%eax
80104183:	8b 00                	mov    (%eax),%eax
80104185:	85 c0                	test   %eax,%eax
80104187:	74 0d                	je     80104196 <pipealloc+0x126>
    fileclose(*f0);
80104189:	8b 45 08             	mov    0x8(%ebp),%eax
8010418c:	8b 00                	mov    (%eax),%eax
8010418e:	89 04 24             	mov    %eax,(%esp)
80104191:	e8 67 ce ff ff       	call   80100ffd <fileclose>
  if(*f1)
80104196:	8b 45 0c             	mov    0xc(%ebp),%eax
80104199:	8b 00                	mov    (%eax),%eax
8010419b:	85 c0                	test   %eax,%eax
8010419d:	74 0d                	je     801041ac <pipealloc+0x13c>
    fileclose(*f1);
8010419f:	8b 45 0c             	mov    0xc(%ebp),%eax
801041a2:	8b 00                	mov    (%eax),%eax
801041a4:	89 04 24             	mov    %eax,(%esp)
801041a7:	e8 51 ce ff ff       	call   80100ffd <fileclose>
  return -1;
801041ac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801041b1:	c9                   	leave  
801041b2:	c3                   	ret    

801041b3 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
801041b3:	55                   	push   %ebp
801041b4:	89 e5                	mov    %esp,%ebp
801041b6:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
801041b9:	8b 45 08             	mov    0x8(%ebp),%eax
801041bc:	89 04 24             	mov    %eax,(%esp)
801041bf:	e8 81 15 00 00       	call   80105745 <acquire>
  if(writable){
801041c4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801041c8:	74 1f                	je     801041e9 <pipeclose+0x36>
    p->writeopen = 0;
801041ca:	8b 45 08             	mov    0x8(%ebp),%eax
801041cd:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
801041d4:	00 00 00 
    wakeup(&p->nread);
801041d7:	8b 45 08             	mov    0x8(%ebp),%eax
801041da:	05 34 02 00 00       	add    $0x234,%eax
801041df:	89 04 24             	mov    %eax,(%esp)
801041e2:	e8 b9 0b 00 00       	call   80104da0 <wakeup>
801041e7:	eb 1d                	jmp    80104206 <pipeclose+0x53>
  } else {
    p->readopen = 0;
801041e9:	8b 45 08             	mov    0x8(%ebp),%eax
801041ec:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
801041f3:	00 00 00 
    wakeup(&p->nwrite);
801041f6:	8b 45 08             	mov    0x8(%ebp),%eax
801041f9:	05 38 02 00 00       	add    $0x238,%eax
801041fe:	89 04 24             	mov    %eax,(%esp)
80104201:	e8 9a 0b 00 00       	call   80104da0 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80104206:	8b 45 08             	mov    0x8(%ebp),%eax
80104209:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
8010420f:	85 c0                	test   %eax,%eax
80104211:	75 25                	jne    80104238 <pipeclose+0x85>
80104213:	8b 45 08             	mov    0x8(%ebp),%eax
80104216:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
8010421c:	85 c0                	test   %eax,%eax
8010421e:	75 18                	jne    80104238 <pipeclose+0x85>
    release(&p->lock);
80104220:	8b 45 08             	mov    0x8(%ebp),%eax
80104223:	89 04 24             	mov    %eax,(%esp)
80104226:	e8 7c 15 00 00       	call   801057a7 <release>
    kfree((char*)p);
8010422b:	8b 45 08             	mov    0x8(%ebp),%eax
8010422e:	89 04 24             	mov    %eax,(%esp)
80104231:	e8 5d e9 ff ff       	call   80102b93 <kfree>
80104236:	eb 0b                	jmp    80104243 <pipeclose+0x90>
  } else
    release(&p->lock);
80104238:	8b 45 08             	mov    0x8(%ebp),%eax
8010423b:	89 04 24             	mov    %eax,(%esp)
8010423e:	e8 64 15 00 00       	call   801057a7 <release>
}
80104243:	c9                   	leave  
80104244:	c3                   	ret    

80104245 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80104245:	55                   	push   %ebp
80104246:	89 e5                	mov    %esp,%ebp
80104248:	83 ec 28             	sub    $0x28,%esp
  int i;

  acquire(&p->lock);
8010424b:	8b 45 08             	mov    0x8(%ebp),%eax
8010424e:	89 04 24             	mov    %eax,(%esp)
80104251:	e8 ef 14 00 00       	call   80105745 <acquire>
  for(i = 0; i < n; i++){
80104256:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010425d:	e9 a6 00 00 00       	jmp    80104308 <pipewrite+0xc3>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104262:	eb 57                	jmp    801042bb <pipewrite+0x76>
      if(p->readopen == 0 || proc->killed){
80104264:	8b 45 08             	mov    0x8(%ebp),%eax
80104267:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
8010426d:	85 c0                	test   %eax,%eax
8010426f:	74 0d                	je     8010427e <pipewrite+0x39>
80104271:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104277:	8b 40 24             	mov    0x24(%eax),%eax
8010427a:	85 c0                	test   %eax,%eax
8010427c:	74 15                	je     80104293 <pipewrite+0x4e>
        release(&p->lock);
8010427e:	8b 45 08             	mov    0x8(%ebp),%eax
80104281:	89 04 24             	mov    %eax,(%esp)
80104284:	e8 1e 15 00 00       	call   801057a7 <release>
        return -1;
80104289:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010428e:	e9 9f 00 00 00       	jmp    80104332 <pipewrite+0xed>
      }
      wakeup(&p->nread);
80104293:	8b 45 08             	mov    0x8(%ebp),%eax
80104296:	05 34 02 00 00       	add    $0x234,%eax
8010429b:	89 04 24             	mov    %eax,(%esp)
8010429e:	e8 fd 0a 00 00       	call   80104da0 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
801042a3:	8b 45 08             	mov    0x8(%ebp),%eax
801042a6:	8b 55 08             	mov    0x8(%ebp),%edx
801042a9:	81 c2 38 02 00 00    	add    $0x238,%edx
801042af:	89 44 24 04          	mov    %eax,0x4(%esp)
801042b3:	89 14 24             	mov    %edx,(%esp)
801042b6:	e8 09 0a 00 00       	call   80104cc4 <sleep>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801042bb:	8b 45 08             	mov    0x8(%ebp),%eax
801042be:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
801042c4:	8b 45 08             	mov    0x8(%ebp),%eax
801042c7:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801042cd:	05 00 02 00 00       	add    $0x200,%eax
801042d2:	39 c2                	cmp    %eax,%edx
801042d4:	74 8e                	je     80104264 <pipewrite+0x1f>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
801042d6:	8b 45 08             	mov    0x8(%ebp),%eax
801042d9:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801042df:	8d 48 01             	lea    0x1(%eax),%ecx
801042e2:	8b 55 08             	mov    0x8(%ebp),%edx
801042e5:	89 8a 38 02 00 00    	mov    %ecx,0x238(%edx)
801042eb:	25 ff 01 00 00       	and    $0x1ff,%eax
801042f0:	89 c1                	mov    %eax,%ecx
801042f2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042f5:	8b 45 0c             	mov    0xc(%ebp),%eax
801042f8:	01 d0                	add    %edx,%eax
801042fa:	0f b6 10             	movzbl (%eax),%edx
801042fd:	8b 45 08             	mov    0x8(%ebp),%eax
80104300:	88 54 08 34          	mov    %dl,0x34(%eax,%ecx,1)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80104304:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104308:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010430b:	3b 45 10             	cmp    0x10(%ebp),%eax
8010430e:	0f 8c 4e ff ff ff    	jl     80104262 <pipewrite+0x1d>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80104314:	8b 45 08             	mov    0x8(%ebp),%eax
80104317:	05 34 02 00 00       	add    $0x234,%eax
8010431c:	89 04 24             	mov    %eax,(%esp)
8010431f:	e8 7c 0a 00 00       	call   80104da0 <wakeup>
  release(&p->lock);
80104324:	8b 45 08             	mov    0x8(%ebp),%eax
80104327:	89 04 24             	mov    %eax,(%esp)
8010432a:	e8 78 14 00 00       	call   801057a7 <release>
  return n;
8010432f:	8b 45 10             	mov    0x10(%ebp),%eax
}
80104332:	c9                   	leave  
80104333:	c3                   	ret    

80104334 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80104334:	55                   	push   %ebp
80104335:	89 e5                	mov    %esp,%ebp
80104337:	53                   	push   %ebx
80104338:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
8010433b:	8b 45 08             	mov    0x8(%ebp),%eax
8010433e:	89 04 24             	mov    %eax,(%esp)
80104341:	e8 ff 13 00 00       	call   80105745 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104346:	eb 3a                	jmp    80104382 <piperead+0x4e>
    if(proc->killed){
80104348:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010434e:	8b 40 24             	mov    0x24(%eax),%eax
80104351:	85 c0                	test   %eax,%eax
80104353:	74 15                	je     8010436a <piperead+0x36>
      release(&p->lock);
80104355:	8b 45 08             	mov    0x8(%ebp),%eax
80104358:	89 04 24             	mov    %eax,(%esp)
8010435b:	e8 47 14 00 00       	call   801057a7 <release>
      return -1;
80104360:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104365:	e9 b5 00 00 00       	jmp    8010441f <piperead+0xeb>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
8010436a:	8b 45 08             	mov    0x8(%ebp),%eax
8010436d:	8b 55 08             	mov    0x8(%ebp),%edx
80104370:	81 c2 34 02 00 00    	add    $0x234,%edx
80104376:	89 44 24 04          	mov    %eax,0x4(%esp)
8010437a:	89 14 24             	mov    %edx,(%esp)
8010437d:	e8 42 09 00 00       	call   80104cc4 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104382:	8b 45 08             	mov    0x8(%ebp),%eax
80104385:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
8010438b:	8b 45 08             	mov    0x8(%ebp),%eax
8010438e:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104394:	39 c2                	cmp    %eax,%edx
80104396:	75 0d                	jne    801043a5 <piperead+0x71>
80104398:	8b 45 08             	mov    0x8(%ebp),%eax
8010439b:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801043a1:	85 c0                	test   %eax,%eax
801043a3:	75 a3                	jne    80104348 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801043a5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801043ac:	eb 4b                	jmp    801043f9 <piperead+0xc5>
    if(p->nread == p->nwrite)
801043ae:	8b 45 08             	mov    0x8(%ebp),%eax
801043b1:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801043b7:	8b 45 08             	mov    0x8(%ebp),%eax
801043ba:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801043c0:	39 c2                	cmp    %eax,%edx
801043c2:	75 02                	jne    801043c6 <piperead+0x92>
      break;
801043c4:	eb 3b                	jmp    80104401 <piperead+0xcd>
    addr[i] = p->data[p->nread++ % PIPESIZE];
801043c6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801043c9:	8b 45 0c             	mov    0xc(%ebp),%eax
801043cc:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
801043cf:	8b 45 08             	mov    0x8(%ebp),%eax
801043d2:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801043d8:	8d 48 01             	lea    0x1(%eax),%ecx
801043db:	8b 55 08             	mov    0x8(%ebp),%edx
801043de:	89 8a 34 02 00 00    	mov    %ecx,0x234(%edx)
801043e4:	25 ff 01 00 00       	and    $0x1ff,%eax
801043e9:	89 c2                	mov    %eax,%edx
801043eb:	8b 45 08             	mov    0x8(%ebp),%eax
801043ee:	0f b6 44 10 34       	movzbl 0x34(%eax,%edx,1),%eax
801043f3:	88 03                	mov    %al,(%ebx)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801043f5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801043f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043fc:	3b 45 10             	cmp    0x10(%ebp),%eax
801043ff:	7c ad                	jl     801043ae <piperead+0x7a>
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80104401:	8b 45 08             	mov    0x8(%ebp),%eax
80104404:	05 38 02 00 00       	add    $0x238,%eax
80104409:	89 04 24             	mov    %eax,(%esp)
8010440c:	e8 8f 09 00 00       	call   80104da0 <wakeup>
  release(&p->lock);
80104411:	8b 45 08             	mov    0x8(%ebp),%eax
80104414:	89 04 24             	mov    %eax,(%esp)
80104417:	e8 8b 13 00 00       	call   801057a7 <release>
  return i;
8010441c:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010441f:	83 c4 24             	add    $0x24,%esp
80104422:	5b                   	pop    %ebx
80104423:	5d                   	pop    %ebp
80104424:	c3                   	ret    

80104425 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104425:	55                   	push   %ebp
80104426:	89 e5                	mov    %esp,%ebp
80104428:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010442b:	9c                   	pushf  
8010442c:	58                   	pop    %eax
8010442d:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80104430:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104433:	c9                   	leave  
80104434:	c3                   	ret    

80104435 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104435:	55                   	push   %ebp
80104436:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104438:	fb                   	sti    
}
80104439:	5d                   	pop    %ebp
8010443a:	c3                   	ret    

8010443b <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
8010443b:	55                   	push   %ebp
8010443c:	89 e5                	mov    %esp,%ebp
8010443e:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104441:	c7 44 24 04 49 90 10 	movl   $0x80109049,0x4(%esp)
80104448:	80 
80104449:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104450:	e8 cf 12 00 00       	call   80105724 <initlock>
}
80104455:	c9                   	leave  
80104456:	c3                   	ret    

80104457 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104457:	55                   	push   %ebp
80104458:	89 e5                	mov    %esp,%ebp
8010445a:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
8010445d:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104464:	e8 dc 12 00 00       	call   80105745 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104469:	c7 45 f4 d4 39 11 80 	movl   $0x801139d4,-0xc(%ebp)
80104470:	eb 53                	jmp    801044c5 <allocproc+0x6e>
    if(p->state == UNUSED)
80104472:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104475:	8b 40 0c             	mov    0xc(%eax),%eax
80104478:	85 c0                	test   %eax,%eax
8010447a:	75 42                	jne    801044be <allocproc+0x67>
      goto found;
8010447c:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
8010447d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104480:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
80104487:	a1 04 c0 10 80       	mov    0x8010c004,%eax
8010448c:	8d 50 01             	lea    0x1(%eax),%edx
8010448f:	89 15 04 c0 10 80    	mov    %edx,0x8010c004
80104495:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104498:	89 42 10             	mov    %eax,0x10(%edx)
  release(&ptable.lock);
8010449b:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
801044a2:	e8 00 13 00 00       	call   801057a7 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
801044a7:	e8 80 e7 ff ff       	call   80102c2c <kalloc>
801044ac:	8b 55 f4             	mov    -0xc(%ebp),%edx
801044af:	89 42 08             	mov    %eax,0x8(%edx)
801044b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044b5:	8b 40 08             	mov    0x8(%eax),%eax
801044b8:	85 c0                	test   %eax,%eax
801044ba:	75 36                	jne    801044f2 <allocproc+0x9b>
801044bc:	eb 23                	jmp    801044e1 <allocproc+0x8a>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801044be:	81 45 f4 e4 00 00 00 	addl   $0xe4,-0xc(%ebp)
801044c5:	81 7d f4 d4 72 11 80 	cmpl   $0x801172d4,-0xc(%ebp)
801044cc:	72 a4                	jb     80104472 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
801044ce:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
801044d5:	e8 cd 12 00 00       	call   801057a7 <release>
  return 0;
801044da:	b8 00 00 00 00       	mov    $0x0,%eax
801044df:	eb 76                	jmp    80104557 <allocproc+0x100>
  p->pid = nextpid++;
  release(&ptable.lock);

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
    p->state = UNUSED;
801044e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044e4:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
801044eb:	b8 00 00 00 00       	mov    $0x0,%eax
801044f0:	eb 65                	jmp    80104557 <allocproc+0x100>
  }
  sp = p->kstack + KSTACKSIZE;
801044f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044f5:	8b 40 08             	mov    0x8(%eax),%eax
801044f8:	05 00 10 00 00       	add    $0x1000,%eax
801044fd:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104500:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80104504:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104507:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010450a:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
8010450d:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80104511:	ba 13 6e 10 80       	mov    $0x80106e13,%edx
80104516:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104519:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
8010451b:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
8010451f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104522:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104525:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
80104528:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010452b:	8b 40 1c             	mov    0x1c(%eax),%eax
8010452e:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104535:	00 
80104536:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010453d:	00 
8010453e:	89 04 24             	mov    %eax,(%esp)
80104541:	e8 53 14 00 00       	call   80105999 <memset>
  p->context->eip = (uint)forkret;
80104546:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104549:	8b 40 1c             	mov    0x1c(%eax),%eax
8010454c:	ba 98 4c 10 80       	mov    $0x80104c98,%edx
80104551:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
80104554:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104557:	c9                   	leave  
80104558:	c3                   	ret    

80104559 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
80104559:	55                   	push   %ebp
8010455a:	89 e5                	mov    %esp,%ebp
8010455c:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
8010455f:	e8 f3 fe ff ff       	call   80104457 <allocproc>
80104564:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80104567:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010456a:	a3 48 c6 10 80       	mov    %eax,0x8010c648
  if((p->pgdir = setupkvm()) == 0)
8010456f:	e8 93 3f 00 00       	call   80108507 <setupkvm>
80104574:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104577:	89 42 04             	mov    %eax,0x4(%edx)
8010457a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010457d:	8b 40 04             	mov    0x4(%eax),%eax
80104580:	85 c0                	test   %eax,%eax
80104582:	75 0c                	jne    80104590 <userinit+0x37>
    panic("userinit: out of memory?");
80104584:	c7 04 24 50 90 10 80 	movl   $0x80109050,(%esp)
8010458b:	e8 aa bf ff ff       	call   8010053a <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104590:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104595:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104598:	8b 40 04             	mov    0x4(%eax),%eax
8010459b:	89 54 24 08          	mov    %edx,0x8(%esp)
8010459f:	c7 44 24 04 e0 c4 10 	movl   $0x8010c4e0,0x4(%esp)
801045a6:	80 
801045a7:	89 04 24             	mov    %eax,(%esp)
801045aa:	e8 b0 41 00 00       	call   8010875f <inituvm>
  p->sz = PGSIZE;
801045af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045b2:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
801045b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045bb:	8b 40 18             	mov    0x18(%eax),%eax
801045be:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
801045c5:	00 
801045c6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801045cd:	00 
801045ce:	89 04 24             	mov    %eax,(%esp)
801045d1:	e8 c3 13 00 00       	call   80105999 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801045d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045d9:	8b 40 18             	mov    0x18(%eax),%eax
801045dc:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801045e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045e5:	8b 40 18             	mov    0x18(%eax),%eax
801045e8:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
801045ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045f1:	8b 40 18             	mov    0x18(%eax),%eax
801045f4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801045f7:	8b 52 18             	mov    0x18(%edx),%edx
801045fa:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801045fe:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80104602:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104605:	8b 40 18             	mov    0x18(%eax),%eax
80104608:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010460b:	8b 52 18             	mov    0x18(%edx),%edx
8010460e:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104612:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80104616:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104619:	8b 40 18             	mov    0x18(%eax),%eax
8010461c:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80104623:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104626:	8b 40 18             	mov    0x18(%eax),%eax
80104629:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104630:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104633:	8b 40 18             	mov    0x18(%eax),%eax
80104636:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
8010463d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104640:	83 c0 28             	add    $0x28,%eax
80104643:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010464a:	00 
8010464b:	c7 44 24 04 69 90 10 	movl   $0x80109069,0x4(%esp)
80104652:	80 
80104653:	89 04 24             	mov    %eax,(%esp)
80104656:	e8 5e 15 00 00       	call   80105bb9 <safestrcpy>
  p->cwd = namei("/");
8010465b:	c7 04 24 72 90 10 80 	movl   $0x80109072,(%esp)
80104662:	e8 e9 de ff ff       	call   80102550 <namei>
80104667:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010466a:	89 42 78             	mov    %eax,0x78(%edx)
  p->exe=0;
8010466d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104670:	c7 40 7c 00 00 00 00 	movl   $0x0,0x7c(%eax)
  p->state = RUNNABLE;
80104677:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010467a:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
80104681:	c9                   	leave  
80104682:	c3                   	ret    

80104683 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104683:	55                   	push   %ebp
80104684:	89 e5                	mov    %esp,%ebp
80104686:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
80104689:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010468f:	8b 00                	mov    (%eax),%eax
80104691:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104694:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104698:	7e 34                	jle    801046ce <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
8010469a:	8b 55 08             	mov    0x8(%ebp),%edx
8010469d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046a0:	01 c2                	add    %eax,%edx
801046a2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046a8:	8b 40 04             	mov    0x4(%eax),%eax
801046ab:	89 54 24 08          	mov    %edx,0x8(%esp)
801046af:	8b 55 f4             	mov    -0xc(%ebp),%edx
801046b2:	89 54 24 04          	mov    %edx,0x4(%esp)
801046b6:	89 04 24             	mov    %eax,(%esp)
801046b9:	e8 17 42 00 00       	call   801088d5 <allocuvm>
801046be:	89 45 f4             	mov    %eax,-0xc(%ebp)
801046c1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801046c5:	75 41                	jne    80104708 <growproc+0x85>
      return -1;
801046c7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046cc:	eb 58                	jmp    80104726 <growproc+0xa3>
  } else if(n < 0){
801046ce:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801046d2:	79 34                	jns    80104708 <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
801046d4:	8b 55 08             	mov    0x8(%ebp),%edx
801046d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046da:	01 c2                	add    %eax,%edx
801046dc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046e2:	8b 40 04             	mov    0x4(%eax),%eax
801046e5:	89 54 24 08          	mov    %edx,0x8(%esp)
801046e9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801046ec:	89 54 24 04          	mov    %edx,0x4(%esp)
801046f0:	89 04 24             	mov    %eax,(%esp)
801046f3:	e8 b7 42 00 00       	call   801089af <deallocuvm>
801046f8:	89 45 f4             	mov    %eax,-0xc(%ebp)
801046fb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801046ff:	75 07                	jne    80104708 <growproc+0x85>
      return -1;
80104701:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104706:	eb 1e                	jmp    80104726 <growproc+0xa3>
  }
  proc->sz = sz;
80104708:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010470e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104711:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104713:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104719:	89 04 24             	mov    %eax,(%esp)
8010471c:	e8 d7 3e 00 00       	call   801085f8 <switchuvm>
  return 0;
80104721:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104726:	c9                   	leave  
80104727:	c3                   	ret    

80104728 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80104728:	55                   	push   %ebp
80104729:	89 e5                	mov    %esp,%ebp
8010472b:	57                   	push   %edi
8010472c:	56                   	push   %esi
8010472d:	53                   	push   %ebx
8010472e:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104731:	e8 21 fd ff ff       	call   80104457 <allocproc>
80104736:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104739:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
8010473d:	75 0a                	jne    80104749 <fork+0x21>
    return -1;
8010473f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104744:	e9 91 01 00 00       	jmp    801048da <fork+0x1b2>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
80104749:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010474f:	8b 10                	mov    (%eax),%edx
80104751:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104757:	8b 40 04             	mov    0x4(%eax),%eax
8010475a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010475e:	89 04 24             	mov    %eax,(%esp)
80104761:	e8 e5 43 00 00       	call   80108b4b <copyuvm>
80104766:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104769:	89 42 04             	mov    %eax,0x4(%edx)
8010476c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010476f:	8b 40 04             	mov    0x4(%eax),%eax
80104772:	85 c0                	test   %eax,%eax
80104774:	75 2c                	jne    801047a2 <fork+0x7a>
    kfree(np->kstack);
80104776:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104779:	8b 40 08             	mov    0x8(%eax),%eax
8010477c:	89 04 24             	mov    %eax,(%esp)
8010477f:	e8 0f e4 ff ff       	call   80102b93 <kfree>
    np->kstack = 0;
80104784:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104787:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
8010478e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104791:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80104798:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010479d:	e9 38 01 00 00       	jmp    801048da <fork+0x1b2>
  }
  np->sz = proc->sz;
801047a2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047a8:	8b 10                	mov    (%eax),%edx
801047aa:	8b 45 e0             	mov    -0x20(%ebp),%eax
801047ad:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
801047af:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801047b6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801047b9:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
801047bc:	8b 45 e0             	mov    -0x20(%ebp),%eax
801047bf:	8b 50 18             	mov    0x18(%eax),%edx
801047c2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047c8:	8b 40 18             	mov    0x18(%eax),%eax
801047cb:	89 c3                	mov    %eax,%ebx
801047cd:	b8 13 00 00 00       	mov    $0x13,%eax
801047d2:	89 d7                	mov    %edx,%edi
801047d4:	89 de                	mov    %ebx,%esi
801047d6:	89 c1                	mov    %eax,%ecx
801047d8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
801047da:	8b 45 e0             	mov    -0x20(%ebp),%eax
801047dd:	8b 40 18             	mov    0x18(%eax),%eax
801047e0:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
801047e7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801047ee:	eb 3d                	jmp    8010482d <fork+0x105>
    if(proc->ofile[i])
801047f0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047f6:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801047f9:	83 c2 0c             	add    $0xc,%edx
801047fc:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104800:	85 c0                	test   %eax,%eax
80104802:	74 25                	je     80104829 <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
80104804:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010480a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010480d:	83 c2 0c             	add    $0xc,%edx
80104810:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104814:	89 04 24             	mov    %eax,(%esp)
80104817:	e8 99 c7 ff ff       	call   80100fb5 <filedup>
8010481c:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010481f:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80104822:	83 c1 0c             	add    $0xc,%ecx
80104825:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80104829:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
8010482d:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104831:	7e bd                	jle    801047f0 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
80104833:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104839:	8b 40 78             	mov    0x78(%eax),%eax
8010483c:	89 04 24             	mov    %eax,(%esp)
8010483f:	e8 14 d0 ff ff       	call   80101858 <idup>
80104844:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104847:	89 42 78             	mov    %eax,0x78(%edx)

  safestrcpy(np->name, proc->name, sizeof(proc->name));
8010484a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104850:	8d 50 28             	lea    0x28(%eax),%edx
80104853:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104856:	83 c0 28             	add    $0x28,%eax
80104859:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104860:	00 
80104861:	89 54 24 04          	mov    %edx,0x4(%esp)
80104865:	89 04 24             	mov    %eax,(%esp)
80104868:	e8 4c 13 00 00       	call   80105bb9 <safestrcpy>
 
  pid = np->pid;
8010486d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104870:	8b 40 10             	mov    0x10(%eax),%eax
80104873:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
80104876:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104879:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  np->exe = proc->exe;
80104880:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104886:	8b 50 7c             	mov    0x7c(%eax),%edx
80104889:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010488c:	89 50 7c             	mov    %edx,0x7c(%eax)
  safestrcpy(np->cmdline, proc->cmdline, sizeof( proc->cmdline));
8010488f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104895:	8d 90 80 00 00 00    	lea    0x80(%eax),%edx
8010489b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010489e:	83 e8 80             	sub    $0xffffff80,%eax
801048a1:	c7 44 24 08 64 00 00 	movl   $0x64,0x8(%esp)
801048a8:	00 
801048a9:	89 54 24 04          	mov    %edx,0x4(%esp)
801048ad:	89 04 24             	mov    %eax,(%esp)
801048b0:	e8 04 13 00 00       	call   80105bb9 <safestrcpy>
 
  // lock to force the compiler to emit the np->state write last.
  acquire(&ptable.lock);
801048b5:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
801048bc:	e8 84 0e 00 00       	call   80105745 <acquire>
  np->state = RUNNABLE;
801048c1:	8b 45 e0             	mov    -0x20(%ebp),%eax
801048c4:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  release(&ptable.lock);
801048cb:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
801048d2:	e8 d0 0e 00 00       	call   801057a7 <release>
  
  return pid;
801048d7:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
801048da:	83 c4 2c             	add    $0x2c,%esp
801048dd:	5b                   	pop    %ebx
801048de:	5e                   	pop    %esi
801048df:	5f                   	pop    %edi
801048e0:	5d                   	pop    %ebp
801048e1:	c3                   	ret    

801048e2 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
801048e2:	55                   	push   %ebp
801048e3:	89 e5                	mov    %esp,%ebp
801048e5:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
801048e8:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801048ef:	a1 48 c6 10 80       	mov    0x8010c648,%eax
801048f4:	39 c2                	cmp    %eax,%edx
801048f6:	75 0c                	jne    80104904 <exit+0x22>
    panic("init exiting");
801048f8:	c7 04 24 74 90 10 80 	movl   $0x80109074,(%esp)
801048ff:	e8 36 bc ff ff       	call   8010053a <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104904:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010490b:	eb 44                	jmp    80104951 <exit+0x6f>
    if(proc->ofile[fd]){
8010490d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104913:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104916:	83 c2 0c             	add    $0xc,%edx
80104919:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010491d:	85 c0                	test   %eax,%eax
8010491f:	74 2c                	je     8010494d <exit+0x6b>
      fileclose(proc->ofile[fd]);
80104921:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104927:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010492a:	83 c2 0c             	add    $0xc,%edx
8010492d:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104931:	89 04 24             	mov    %eax,(%esp)
80104934:	e8 c4 c6 ff ff       	call   80100ffd <fileclose>
      proc->ofile[fd] = 0;
80104939:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010493f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104942:	83 c2 0c             	add    $0xc,%edx
80104945:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010494c:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
8010494d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104951:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104955:	7e b6                	jle    8010490d <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  begin_op();
80104957:	e8 fe eb ff ff       	call   8010355a <begin_op>
  iput(proc->cwd);
8010495c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104962:	8b 40 78             	mov    0x78(%eax),%eax
80104965:	89 04 24             	mov    %eax,(%esp)
80104968:	e8 d0 d0 ff ff       	call   80101a3d <iput>
  end_op();
8010496d:	e8 6c ec ff ff       	call   801035de <end_op>
  proc->cwd = 0;
80104972:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104978:	c7 40 78 00 00 00 00 	movl   $0x0,0x78(%eax)

  acquire(&ptable.lock);
8010497f:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104986:	e8 ba 0d 00 00       	call   80105745 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
8010498b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104991:	8b 40 14             	mov    0x14(%eax),%eax
80104994:	89 04 24             	mov    %eax,(%esp)
80104997:	e8 c3 03 00 00       	call   80104d5f <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010499c:	c7 45 f4 d4 39 11 80 	movl   $0x801139d4,-0xc(%ebp)
801049a3:	eb 3b                	jmp    801049e0 <exit+0xfe>
    if(p->parent == proc){
801049a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049a8:	8b 50 14             	mov    0x14(%eax),%edx
801049ab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049b1:	39 c2                	cmp    %eax,%edx
801049b3:	75 24                	jne    801049d9 <exit+0xf7>
      p->parent = initproc;
801049b5:	8b 15 48 c6 10 80    	mov    0x8010c648,%edx
801049bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049be:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
801049c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049c4:	8b 40 0c             	mov    0xc(%eax),%eax
801049c7:	83 f8 05             	cmp    $0x5,%eax
801049ca:	75 0d                	jne    801049d9 <exit+0xf7>
        wakeup1(initproc);
801049cc:	a1 48 c6 10 80       	mov    0x8010c648,%eax
801049d1:	89 04 24             	mov    %eax,(%esp)
801049d4:	e8 86 03 00 00       	call   80104d5f <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801049d9:	81 45 f4 e4 00 00 00 	addl   $0xe4,-0xc(%ebp)
801049e0:	81 7d f4 d4 72 11 80 	cmpl   $0x801172d4,-0xc(%ebp)
801049e7:	72 bc                	jb     801049a5 <exit+0xc3>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
801049e9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049ef:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
801049f6:	e8 b9 01 00 00       	call   80104bb4 <sched>
  panic("zombie exit");
801049fb:	c7 04 24 81 90 10 80 	movl   $0x80109081,(%esp)
80104a02:	e8 33 bb ff ff       	call   8010053a <panic>

80104a07 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
80104a07:	55                   	push   %ebp
80104a08:	89 e5                	mov    %esp,%ebp
80104a0a:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
80104a0d:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104a14:	e8 2c 0d 00 00       	call   80105745 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
80104a19:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104a20:	c7 45 f4 d4 39 11 80 	movl   $0x801139d4,-0xc(%ebp)
80104a27:	e9 9d 00 00 00       	jmp    80104ac9 <wait+0xc2>
      if(p->parent != proc)
80104a2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a2f:	8b 50 14             	mov    0x14(%eax),%edx
80104a32:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a38:	39 c2                	cmp    %eax,%edx
80104a3a:	74 05                	je     80104a41 <wait+0x3a>
        continue;
80104a3c:	e9 81 00 00 00       	jmp    80104ac2 <wait+0xbb>
      havekids = 1;
80104a41:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80104a48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a4b:	8b 40 0c             	mov    0xc(%eax),%eax
80104a4e:	83 f8 05             	cmp    $0x5,%eax
80104a51:	75 6f                	jne    80104ac2 <wait+0xbb>
        // Found one.
        pid = p->pid;
80104a53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a56:	8b 40 10             	mov    0x10(%eax),%eax
80104a59:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80104a5c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a5f:	8b 40 08             	mov    0x8(%eax),%eax
80104a62:	89 04 24             	mov    %eax,(%esp)
80104a65:	e8 29 e1 ff ff       	call   80102b93 <kfree>
        p->kstack = 0;
80104a6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a6d:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80104a74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a77:	8b 40 04             	mov    0x4(%eax),%eax
80104a7a:	89 04 24             	mov    %eax,(%esp)
80104a7d:	e8 e9 3f 00 00       	call   80108a6b <freevm>
        p->state = UNUSED;
80104a82:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a85:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80104a8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a8f:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80104a96:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a99:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80104aa0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aa3:	c6 40 28 00          	movb   $0x0,0x28(%eax)
        p->killed = 0;
80104aa7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aaa:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
80104ab1:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104ab8:	e8 ea 0c 00 00       	call   801057a7 <release>
        return pid;
80104abd:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104ac0:	eb 55                	jmp    80104b17 <wait+0x110>

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104ac2:	81 45 f4 e4 00 00 00 	addl   $0xe4,-0xc(%ebp)
80104ac9:	81 7d f4 d4 72 11 80 	cmpl   $0x801172d4,-0xc(%ebp)
80104ad0:	0f 82 56 ff ff ff    	jb     80104a2c <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80104ad6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104ada:	74 0d                	je     80104ae9 <wait+0xe2>
80104adc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ae2:	8b 40 24             	mov    0x24(%eax),%eax
80104ae5:	85 c0                	test   %eax,%eax
80104ae7:	74 13                	je     80104afc <wait+0xf5>
      release(&ptable.lock);
80104ae9:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104af0:	e8 b2 0c 00 00       	call   801057a7 <release>
      return -1;
80104af5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104afa:	eb 1b                	jmp    80104b17 <wait+0x110>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80104afc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b02:	c7 44 24 04 a0 39 11 	movl   $0x801139a0,0x4(%esp)
80104b09:	80 
80104b0a:	89 04 24             	mov    %eax,(%esp)
80104b0d:	e8 b2 01 00 00       	call   80104cc4 <sleep>
  }
80104b12:	e9 02 ff ff ff       	jmp    80104a19 <wait+0x12>
}
80104b17:	c9                   	leave  
80104b18:	c3                   	ret    

80104b19 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80104b19:	55                   	push   %ebp
80104b1a:	89 e5                	mov    %esp,%ebp
80104b1c:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
80104b1f:	e8 11 f9 ff ff       	call   80104435 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80104b24:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104b2b:	e8 15 0c 00 00       	call   80105745 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b30:	c7 45 f4 d4 39 11 80 	movl   $0x801139d4,-0xc(%ebp)
80104b37:	eb 61                	jmp    80104b9a <scheduler+0x81>
      if(p->state != RUNNABLE)
80104b39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b3c:	8b 40 0c             	mov    0xc(%eax),%eax
80104b3f:	83 f8 03             	cmp    $0x3,%eax
80104b42:	74 02                	je     80104b46 <scheduler+0x2d>
        continue;
80104b44:	eb 4d                	jmp    80104b93 <scheduler+0x7a>

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
80104b46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b49:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80104b4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b52:	89 04 24             	mov    %eax,(%esp)
80104b55:	e8 9e 3a 00 00       	call   801085f8 <switchuvm>
      p->state = RUNNING;
80104b5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b5d:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80104b64:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b6a:	8b 40 1c             	mov    0x1c(%eax),%eax
80104b6d:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104b74:	83 c2 04             	add    $0x4,%edx
80104b77:	89 44 24 04          	mov    %eax,0x4(%esp)
80104b7b:	89 14 24             	mov    %edx,(%esp)
80104b7e:	e8 a7 10 00 00       	call   80105c2a <swtch>
      switchkvm();
80104b83:	e8 53 3a 00 00       	call   801085db <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80104b88:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80104b8f:	00 00 00 00 
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b93:	81 45 f4 e4 00 00 00 	addl   $0xe4,-0xc(%ebp)
80104b9a:	81 7d f4 d4 72 11 80 	cmpl   $0x801172d4,-0xc(%ebp)
80104ba1:	72 96                	jb     80104b39 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80104ba3:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104baa:	e8 f8 0b 00 00       	call   801057a7 <release>

  }
80104baf:	e9 6b ff ff ff       	jmp    80104b1f <scheduler+0x6>

80104bb4 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80104bb4:	55                   	push   %ebp
80104bb5:	89 e5                	mov    %esp,%ebp
80104bb7:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80104bba:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104bc1:	e8 a9 0c 00 00       	call   8010586f <holding>
80104bc6:	85 c0                	test   %eax,%eax
80104bc8:	75 0c                	jne    80104bd6 <sched+0x22>
    panic("sched ptable.lock");
80104bca:	c7 04 24 8d 90 10 80 	movl   $0x8010908d,(%esp)
80104bd1:	e8 64 b9 ff ff       	call   8010053a <panic>
  if(cpu->ncli != 1)
80104bd6:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104bdc:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104be2:	83 f8 01             	cmp    $0x1,%eax
80104be5:	74 0c                	je     80104bf3 <sched+0x3f>
    panic("sched locks");
80104be7:	c7 04 24 9f 90 10 80 	movl   $0x8010909f,(%esp)
80104bee:	e8 47 b9 ff ff       	call   8010053a <panic>
  if(proc->state == RUNNING)
80104bf3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104bf9:	8b 40 0c             	mov    0xc(%eax),%eax
80104bfc:	83 f8 04             	cmp    $0x4,%eax
80104bff:	75 0c                	jne    80104c0d <sched+0x59>
    panic("sched running");
80104c01:	c7 04 24 ab 90 10 80 	movl   $0x801090ab,(%esp)
80104c08:	e8 2d b9 ff ff       	call   8010053a <panic>
  if(readeflags()&FL_IF)
80104c0d:	e8 13 f8 ff ff       	call   80104425 <readeflags>
80104c12:	25 00 02 00 00       	and    $0x200,%eax
80104c17:	85 c0                	test   %eax,%eax
80104c19:	74 0c                	je     80104c27 <sched+0x73>
    panic("sched interruptible");
80104c1b:	c7 04 24 b9 90 10 80 	movl   $0x801090b9,(%esp)
80104c22:	e8 13 b9 ff ff       	call   8010053a <panic>
  intena = cpu->intena;
80104c27:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104c2d:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104c33:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80104c36:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104c3c:	8b 40 04             	mov    0x4(%eax),%eax
80104c3f:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104c46:	83 c2 1c             	add    $0x1c,%edx
80104c49:	89 44 24 04          	mov    %eax,0x4(%esp)
80104c4d:	89 14 24             	mov    %edx,(%esp)
80104c50:	e8 d5 0f 00 00       	call   80105c2a <swtch>
  cpu->intena = intena;
80104c55:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104c5b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c5e:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104c64:	c9                   	leave  
80104c65:	c3                   	ret    

80104c66 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80104c66:	55                   	push   %ebp
80104c67:	89 e5                	mov    %esp,%ebp
80104c69:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80104c6c:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104c73:	e8 cd 0a 00 00       	call   80105745 <acquire>
  proc->state = RUNNABLE;
80104c78:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c7e:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80104c85:	e8 2a ff ff ff       	call   80104bb4 <sched>
  release(&ptable.lock);
80104c8a:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104c91:	e8 11 0b 00 00       	call   801057a7 <release>
}
80104c96:	c9                   	leave  
80104c97:	c3                   	ret    

80104c98 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80104c98:	55                   	push   %ebp
80104c99:	89 e5                	mov    %esp,%ebp
80104c9b:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80104c9e:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104ca5:	e8 fd 0a 00 00       	call   801057a7 <release>

  if (first) {
80104caa:	a1 08 c0 10 80       	mov    0x8010c008,%eax
80104caf:	85 c0                	test   %eax,%eax
80104cb1:	74 0f                	je     80104cc2 <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80104cb3:	c7 05 08 c0 10 80 00 	movl   $0x0,0x8010c008
80104cba:	00 00 00 
    initlog();
80104cbd:	e8 8a e6 ff ff       	call   8010334c <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80104cc2:	c9                   	leave  
80104cc3:	c3                   	ret    

80104cc4 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80104cc4:	55                   	push   %ebp
80104cc5:	89 e5                	mov    %esp,%ebp
80104cc7:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80104cca:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cd0:	85 c0                	test   %eax,%eax
80104cd2:	75 0c                	jne    80104ce0 <sleep+0x1c>
    panic("sleep");
80104cd4:	c7 04 24 cd 90 10 80 	movl   $0x801090cd,(%esp)
80104cdb:	e8 5a b8 ff ff       	call   8010053a <panic>

  if(lk == 0)
80104ce0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104ce4:	75 0c                	jne    80104cf2 <sleep+0x2e>
    panic("sleep without lk");
80104ce6:	c7 04 24 d3 90 10 80 	movl   $0x801090d3,(%esp)
80104ced:	e8 48 b8 ff ff       	call   8010053a <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104cf2:	81 7d 0c a0 39 11 80 	cmpl   $0x801139a0,0xc(%ebp)
80104cf9:	74 17                	je     80104d12 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80104cfb:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104d02:	e8 3e 0a 00 00       	call   80105745 <acquire>
    release(lk);
80104d07:	8b 45 0c             	mov    0xc(%ebp),%eax
80104d0a:	89 04 24             	mov    %eax,(%esp)
80104d0d:	e8 95 0a 00 00       	call   801057a7 <release>
  }

  // Go to sleep.
  proc->chan = chan;
80104d12:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d18:	8b 55 08             	mov    0x8(%ebp),%edx
80104d1b:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80104d1e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d24:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
80104d2b:	e8 84 fe ff ff       	call   80104bb4 <sched>

  // Tidy up.
  proc->chan = 0;
80104d30:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d36:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80104d3d:	81 7d 0c a0 39 11 80 	cmpl   $0x801139a0,0xc(%ebp)
80104d44:	74 17                	je     80104d5d <sleep+0x99>
    release(&ptable.lock);
80104d46:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104d4d:	e8 55 0a 00 00       	call   801057a7 <release>
    acquire(lk);
80104d52:	8b 45 0c             	mov    0xc(%ebp),%eax
80104d55:	89 04 24             	mov    %eax,(%esp)
80104d58:	e8 e8 09 00 00       	call   80105745 <acquire>
  }
}
80104d5d:	c9                   	leave  
80104d5e:	c3                   	ret    

80104d5f <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104d5f:	55                   	push   %ebp
80104d60:	89 e5                	mov    %esp,%ebp
80104d62:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104d65:	c7 45 fc d4 39 11 80 	movl   $0x801139d4,-0x4(%ebp)
80104d6c:	eb 27                	jmp    80104d95 <wakeup1+0x36>
    if(p->state == SLEEPING && p->chan == chan)
80104d6e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104d71:	8b 40 0c             	mov    0xc(%eax),%eax
80104d74:	83 f8 02             	cmp    $0x2,%eax
80104d77:	75 15                	jne    80104d8e <wakeup1+0x2f>
80104d79:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104d7c:	8b 40 20             	mov    0x20(%eax),%eax
80104d7f:	3b 45 08             	cmp    0x8(%ebp),%eax
80104d82:	75 0a                	jne    80104d8e <wakeup1+0x2f>
      p->state = RUNNABLE;
80104d84:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104d87:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104d8e:	81 45 fc e4 00 00 00 	addl   $0xe4,-0x4(%ebp)
80104d95:	81 7d fc d4 72 11 80 	cmpl   $0x801172d4,-0x4(%ebp)
80104d9c:	72 d0                	jb     80104d6e <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80104d9e:	c9                   	leave  
80104d9f:	c3                   	ret    

80104da0 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104da0:	55                   	push   %ebp
80104da1:	89 e5                	mov    %esp,%ebp
80104da3:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80104da6:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104dad:	e8 93 09 00 00       	call   80105745 <acquire>
  wakeup1(chan);
80104db2:	8b 45 08             	mov    0x8(%ebp),%eax
80104db5:	89 04 24             	mov    %eax,(%esp)
80104db8:	e8 a2 ff ff ff       	call   80104d5f <wakeup1>
  release(&ptable.lock);
80104dbd:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104dc4:	e8 de 09 00 00       	call   801057a7 <release>
}
80104dc9:	c9                   	leave  
80104dca:	c3                   	ret    

80104dcb <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104dcb:	55                   	push   %ebp
80104dcc:	89 e5                	mov    %esp,%ebp
80104dce:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104dd1:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104dd8:	e8 68 09 00 00       	call   80105745 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104ddd:	c7 45 f4 d4 39 11 80 	movl   $0x801139d4,-0xc(%ebp)
80104de4:	eb 44                	jmp    80104e2a <kill+0x5f>
    if(p->pid == pid){
80104de6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104de9:	8b 40 10             	mov    0x10(%eax),%eax
80104dec:	3b 45 08             	cmp    0x8(%ebp),%eax
80104def:	75 32                	jne    80104e23 <kill+0x58>
      p->killed = 1;
80104df1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104df4:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104dfb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104dfe:	8b 40 0c             	mov    0xc(%eax),%eax
80104e01:	83 f8 02             	cmp    $0x2,%eax
80104e04:	75 0a                	jne    80104e10 <kill+0x45>
        p->state = RUNNABLE;
80104e06:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e09:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104e10:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104e17:	e8 8b 09 00 00       	call   801057a7 <release>
      return 0;
80104e1c:	b8 00 00 00 00       	mov    $0x0,%eax
80104e21:	eb 21                	jmp    80104e44 <kill+0x79>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104e23:	81 45 f4 e4 00 00 00 	addl   $0xe4,-0xc(%ebp)
80104e2a:	81 7d f4 d4 72 11 80 	cmpl   $0x801172d4,-0xc(%ebp)
80104e31:	72 b3                	jb     80104de6 <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80104e33:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104e3a:	e8 68 09 00 00       	call   801057a7 <release>
  return -1;
80104e3f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104e44:	c9                   	leave  
80104e45:	c3                   	ret    

80104e46 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104e46:	55                   	push   %ebp
80104e47:	89 e5                	mov    %esp,%ebp
80104e49:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104e4c:	c7 45 f0 d4 39 11 80 	movl   $0x801139d4,-0x10(%ebp)
80104e53:	e9 d9 00 00 00       	jmp    80104f31 <procdump+0xeb>
    if(p->state == UNUSED)
80104e58:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e5b:	8b 40 0c             	mov    0xc(%eax),%eax
80104e5e:	85 c0                	test   %eax,%eax
80104e60:	75 05                	jne    80104e67 <procdump+0x21>
      continue;
80104e62:	e9 c3 00 00 00       	jmp    80104f2a <procdump+0xe4>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104e67:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e6a:	8b 40 0c             	mov    0xc(%eax),%eax
80104e6d:	83 f8 05             	cmp    $0x5,%eax
80104e70:	77 23                	ja     80104e95 <procdump+0x4f>
80104e72:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e75:	8b 40 0c             	mov    0xc(%eax),%eax
80104e78:	8b 04 85 0c c0 10 80 	mov    -0x7fef3ff4(,%eax,4),%eax
80104e7f:	85 c0                	test   %eax,%eax
80104e81:	74 12                	je     80104e95 <procdump+0x4f>
      state = states[p->state];
80104e83:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e86:	8b 40 0c             	mov    0xc(%eax),%eax
80104e89:	8b 04 85 0c c0 10 80 	mov    -0x7fef3ff4(,%eax,4),%eax
80104e90:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104e93:	eb 07                	jmp    80104e9c <procdump+0x56>
    else
      state = "???";
80104e95:	c7 45 ec e4 90 10 80 	movl   $0x801090e4,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80104e9c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e9f:	8d 50 28             	lea    0x28(%eax),%edx
80104ea2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ea5:	8b 40 10             	mov    0x10(%eax),%eax
80104ea8:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104eac:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104eaf:	89 54 24 08          	mov    %edx,0x8(%esp)
80104eb3:	89 44 24 04          	mov    %eax,0x4(%esp)
80104eb7:	c7 04 24 e8 90 10 80 	movl   $0x801090e8,(%esp)
80104ebe:	e8 dd b4 ff ff       	call   801003a0 <cprintf>
    if(p->state == SLEEPING){
80104ec3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ec6:	8b 40 0c             	mov    0xc(%eax),%eax
80104ec9:	83 f8 02             	cmp    $0x2,%eax
80104ecc:	75 50                	jne    80104f1e <procdump+0xd8>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80104ece:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ed1:	8b 40 1c             	mov    0x1c(%eax),%eax
80104ed4:	8b 40 0c             	mov    0xc(%eax),%eax
80104ed7:	83 c0 08             	add    $0x8,%eax
80104eda:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80104edd:	89 54 24 04          	mov    %edx,0x4(%esp)
80104ee1:	89 04 24             	mov    %eax,(%esp)
80104ee4:	e8 0d 09 00 00       	call   801057f6 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80104ee9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104ef0:	eb 1b                	jmp    80104f0d <procdump+0xc7>
        cprintf(" %p", pc[i]);
80104ef2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ef5:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104ef9:	89 44 24 04          	mov    %eax,0x4(%esp)
80104efd:	c7 04 24 f1 90 10 80 	movl   $0x801090f1,(%esp)
80104f04:	e8 97 b4 ff ff       	call   801003a0 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80104f09:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104f0d:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80104f11:	7f 0b                	jg     80104f1e <procdump+0xd8>
80104f13:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f16:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104f1a:	85 c0                	test   %eax,%eax
80104f1c:	75 d4                	jne    80104ef2 <procdump+0xac>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80104f1e:	c7 04 24 f5 90 10 80 	movl   $0x801090f5,(%esp)
80104f25:	e8 76 b4 ff ff       	call   801003a0 <cprintf>
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104f2a:	81 45 f0 e4 00 00 00 	addl   $0xe4,-0x10(%ebp)
80104f31:	81 7d f0 d4 72 11 80 	cmpl   $0x801172d4,-0x10(%ebp)
80104f38:	0f 82 1a ff ff ff    	jb     80104e58 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80104f3e:	c9                   	leave  
80104f3f:	c3                   	ret    

80104f40 <getProcPIDS>:

// set pids to contain all the current pids number 
// returns the number of elemets in pids
int getProcPIDS (int *pids){
80104f40:	55                   	push   %ebp
80104f41:	89 e5                	mov    %esp,%ebp
80104f43:	83 ec 28             	sub    $0x28,%esp

  struct proc *p;
  int count =0;
80104f46:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  acquire(& ptable.lock);
80104f4d:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104f54:	e8 ec 07 00 00       	call   80105745 <acquire>
  for(p = ptable.proc; p< &ptable.proc[NPROC]; p++){
80104f59:	c7 45 f4 d4 39 11 80 	movl   $0x801139d4,-0xc(%ebp)
80104f60:	eb 43                	jmp    80104fa5 <getProcPIDS+0x65>

      if  ((p->state==SLEEPING ||  p->state==RUNNABLE || p->state==RUNNING )){
80104f62:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f65:	8b 40 0c             	mov    0xc(%eax),%eax
80104f68:	83 f8 02             	cmp    $0x2,%eax
80104f6b:	74 16                	je     80104f83 <getProcPIDS+0x43>
80104f6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f70:	8b 40 0c             	mov    0xc(%eax),%eax
80104f73:	83 f8 03             	cmp    $0x3,%eax
80104f76:	74 0b                	je     80104f83 <getProcPIDS+0x43>
80104f78:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f7b:	8b 40 0c             	mov    0xc(%eax),%eax
80104f7e:	83 f8 04             	cmp    $0x4,%eax
80104f81:	75 1b                	jne    80104f9e <getProcPIDS+0x5e>
         pids[count]= p->pid;
80104f83:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f86:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80104f8d:	8b 45 08             	mov    0x8(%ebp),%eax
80104f90:	01 c2                	add    %eax,%edx
80104f92:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f95:	8b 40 10             	mov    0x10(%eax),%eax
80104f98:	89 02                	mov    %eax,(%edx)
      	 //cprintf("%d   ", pids[count]);
         count++;
80104f9a:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
int getProcPIDS (int *pids){

  struct proc *p;
  int count =0;
  acquire(& ptable.lock);
  for(p = ptable.proc; p< &ptable.proc[NPROC]; p++){
80104f9e:	81 45 f4 e4 00 00 00 	addl   $0xe4,-0xc(%ebp)
80104fa5:	81 7d f4 d4 72 11 80 	cmpl   $0x801172d4,-0xc(%ebp)
80104fac:	72 b4                	jb     80104f62 <getProcPIDS+0x22>
         count++;
      }

  }
  
  release(& ptable.lock);
80104fae:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104fb5:	e8 ed 07 00 00       	call   801057a7 <release>
  return count;
80104fba:	8b 45 f0             	mov    -0x10(%ebp),%eax

}
80104fbd:	c9                   	leave  
80104fbe:	c3                   	ret    

80104fbf <procLock>:


// locks ptable
void procLock(){
80104fbf:	55                   	push   %ebp
80104fc0:	89 e5                	mov    %esp,%ebp
80104fc2:	83 ec 18             	sub    $0x18,%esp
	acquire(&ptable.lock);
80104fc5:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104fcc:	e8 74 07 00 00       	call   80105745 <acquire>
}
80104fd1:	c9                   	leave  
80104fd2:	c3                   	ret    

80104fd3 <procRelease>:

// release ptable
void procRelease(){
80104fd3:	55                   	push   %ebp
80104fd4:	89 e5                	mov    %esp,%ebp
80104fd6:	83 ec 18             	sub    $0x18,%esp
	release(&ptable.lock);
80104fd9:	c7 04 24 a0 39 11 80 	movl   $0x801139a0,(%esp)
80104fe0:	e8 c2 07 00 00       	call   801057a7 <release>
}
80104fe5:	c9                   	leave  
80104fe6:	c3                   	ret    

80104fe7 <getProc>:


// returns the process struct with the current pid number
// if process is not found, or not alive the function return null
struct proc* getProc (int pid){
80104fe7:	55                   	push   %ebp
80104fe8:	89 e5                	mov    %esp,%ebp
80104fea:	83 ec 10             	sub    $0x10,%esp

  struct proc *p;

  for(p = ptable.proc; p< &ptable.proc[NPROC]; p++){
80104fed:	c7 45 fc d4 39 11 80 	movl   $0x801139d4,-0x4(%ebp)
80104ff4:	eb 37                	jmp    8010502d <getProc+0x46>
      if  (p->pid && (p->state==SLEEPING ||  p->state==RUNNABLE || p->state==RUNNING )){
80104ff6:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104ff9:	8b 40 10             	mov    0x10(%eax),%eax
80104ffc:	85 c0                	test   %eax,%eax
80104ffe:	74 26                	je     80105026 <getProc+0x3f>
80105000:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105003:	8b 40 0c             	mov    0xc(%eax),%eax
80105006:	83 f8 02             	cmp    $0x2,%eax
80105009:	74 16                	je     80105021 <getProc+0x3a>
8010500b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010500e:	8b 40 0c             	mov    0xc(%eax),%eax
80105011:	83 f8 03             	cmp    $0x3,%eax
80105014:	74 0b                	je     80105021 <getProc+0x3a>
80105016:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105019:	8b 40 0c             	mov    0xc(%eax),%eax
8010501c:	83 f8 04             	cmp    $0x4,%eax
8010501f:	75 05                	jne    80105026 <getProc+0x3f>
    	  return p;
80105021:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105024:	eb 15                	jmp    8010503b <getProc+0x54>
// if process is not found, or not alive the function return null
struct proc* getProc (int pid){

  struct proc *p;

  for(p = ptable.proc; p< &ptable.proc[NPROC]; p++){
80105026:	81 45 fc e4 00 00 00 	addl   $0xe4,-0x4(%ebp)
8010502d:	81 7d fc d4 72 11 80 	cmpl   $0x801172d4,-0x4(%ebp)
80105034:	72 c0                	jb     80104ff6 <getProc+0xf>
      if  (p->pid && (p->state==SLEEPING ||  p->state==RUNNABLE || p->state==RUNNING )){
    	  return p;
      }

  }
  return 0;
80105036:	b8 00 00 00 00       	mov    $0x0,%eax

}
8010503b:	c9                   	leave  
8010503c:	c3                   	ret    

8010503d <procfsisdir>:

int procfsInum;
int first=1;
 
int
procfsisdir(struct inode *ip) {
8010503d:	55                   	push   %ebp
8010503e:	89 e5                	mov    %esp,%ebp

 if (first){
80105040:	a1 24 c0 10 80       	mov    0x8010c024,%eax
80105045:	85 c0                	test   %eax,%eax
80105047:	74 1e                	je     80105067 <procfsisdir+0x2a>
    procfsInum= ip->inum;
80105049:	8b 45 08             	mov    0x8(%ebp),%eax
8010504c:	8b 40 04             	mov    0x4(%eax),%eax
8010504f:	a3 d4 72 11 80       	mov    %eax,0x801172d4
    ip->minor =0;
80105054:	8b 45 08             	mov    0x8(%ebp),%eax
80105057:	66 c7 40 14 00 00    	movw   $0x0,0x14(%eax)
    first= 0;
8010505d:	c7 05 24 c0 10 80 00 	movl   $0x0,0x8010c024
80105064:	00 00 00 
  }


  if (ip->inum == procfsInum)
80105067:	8b 45 08             	mov    0x8(%ebp),%eax
8010506a:	8b 50 04             	mov    0x4(%eax),%edx
8010506d:	a1 d4 72 11 80       	mov    0x801172d4,%eax
80105072:	39 c2                	cmp    %eax,%edx
80105074:	75 07                	jne    8010507d <procfsisdir+0x40>
	  return 1;
80105076:	b8 01 00 00 00       	mov    $0x1,%eax
8010507b:	eb 26                	jmp    801050a3 <procfsisdir+0x66>

  if (ip->inum >= BASE_INUM && ip->inum <BASE_INUM_LIM)
8010507d:	8b 45 08             	mov    0x8(%ebp),%eax
80105080:	8b 40 04             	mov    0x4(%eax),%eax
80105083:	3d e7 03 00 00       	cmp    $0x3e7,%eax
80105088:	76 14                	jbe    8010509e <procfsisdir+0x61>
8010508a:	8b 45 08             	mov    0x8(%ebp),%eax
8010508d:	8b 40 04             	mov    0x4(%eax),%eax
80105090:	3d 27 04 00 00       	cmp    $0x427,%eax
80105095:	77 07                	ja     8010509e <procfsisdir+0x61>
    return 1;
80105097:	b8 01 00 00 00       	mov    $0x1,%eax
8010509c:	eb 05                	jmp    801050a3 <procfsisdir+0x66>
  
  else return 0;
8010509e:	b8 00 00 00 00       	mov    $0x0,%eax
}
801050a3:	5d                   	pop    %ebp
801050a4:	c3                   	ret    

801050a5 <procfsiread>:

void 
procfsiread(struct inode* dp, struct inode *ip) 
{
801050a5:	55                   	push   %ebp
801050a6:	89 e5                	mov    %esp,%ebp
	// ip->flags = i_valid;
	// ip->major = 2;

 // cprintf("**** iread  inmu dp %d ip %d\n", dp->inum, ip->inum);
  //if (ip->inum >= BASE_INUM) {
    ip->type = T_DEV;
801050a8:	8b 45 0c             	mov    0xc(%ebp),%eax
801050ab:	66 c7 40 10 03 00    	movw   $0x3,0x10(%eax)
    ip->major = PROCFS;
801050b1:	8b 45 0c             	mov    0xc(%ebp),%eax
801050b4:	66 c7 40 12 02 00    	movw   $0x2,0x12(%eax)
    ip->minor = dp->minor +1;
801050ba:	8b 45 08             	mov    0x8(%ebp),%eax
801050bd:	0f b7 40 14          	movzwl 0x14(%eax),%eax
801050c1:	83 c0 01             	add    $0x1,%eax
801050c4:	89 c2                	mov    %eax,%edx
801050c6:	8b 45 0c             	mov    0xc(%ebp),%eax
801050c9:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->size = 0;
801050cd:	8b 45 0c             	mov    0xc(%ebp),%eax
801050d0:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
    ip->flags |= I_VALID;
801050d7:	8b 45 0c             	mov    0xc(%ebp),%eax
801050da:	8b 40 0c             	mov    0xc(%eax),%eax
801050dd:	83 c8 02             	or     $0x2,%eax
801050e0:	89 c2                	mov    %eax,%edx
801050e2:	8b 45 0c             	mov    0xc(%ebp),%eax
801050e5:	89 50 0c             	mov    %edx,0xc(%eax)

  // cprintf("**** iread  type %d isdir %d  isdir(ip) %d\n",  ip->type, devsw[ip->major].isdir, devsw[ip->major].isdir(ip));
  // cprintf("**** iread  major dp %d ip %d\n", dp->major, ip->major);
  // cprintf("**** iread  minor dp %d ip %d\n", dp->minor, ip->minor);
    
}
801050e8:	5d                   	pop    %ebp
801050e9:	c3                   	ret    

801050ea <getProcList>:

int getProcList(char *buf, struct inode *pidIp) {
801050ea:	55                   	push   %ebp
801050eb:	89 e5                	mov    %esp,%ebp
801050ed:	81 ec 78 01 00 00    	sub    $0x178,%esp
  struct dirent de;
  int pidCount;
  int bufOff= 2;
801050f3:	c7 45 f4 02 00 00 00 	movl   $0x2,-0xc(%ebp)
  char stringNum[64];
  int  stringNumLength;


  //create "this dir" reference
  de.inum = procfsInum;
801050fa:	a1 d4 72 11 80       	mov    0x801172d4,%eax
801050ff:	66 89 45 d8          	mov    %ax,-0x28(%ebp)
  memmove(de.name, ".", 2);
80105103:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
8010510a:	00 
8010510b:	c7 44 24 04 21 91 10 	movl   $0x80109121,0x4(%esp)
80105112:	80 
80105113:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105116:	83 c0 02             	add    $0x2,%eax
80105119:	89 04 24             	mov    %eax,(%esp)
8010511c:	e8 47 09 00 00       	call   80105a68 <memmove>
  memmove(buf, (char*)&de, sizeof(de));
80105121:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105128:	00 
80105129:	8d 45 d8             	lea    -0x28(%ebp),%eax
8010512c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105130:	8b 45 08             	mov    0x8(%ebp),%eax
80105133:	89 04 24             	mov    %eax,(%esp)
80105136:	e8 2d 09 00 00       	call   80105a68 <memmove>

  //create "prev dir" reference -procfs Dir
  de.inum = ROOTINO;
8010513b:	66 c7 45 d8 01 00    	movw   $0x1,-0x28(%ebp)
  memmove(de.name, "..", 3);
80105141:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
80105148:	00 
80105149:	c7 44 24 04 23 91 10 	movl   $0x80109123,0x4(%esp)
80105150:	80 
80105151:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105154:	83 c0 02             	add    $0x2,%eax
80105157:	89 04 24             	mov    %eax,(%esp)
8010515a:	e8 09 09 00 00       	call   80105a68 <memmove>
  memmove(buf + sizeof(de), (char*)&de, sizeof(de));
8010515f:	8b 45 08             	mov    0x8(%ebp),%eax
80105162:	8d 50 10             	lea    0x10(%eax),%edx
80105165:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010516c:	00 
8010516d:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105170:	89 44 24 04          	mov    %eax,0x4(%esp)
80105174:	89 14 24             	mov    %edx,(%esp)
80105177:	e8 ec 08 00 00       	call   80105a68 <memmove>

  // return the current running processes pids
  pidCount = getProcPIDS(pids);
8010517c:	8d 85 d8 fe ff ff    	lea    -0x128(%ebp),%eax
80105182:	89 04 24             	mov    %eax,(%esp)
80105185:	e8 b6 fd ff ff       	call   80104f40 <getProcPIDS>
8010518a:	89 45 ec             	mov    %eax,-0x14(%ebp)

  //push Pids as file entries
  for (pidIndex = 0; pidIndex< pidCount; pidIndex++){
8010518d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80105194:	eb 7f                	jmp    80105215 <getProcList+0x12b>

      de.inum = pids[pidIndex] + BASE_INUM ;
80105196:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105199:	8b 84 85 d8 fe ff ff 	mov    -0x128(%ebp,%eax,4),%eax
801051a0:	66 05 e8 03          	add    $0x3e8,%ax
801051a4:	66 89 45 d8          	mov    %ax,-0x28(%ebp)
      
      stringNumLength = itoa(  pids[pidIndex], stringNum );
801051a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801051ab:	8b 84 85 d8 fe ff ff 	mov    -0x128(%ebp,%eax,4),%eax
801051b2:	8d 95 98 fe ff ff    	lea    -0x168(%ebp),%edx
801051b8:	89 54 24 04          	mov    %edx,0x4(%esp)
801051bc:	89 04 24             	mov    %eax,(%esp)
801051bf:	e8 22 04 00 00       	call   801055e6 <itoa>
801051c4:	89 45 e8             	mov    %eax,-0x18(%ebp)

      memmove(de.name, stringNum, stringNumLength+1);
801051c7:	8b 45 e8             	mov    -0x18(%ebp),%eax
801051ca:	83 c0 01             	add    $0x1,%eax
801051cd:	89 44 24 08          	mov    %eax,0x8(%esp)
801051d1:	8d 85 98 fe ff ff    	lea    -0x168(%ebp),%eax
801051d7:	89 44 24 04          	mov    %eax,0x4(%esp)
801051db:	8d 45 d8             	lea    -0x28(%ebp),%eax
801051de:	83 c0 02             	add    $0x2,%eax
801051e1:	89 04 24             	mov    %eax,(%esp)
801051e4:	e8 7f 08 00 00       	call   80105a68 <memmove>
      memmove(buf + bufOff * sizeof(de), (char*)&de, sizeof(de));
801051e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051ec:	c1 e0 04             	shl    $0x4,%eax
801051ef:	89 c2                	mov    %eax,%edx
801051f1:	8b 45 08             	mov    0x8(%ebp),%eax
801051f4:	01 c2                	add    %eax,%edx
801051f6:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801051fd:	00 
801051fe:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105201:	89 44 24 04          	mov    %eax,0x4(%esp)
80105205:	89 14 24             	mov    %edx,(%esp)
80105208:	e8 5b 08 00 00       	call   80105a68 <memmove>
      bufOff++;
8010520d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

  // return the current running processes pids
  pidCount = getProcPIDS(pids);

  //push Pids as file entries
  for (pidIndex = 0; pidIndex< pidCount; pidIndex++){
80105211:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80105215:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105218:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010521b:	0f 8c 75 ff ff ff    	jl     80105196 <getProcList+0xac>
      memmove(buf + bufOff * sizeof(de), (char*)&de, sizeof(de));
      bufOff++;

  }

  return (bufOff)* sizeof(de);
80105221:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105224:	c1 e0 04             	shl    $0x4,%eax
}
80105227:	c9                   	leave  
80105228:	c3                   	ret    

80105229 <getProcEntry>:



int getProcEntry(int pid ,char *buf, struct inode *ip) {
80105229:	55                   	push   %ebp
8010522a:	89 e5                	mov    %esp,%ebp
8010522c:	83 ec 38             	sub    $0x38,%esp

  struct dirent de;

  struct proc *p;
  procLock();
8010522f:	e8 8b fd ff ff       	call   80104fbf <procLock>

  p = getProc(pid);
80105234:	8b 45 08             	mov    0x8(%ebp),%eax
80105237:	89 04 24             	mov    %eax,(%esp)
8010523a:	e8 a8 fd ff ff       	call   80104fe7 <getProc>
8010523f:	89 45 f4             	mov    %eax,-0xc(%ebp)

  procRelease();
80105242:	e8 8c fd ff ff       	call   80104fd3 <procRelease>
  if (!p){
80105247:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010524b:	75 0a                	jne    80105257 <getProcEntry+0x2e>
	  return 0;
8010524d:	b8 00 00 00 00       	mov    $0x0,%eax
80105252:	e9 d0 01 00 00       	jmp    80105427 <getProcEntry+0x1fe>
  }


  //create "this dir" reference
  de.inum = ip->inum;
80105257:	8b 45 10             	mov    0x10(%ebp),%eax
8010525a:	8b 40 04             	mov    0x4(%eax),%eax
8010525d:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
   //cprintf(" ********* %d\n", ip->inum);
  memmove(de.name, ".", 2);
80105261:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
80105268:	00 
80105269:	c7 44 24 04 21 91 10 	movl   $0x80109121,0x4(%esp)
80105270:	80 
80105271:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105274:	83 c0 02             	add    $0x2,%eax
80105277:	89 04 24             	mov    %eax,(%esp)
8010527a:	e8 e9 07 00 00       	call   80105a68 <memmove>
  memmove(buf, (char*)&de, sizeof(de));
8010527f:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105286:	00 
80105287:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010528a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010528e:	8b 45 0c             	mov    0xc(%ebp),%eax
80105291:	89 04 24             	mov    %eax,(%esp)
80105294:	e8 cf 07 00 00       	call   80105a68 <memmove>

  //create "prev dir" reference -root Dir
  de.inum = procfsInum;
80105299:	a1 d4 72 11 80       	mov    0x801172d4,%eax
8010529e:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  memmove(de.name, "..", 3);
801052a2:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
801052a9:	00 
801052aa:	c7 44 24 04 23 91 10 	movl   $0x80109123,0x4(%esp)
801052b1:	80 
801052b2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801052b5:	83 c0 02             	add    $0x2,%eax
801052b8:	89 04 24             	mov    %eax,(%esp)
801052bb:	e8 a8 07 00 00       	call   80105a68 <memmove>
  memmove(buf + sizeof(de), (char*)&de, sizeof(de));
801052c0:	8b 45 0c             	mov    0xc(%ebp),%eax
801052c3:	8d 50 10             	lea    0x10(%eax),%edx
801052c6:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801052cd:	00 
801052ce:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801052d1:	89 44 24 04          	mov    %eax,0x4(%esp)
801052d5:	89 14 24             	mov    %edx,(%esp)
801052d8:	e8 8b 07 00 00       	call   80105a68 <memmove>

  //create "cmdline " reference
  de.inum = CMDLINE_INUM;
801052dd:	66 c7 45 e4 11 27    	movw   $0x2711,-0x1c(%ebp)
  memmove(de.name, "cmdline", 8);
801052e3:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
801052ea:	00 
801052eb:	c7 44 24 04 26 91 10 	movl   $0x80109126,0x4(%esp)
801052f2:	80 
801052f3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801052f6:	83 c0 02             	add    $0x2,%eax
801052f9:	89 04 24             	mov    %eax,(%esp)
801052fc:	e8 67 07 00 00       	call   80105a68 <memmove>
  memmove(buf + 2*sizeof(de), (char*)&de, sizeof(de));
80105301:	8b 45 0c             	mov    0xc(%ebp),%eax
80105304:	8d 50 20             	lea    0x20(%eax),%edx
80105307:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010530e:	00 
8010530f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105312:	89 44 24 04          	mov    %eax,0x4(%esp)
80105316:	89 14 24             	mov    %edx,(%esp)
80105319:	e8 4a 07 00 00       	call   80105a68 <memmove>

  //create "cwd " reference
  de.inum = CWD_INUM;
8010531e:	66 c7 45 e4 12 27    	movw   $0x2712,-0x1c(%ebp)
  memmove(de.name, "cwd", 4);
80105324:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010532b:	00 
8010532c:	c7 44 24 04 2e 91 10 	movl   $0x8010912e,0x4(%esp)
80105333:	80 
80105334:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105337:	83 c0 02             	add    $0x2,%eax
8010533a:	89 04 24             	mov    %eax,(%esp)
8010533d:	e8 26 07 00 00       	call   80105a68 <memmove>
  memmove(buf + 3*sizeof(de), (char*)&de, sizeof(de));
80105342:	8b 45 0c             	mov    0xc(%ebp),%eax
80105345:	8d 50 30             	lea    0x30(%eax),%edx
80105348:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010534f:	00 
80105350:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105353:	89 44 24 04          	mov    %eax,0x4(%esp)
80105357:	89 14 24             	mov    %edx,(%esp)
8010535a:	e8 09 07 00 00       	call   80105a68 <memmove>

  //create "exe " reference
  de.inum = EXE_INUM;
8010535f:	66 c7 45 e4 13 27    	movw   $0x2713,-0x1c(%ebp)
  memmove(de.name, "exe", 4);
80105365:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010536c:	00 
8010536d:	c7 44 24 04 32 91 10 	movl   $0x80109132,0x4(%esp)
80105374:	80 
80105375:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105378:	83 c0 02             	add    $0x2,%eax
8010537b:	89 04 24             	mov    %eax,(%esp)
8010537e:	e8 e5 06 00 00       	call   80105a68 <memmove>
  memmove(buf + 4*sizeof(de), (char*)&de, sizeof(de));
80105383:	8b 45 0c             	mov    0xc(%ebp),%eax
80105386:	8d 50 40             	lea    0x40(%eax),%edx
80105389:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105390:	00 
80105391:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105394:	89 44 24 04          	mov    %eax,0x4(%esp)
80105398:	89 14 24             	mov    %edx,(%esp)
8010539b:	e8 c8 06 00 00       	call   80105a68 <memmove>

  //create "fdinfo " reference -root Dir
  de.inum = FDINFO_INUM;
801053a0:	66 c7 45 e4 14 27    	movw   $0x2714,-0x1c(%ebp)
  memmove(de.name, "fdinfo", 7);
801053a6:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
801053ad:	00 
801053ae:	c7 44 24 04 36 91 10 	movl   $0x80109136,0x4(%esp)
801053b5:	80 
801053b6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801053b9:	83 c0 02             	add    $0x2,%eax
801053bc:	89 04 24             	mov    %eax,(%esp)
801053bf:	e8 a4 06 00 00       	call   80105a68 <memmove>
  memmove(buf + 5*sizeof(de), (char*)&de, sizeof(de));
801053c4:	8b 45 0c             	mov    0xc(%ebp),%eax
801053c7:	8d 50 50             	lea    0x50(%eax),%edx
801053ca:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801053d1:	00 
801053d2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801053d5:	89 44 24 04          	mov    %eax,0x4(%esp)
801053d9:	89 14 24             	mov    %edx,(%esp)
801053dc:	e8 87 06 00 00       	call   80105a68 <memmove>

  //create "status " reference -root Dir
  de.inum = FDINFO_INUM;
801053e1:	66 c7 45 e4 14 27    	movw   $0x2714,-0x1c(%ebp)
  memmove(de.name, "status", 7);
801053e7:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
801053ee:	00 
801053ef:	c7 44 24 04 3d 91 10 	movl   $0x8010913d,0x4(%esp)
801053f6:	80 
801053f7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801053fa:	83 c0 02             	add    $0x2,%eax
801053fd:	89 04 24             	mov    %eax,(%esp)
80105400:	e8 63 06 00 00       	call   80105a68 <memmove>
  memmove(buf + 6*sizeof(de), (char*)&de, sizeof(de));
80105405:	8b 45 0c             	mov    0xc(%ebp),%eax
80105408:	8d 50 60             	lea    0x60(%eax),%edx
8010540b:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105412:	00 
80105413:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105416:	89 44 24 04          	mov    %eax,0x4(%esp)
8010541a:	89 14 24             	mov    %edx,(%esp)
8010541d:	e8 46 06 00 00       	call   80105a68 <memmove>

  return 7 * sizeof(de);
80105422:	b8 70 00 00 00       	mov    $0x70,%eax
}
80105427:	c9                   	leave  
80105428:	c3                   	ret    

80105429 <procfsread>:



int
procfsread(struct inode *ip, char *dst, int off, int n) {
80105429:	55                   	push   %ebp
8010542a:	89 e5                	mov    %esp,%ebp
8010542c:	81 ec 28 04 00 00    	sub    $0x428,%esp
  char buf[1024];
  int size;
    //cprintf("***********    %d \n", ip->inum);
    if (first){
80105432:	a1 24 c0 10 80       	mov    0x8010c024,%eax
80105437:	85 c0                	test   %eax,%eax
80105439:	74 1e                	je     80105459 <procfsread+0x30>
      procfsInum= ip->inum;
8010543b:	8b 45 08             	mov    0x8(%ebp),%eax
8010543e:	8b 40 04             	mov    0x4(%eax),%eax
80105441:	a3 d4 72 11 80       	mov    %eax,0x801172d4
      ip->minor =0;
80105446:	8b 45 08             	mov    0x8(%ebp),%eax
80105449:	66 c7 40 14 00 00    	movw   $0x0,0x14(%eax)
      first= 0;
8010544f:	c7 05 24 c0 10 80 00 	movl   $0x0,0x8010c024
80105456:	00 00 00 
    }
    
	  if (ip->inum == procfsInum) {
80105459:	8b 45 08             	mov    0x8(%ebp),%eax
8010545c:	8b 50 04             	mov    0x4(%eax),%edx
8010545f:	a1 d4 72 11 80       	mov    0x801172d4,%eax
80105464:	39 c2                	cmp    %eax,%edx
80105466:	75 18                	jne    80105480 <procfsread+0x57>
		  size = getProcList(buf, ip);
80105468:	8b 45 08             	mov    0x8(%ebp),%eax
8010546b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010546f:	8d 85 e8 fb ff ff    	lea    -0x418(%ebp),%eax
80105475:	89 04 24             	mov    %eax,(%esp)
80105478:	e8 6d fc ff ff       	call   801050ea <getProcList>
8010547d:	89 45 f4             	mov    %eax,-0xc(%ebp)
         // cprintf("HERE 1\n");
    }

    int pid =ip->inum - BASE_INUM;
80105480:	8b 45 08             	mov    0x8(%ebp),%eax
80105483:	8b 40 04             	mov    0x4(%eax),%eax
80105486:	2d e8 03 00 00       	sub    $0x3e8,%eax
8010548b:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct proc * p= getProc(pid);
8010548e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105491:	89 04 24             	mov    %eax,(%esp)
80105494:	e8 4e fb ff ff       	call   80104fe7 <getProc>
80105499:	89 45 ec             	mov    %eax,-0x14(%ebp)
    
    if(!p)
8010549c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801054a0:	75 0a                	jne    801054ac <procfsread+0x83>
       return 0;
801054a2:	b8 00 00 00 00       	mov    $0x0,%eax
801054a7:	e9 01 01 00 00       	jmp    801055ad <procfsread+0x184>

    if (ip->minor == 1){
801054ac:	8b 45 08             	mov    0x8(%ebp),%eax
801054af:	0f b7 40 14          	movzwl 0x14(%eax),%eax
801054b3:	66 83 f8 01          	cmp    $0x1,%ax
801054b7:	75 1f                	jne    801054d8 <procfsread+0xaf>
		      
        
         size = getProcEntry(pid,buf, ip);
801054b9:	8b 45 08             	mov    0x8(%ebp),%eax
801054bc:	89 44 24 08          	mov    %eax,0x8(%esp)
801054c0:	8d 85 e8 fb ff ff    	lea    -0x418(%ebp),%eax
801054c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801054ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
801054cd:	89 04 24             	mov    %eax,(%esp)
801054d0:	e8 54 fd ff ff       	call   80105229 <getProcEntry>
801054d5:	89 45 f4             	mov    %eax,-0xc(%ebp)
	  }
    if (ip->minor == 2) {
801054d8:	8b 45 08             	mov    0x8(%ebp),%eax
801054db:	0f b7 40 14          	movzwl 0x14(%eax),%eax
801054df:	66 83 f8 02          	cmp    $0x2,%ax
801054e3:	75 7b                	jne    80105560 <procfsread+0x137>
        

        switch (ip->inum ){
801054e5:	8b 45 08             	mov    0x8(%ebp),%eax
801054e8:	8b 40 04             	mov    0x4(%eax),%eax
801054eb:	3d 11 27 00 00       	cmp    $0x2711,%eax
801054f0:	74 09                	je     801054fb <procfsread+0xd2>
801054f2:	3d 12 27 00 00       	cmp    $0x2712,%eax
801054f7:	74 40                	je     80105539 <procfsread+0x110>
801054f9:	eb 65                	jmp    80105560 <procfsread+0x137>
         
              case CMDLINE_INUM:
                            cprintf ("****** %s \n", p->cmdline);
801054fb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801054fe:	83 e8 80             	sub    $0xffffff80,%eax
80105501:	89 44 24 04          	mov    %eax,0x4(%esp)
80105505:	c7 04 24 44 91 10 80 	movl   $0x80109144,(%esp)
8010550c:	e8 8f ae ff ff       	call   801003a0 <cprintf>
                            size = sizeof(p->cmdline);
80105511:	c7 45 f4 64 00 00 00 	movl   $0x64,-0xc(%ebp)
                            memmove(buf, p->cmdline, size);
80105518:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010551b:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010551e:	83 ea 80             	sub    $0xffffff80,%edx
80105521:	89 44 24 08          	mov    %eax,0x8(%esp)
80105525:	89 54 24 04          	mov    %edx,0x4(%esp)
80105529:	8d 85 e8 fb ff ff    	lea    -0x418(%ebp),%eax
8010552f:	89 04 24             	mov    %eax,(%esp)
80105532:	e8 31 05 00 00       	call   80105a68 <memmove>
                            break;
80105537:	eb 27                	jmp    80105560 <procfsread+0x137>
              case CWD_INUM:

                            size = sizeof(p->cwd);
80105539:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%ebp)
                            memmove(buf, p->cwd, size);
80105540:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105543:	8b 45 ec             	mov    -0x14(%ebp),%eax
80105546:	8b 40 78             	mov    0x78(%eax),%eax
80105549:	89 54 24 08          	mov    %edx,0x8(%esp)
8010554d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105551:	8d 85 e8 fb ff ff    	lea    -0x418(%ebp),%eax
80105557:	89 04 24             	mov    %eax,(%esp)
8010555a:	e8 09 05 00 00       	call   80105a68 <memmove>
                            break;
8010555f:	90                   	nop
              //               break; 

        }
    }

  if (off < size) {
80105560:	8b 45 10             	mov    0x10(%ebp),%eax
80105563:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80105566:	7d 40                	jge    801055a8 <procfsread+0x17f>
    int rr = size - off;
80105568:	8b 45 10             	mov    0x10(%ebp),%eax
8010556b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010556e:	29 c2                	sub    %eax,%edx
80105570:	89 d0                	mov    %edx,%eax
80105572:	89 45 e8             	mov    %eax,-0x18(%ebp)
    rr = rr < n ? rr : n;
80105575:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105578:	39 45 14             	cmp    %eax,0x14(%ebp)
8010557b:	0f 4e 45 14          	cmovle 0x14(%ebp),%eax
8010557f:	89 45 e8             	mov    %eax,-0x18(%ebp)
    memmove(dst, buf + off, rr);
80105582:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105585:	8b 55 10             	mov    0x10(%ebp),%edx
80105588:	8d 8d e8 fb ff ff    	lea    -0x418(%ebp),%ecx
8010558e:	01 ca                	add    %ecx,%edx
80105590:	89 44 24 08          	mov    %eax,0x8(%esp)
80105594:	89 54 24 04          	mov    %edx,0x4(%esp)
80105598:	8b 45 0c             	mov    0xc(%ebp),%eax
8010559b:	89 04 24             	mov    %eax,(%esp)
8010559e:	e8 c5 04 00 00       	call   80105a68 <memmove>
    return rr;
801055a3:	8b 45 e8             	mov    -0x18(%ebp),%eax
801055a6:	eb 05                	jmp    801055ad <procfsread+0x184>
  }

  return 0;
801055a8:	b8 00 00 00 00       	mov    $0x0,%eax
}
801055ad:	c9                   	leave  
801055ae:	c3                   	ret    

801055af <procfswrite>:

int
procfswrite(struct inode *ip, char *buf, int n)
{
801055af:	55                   	push   %ebp
801055b0:	89 e5                	mov    %esp,%ebp
  return 0;
801055b2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801055b7:	5d                   	pop    %ebp
801055b8:	c3                   	ret    

801055b9 <procfsinit>:

void
procfsinit(void)
{
801055b9:	55                   	push   %ebp
801055ba:	89 e5                	mov    %esp,%ebp
  devsw[PROCFS].isdir = procfsisdir;
801055bc:	c7 05 00 22 11 80 3d 	movl   $0x8010503d,0x80112200
801055c3:	50 10 80 
  devsw[PROCFS].iread = procfsiread;
801055c6:	c7 05 04 22 11 80 a5 	movl   $0x801050a5,0x80112204
801055cd:	50 10 80 
  devsw[PROCFS].write = procfswrite;
801055d0:	c7 05 0c 22 11 80 af 	movl   $0x801055af,0x8011220c
801055d7:	55 10 80 
  devsw[PROCFS].read = procfsread;
801055da:	c7 05 08 22 11 80 29 	movl   $0x80105429,0x80112208
801055e1:	54 10 80 
}
801055e4:	5d                   	pop    %ebp
801055e5:	c3                   	ret    

801055e6 <itoa>:


//receives an integer and set stringNum to its string representation
// return the number of charachters in string num;

int  itoa(int num , char *stringNum ){
801055e6:	55                   	push   %ebp
801055e7:	89 e5                	mov    %esp,%ebp
801055e9:	83 ec 10             	sub    $0x10,%esp

  int i, rem, len = 0, n;
801055ec:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

    n = num;
801055f3:	8b 45 08             	mov    0x8(%ebp),%eax
801055f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
    while (n != 0)
801055f9:	eb 1f                	jmp    8010561a <itoa+0x34>
    {
        len++;
801055fb:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
        n /= 10;
801055ff:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80105602:	ba 67 66 66 66       	mov    $0x66666667,%edx
80105607:	89 c8                	mov    %ecx,%eax
80105609:	f7 ea                	imul   %edx
8010560b:	c1 fa 02             	sar    $0x2,%edx
8010560e:	89 c8                	mov    %ecx,%eax
80105610:	c1 f8 1f             	sar    $0x1f,%eax
80105613:	29 c2                	sub    %eax,%edx
80105615:	89 d0                	mov    %edx,%eax
80105617:	89 45 f4             	mov    %eax,-0xc(%ebp)
int  itoa(int num , char *stringNum ){

  int i, rem, len = 0, n;

    n = num;
    while (n != 0)
8010561a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010561e:	75 db                	jne    801055fb <itoa+0x15>
    {
        len++;
        n /= 10;
    }
    for (i = 0; i < len; i++)
80105620:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105627:	eb 60                	jmp    80105689 <itoa+0xa3>
    {
        rem = num % 10;
80105629:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010562c:	ba 67 66 66 66       	mov    $0x66666667,%edx
80105631:	89 c8                	mov    %ecx,%eax
80105633:	f7 ea                	imul   %edx
80105635:	c1 fa 02             	sar    $0x2,%edx
80105638:	89 c8                	mov    %ecx,%eax
8010563a:	c1 f8 1f             	sar    $0x1f,%eax
8010563d:	29 c2                	sub    %eax,%edx
8010563f:	89 d0                	mov    %edx,%eax
80105641:	c1 e0 02             	shl    $0x2,%eax
80105644:	01 d0                	add    %edx,%eax
80105646:	01 c0                	add    %eax,%eax
80105648:	29 c1                	sub    %eax,%ecx
8010564a:	89 c8                	mov    %ecx,%eax
8010564c:	89 45 f0             	mov    %eax,-0x10(%ebp)
        num = num / 10;
8010564f:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105652:	ba 67 66 66 66       	mov    $0x66666667,%edx
80105657:	89 c8                	mov    %ecx,%eax
80105659:	f7 ea                	imul   %edx
8010565b:	c1 fa 02             	sar    $0x2,%edx
8010565e:	89 c8                	mov    %ecx,%eax
80105660:	c1 f8 1f             	sar    $0x1f,%eax
80105663:	29 c2                	sub    %eax,%edx
80105665:	89 d0                	mov    %edx,%eax
80105667:	89 45 08             	mov    %eax,0x8(%ebp)
        stringNum[len - (i + 1)] = rem + '0';
8010566a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010566d:	f7 d0                	not    %eax
8010566f:	89 c2                	mov    %eax,%edx
80105671:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105674:	01 d0                	add    %edx,%eax
80105676:	89 c2                	mov    %eax,%edx
80105678:	8b 45 0c             	mov    0xc(%ebp),%eax
8010567b:	01 c2                	add    %eax,%edx
8010567d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105680:	83 c0 30             	add    $0x30,%eax
80105683:	88 02                	mov    %al,(%edx)
    while (n != 0)
    {
        len++;
        n /= 10;
    }
    for (i = 0; i < len; i++)
80105685:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105689:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010568c:	3b 45 f8             	cmp    -0x8(%ebp),%eax
8010568f:	7c 98                	jl     80105629 <itoa+0x43>
    {
        rem = num % 10;
        num = num / 10;
        stringNum[len - (i + 1)] = rem + '0';
    }
    stringNum[len] = '\0';
80105691:	8b 55 f8             	mov    -0x8(%ebp),%edx
80105694:	8b 45 0c             	mov    0xc(%ebp),%eax
80105697:	01 d0                	add    %edx,%eax
80105699:	c6 00 00             	movb   $0x0,(%eax)
//    cprintf("%s %d \n", stringNum ,len);
    return len;
8010569c:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010569f:	c9                   	leave  
801056a0:	c3                   	ret    

801056a1 <atoi>:

int atoi(const char *s)
{
801056a1:	55                   	push   %ebp
801056a2:	89 e5                	mov    %esp,%ebp
801056a4:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
801056a7:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
801056ae:	eb 25                	jmp    801056d5 <atoi+0x34>
    n = n*10 + *s++ - '0';
801056b0:	8b 55 fc             	mov    -0x4(%ebp),%edx
801056b3:	89 d0                	mov    %edx,%eax
801056b5:	c1 e0 02             	shl    $0x2,%eax
801056b8:	01 d0                	add    %edx,%eax
801056ba:	01 c0                	add    %eax,%eax
801056bc:	89 c1                	mov    %eax,%ecx
801056be:	8b 45 08             	mov    0x8(%ebp),%eax
801056c1:	8d 50 01             	lea    0x1(%eax),%edx
801056c4:	89 55 08             	mov    %edx,0x8(%ebp)
801056c7:	0f b6 00             	movzbl (%eax),%eax
801056ca:	0f be c0             	movsbl %al,%eax
801056cd:	01 c8                	add    %ecx,%eax
801056cf:	83 e8 30             	sub    $0x30,%eax
801056d2:	89 45 fc             	mov    %eax,-0x4(%ebp)
int atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
801056d5:	8b 45 08             	mov    0x8(%ebp),%eax
801056d8:	0f b6 00             	movzbl (%eax),%eax
801056db:	3c 2f                	cmp    $0x2f,%al
801056dd:	7e 0a                	jle    801056e9 <atoi+0x48>
801056df:	8b 45 08             	mov    0x8(%ebp),%eax
801056e2:	0f b6 00             	movzbl (%eax),%eax
801056e5:	3c 39                	cmp    $0x39,%al
801056e7:	7e c7                	jle    801056b0 <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
801056e9:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801056ec:	c9                   	leave  
801056ed:	c3                   	ret    

801056ee <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801056ee:	55                   	push   %ebp
801056ef:	89 e5                	mov    %esp,%ebp
801056f1:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801056f4:	9c                   	pushf  
801056f5:	58                   	pop    %eax
801056f6:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
801056f9:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801056fc:	c9                   	leave  
801056fd:	c3                   	ret    

801056fe <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801056fe:	55                   	push   %ebp
801056ff:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80105701:	fa                   	cli    
}
80105702:	5d                   	pop    %ebp
80105703:	c3                   	ret    

80105704 <sti>:

static inline void
sti(void)
{
80105704:	55                   	push   %ebp
80105705:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105707:	fb                   	sti    
}
80105708:	5d                   	pop    %ebp
80105709:	c3                   	ret    

8010570a <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
8010570a:	55                   	push   %ebp
8010570b:	89 e5                	mov    %esp,%ebp
8010570d:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105710:	8b 55 08             	mov    0x8(%ebp),%edx
80105713:	8b 45 0c             	mov    0xc(%ebp),%eax
80105716:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105719:	f0 87 02             	lock xchg %eax,(%edx)
8010571c:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
8010571f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105722:	c9                   	leave  
80105723:	c3                   	ret    

80105724 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105724:	55                   	push   %ebp
80105725:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105727:	8b 45 08             	mov    0x8(%ebp),%eax
8010572a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010572d:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80105730:	8b 45 08             	mov    0x8(%ebp),%eax
80105733:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105739:	8b 45 08             	mov    0x8(%ebp),%eax
8010573c:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80105743:	5d                   	pop    %ebp
80105744:	c3                   	ret    

80105745 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80105745:	55                   	push   %ebp
80105746:	89 e5                	mov    %esp,%ebp
80105748:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
8010574b:	e8 49 01 00 00       	call   80105899 <pushcli>
  if(holding(lk))
80105750:	8b 45 08             	mov    0x8(%ebp),%eax
80105753:	89 04 24             	mov    %eax,(%esp)
80105756:	e8 14 01 00 00       	call   8010586f <holding>
8010575b:	85 c0                	test   %eax,%eax
8010575d:	74 0c                	je     8010576b <acquire+0x26>
    panic("acquire");
8010575f:	c7 04 24 50 91 10 80 	movl   $0x80109150,(%esp)
80105766:	e8 cf ad ff ff       	call   8010053a <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
8010576b:	90                   	nop
8010576c:	8b 45 08             	mov    0x8(%ebp),%eax
8010576f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105776:	00 
80105777:	89 04 24             	mov    %eax,(%esp)
8010577a:	e8 8b ff ff ff       	call   8010570a <xchg>
8010577f:	85 c0                	test   %eax,%eax
80105781:	75 e9                	jne    8010576c <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80105783:	8b 45 08             	mov    0x8(%ebp),%eax
80105786:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010578d:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105790:	8b 45 08             	mov    0x8(%ebp),%eax
80105793:	83 c0 0c             	add    $0xc,%eax
80105796:	89 44 24 04          	mov    %eax,0x4(%esp)
8010579a:	8d 45 08             	lea    0x8(%ebp),%eax
8010579d:	89 04 24             	mov    %eax,(%esp)
801057a0:	e8 51 00 00 00       	call   801057f6 <getcallerpcs>
}
801057a5:	c9                   	leave  
801057a6:	c3                   	ret    

801057a7 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
801057a7:	55                   	push   %ebp
801057a8:	89 e5                	mov    %esp,%ebp
801057aa:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
801057ad:	8b 45 08             	mov    0x8(%ebp),%eax
801057b0:	89 04 24             	mov    %eax,(%esp)
801057b3:	e8 b7 00 00 00       	call   8010586f <holding>
801057b8:	85 c0                	test   %eax,%eax
801057ba:	75 0c                	jne    801057c8 <release+0x21>
    panic("release");
801057bc:	c7 04 24 58 91 10 80 	movl   $0x80109158,(%esp)
801057c3:	e8 72 ad ff ff       	call   8010053a <panic>

  lk->pcs[0] = 0;
801057c8:	8b 45 08             	mov    0x8(%ebp),%eax
801057cb:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
801057d2:	8b 45 08             	mov    0x8(%ebp),%eax
801057d5:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
801057dc:	8b 45 08             	mov    0x8(%ebp),%eax
801057df:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801057e6:	00 
801057e7:	89 04 24             	mov    %eax,(%esp)
801057ea:	e8 1b ff ff ff       	call   8010570a <xchg>

  popcli();
801057ef:	e8 e9 00 00 00       	call   801058dd <popcli>
}
801057f4:	c9                   	leave  
801057f5:	c3                   	ret    

801057f6 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
801057f6:	55                   	push   %ebp
801057f7:	89 e5                	mov    %esp,%ebp
801057f9:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
801057fc:	8b 45 08             	mov    0x8(%ebp),%eax
801057ff:	83 e8 08             	sub    $0x8,%eax
80105802:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105805:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
8010580c:	eb 38                	jmp    80105846 <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
8010580e:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105812:	74 38                	je     8010584c <getcallerpcs+0x56>
80105814:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
8010581b:	76 2f                	jbe    8010584c <getcallerpcs+0x56>
8010581d:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105821:	74 29                	je     8010584c <getcallerpcs+0x56>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105823:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105826:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010582d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105830:	01 c2                	add    %eax,%edx
80105832:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105835:	8b 40 04             	mov    0x4(%eax),%eax
80105838:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
8010583a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010583d:	8b 00                	mov    (%eax),%eax
8010583f:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105842:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105846:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
8010584a:	7e c2                	jle    8010580e <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
8010584c:	eb 19                	jmp    80105867 <getcallerpcs+0x71>
    pcs[i] = 0;
8010584e:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105851:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105858:	8b 45 0c             	mov    0xc(%ebp),%eax
8010585b:	01 d0                	add    %edx,%eax
8010585d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105863:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105867:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
8010586b:	7e e1                	jle    8010584e <getcallerpcs+0x58>
    pcs[i] = 0;
}
8010586d:	c9                   	leave  
8010586e:	c3                   	ret    

8010586f <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
8010586f:	55                   	push   %ebp
80105870:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105872:	8b 45 08             	mov    0x8(%ebp),%eax
80105875:	8b 00                	mov    (%eax),%eax
80105877:	85 c0                	test   %eax,%eax
80105879:	74 17                	je     80105892 <holding+0x23>
8010587b:	8b 45 08             	mov    0x8(%ebp),%eax
8010587e:	8b 50 08             	mov    0x8(%eax),%edx
80105881:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105887:	39 c2                	cmp    %eax,%edx
80105889:	75 07                	jne    80105892 <holding+0x23>
8010588b:	b8 01 00 00 00       	mov    $0x1,%eax
80105890:	eb 05                	jmp    80105897 <holding+0x28>
80105892:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105897:	5d                   	pop    %ebp
80105898:	c3                   	ret    

80105899 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105899:	55                   	push   %ebp
8010589a:	89 e5                	mov    %esp,%ebp
8010589c:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
8010589f:	e8 4a fe ff ff       	call   801056ee <readeflags>
801058a4:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
801058a7:	e8 52 fe ff ff       	call   801056fe <cli>
  if(cpu->ncli++ == 0)
801058ac:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801058b3:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
801058b9:	8d 48 01             	lea    0x1(%eax),%ecx
801058bc:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
801058c2:	85 c0                	test   %eax,%eax
801058c4:	75 15                	jne    801058db <pushcli+0x42>
    cpu->intena = eflags & FL_IF;
801058c6:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801058cc:	8b 55 fc             	mov    -0x4(%ebp),%edx
801058cf:	81 e2 00 02 00 00    	and    $0x200,%edx
801058d5:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801058db:	c9                   	leave  
801058dc:	c3                   	ret    

801058dd <popcli>:

void
popcli(void)
{
801058dd:	55                   	push   %ebp
801058de:	89 e5                	mov    %esp,%ebp
801058e0:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
801058e3:	e8 06 fe ff ff       	call   801056ee <readeflags>
801058e8:	25 00 02 00 00       	and    $0x200,%eax
801058ed:	85 c0                	test   %eax,%eax
801058ef:	74 0c                	je     801058fd <popcli+0x20>
    panic("popcli - interruptible");
801058f1:	c7 04 24 60 91 10 80 	movl   $0x80109160,(%esp)
801058f8:	e8 3d ac ff ff       	call   8010053a <panic>
  if(--cpu->ncli < 0)
801058fd:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105903:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105909:	83 ea 01             	sub    $0x1,%edx
8010590c:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105912:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105918:	85 c0                	test   %eax,%eax
8010591a:	79 0c                	jns    80105928 <popcli+0x4b>
    panic("popcli");
8010591c:	c7 04 24 77 91 10 80 	movl   $0x80109177,(%esp)
80105923:	e8 12 ac ff ff       	call   8010053a <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105928:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010592e:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105934:	85 c0                	test   %eax,%eax
80105936:	75 15                	jne    8010594d <popcli+0x70>
80105938:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010593e:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105944:	85 c0                	test   %eax,%eax
80105946:	74 05                	je     8010594d <popcli+0x70>
    sti();
80105948:	e8 b7 fd ff ff       	call   80105704 <sti>
}
8010594d:	c9                   	leave  
8010594e:	c3                   	ret    

8010594f <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
8010594f:	55                   	push   %ebp
80105950:	89 e5                	mov    %esp,%ebp
80105952:	57                   	push   %edi
80105953:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105954:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105957:	8b 55 10             	mov    0x10(%ebp),%edx
8010595a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010595d:	89 cb                	mov    %ecx,%ebx
8010595f:	89 df                	mov    %ebx,%edi
80105961:	89 d1                	mov    %edx,%ecx
80105963:	fc                   	cld    
80105964:	f3 aa                	rep stos %al,%es:(%edi)
80105966:	89 ca                	mov    %ecx,%edx
80105968:	89 fb                	mov    %edi,%ebx
8010596a:	89 5d 08             	mov    %ebx,0x8(%ebp)
8010596d:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105970:	5b                   	pop    %ebx
80105971:	5f                   	pop    %edi
80105972:	5d                   	pop    %ebp
80105973:	c3                   	ret    

80105974 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105974:	55                   	push   %ebp
80105975:	89 e5                	mov    %esp,%ebp
80105977:	57                   	push   %edi
80105978:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80105979:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010597c:	8b 55 10             	mov    0x10(%ebp),%edx
8010597f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105982:	89 cb                	mov    %ecx,%ebx
80105984:	89 df                	mov    %ebx,%edi
80105986:	89 d1                	mov    %edx,%ecx
80105988:	fc                   	cld    
80105989:	f3 ab                	rep stos %eax,%es:(%edi)
8010598b:	89 ca                	mov    %ecx,%edx
8010598d:	89 fb                	mov    %edi,%ebx
8010598f:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105992:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105995:	5b                   	pop    %ebx
80105996:	5f                   	pop    %edi
80105997:	5d                   	pop    %ebp
80105998:	c3                   	ret    

80105999 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105999:	55                   	push   %ebp
8010599a:	89 e5                	mov    %esp,%ebp
8010599c:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
8010599f:	8b 45 08             	mov    0x8(%ebp),%eax
801059a2:	83 e0 03             	and    $0x3,%eax
801059a5:	85 c0                	test   %eax,%eax
801059a7:	75 49                	jne    801059f2 <memset+0x59>
801059a9:	8b 45 10             	mov    0x10(%ebp),%eax
801059ac:	83 e0 03             	and    $0x3,%eax
801059af:	85 c0                	test   %eax,%eax
801059b1:	75 3f                	jne    801059f2 <memset+0x59>
    c &= 0xFF;
801059b3:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
801059ba:	8b 45 10             	mov    0x10(%ebp),%eax
801059bd:	c1 e8 02             	shr    $0x2,%eax
801059c0:	89 c2                	mov    %eax,%edx
801059c2:	8b 45 0c             	mov    0xc(%ebp),%eax
801059c5:	c1 e0 18             	shl    $0x18,%eax
801059c8:	89 c1                	mov    %eax,%ecx
801059ca:	8b 45 0c             	mov    0xc(%ebp),%eax
801059cd:	c1 e0 10             	shl    $0x10,%eax
801059d0:	09 c1                	or     %eax,%ecx
801059d2:	8b 45 0c             	mov    0xc(%ebp),%eax
801059d5:	c1 e0 08             	shl    $0x8,%eax
801059d8:	09 c8                	or     %ecx,%eax
801059da:	0b 45 0c             	or     0xc(%ebp),%eax
801059dd:	89 54 24 08          	mov    %edx,0x8(%esp)
801059e1:	89 44 24 04          	mov    %eax,0x4(%esp)
801059e5:	8b 45 08             	mov    0x8(%ebp),%eax
801059e8:	89 04 24             	mov    %eax,(%esp)
801059eb:	e8 84 ff ff ff       	call   80105974 <stosl>
801059f0:	eb 19                	jmp    80105a0b <memset+0x72>
  } else
    stosb(dst, c, n);
801059f2:	8b 45 10             	mov    0x10(%ebp),%eax
801059f5:	89 44 24 08          	mov    %eax,0x8(%esp)
801059f9:	8b 45 0c             	mov    0xc(%ebp),%eax
801059fc:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a00:	8b 45 08             	mov    0x8(%ebp),%eax
80105a03:	89 04 24             	mov    %eax,(%esp)
80105a06:	e8 44 ff ff ff       	call   8010594f <stosb>
  return dst;
80105a0b:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105a0e:	c9                   	leave  
80105a0f:	c3                   	ret    

80105a10 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105a10:	55                   	push   %ebp
80105a11:	89 e5                	mov    %esp,%ebp
80105a13:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105a16:	8b 45 08             	mov    0x8(%ebp),%eax
80105a19:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105a1c:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a1f:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105a22:	eb 30                	jmp    80105a54 <memcmp+0x44>
    if(*s1 != *s2)
80105a24:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105a27:	0f b6 10             	movzbl (%eax),%edx
80105a2a:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105a2d:	0f b6 00             	movzbl (%eax),%eax
80105a30:	38 c2                	cmp    %al,%dl
80105a32:	74 18                	je     80105a4c <memcmp+0x3c>
      return *s1 - *s2;
80105a34:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105a37:	0f b6 00             	movzbl (%eax),%eax
80105a3a:	0f b6 d0             	movzbl %al,%edx
80105a3d:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105a40:	0f b6 00             	movzbl (%eax),%eax
80105a43:	0f b6 c0             	movzbl %al,%eax
80105a46:	29 c2                	sub    %eax,%edx
80105a48:	89 d0                	mov    %edx,%eax
80105a4a:	eb 1a                	jmp    80105a66 <memcmp+0x56>
    s1++, s2++;
80105a4c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105a50:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105a54:	8b 45 10             	mov    0x10(%ebp),%eax
80105a57:	8d 50 ff             	lea    -0x1(%eax),%edx
80105a5a:	89 55 10             	mov    %edx,0x10(%ebp)
80105a5d:	85 c0                	test   %eax,%eax
80105a5f:	75 c3                	jne    80105a24 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105a61:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105a66:	c9                   	leave  
80105a67:	c3                   	ret    

80105a68 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105a68:	55                   	push   %ebp
80105a69:	89 e5                	mov    %esp,%ebp
80105a6b:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105a6e:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a71:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105a74:	8b 45 08             	mov    0x8(%ebp),%eax
80105a77:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105a7a:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105a7d:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105a80:	73 3d                	jae    80105abf <memmove+0x57>
80105a82:	8b 45 10             	mov    0x10(%ebp),%eax
80105a85:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105a88:	01 d0                	add    %edx,%eax
80105a8a:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105a8d:	76 30                	jbe    80105abf <memmove+0x57>
    s += n;
80105a8f:	8b 45 10             	mov    0x10(%ebp),%eax
80105a92:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80105a95:	8b 45 10             	mov    0x10(%ebp),%eax
80105a98:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105a9b:	eb 13                	jmp    80105ab0 <memmove+0x48>
      *--d = *--s;
80105a9d:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105aa1:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80105aa5:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105aa8:	0f b6 10             	movzbl (%eax),%edx
80105aab:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105aae:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105ab0:	8b 45 10             	mov    0x10(%ebp),%eax
80105ab3:	8d 50 ff             	lea    -0x1(%eax),%edx
80105ab6:	89 55 10             	mov    %edx,0x10(%ebp)
80105ab9:	85 c0                	test   %eax,%eax
80105abb:	75 e0                	jne    80105a9d <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105abd:	eb 26                	jmp    80105ae5 <memmove+0x7d>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105abf:	eb 17                	jmp    80105ad8 <memmove+0x70>
      *d++ = *s++;
80105ac1:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105ac4:	8d 50 01             	lea    0x1(%eax),%edx
80105ac7:	89 55 f8             	mov    %edx,-0x8(%ebp)
80105aca:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105acd:	8d 4a 01             	lea    0x1(%edx),%ecx
80105ad0:	89 4d fc             	mov    %ecx,-0x4(%ebp)
80105ad3:	0f b6 12             	movzbl (%edx),%edx
80105ad6:	88 10                	mov    %dl,(%eax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105ad8:	8b 45 10             	mov    0x10(%ebp),%eax
80105adb:	8d 50 ff             	lea    -0x1(%eax),%edx
80105ade:	89 55 10             	mov    %edx,0x10(%ebp)
80105ae1:	85 c0                	test   %eax,%eax
80105ae3:	75 dc                	jne    80105ac1 <memmove+0x59>
      *d++ = *s++;

  return dst;
80105ae5:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105ae8:	c9                   	leave  
80105ae9:	c3                   	ret    

80105aea <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105aea:	55                   	push   %ebp
80105aeb:	89 e5                	mov    %esp,%ebp
80105aed:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105af0:	8b 45 10             	mov    0x10(%ebp),%eax
80105af3:	89 44 24 08          	mov    %eax,0x8(%esp)
80105af7:	8b 45 0c             	mov    0xc(%ebp),%eax
80105afa:	89 44 24 04          	mov    %eax,0x4(%esp)
80105afe:	8b 45 08             	mov    0x8(%ebp),%eax
80105b01:	89 04 24             	mov    %eax,(%esp)
80105b04:	e8 5f ff ff ff       	call   80105a68 <memmove>
}
80105b09:	c9                   	leave  
80105b0a:	c3                   	ret    

80105b0b <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105b0b:	55                   	push   %ebp
80105b0c:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105b0e:	eb 0c                	jmp    80105b1c <strncmp+0x11>
    n--, p++, q++;
80105b10:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105b14:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105b18:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105b1c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105b20:	74 1a                	je     80105b3c <strncmp+0x31>
80105b22:	8b 45 08             	mov    0x8(%ebp),%eax
80105b25:	0f b6 00             	movzbl (%eax),%eax
80105b28:	84 c0                	test   %al,%al
80105b2a:	74 10                	je     80105b3c <strncmp+0x31>
80105b2c:	8b 45 08             	mov    0x8(%ebp),%eax
80105b2f:	0f b6 10             	movzbl (%eax),%edx
80105b32:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b35:	0f b6 00             	movzbl (%eax),%eax
80105b38:	38 c2                	cmp    %al,%dl
80105b3a:	74 d4                	je     80105b10 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105b3c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105b40:	75 07                	jne    80105b49 <strncmp+0x3e>
    return 0;
80105b42:	b8 00 00 00 00       	mov    $0x0,%eax
80105b47:	eb 16                	jmp    80105b5f <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
80105b49:	8b 45 08             	mov    0x8(%ebp),%eax
80105b4c:	0f b6 00             	movzbl (%eax),%eax
80105b4f:	0f b6 d0             	movzbl %al,%edx
80105b52:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b55:	0f b6 00             	movzbl (%eax),%eax
80105b58:	0f b6 c0             	movzbl %al,%eax
80105b5b:	29 c2                	sub    %eax,%edx
80105b5d:	89 d0                	mov    %edx,%eax
}
80105b5f:	5d                   	pop    %ebp
80105b60:	c3                   	ret    

80105b61 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105b61:	55                   	push   %ebp
80105b62:	89 e5                	mov    %esp,%ebp
80105b64:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105b67:	8b 45 08             	mov    0x8(%ebp),%eax
80105b6a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105b6d:	90                   	nop
80105b6e:	8b 45 10             	mov    0x10(%ebp),%eax
80105b71:	8d 50 ff             	lea    -0x1(%eax),%edx
80105b74:	89 55 10             	mov    %edx,0x10(%ebp)
80105b77:	85 c0                	test   %eax,%eax
80105b79:	7e 1e                	jle    80105b99 <strncpy+0x38>
80105b7b:	8b 45 08             	mov    0x8(%ebp),%eax
80105b7e:	8d 50 01             	lea    0x1(%eax),%edx
80105b81:	89 55 08             	mov    %edx,0x8(%ebp)
80105b84:	8b 55 0c             	mov    0xc(%ebp),%edx
80105b87:	8d 4a 01             	lea    0x1(%edx),%ecx
80105b8a:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105b8d:	0f b6 12             	movzbl (%edx),%edx
80105b90:	88 10                	mov    %dl,(%eax)
80105b92:	0f b6 00             	movzbl (%eax),%eax
80105b95:	84 c0                	test   %al,%al
80105b97:	75 d5                	jne    80105b6e <strncpy+0xd>
    ;
  while(n-- > 0)
80105b99:	eb 0c                	jmp    80105ba7 <strncpy+0x46>
    *s++ = 0;
80105b9b:	8b 45 08             	mov    0x8(%ebp),%eax
80105b9e:	8d 50 01             	lea    0x1(%eax),%edx
80105ba1:	89 55 08             	mov    %edx,0x8(%ebp)
80105ba4:	c6 00 00             	movb   $0x0,(%eax)
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105ba7:	8b 45 10             	mov    0x10(%ebp),%eax
80105baa:	8d 50 ff             	lea    -0x1(%eax),%edx
80105bad:	89 55 10             	mov    %edx,0x10(%ebp)
80105bb0:	85 c0                	test   %eax,%eax
80105bb2:	7f e7                	jg     80105b9b <strncpy+0x3a>
    *s++ = 0;
  return os;
80105bb4:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105bb7:	c9                   	leave  
80105bb8:	c3                   	ret    

80105bb9 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80105bb9:	55                   	push   %ebp
80105bba:	89 e5                	mov    %esp,%ebp
80105bbc:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105bbf:	8b 45 08             	mov    0x8(%ebp),%eax
80105bc2:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105bc5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105bc9:	7f 05                	jg     80105bd0 <safestrcpy+0x17>
    return os;
80105bcb:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105bce:	eb 31                	jmp    80105c01 <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
80105bd0:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105bd4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105bd8:	7e 1e                	jle    80105bf8 <safestrcpy+0x3f>
80105bda:	8b 45 08             	mov    0x8(%ebp),%eax
80105bdd:	8d 50 01             	lea    0x1(%eax),%edx
80105be0:	89 55 08             	mov    %edx,0x8(%ebp)
80105be3:	8b 55 0c             	mov    0xc(%ebp),%edx
80105be6:	8d 4a 01             	lea    0x1(%edx),%ecx
80105be9:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105bec:	0f b6 12             	movzbl (%edx),%edx
80105bef:	88 10                	mov    %dl,(%eax)
80105bf1:	0f b6 00             	movzbl (%eax),%eax
80105bf4:	84 c0                	test   %al,%al
80105bf6:	75 d8                	jne    80105bd0 <safestrcpy+0x17>
    ;
  *s = 0;
80105bf8:	8b 45 08             	mov    0x8(%ebp),%eax
80105bfb:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105bfe:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105c01:	c9                   	leave  
80105c02:	c3                   	ret    

80105c03 <strlen>:

int
strlen(const char *s)
{
80105c03:	55                   	push   %ebp
80105c04:	89 e5                	mov    %esp,%ebp
80105c06:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105c09:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105c10:	eb 04                	jmp    80105c16 <strlen+0x13>
80105c12:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105c16:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105c19:	8b 45 08             	mov    0x8(%ebp),%eax
80105c1c:	01 d0                	add    %edx,%eax
80105c1e:	0f b6 00             	movzbl (%eax),%eax
80105c21:	84 c0                	test   %al,%al
80105c23:	75 ed                	jne    80105c12 <strlen+0xf>
    ;
  return n;
80105c25:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105c28:	c9                   	leave  
80105c29:	c3                   	ret    

80105c2a <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105c2a:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105c2e:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105c32:	55                   	push   %ebp
  pushl %ebx
80105c33:	53                   	push   %ebx
  pushl %esi
80105c34:	56                   	push   %esi
  pushl %edi
80105c35:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105c36:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105c38:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105c3a:	5f                   	pop    %edi
  popl %esi
80105c3b:	5e                   	pop    %esi
  popl %ebx
80105c3c:	5b                   	pop    %ebx
  popl %ebp
80105c3d:	5d                   	pop    %ebp
  ret
80105c3e:	c3                   	ret    

80105c3f <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80105c3f:	55                   	push   %ebp
80105c40:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
80105c42:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105c48:	8b 00                	mov    (%eax),%eax
80105c4a:	3b 45 08             	cmp    0x8(%ebp),%eax
80105c4d:	76 12                	jbe    80105c61 <fetchint+0x22>
80105c4f:	8b 45 08             	mov    0x8(%ebp),%eax
80105c52:	8d 50 04             	lea    0x4(%eax),%edx
80105c55:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105c5b:	8b 00                	mov    (%eax),%eax
80105c5d:	39 c2                	cmp    %eax,%edx
80105c5f:	76 07                	jbe    80105c68 <fetchint+0x29>
    return -1;
80105c61:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c66:	eb 0f                	jmp    80105c77 <fetchint+0x38>
  *ip = *(int*)(addr);
80105c68:	8b 45 08             	mov    0x8(%ebp),%eax
80105c6b:	8b 10                	mov    (%eax),%edx
80105c6d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105c70:	89 10                	mov    %edx,(%eax)
  return 0;
80105c72:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105c77:	5d                   	pop    %ebp
80105c78:	c3                   	ret    

80105c79 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80105c79:	55                   	push   %ebp
80105c7a:	89 e5                	mov    %esp,%ebp
80105c7c:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
80105c7f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105c85:	8b 00                	mov    (%eax),%eax
80105c87:	3b 45 08             	cmp    0x8(%ebp),%eax
80105c8a:	77 07                	ja     80105c93 <fetchstr+0x1a>
    return -1;
80105c8c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c91:	eb 46                	jmp    80105cd9 <fetchstr+0x60>
  *pp = (char*)addr;
80105c93:	8b 55 08             	mov    0x8(%ebp),%edx
80105c96:	8b 45 0c             	mov    0xc(%ebp),%eax
80105c99:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
80105c9b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ca1:	8b 00                	mov    (%eax),%eax
80105ca3:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105ca6:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ca9:	8b 00                	mov    (%eax),%eax
80105cab:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105cae:	eb 1c                	jmp    80105ccc <fetchstr+0x53>
    if(*s == 0)
80105cb0:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105cb3:	0f b6 00             	movzbl (%eax),%eax
80105cb6:	84 c0                	test   %al,%al
80105cb8:	75 0e                	jne    80105cc8 <fetchstr+0x4f>
      return s - *pp;
80105cba:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105cbd:	8b 45 0c             	mov    0xc(%ebp),%eax
80105cc0:	8b 00                	mov    (%eax),%eax
80105cc2:	29 c2                	sub    %eax,%edx
80105cc4:	89 d0                	mov    %edx,%eax
80105cc6:	eb 11                	jmp    80105cd9 <fetchstr+0x60>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
80105cc8:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105ccc:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105ccf:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105cd2:	72 dc                	jb     80105cb0 <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
80105cd4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105cd9:	c9                   	leave  
80105cda:	c3                   	ret    

80105cdb <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80105cdb:	55                   	push   %ebp
80105cdc:	89 e5                	mov    %esp,%ebp
80105cde:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->tf->esp + 4 + 4*n, ip);
80105ce1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ce7:	8b 40 18             	mov    0x18(%eax),%eax
80105cea:	8b 50 44             	mov    0x44(%eax),%edx
80105ced:	8b 45 08             	mov    0x8(%ebp),%eax
80105cf0:	c1 e0 02             	shl    $0x2,%eax
80105cf3:	01 d0                	add    %edx,%eax
80105cf5:	8d 50 04             	lea    0x4(%eax),%edx
80105cf8:	8b 45 0c             	mov    0xc(%ebp),%eax
80105cfb:	89 44 24 04          	mov    %eax,0x4(%esp)
80105cff:	89 14 24             	mov    %edx,(%esp)
80105d02:	e8 38 ff ff ff       	call   80105c3f <fetchint>
}
80105d07:	c9                   	leave  
80105d08:	c3                   	ret    

80105d09 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80105d09:	55                   	push   %ebp
80105d0a:	89 e5                	mov    %esp,%ebp
80105d0c:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80105d0f:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105d12:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d16:	8b 45 08             	mov    0x8(%ebp),%eax
80105d19:	89 04 24             	mov    %eax,(%esp)
80105d1c:	e8 ba ff ff ff       	call   80105cdb <argint>
80105d21:	85 c0                	test   %eax,%eax
80105d23:	79 07                	jns    80105d2c <argptr+0x23>
    return -1;
80105d25:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d2a:	eb 3d                	jmp    80105d69 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105d2c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d2f:	89 c2                	mov    %eax,%edx
80105d31:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d37:	8b 00                	mov    (%eax),%eax
80105d39:	39 c2                	cmp    %eax,%edx
80105d3b:	73 16                	jae    80105d53 <argptr+0x4a>
80105d3d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d40:	89 c2                	mov    %eax,%edx
80105d42:	8b 45 10             	mov    0x10(%ebp),%eax
80105d45:	01 c2                	add    %eax,%edx
80105d47:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d4d:	8b 00                	mov    (%eax),%eax
80105d4f:	39 c2                	cmp    %eax,%edx
80105d51:	76 07                	jbe    80105d5a <argptr+0x51>
    return -1;
80105d53:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d58:	eb 0f                	jmp    80105d69 <argptr+0x60>
  *pp = (char*)i;
80105d5a:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d5d:	89 c2                	mov    %eax,%edx
80105d5f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d62:	89 10                	mov    %edx,(%eax)
  return 0;
80105d64:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105d69:	c9                   	leave  
80105d6a:	c3                   	ret    

80105d6b <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105d6b:	55                   	push   %ebp
80105d6c:	89 e5                	mov    %esp,%ebp
80105d6e:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105d71:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105d74:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d78:	8b 45 08             	mov    0x8(%ebp),%eax
80105d7b:	89 04 24             	mov    %eax,(%esp)
80105d7e:	e8 58 ff ff ff       	call   80105cdb <argint>
80105d83:	85 c0                	test   %eax,%eax
80105d85:	79 07                	jns    80105d8e <argstr+0x23>
    return -1;
80105d87:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d8c:	eb 12                	jmp    80105da0 <argstr+0x35>
  return fetchstr(addr, pp);
80105d8e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d91:	8b 55 0c             	mov    0xc(%ebp),%edx
80105d94:	89 54 24 04          	mov    %edx,0x4(%esp)
80105d98:	89 04 24             	mov    %eax,(%esp)
80105d9b:	e8 d9 fe ff ff       	call   80105c79 <fetchstr>
}
80105da0:	c9                   	leave  
80105da1:	c3                   	ret    

80105da2 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
80105da2:	55                   	push   %ebp
80105da3:	89 e5                	mov    %esp,%ebp
80105da5:	53                   	push   %ebx
80105da6:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
80105da9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105daf:	8b 40 18             	mov    0x18(%eax),%eax
80105db2:	8b 40 1c             	mov    0x1c(%eax),%eax
80105db5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80105db8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105dbc:	7e 30                	jle    80105dee <syscall+0x4c>
80105dbe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dc1:	83 f8 15             	cmp    $0x15,%eax
80105dc4:	77 28                	ja     80105dee <syscall+0x4c>
80105dc6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dc9:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80105dd0:	85 c0                	test   %eax,%eax
80105dd2:	74 1a                	je     80105dee <syscall+0x4c>
    proc->tf->eax = syscalls[num]();
80105dd4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105dda:	8b 58 18             	mov    0x18(%eax),%ebx
80105ddd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105de0:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80105de7:	ff d0                	call   *%eax
80105de9:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105dec:	eb 3d                	jmp    80105e2b <syscall+0x89>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80105dee:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105df4:	8d 48 28             	lea    0x28(%eax),%ecx
80105df7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80105dfd:	8b 40 10             	mov    0x10(%eax),%eax
80105e00:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105e03:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105e07:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105e0b:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e0f:	c7 04 24 7e 91 10 80 	movl   $0x8010917e,(%esp)
80105e16:	e8 85 a5 ff ff       	call   801003a0 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105e1b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e21:	8b 40 18             	mov    0x18(%eax),%eax
80105e24:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105e2b:	83 c4 24             	add    $0x24,%esp
80105e2e:	5b                   	pop    %ebx
80105e2f:	5d                   	pop    %ebp
80105e30:	c3                   	ret    

80105e31 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105e31:	55                   	push   %ebp
80105e32:	89 e5                	mov    %esp,%ebp
80105e34:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80105e37:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105e3a:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e3e:	8b 45 08             	mov    0x8(%ebp),%eax
80105e41:	89 04 24             	mov    %eax,(%esp)
80105e44:	e8 92 fe ff ff       	call   80105cdb <argint>
80105e49:	85 c0                	test   %eax,%eax
80105e4b:	79 07                	jns    80105e54 <argfd+0x23>
    return -1;
80105e4d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e52:	eb 50                	jmp    80105ea4 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80105e54:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e57:	85 c0                	test   %eax,%eax
80105e59:	78 21                	js     80105e7c <argfd+0x4b>
80105e5b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e5e:	83 f8 0f             	cmp    $0xf,%eax
80105e61:	7f 19                	jg     80105e7c <argfd+0x4b>
80105e63:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e69:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105e6c:	83 c2 0c             	add    $0xc,%edx
80105e6f:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105e73:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105e76:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105e7a:	75 07                	jne    80105e83 <argfd+0x52>
    return -1;
80105e7c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e81:	eb 21                	jmp    80105ea4 <argfd+0x73>
  if(pfd)
80105e83:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105e87:	74 08                	je     80105e91 <argfd+0x60>
    *pfd = fd;
80105e89:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105e8c:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e8f:	89 10                	mov    %edx,(%eax)
  if(pf)
80105e91:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105e95:	74 08                	je     80105e9f <argfd+0x6e>
    *pf = f;
80105e97:	8b 45 10             	mov    0x10(%ebp),%eax
80105e9a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105e9d:	89 10                	mov    %edx,(%eax)
  return 0;
80105e9f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105ea4:	c9                   	leave  
80105ea5:	c3                   	ret    

80105ea6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80105ea6:	55                   	push   %ebp
80105ea7:	89 e5                	mov    %esp,%ebp
80105ea9:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105eac:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105eb3:	eb 30                	jmp    80105ee5 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80105eb5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ebb:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105ebe:	83 c2 0c             	add    $0xc,%edx
80105ec1:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105ec5:	85 c0                	test   %eax,%eax
80105ec7:	75 18                	jne    80105ee1 <fdalloc+0x3b>
      proc->ofile[fd] = f;
80105ec9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ecf:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105ed2:	8d 4a 0c             	lea    0xc(%edx),%ecx
80105ed5:	8b 55 08             	mov    0x8(%ebp),%edx
80105ed8:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80105edc:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105edf:	eb 0f                	jmp    80105ef0 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105ee1:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105ee5:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80105ee9:	7e ca                	jle    80105eb5 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80105eeb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105ef0:	c9                   	leave  
80105ef1:	c3                   	ret    

80105ef2 <sys_dup>:

int
sys_dup(void)
{
80105ef2:	55                   	push   %ebp
80105ef3:	89 e5                	mov    %esp,%ebp
80105ef5:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80105ef8:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105efb:	89 44 24 08          	mov    %eax,0x8(%esp)
80105eff:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105f06:	00 
80105f07:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f0e:	e8 1e ff ff ff       	call   80105e31 <argfd>
80105f13:	85 c0                	test   %eax,%eax
80105f15:	79 07                	jns    80105f1e <sys_dup+0x2c>
    return -1;
80105f17:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f1c:	eb 29                	jmp    80105f47 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105f1e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f21:	89 04 24             	mov    %eax,(%esp)
80105f24:	e8 7d ff ff ff       	call   80105ea6 <fdalloc>
80105f29:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105f2c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105f30:	79 07                	jns    80105f39 <sys_dup+0x47>
    return -1;
80105f32:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f37:	eb 0e                	jmp    80105f47 <sys_dup+0x55>
  filedup(f);
80105f39:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f3c:	89 04 24             	mov    %eax,(%esp)
80105f3f:	e8 71 b0 ff ff       	call   80100fb5 <filedup>
  return fd;
80105f44:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105f47:	c9                   	leave  
80105f48:	c3                   	ret    

80105f49 <sys_read>:

int
sys_read(void)
{
80105f49:	55                   	push   %ebp
80105f4a:	89 e5                	mov    %esp,%ebp
80105f4c:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105f4f:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105f52:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f56:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105f5d:	00 
80105f5e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f65:	e8 c7 fe ff ff       	call   80105e31 <argfd>
80105f6a:	85 c0                	test   %eax,%eax
80105f6c:	78 35                	js     80105fa3 <sys_read+0x5a>
80105f6e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105f71:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f75:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105f7c:	e8 5a fd ff ff       	call   80105cdb <argint>
80105f81:	85 c0                	test   %eax,%eax
80105f83:	78 1e                	js     80105fa3 <sys_read+0x5a>
80105f85:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f88:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f8c:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105f8f:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f93:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105f9a:	e8 6a fd ff ff       	call   80105d09 <argptr>
80105f9f:	85 c0                	test   %eax,%eax
80105fa1:	79 07                	jns    80105faa <sys_read+0x61>
    return -1;
80105fa3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fa8:	eb 19                	jmp    80105fc3 <sys_read+0x7a>
  return fileread(f, p, n);
80105faa:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105fad:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105fb0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fb3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105fb7:	89 54 24 04          	mov    %edx,0x4(%esp)
80105fbb:	89 04 24             	mov    %eax,(%esp)
80105fbe:	e8 5f b1 ff ff       	call   80101122 <fileread>
}
80105fc3:	c9                   	leave  
80105fc4:	c3                   	ret    

80105fc5 <sys_write>:

int
sys_write(void)
{
80105fc5:	55                   	push   %ebp
80105fc6:	89 e5                	mov    %esp,%ebp
80105fc8:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105fcb:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105fce:	89 44 24 08          	mov    %eax,0x8(%esp)
80105fd2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105fd9:	00 
80105fda:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105fe1:	e8 4b fe ff ff       	call   80105e31 <argfd>
80105fe6:	85 c0                	test   %eax,%eax
80105fe8:	78 35                	js     8010601f <sys_write+0x5a>
80105fea:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105fed:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ff1:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105ff8:	e8 de fc ff ff       	call   80105cdb <argint>
80105ffd:	85 c0                	test   %eax,%eax
80105fff:	78 1e                	js     8010601f <sys_write+0x5a>
80106001:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106004:	89 44 24 08          	mov    %eax,0x8(%esp)
80106008:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010600b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010600f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106016:	e8 ee fc ff ff       	call   80105d09 <argptr>
8010601b:	85 c0                	test   %eax,%eax
8010601d:	79 07                	jns    80106026 <sys_write+0x61>
    return -1;
8010601f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106024:	eb 19                	jmp    8010603f <sys_write+0x7a>
  return filewrite(f, p, n);
80106026:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106029:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010602c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010602f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106033:	89 54 24 04          	mov    %edx,0x4(%esp)
80106037:	89 04 24             	mov    %eax,(%esp)
8010603a:	e8 9f b1 ff ff       	call   801011de <filewrite>
}
8010603f:	c9                   	leave  
80106040:	c3                   	ret    

80106041 <sys_close>:

int
sys_close(void)
{
80106041:	55                   	push   %ebp
80106042:	89 e5                	mov    %esp,%ebp
80106044:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
80106047:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010604a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010604e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106051:	89 44 24 04          	mov    %eax,0x4(%esp)
80106055:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010605c:	e8 d0 fd ff ff       	call   80105e31 <argfd>
80106061:	85 c0                	test   %eax,%eax
80106063:	79 07                	jns    8010606c <sys_close+0x2b>
    return -1;
80106065:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010606a:	eb 24                	jmp    80106090 <sys_close+0x4f>
  proc->ofile[fd] = 0;
8010606c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106072:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106075:	83 c2 0c             	add    $0xc,%edx
80106078:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010607f:	00 
  fileclose(f);
80106080:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106083:	89 04 24             	mov    %eax,(%esp)
80106086:	e8 72 af ff ff       	call   80100ffd <fileclose>
  return 0;
8010608b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106090:	c9                   	leave  
80106091:	c3                   	ret    

80106092 <sys_fstat>:

int
sys_fstat(void)
{
80106092:	55                   	push   %ebp
80106093:	89 e5                	mov    %esp,%ebp
80106095:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80106098:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010609b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010609f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801060a6:	00 
801060a7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801060ae:	e8 7e fd ff ff       	call   80105e31 <argfd>
801060b3:	85 c0                	test   %eax,%eax
801060b5:	78 1f                	js     801060d6 <sys_fstat+0x44>
801060b7:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801060be:	00 
801060bf:	8d 45 f0             	lea    -0x10(%ebp),%eax
801060c2:	89 44 24 04          	mov    %eax,0x4(%esp)
801060c6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801060cd:	e8 37 fc ff ff       	call   80105d09 <argptr>
801060d2:	85 c0                	test   %eax,%eax
801060d4:	79 07                	jns    801060dd <sys_fstat+0x4b>
    return -1;
801060d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060db:	eb 12                	jmp    801060ef <sys_fstat+0x5d>
  return filestat(f, st);
801060dd:	8b 55 f0             	mov    -0x10(%ebp),%edx
801060e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060e3:	89 54 24 04          	mov    %edx,0x4(%esp)
801060e7:	89 04 24             	mov    %eax,(%esp)
801060ea:	e8 e4 af ff ff       	call   801010d3 <filestat>
}
801060ef:	c9                   	leave  
801060f0:	c3                   	ret    

801060f1 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
801060f1:	55                   	push   %ebp
801060f2:	89 e5                	mov    %esp,%ebp
801060f4:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801060f7:	8d 45 d8             	lea    -0x28(%ebp),%eax
801060fa:	89 44 24 04          	mov    %eax,0x4(%esp)
801060fe:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106105:	e8 61 fc ff ff       	call   80105d6b <argstr>
8010610a:	85 c0                	test   %eax,%eax
8010610c:	78 17                	js     80106125 <sys_link+0x34>
8010610e:	8d 45 dc             	lea    -0x24(%ebp),%eax
80106111:	89 44 24 04          	mov    %eax,0x4(%esp)
80106115:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010611c:	e8 4a fc ff ff       	call   80105d6b <argstr>
80106121:	85 c0                	test   %eax,%eax
80106123:	79 0a                	jns    8010612f <sys_link+0x3e>
    return -1;
80106125:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010612a:	e9 42 01 00 00       	jmp    80106271 <sys_link+0x180>

  begin_op();
8010612f:	e8 26 d4 ff ff       	call   8010355a <begin_op>
  if((ip = namei(old)) == 0){
80106134:	8b 45 d8             	mov    -0x28(%ebp),%eax
80106137:	89 04 24             	mov    %eax,(%esp)
8010613a:	e8 11 c4 ff ff       	call   80102550 <namei>
8010613f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106142:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106146:	75 0f                	jne    80106157 <sys_link+0x66>
    end_op();
80106148:	e8 91 d4 ff ff       	call   801035de <end_op>
    return -1;
8010614d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106152:	e9 1a 01 00 00       	jmp    80106271 <sys_link+0x180>
  }

  ilock(ip);
80106157:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010615a:	89 04 24             	mov    %eax,(%esp)
8010615d:	e8 28 b7 ff ff       	call   8010188a <ilock>
  if(ip->type == T_DIR){
80106162:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106165:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106169:	66 83 f8 01          	cmp    $0x1,%ax
8010616d:	75 1a                	jne    80106189 <sys_link+0x98>
    iunlockput(ip);
8010616f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106172:	89 04 24             	mov    %eax,(%esp)
80106175:	e8 94 b9 ff ff       	call   80101b0e <iunlockput>
    end_op();
8010617a:	e8 5f d4 ff ff       	call   801035de <end_op>
    return -1;
8010617f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106184:	e9 e8 00 00 00       	jmp    80106271 <sys_link+0x180>
  }

  ip->nlink++;
80106189:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010618c:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106190:	8d 50 01             	lea    0x1(%eax),%edx
80106193:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106196:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
8010619a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010619d:	89 04 24             	mov    %eax,(%esp)
801061a0:	e8 29 b5 ff ff       	call   801016ce <iupdate>
  iunlock(ip);
801061a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061a8:	89 04 24             	mov    %eax,(%esp)
801061ab:	e8 28 b8 ff ff       	call   801019d8 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
801061b0:	8b 45 dc             	mov    -0x24(%ebp),%eax
801061b3:	8d 55 e2             	lea    -0x1e(%ebp),%edx
801061b6:	89 54 24 04          	mov    %edx,0x4(%esp)
801061ba:	89 04 24             	mov    %eax,(%esp)
801061bd:	e8 b0 c3 ff ff       	call   80102572 <nameiparent>
801061c2:	89 45 f0             	mov    %eax,-0x10(%ebp)
801061c5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801061c9:	75 02                	jne    801061cd <sys_link+0xdc>
    goto bad;
801061cb:	eb 68                	jmp    80106235 <sys_link+0x144>
  ilock(dp);
801061cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061d0:	89 04 24             	mov    %eax,(%esp)
801061d3:	e8 b2 b6 ff ff       	call   8010188a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801061d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061db:	8b 10                	mov    (%eax),%edx
801061dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061e0:	8b 00                	mov    (%eax),%eax
801061e2:	39 c2                	cmp    %eax,%edx
801061e4:	75 20                	jne    80106206 <sys_link+0x115>
801061e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061e9:	8b 40 04             	mov    0x4(%eax),%eax
801061ec:	89 44 24 08          	mov    %eax,0x8(%esp)
801061f0:	8d 45 e2             	lea    -0x1e(%ebp),%eax
801061f3:	89 44 24 04          	mov    %eax,0x4(%esp)
801061f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061fa:	89 04 24             	mov    %eax,(%esp)
801061fd:	e8 4d c0 ff ff       	call   8010224f <dirlink>
80106202:	85 c0                	test   %eax,%eax
80106204:	79 0d                	jns    80106213 <sys_link+0x122>
    iunlockput(dp);
80106206:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106209:	89 04 24             	mov    %eax,(%esp)
8010620c:	e8 fd b8 ff ff       	call   80101b0e <iunlockput>
    goto bad;
80106211:	eb 22                	jmp    80106235 <sys_link+0x144>
  }
  iunlockput(dp);
80106213:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106216:	89 04 24             	mov    %eax,(%esp)
80106219:	e8 f0 b8 ff ff       	call   80101b0e <iunlockput>
  iput(ip);
8010621e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106221:	89 04 24             	mov    %eax,(%esp)
80106224:	e8 14 b8 ff ff       	call   80101a3d <iput>

  end_op();
80106229:	e8 b0 d3 ff ff       	call   801035de <end_op>

  return 0;
8010622e:	b8 00 00 00 00       	mov    $0x0,%eax
80106233:	eb 3c                	jmp    80106271 <sys_link+0x180>

bad:
  ilock(ip);
80106235:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106238:	89 04 24             	mov    %eax,(%esp)
8010623b:	e8 4a b6 ff ff       	call   8010188a <ilock>
  ip->nlink--;
80106240:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106243:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106247:	8d 50 ff             	lea    -0x1(%eax),%edx
8010624a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010624d:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106251:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106254:	89 04 24             	mov    %eax,(%esp)
80106257:	e8 72 b4 ff ff       	call   801016ce <iupdate>
  iunlockput(ip);
8010625c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010625f:	89 04 24             	mov    %eax,(%esp)
80106262:	e8 a7 b8 ff ff       	call   80101b0e <iunlockput>
  end_op();
80106267:	e8 72 d3 ff ff       	call   801035de <end_op>
  return -1;
8010626c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106271:	c9                   	leave  
80106272:	c3                   	ret    

80106273 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80106273:	55                   	push   %ebp
80106274:	89 e5                	mov    %esp,%ebp
80106276:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106279:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80106280:	eb 4b                	jmp    801062cd <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106282:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106285:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010628c:	00 
8010628d:	89 44 24 08          	mov    %eax,0x8(%esp)
80106291:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106294:	89 44 24 04          	mov    %eax,0x4(%esp)
80106298:	8b 45 08             	mov    0x8(%ebp),%eax
8010629b:	89 04 24             	mov    %eax,(%esp)
8010629e:	e8 f4 ba ff ff       	call   80101d97 <readi>
801062a3:	83 f8 10             	cmp    $0x10,%eax
801062a6:	74 0c                	je     801062b4 <isdirempty+0x41>
      panic("isdirempty: readi");
801062a8:	c7 04 24 9a 91 10 80 	movl   $0x8010919a,(%esp)
801062af:	e8 86 a2 ff ff       	call   8010053a <panic>
    if(de.inum != 0)
801062b4:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
801062b8:	66 85 c0             	test   %ax,%ax
801062bb:	74 07                	je     801062c4 <isdirempty+0x51>
      return 0;
801062bd:	b8 00 00 00 00       	mov    $0x0,%eax
801062c2:	eb 1b                	jmp    801062df <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801062c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062c7:	83 c0 10             	add    $0x10,%eax
801062ca:	89 45 f4             	mov    %eax,-0xc(%ebp)
801062cd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801062d0:	8b 45 08             	mov    0x8(%ebp),%eax
801062d3:	8b 40 18             	mov    0x18(%eax),%eax
801062d6:	39 c2                	cmp    %eax,%edx
801062d8:	72 a8                	jb     80106282 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
801062da:	b8 01 00 00 00       	mov    $0x1,%eax
}
801062df:	c9                   	leave  
801062e0:	c3                   	ret    

801062e1 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
801062e1:	55                   	push   %ebp
801062e2:	89 e5                	mov    %esp,%ebp
801062e4:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
801062e7:	8d 45 cc             	lea    -0x34(%ebp),%eax
801062ea:	89 44 24 04          	mov    %eax,0x4(%esp)
801062ee:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801062f5:	e8 71 fa ff ff       	call   80105d6b <argstr>
801062fa:	85 c0                	test   %eax,%eax
801062fc:	79 0a                	jns    80106308 <sys_unlink+0x27>
    return -1;
801062fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106303:	e9 af 01 00 00       	jmp    801064b7 <sys_unlink+0x1d6>

  begin_op();
80106308:	e8 4d d2 ff ff       	call   8010355a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
8010630d:	8b 45 cc             	mov    -0x34(%ebp),%eax
80106310:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80106313:	89 54 24 04          	mov    %edx,0x4(%esp)
80106317:	89 04 24             	mov    %eax,(%esp)
8010631a:	e8 53 c2 ff ff       	call   80102572 <nameiparent>
8010631f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106322:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106326:	75 0f                	jne    80106337 <sys_unlink+0x56>
    end_op();
80106328:	e8 b1 d2 ff ff       	call   801035de <end_op>
    return -1;
8010632d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106332:	e9 80 01 00 00       	jmp    801064b7 <sys_unlink+0x1d6>
  }

  ilock(dp);
80106337:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010633a:	89 04 24             	mov    %eax,(%esp)
8010633d:	e8 48 b5 ff ff       	call   8010188a <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80106342:	c7 44 24 04 ac 91 10 	movl   $0x801091ac,0x4(%esp)
80106349:	80 
8010634a:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010634d:	89 04 24             	mov    %eax,(%esp)
80106350:	e8 48 bd ff ff       	call   8010209d <namecmp>
80106355:	85 c0                	test   %eax,%eax
80106357:	0f 84 45 01 00 00    	je     801064a2 <sys_unlink+0x1c1>
8010635d:	c7 44 24 04 ae 91 10 	movl   $0x801091ae,0x4(%esp)
80106364:	80 
80106365:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106368:	89 04 24             	mov    %eax,(%esp)
8010636b:	e8 2d bd ff ff       	call   8010209d <namecmp>
80106370:	85 c0                	test   %eax,%eax
80106372:	0f 84 2a 01 00 00    	je     801064a2 <sys_unlink+0x1c1>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80106378:	8d 45 c8             	lea    -0x38(%ebp),%eax
8010637b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010637f:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106382:	89 44 24 04          	mov    %eax,0x4(%esp)
80106386:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106389:	89 04 24             	mov    %eax,(%esp)
8010638c:	e8 2e bd ff ff       	call   801020bf <dirlookup>
80106391:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106394:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106398:	75 05                	jne    8010639f <sys_unlink+0xbe>
    goto bad;
8010639a:	e9 03 01 00 00       	jmp    801064a2 <sys_unlink+0x1c1>
  ilock(ip);
8010639f:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063a2:	89 04 24             	mov    %eax,(%esp)
801063a5:	e8 e0 b4 ff ff       	call   8010188a <ilock>

  if(ip->nlink < 1)
801063aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063ad:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801063b1:	66 85 c0             	test   %ax,%ax
801063b4:	7f 0c                	jg     801063c2 <sys_unlink+0xe1>
    panic("unlink: nlink < 1");
801063b6:	c7 04 24 b1 91 10 80 	movl   $0x801091b1,(%esp)
801063bd:	e8 78 a1 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
801063c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063c5:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801063c9:	66 83 f8 01          	cmp    $0x1,%ax
801063cd:	75 1f                	jne    801063ee <sys_unlink+0x10d>
801063cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063d2:	89 04 24             	mov    %eax,(%esp)
801063d5:	e8 99 fe ff ff       	call   80106273 <isdirempty>
801063da:	85 c0                	test   %eax,%eax
801063dc:	75 10                	jne    801063ee <sys_unlink+0x10d>
    iunlockput(ip);
801063de:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063e1:	89 04 24             	mov    %eax,(%esp)
801063e4:	e8 25 b7 ff ff       	call   80101b0e <iunlockput>
    goto bad;
801063e9:	e9 b4 00 00 00       	jmp    801064a2 <sys_unlink+0x1c1>
  }

  memset(&de, 0, sizeof(de));
801063ee:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801063f5:	00 
801063f6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801063fd:	00 
801063fe:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106401:	89 04 24             	mov    %eax,(%esp)
80106404:	e8 90 f5 ff ff       	call   80105999 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106409:	8b 45 c8             	mov    -0x38(%ebp),%eax
8010640c:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106413:	00 
80106414:	89 44 24 08          	mov    %eax,0x8(%esp)
80106418:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010641b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010641f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106422:	89 04 24             	mov    %eax,(%esp)
80106425:	e8 de ba ff ff       	call   80101f08 <writei>
8010642a:	83 f8 10             	cmp    $0x10,%eax
8010642d:	74 0c                	je     8010643b <sys_unlink+0x15a>
    panic("unlink: writei");
8010642f:	c7 04 24 c3 91 10 80 	movl   $0x801091c3,(%esp)
80106436:	e8 ff a0 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR){
8010643b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010643e:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106442:	66 83 f8 01          	cmp    $0x1,%ax
80106446:	75 1c                	jne    80106464 <sys_unlink+0x183>
    dp->nlink--;
80106448:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010644b:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010644f:	8d 50 ff             	lea    -0x1(%eax),%edx
80106452:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106455:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106459:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010645c:	89 04 24             	mov    %eax,(%esp)
8010645f:	e8 6a b2 ff ff       	call   801016ce <iupdate>
  }
  iunlockput(dp);
80106464:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106467:	89 04 24             	mov    %eax,(%esp)
8010646a:	e8 9f b6 ff ff       	call   80101b0e <iunlockput>

  ip->nlink--;
8010646f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106472:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106476:	8d 50 ff             	lea    -0x1(%eax),%edx
80106479:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010647c:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106480:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106483:	89 04 24             	mov    %eax,(%esp)
80106486:	e8 43 b2 ff ff       	call   801016ce <iupdate>
  iunlockput(ip);
8010648b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010648e:	89 04 24             	mov    %eax,(%esp)
80106491:	e8 78 b6 ff ff       	call   80101b0e <iunlockput>

  end_op();
80106496:	e8 43 d1 ff ff       	call   801035de <end_op>

  return 0;
8010649b:	b8 00 00 00 00       	mov    $0x0,%eax
801064a0:	eb 15                	jmp    801064b7 <sys_unlink+0x1d6>

bad:
  iunlockput(dp);
801064a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064a5:	89 04 24             	mov    %eax,(%esp)
801064a8:	e8 61 b6 ff ff       	call   80101b0e <iunlockput>
  end_op();
801064ad:	e8 2c d1 ff ff       	call   801035de <end_op>
  return -1;
801064b2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801064b7:	c9                   	leave  
801064b8:	c3                   	ret    

801064b9 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
801064b9:	55                   	push   %ebp
801064ba:	89 e5                	mov    %esp,%ebp
801064bc:	83 ec 48             	sub    $0x48,%esp
801064bf:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801064c2:	8b 55 10             	mov    0x10(%ebp),%edx
801064c5:	8b 45 14             	mov    0x14(%ebp),%eax
801064c8:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
801064cc:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
801064d0:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
801064d4:	8d 45 de             	lea    -0x22(%ebp),%eax
801064d7:	89 44 24 04          	mov    %eax,0x4(%esp)
801064db:	8b 45 08             	mov    0x8(%ebp),%eax
801064de:	89 04 24             	mov    %eax,(%esp)
801064e1:	e8 8c c0 ff ff       	call   80102572 <nameiparent>
801064e6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801064e9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801064ed:	75 0a                	jne    801064f9 <create+0x40>
    return 0;
801064ef:	b8 00 00 00 00       	mov    $0x0,%eax
801064f4:	e9 a0 01 00 00       	jmp    80106699 <create+0x1e0>
  ilock(dp);
801064f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064fc:	89 04 24             	mov    %eax,(%esp)
801064ff:	e8 86 b3 ff ff       	call   8010188a <ilock>

  if (dp->type == T_DEV) {
80106504:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106507:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010650b:	66 83 f8 03          	cmp    $0x3,%ax
8010650f:	75 15                	jne    80106526 <create+0x6d>
    iunlockput(dp);
80106511:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106514:	89 04 24             	mov    %eax,(%esp)
80106517:	e8 f2 b5 ff ff       	call   80101b0e <iunlockput>
    return 0;
8010651c:	b8 00 00 00 00       	mov    $0x0,%eax
80106521:	e9 73 01 00 00       	jmp    80106699 <create+0x1e0>
  }

  if((ip = dirlookup(dp, name, &off)) != 0){
80106526:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106529:	89 44 24 08          	mov    %eax,0x8(%esp)
8010652d:	8d 45 de             	lea    -0x22(%ebp),%eax
80106530:	89 44 24 04          	mov    %eax,0x4(%esp)
80106534:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106537:	89 04 24             	mov    %eax,(%esp)
8010653a:	e8 80 bb ff ff       	call   801020bf <dirlookup>
8010653f:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106542:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106546:	74 47                	je     8010658f <create+0xd6>
    iunlockput(dp);
80106548:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010654b:	89 04 24             	mov    %eax,(%esp)
8010654e:	e8 bb b5 ff ff       	call   80101b0e <iunlockput>
    ilock(ip);
80106553:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106556:	89 04 24             	mov    %eax,(%esp)
80106559:	e8 2c b3 ff ff       	call   8010188a <ilock>
    if(type == T_FILE && ip->type == T_FILE)
8010655e:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80106563:	75 15                	jne    8010657a <create+0xc1>
80106565:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106568:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010656c:	66 83 f8 02          	cmp    $0x2,%ax
80106570:	75 08                	jne    8010657a <create+0xc1>
      return ip;
80106572:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106575:	e9 1f 01 00 00       	jmp    80106699 <create+0x1e0>
    iunlockput(ip);
8010657a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010657d:	89 04 24             	mov    %eax,(%esp)
80106580:	e8 89 b5 ff ff       	call   80101b0e <iunlockput>
    return 0;
80106585:	b8 00 00 00 00       	mov    $0x0,%eax
8010658a:	e9 0a 01 00 00       	jmp    80106699 <create+0x1e0>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
8010658f:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80106593:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106596:	8b 00                	mov    (%eax),%eax
80106598:	89 54 24 04          	mov    %edx,0x4(%esp)
8010659c:	89 04 24             	mov    %eax,(%esp)
8010659f:	e8 4b b0 ff ff       	call   801015ef <ialloc>
801065a4:	89 45 f0             	mov    %eax,-0x10(%ebp)
801065a7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801065ab:	75 0c                	jne    801065b9 <create+0x100>
    panic("create: ialloc");
801065ad:	c7 04 24 d2 91 10 80 	movl   $0x801091d2,(%esp)
801065b4:	e8 81 9f ff ff       	call   8010053a <panic>

  ilock(ip);
801065b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065bc:	89 04 24             	mov    %eax,(%esp)
801065bf:	e8 c6 b2 ff ff       	call   8010188a <ilock>
  ip->major = major;
801065c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065c7:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
801065cb:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
801065cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065d2:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
801065d6:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
801065da:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065dd:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
801065e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065e6:	89 04 24             	mov    %eax,(%esp)
801065e9:	e8 e0 b0 ff ff       	call   801016ce <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
801065ee:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
801065f3:	75 6a                	jne    8010665f <create+0x1a6>
    dp->nlink++;  // for ".."
801065f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065f8:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801065fc:	8d 50 01             	lea    0x1(%eax),%edx
801065ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106602:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106606:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106609:	89 04 24             	mov    %eax,(%esp)
8010660c:	e8 bd b0 ff ff       	call   801016ce <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80106611:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106614:	8b 40 04             	mov    0x4(%eax),%eax
80106617:	89 44 24 08          	mov    %eax,0x8(%esp)
8010661b:	c7 44 24 04 ac 91 10 	movl   $0x801091ac,0x4(%esp)
80106622:	80 
80106623:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106626:	89 04 24             	mov    %eax,(%esp)
80106629:	e8 21 bc ff ff       	call   8010224f <dirlink>
8010662e:	85 c0                	test   %eax,%eax
80106630:	78 21                	js     80106653 <create+0x19a>
80106632:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106635:	8b 40 04             	mov    0x4(%eax),%eax
80106638:	89 44 24 08          	mov    %eax,0x8(%esp)
8010663c:	c7 44 24 04 ae 91 10 	movl   $0x801091ae,0x4(%esp)
80106643:	80 
80106644:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106647:	89 04 24             	mov    %eax,(%esp)
8010664a:	e8 00 bc ff ff       	call   8010224f <dirlink>
8010664f:	85 c0                	test   %eax,%eax
80106651:	79 0c                	jns    8010665f <create+0x1a6>
      panic("create dots");
80106653:	c7 04 24 e1 91 10 80 	movl   $0x801091e1,(%esp)
8010665a:	e8 db 9e ff ff       	call   8010053a <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
8010665f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106662:	8b 40 04             	mov    0x4(%eax),%eax
80106665:	89 44 24 08          	mov    %eax,0x8(%esp)
80106669:	8d 45 de             	lea    -0x22(%ebp),%eax
8010666c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106670:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106673:	89 04 24             	mov    %eax,(%esp)
80106676:	e8 d4 bb ff ff       	call   8010224f <dirlink>
8010667b:	85 c0                	test   %eax,%eax
8010667d:	79 0c                	jns    8010668b <create+0x1d2>
    panic("create: dirlink");
8010667f:	c7 04 24 ed 91 10 80 	movl   $0x801091ed,(%esp)
80106686:	e8 af 9e ff ff       	call   8010053a <panic>

  iunlockput(dp);
8010668b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010668e:	89 04 24             	mov    %eax,(%esp)
80106691:	e8 78 b4 ff ff       	call   80101b0e <iunlockput>

  return ip;
80106696:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106699:	c9                   	leave  
8010669a:	c3                   	ret    

8010669b <sys_open>:

int
sys_open(void)
{
8010669b:	55                   	push   %ebp
8010669c:	89 e5                	mov    %esp,%ebp
8010669e:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
801066a1:	8d 45 e8             	lea    -0x18(%ebp),%eax
801066a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801066a8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801066af:	e8 b7 f6 ff ff       	call   80105d6b <argstr>
801066b4:	85 c0                	test   %eax,%eax
801066b6:	78 17                	js     801066cf <sys_open+0x34>
801066b8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801066bb:	89 44 24 04          	mov    %eax,0x4(%esp)
801066bf:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801066c6:	e8 10 f6 ff ff       	call   80105cdb <argint>
801066cb:	85 c0                	test   %eax,%eax
801066cd:	79 0a                	jns    801066d9 <sys_open+0x3e>
    return -1;
801066cf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801066d4:	e9 5c 01 00 00       	jmp    80106835 <sys_open+0x19a>

  begin_op();
801066d9:	e8 7c ce ff ff       	call   8010355a <begin_op>

  if(omode & O_CREATE){
801066de:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801066e1:	25 00 02 00 00       	and    $0x200,%eax
801066e6:	85 c0                	test   %eax,%eax
801066e8:	74 3b                	je     80106725 <sys_open+0x8a>
    ip = create(path, T_FILE, 0, 0);
801066ea:	8b 45 e8             	mov    -0x18(%ebp),%eax
801066ed:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801066f4:	00 
801066f5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801066fc:	00 
801066fd:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106704:	00 
80106705:	89 04 24             	mov    %eax,(%esp)
80106708:	e8 ac fd ff ff       	call   801064b9 <create>
8010670d:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
80106710:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106714:	75 6b                	jne    80106781 <sys_open+0xe6>
      end_op();
80106716:	e8 c3 ce ff ff       	call   801035de <end_op>
      return -1;
8010671b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106720:	e9 10 01 00 00       	jmp    80106835 <sys_open+0x19a>
    }
  } else {
    if((ip = namei(path)) == 0){
80106725:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106728:	89 04 24             	mov    %eax,(%esp)
8010672b:	e8 20 be ff ff       	call   80102550 <namei>
80106730:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106733:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106737:	75 0f                	jne    80106748 <sys_open+0xad>
      end_op();
80106739:	e8 a0 ce ff ff       	call   801035de <end_op>
      return -1;
8010673e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106743:	e9 ed 00 00 00       	jmp    80106835 <sys_open+0x19a>
    }
    ilock(ip);
80106748:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010674b:	89 04 24             	mov    %eax,(%esp)
8010674e:	e8 37 b1 ff ff       	call   8010188a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106753:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106756:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010675a:	66 83 f8 01          	cmp    $0x1,%ax
8010675e:	75 21                	jne    80106781 <sys_open+0xe6>
80106760:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106763:	85 c0                	test   %eax,%eax
80106765:	74 1a                	je     80106781 <sys_open+0xe6>
      iunlockput(ip);
80106767:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010676a:	89 04 24             	mov    %eax,(%esp)
8010676d:	e8 9c b3 ff ff       	call   80101b0e <iunlockput>
      end_op();
80106772:	e8 67 ce ff ff       	call   801035de <end_op>
      return -1;
80106777:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010677c:	e9 b4 00 00 00       	jmp    80106835 <sys_open+0x19a>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106781:	e8 cf a7 ff ff       	call   80100f55 <filealloc>
80106786:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106789:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010678d:	74 14                	je     801067a3 <sys_open+0x108>
8010678f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106792:	89 04 24             	mov    %eax,(%esp)
80106795:	e8 0c f7 ff ff       	call   80105ea6 <fdalloc>
8010679a:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010679d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801067a1:	79 28                	jns    801067cb <sys_open+0x130>
    if(f)
801067a3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801067a7:	74 0b                	je     801067b4 <sys_open+0x119>
      fileclose(f);
801067a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067ac:	89 04 24             	mov    %eax,(%esp)
801067af:	e8 49 a8 ff ff       	call   80100ffd <fileclose>
    iunlockput(ip);
801067b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067b7:	89 04 24             	mov    %eax,(%esp)
801067ba:	e8 4f b3 ff ff       	call   80101b0e <iunlockput>
    end_op();
801067bf:	e8 1a ce ff ff       	call   801035de <end_op>
    return -1;
801067c4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067c9:	eb 6a                	jmp    80106835 <sys_open+0x19a>
  }
  iunlock(ip);
801067cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067ce:	89 04 24             	mov    %eax,(%esp)
801067d1:	e8 02 b2 ff ff       	call   801019d8 <iunlock>
  end_op();
801067d6:	e8 03 ce ff ff       	call   801035de <end_op>

  f->type = FD_INODE;
801067db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067de:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
801067e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067e7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801067ea:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
801067ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067f0:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
801067f7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801067fa:	83 e0 01             	and    $0x1,%eax
801067fd:	85 c0                	test   %eax,%eax
801067ff:	0f 94 c0             	sete   %al
80106802:	89 c2                	mov    %eax,%edx
80106804:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106807:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
8010680a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010680d:	83 e0 01             	and    $0x1,%eax
80106810:	85 c0                	test   %eax,%eax
80106812:	75 0a                	jne    8010681e <sys_open+0x183>
80106814:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106817:	83 e0 02             	and    $0x2,%eax
8010681a:	85 c0                	test   %eax,%eax
8010681c:	74 07                	je     80106825 <sys_open+0x18a>
8010681e:	b8 01 00 00 00       	mov    $0x1,%eax
80106823:	eb 05                	jmp    8010682a <sys_open+0x18f>
80106825:	b8 00 00 00 00       	mov    $0x0,%eax
8010682a:	89 c2                	mov    %eax,%edx
8010682c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010682f:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80106832:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80106835:	c9                   	leave  
80106836:	c3                   	ret    

80106837 <sys_mkdir>:

int
sys_mkdir(void)
{
80106837:	55                   	push   %ebp
80106838:	89 e5                	mov    %esp,%ebp
8010683a:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
8010683d:	e8 18 cd ff ff       	call   8010355a <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80106842:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106845:	89 44 24 04          	mov    %eax,0x4(%esp)
80106849:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106850:	e8 16 f5 ff ff       	call   80105d6b <argstr>
80106855:	85 c0                	test   %eax,%eax
80106857:	78 2c                	js     80106885 <sys_mkdir+0x4e>
80106859:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010685c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106863:	00 
80106864:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010686b:	00 
8010686c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106873:	00 
80106874:	89 04 24             	mov    %eax,(%esp)
80106877:	e8 3d fc ff ff       	call   801064b9 <create>
8010687c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010687f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106883:	75 0c                	jne    80106891 <sys_mkdir+0x5a>
    end_op();
80106885:	e8 54 cd ff ff       	call   801035de <end_op>
    return -1;
8010688a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010688f:	eb 15                	jmp    801068a6 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80106891:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106894:	89 04 24             	mov    %eax,(%esp)
80106897:	e8 72 b2 ff ff       	call   80101b0e <iunlockput>
  end_op();
8010689c:	e8 3d cd ff ff       	call   801035de <end_op>
  return 0;
801068a1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801068a6:	c9                   	leave  
801068a7:	c3                   	ret    

801068a8 <sys_mknod>:

int
sys_mknod(void)
{
801068a8:	55                   	push   %ebp
801068a9:	89 e5                	mov    %esp,%ebp
801068ab:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_op();
801068ae:	e8 a7 cc ff ff       	call   8010355a <begin_op>
  if((len=argstr(0, &path)) < 0 ||
801068b3:	8d 45 ec             	lea    -0x14(%ebp),%eax
801068b6:	89 44 24 04          	mov    %eax,0x4(%esp)
801068ba:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801068c1:	e8 a5 f4 ff ff       	call   80105d6b <argstr>
801068c6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801068c9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801068cd:	78 5e                	js     8010692d <sys_mknod+0x85>
     argint(1, &major) < 0 ||
801068cf:	8d 45 e8             	lea    -0x18(%ebp),%eax
801068d2:	89 44 24 04          	mov    %eax,0x4(%esp)
801068d6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801068dd:	e8 f9 f3 ff ff       	call   80105cdb <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
801068e2:	85 c0                	test   %eax,%eax
801068e4:	78 47                	js     8010692d <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801068e6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801068e9:	89 44 24 04          	mov    %eax,0x4(%esp)
801068ed:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801068f4:	e8 e2 f3 ff ff       	call   80105cdb <argint>
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
801068f9:	85 c0                	test   %eax,%eax
801068fb:	78 30                	js     8010692d <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
801068fd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106900:	0f bf c8             	movswl %ax,%ecx
80106903:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106906:	0f bf d0             	movswl %ax,%edx
80106909:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
8010690c:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106910:	89 54 24 08          	mov    %edx,0x8(%esp)
80106914:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
8010691b:	00 
8010691c:	89 04 24             	mov    %eax,(%esp)
8010691f:	e8 95 fb ff ff       	call   801064b9 <create>
80106924:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106927:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010692b:	75 0c                	jne    80106939 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
8010692d:	e8 ac cc ff ff       	call   801035de <end_op>
    return -1;
80106932:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106937:	eb 15                	jmp    8010694e <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106939:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010693c:	89 04 24             	mov    %eax,(%esp)
8010693f:	e8 ca b1 ff ff       	call   80101b0e <iunlockput>
  end_op();
80106944:	e8 95 cc ff ff       	call   801035de <end_op>
  return 0;
80106949:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010694e:	c9                   	leave  
8010694f:	c3                   	ret    

80106950 <sys_chdir>:

int
sys_chdir(void)
{
80106950:	55                   	push   %ebp
80106951:	89 e5                	mov    %esp,%ebp
80106953:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80106956:	e8 ff cb ff ff       	call   8010355a <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
8010695b:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010695e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106962:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106969:	e8 fd f3 ff ff       	call   80105d6b <argstr>
8010696e:	85 c0                	test   %eax,%eax
80106970:	78 14                	js     80106986 <sys_chdir+0x36>
80106972:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106975:	89 04 24             	mov    %eax,(%esp)
80106978:	e8 d3 bb ff ff       	call   80102550 <namei>
8010697d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106980:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106984:	75 0f                	jne    80106995 <sys_chdir+0x45>
    end_op();
80106986:	e8 53 cc ff ff       	call   801035de <end_op>
    return -1;
8010698b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106990:	e9 a2 00 00 00       	jmp    80106a37 <sys_chdir+0xe7>
  }
  ilock(ip);
80106995:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106998:	89 04 24             	mov    %eax,(%esp)
8010699b:	e8 ea ae ff ff       	call   8010188a <ilock>

  if(ip->type != T_DIR && !IS_DEV_DIR(ip)) {
801069a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069a3:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801069a7:	66 83 f8 01          	cmp    $0x1,%ax
801069ab:	74 58                	je     80106a05 <sys_chdir+0xb5>
801069ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069b0:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801069b4:	66 83 f8 03          	cmp    $0x3,%ax
801069b8:	75 34                	jne    801069ee <sys_chdir+0x9e>
801069ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069bd:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801069c1:	98                   	cwtl   
801069c2:	c1 e0 04             	shl    $0x4,%eax
801069c5:	05 e0 21 11 80       	add    $0x801121e0,%eax
801069ca:	8b 00                	mov    (%eax),%eax
801069cc:	85 c0                	test   %eax,%eax
801069ce:	74 1e                	je     801069ee <sys_chdir+0x9e>
801069d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069d3:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801069d7:	98                   	cwtl   
801069d8:	c1 e0 04             	shl    $0x4,%eax
801069db:	05 e0 21 11 80       	add    $0x801121e0,%eax
801069e0:	8b 00                	mov    (%eax),%eax
801069e2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801069e5:	89 14 24             	mov    %edx,(%esp)
801069e8:	ff d0                	call   *%eax
801069ea:	85 c0                	test   %eax,%eax
801069ec:	75 17                	jne    80106a05 <sys_chdir+0xb5>
    iunlockput(ip);
801069ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069f1:	89 04 24             	mov    %eax,(%esp)
801069f4:	e8 15 b1 ff ff       	call   80101b0e <iunlockput>
    end_op();
801069f9:	e8 e0 cb ff ff       	call   801035de <end_op>
    return -1;
801069fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a03:	eb 32                	jmp    80106a37 <sys_chdir+0xe7>
  }
  
  iunlock(ip);
80106a05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a08:	89 04 24             	mov    %eax,(%esp)
80106a0b:	e8 c8 af ff ff       	call   801019d8 <iunlock>
  iput(proc->cwd);
80106a10:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a16:	8b 40 78             	mov    0x78(%eax),%eax
80106a19:	89 04 24             	mov    %eax,(%esp)
80106a1c:	e8 1c b0 ff ff       	call   80101a3d <iput>
  end_op();
80106a21:	e8 b8 cb ff ff       	call   801035de <end_op>
  proc->cwd = ip;
80106a26:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a2c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106a2f:	89 50 78             	mov    %edx,0x78(%eax)
  return 0;
80106a32:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106a37:	c9                   	leave  
80106a38:	c3                   	ret    

80106a39 <sys_exec>:

int
sys_exec(void)
{
80106a39:	55                   	push   %ebp
80106a3a:	89 e5                	mov    %esp,%ebp
80106a3c:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106a42:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106a45:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a49:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106a50:	e8 16 f3 ff ff       	call   80105d6b <argstr>
80106a55:	85 c0                	test   %eax,%eax
80106a57:	78 1a                	js     80106a73 <sys_exec+0x3a>
80106a59:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80106a5f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a63:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106a6a:	e8 6c f2 ff ff       	call   80105cdb <argint>
80106a6f:	85 c0                	test   %eax,%eax
80106a71:	79 0a                	jns    80106a7d <sys_exec+0x44>
    return -1;
80106a73:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a78:	e9 c8 00 00 00       	jmp    80106b45 <sys_exec+0x10c>
  }
  memset(argv, 0, sizeof(argv));
80106a7d:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106a84:	00 
80106a85:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106a8c:	00 
80106a8d:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106a93:	89 04 24             	mov    %eax,(%esp)
80106a96:	e8 fe ee ff ff       	call   80105999 <memset>
  for(i=0;; i++){
80106a9b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106aa2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106aa5:	83 f8 1f             	cmp    $0x1f,%eax
80106aa8:	76 0a                	jbe    80106ab4 <sys_exec+0x7b>
      return -1;
80106aaa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106aaf:	e9 91 00 00 00       	jmp    80106b45 <sys_exec+0x10c>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80106ab4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ab7:	c1 e0 02             	shl    $0x2,%eax
80106aba:	89 c2                	mov    %eax,%edx
80106abc:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106ac2:	01 c2                	add    %eax,%edx
80106ac4:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
80106aca:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ace:	89 14 24             	mov    %edx,(%esp)
80106ad1:	e8 69 f1 ff ff       	call   80105c3f <fetchint>
80106ad6:	85 c0                	test   %eax,%eax
80106ad8:	79 07                	jns    80106ae1 <sys_exec+0xa8>
      return -1;
80106ada:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106adf:	eb 64                	jmp    80106b45 <sys_exec+0x10c>
    if(uarg == 0){
80106ae1:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106ae7:	85 c0                	test   %eax,%eax
80106ae9:	75 26                	jne    80106b11 <sys_exec+0xd8>
      argv[i] = 0;
80106aeb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106aee:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106af5:	00 00 00 00 
      break;
80106af9:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106afa:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106afd:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80106b03:	89 54 24 04          	mov    %edx,0x4(%esp)
80106b07:	89 04 24             	mov    %eax,(%esp)
80106b0a:	e8 e0 9f ff ff       	call   80100aef <exec>
80106b0f:	eb 34                	jmp    80106b45 <sys_exec+0x10c>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80106b11:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106b17:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106b1a:	c1 e2 02             	shl    $0x2,%edx
80106b1d:	01 c2                	add    %eax,%edx
80106b1f:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106b25:	89 54 24 04          	mov    %edx,0x4(%esp)
80106b29:	89 04 24             	mov    %eax,(%esp)
80106b2c:	e8 48 f1 ff ff       	call   80105c79 <fetchstr>
80106b31:	85 c0                	test   %eax,%eax
80106b33:	79 07                	jns    80106b3c <sys_exec+0x103>
      return -1;
80106b35:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b3a:	eb 09                	jmp    80106b45 <sys_exec+0x10c>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106b3c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
80106b40:	e9 5d ff ff ff       	jmp    80106aa2 <sys_exec+0x69>
  return exec(path, argv);
}
80106b45:	c9                   	leave  
80106b46:	c3                   	ret    

80106b47 <sys_pipe>:

int
sys_pipe(void)
{
80106b47:	55                   	push   %ebp
80106b48:	89 e5                	mov    %esp,%ebp
80106b4a:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106b4d:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106b54:	00 
80106b55:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106b58:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b5c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106b63:	e8 a1 f1 ff ff       	call   80105d09 <argptr>
80106b68:	85 c0                	test   %eax,%eax
80106b6a:	79 0a                	jns    80106b76 <sys_pipe+0x2f>
    return -1;
80106b6c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b71:	e9 9b 00 00 00       	jmp    80106c11 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106b76:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106b79:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b7d:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106b80:	89 04 24             	mov    %eax,(%esp)
80106b83:	e8 e8 d4 ff ff       	call   80104070 <pipealloc>
80106b88:	85 c0                	test   %eax,%eax
80106b8a:	79 07                	jns    80106b93 <sys_pipe+0x4c>
    return -1;
80106b8c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b91:	eb 7e                	jmp    80106c11 <sys_pipe+0xca>
  fd0 = -1;
80106b93:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106b9a:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106b9d:	89 04 24             	mov    %eax,(%esp)
80106ba0:	e8 01 f3 ff ff       	call   80105ea6 <fdalloc>
80106ba5:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106ba8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106bac:	78 14                	js     80106bc2 <sys_pipe+0x7b>
80106bae:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106bb1:	89 04 24             	mov    %eax,(%esp)
80106bb4:	e8 ed f2 ff ff       	call   80105ea6 <fdalloc>
80106bb9:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106bbc:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106bc0:	79 37                	jns    80106bf9 <sys_pipe+0xb2>
    if(fd0 >= 0)
80106bc2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106bc6:	78 14                	js     80106bdc <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106bc8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106bce:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106bd1:	83 c2 0c             	add    $0xc,%edx
80106bd4:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106bdb:	00 
    fileclose(rf);
80106bdc:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106bdf:	89 04 24             	mov    %eax,(%esp)
80106be2:	e8 16 a4 ff ff       	call   80100ffd <fileclose>
    fileclose(wf);
80106be7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106bea:	89 04 24             	mov    %eax,(%esp)
80106bed:	e8 0b a4 ff ff       	call   80100ffd <fileclose>
    return -1;
80106bf2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106bf7:	eb 18                	jmp    80106c11 <sys_pipe+0xca>
  }
  fd[0] = fd0;
80106bf9:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106bfc:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106bff:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80106c01:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106c04:	8d 50 04             	lea    0x4(%eax),%edx
80106c07:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c0a:	89 02                	mov    %eax,(%edx)
  return 0;
80106c0c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106c11:	c9                   	leave  
80106c12:	c3                   	ret    

80106c13 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80106c13:	55                   	push   %ebp
80106c14:	89 e5                	mov    %esp,%ebp
80106c16:	83 ec 08             	sub    $0x8,%esp
  return fork();
80106c19:	e8 0a db ff ff       	call   80104728 <fork>
}
80106c1e:	c9                   	leave  
80106c1f:	c3                   	ret    

80106c20 <sys_exit>:

int
sys_exit(void)
{
80106c20:	55                   	push   %ebp
80106c21:	89 e5                	mov    %esp,%ebp
80106c23:	83 ec 08             	sub    $0x8,%esp
  exit();
80106c26:	e8 b7 dc ff ff       	call   801048e2 <exit>
  return 0;  // not reached
80106c2b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106c30:	c9                   	leave  
80106c31:	c3                   	ret    

80106c32 <sys_wait>:

int
sys_wait(void)
{
80106c32:	55                   	push   %ebp
80106c33:	89 e5                	mov    %esp,%ebp
80106c35:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106c38:	e8 ca dd ff ff       	call   80104a07 <wait>
}
80106c3d:	c9                   	leave  
80106c3e:	c3                   	ret    

80106c3f <sys_kill>:

int
sys_kill(void)
{
80106c3f:	55                   	push   %ebp
80106c40:	89 e5                	mov    %esp,%ebp
80106c42:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80106c45:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106c48:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c4c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106c53:	e8 83 f0 ff ff       	call   80105cdb <argint>
80106c58:	85 c0                	test   %eax,%eax
80106c5a:	79 07                	jns    80106c63 <sys_kill+0x24>
    return -1;
80106c5c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c61:	eb 0b                	jmp    80106c6e <sys_kill+0x2f>
  return kill(pid);
80106c63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c66:	89 04 24             	mov    %eax,(%esp)
80106c69:	e8 5d e1 ff ff       	call   80104dcb <kill>
}
80106c6e:	c9                   	leave  
80106c6f:	c3                   	ret    

80106c70 <sys_getpid>:

int
sys_getpid(void)
{
80106c70:	55                   	push   %ebp
80106c71:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80106c73:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106c79:	8b 40 10             	mov    0x10(%eax),%eax
}
80106c7c:	5d                   	pop    %ebp
80106c7d:	c3                   	ret    

80106c7e <sys_sbrk>:

int
sys_sbrk(void)
{
80106c7e:	55                   	push   %ebp
80106c7f:	89 e5                	mov    %esp,%ebp
80106c81:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80106c84:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106c87:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c8b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106c92:	e8 44 f0 ff ff       	call   80105cdb <argint>
80106c97:	85 c0                	test   %eax,%eax
80106c99:	79 07                	jns    80106ca2 <sys_sbrk+0x24>
    return -1;
80106c9b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ca0:	eb 24                	jmp    80106cc6 <sys_sbrk+0x48>
  addr = proc->sz;
80106ca2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106ca8:	8b 00                	mov    (%eax),%eax
80106caa:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80106cad:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cb0:	89 04 24             	mov    %eax,(%esp)
80106cb3:	e8 cb d9 ff ff       	call   80104683 <growproc>
80106cb8:	85 c0                	test   %eax,%eax
80106cba:	79 07                	jns    80106cc3 <sys_sbrk+0x45>
    return -1;
80106cbc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106cc1:	eb 03                	jmp    80106cc6 <sys_sbrk+0x48>
  return addr;
80106cc3:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106cc6:	c9                   	leave  
80106cc7:	c3                   	ret    

80106cc8 <sys_sleep>:

int
sys_sleep(void)
{
80106cc8:	55                   	push   %ebp
80106cc9:	89 e5                	mov    %esp,%ebp
80106ccb:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
80106cce:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106cd1:	89 44 24 04          	mov    %eax,0x4(%esp)
80106cd5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106cdc:	e8 fa ef ff ff       	call   80105cdb <argint>
80106ce1:	85 c0                	test   %eax,%eax
80106ce3:	79 07                	jns    80106cec <sys_sleep+0x24>
    return -1;
80106ce5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106cea:	eb 6c                	jmp    80106d58 <sys_sleep+0x90>
  acquire(&tickslock);
80106cec:	c7 04 24 e0 72 11 80 	movl   $0x801172e0,(%esp)
80106cf3:	e8 4d ea ff ff       	call   80105745 <acquire>
  ticks0 = ticks;
80106cf8:	a1 20 7b 11 80       	mov    0x80117b20,%eax
80106cfd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80106d00:	eb 34                	jmp    80106d36 <sys_sleep+0x6e>
    if(proc->killed){
80106d02:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d08:	8b 40 24             	mov    0x24(%eax),%eax
80106d0b:	85 c0                	test   %eax,%eax
80106d0d:	74 13                	je     80106d22 <sys_sleep+0x5a>
      release(&tickslock);
80106d0f:	c7 04 24 e0 72 11 80 	movl   $0x801172e0,(%esp)
80106d16:	e8 8c ea ff ff       	call   801057a7 <release>
      return -1;
80106d1b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d20:	eb 36                	jmp    80106d58 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80106d22:	c7 44 24 04 e0 72 11 	movl   $0x801172e0,0x4(%esp)
80106d29:	80 
80106d2a:	c7 04 24 20 7b 11 80 	movl   $0x80117b20,(%esp)
80106d31:	e8 8e df ff ff       	call   80104cc4 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106d36:	a1 20 7b 11 80       	mov    0x80117b20,%eax
80106d3b:	2b 45 f4             	sub    -0xc(%ebp),%eax
80106d3e:	89 c2                	mov    %eax,%edx
80106d40:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d43:	39 c2                	cmp    %eax,%edx
80106d45:	72 bb                	jb     80106d02 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106d47:	c7 04 24 e0 72 11 80 	movl   $0x801172e0,(%esp)
80106d4e:	e8 54 ea ff ff       	call   801057a7 <release>
  return 0;
80106d53:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106d58:	c9                   	leave  
80106d59:	c3                   	ret    

80106d5a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106d5a:	55                   	push   %ebp
80106d5b:	89 e5                	mov    %esp,%ebp
80106d5d:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80106d60:	c7 04 24 e0 72 11 80 	movl   $0x801172e0,(%esp)
80106d67:	e8 d9 e9 ff ff       	call   80105745 <acquire>
  xticks = ticks;
80106d6c:	a1 20 7b 11 80       	mov    0x80117b20,%eax
80106d71:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106d74:	c7 04 24 e0 72 11 80 	movl   $0x801172e0,(%esp)
80106d7b:	e8 27 ea ff ff       	call   801057a7 <release>
  return xticks;
80106d80:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106d83:	c9                   	leave  
80106d84:	c3                   	ret    

80106d85 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106d85:	55                   	push   %ebp
80106d86:	89 e5                	mov    %esp,%ebp
80106d88:	83 ec 08             	sub    $0x8,%esp
80106d8b:	8b 55 08             	mov    0x8(%ebp),%edx
80106d8e:	8b 45 0c             	mov    0xc(%ebp),%eax
80106d91:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106d95:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106d98:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106d9c:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106da0:	ee                   	out    %al,(%dx)
}
80106da1:	c9                   	leave  
80106da2:	c3                   	ret    

80106da3 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80106da3:	55                   	push   %ebp
80106da4:	89 e5                	mov    %esp,%ebp
80106da6:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80106da9:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80106db0:	00 
80106db1:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80106db8:	e8 c8 ff ff ff       	call   80106d85 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80106dbd:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80106dc4:	00 
80106dc5:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106dcc:	e8 b4 ff ff ff       	call   80106d85 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106dd1:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80106dd8:	00 
80106dd9:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106de0:	e8 a0 ff ff ff       	call   80106d85 <outb>
  picenable(IRQ_TIMER);
80106de5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106dec:	e8 12 d1 ff ff       	call   80103f03 <picenable>
}
80106df1:	c9                   	leave  
80106df2:	c3                   	ret    

80106df3 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106df3:	1e                   	push   %ds
  pushl %es
80106df4:	06                   	push   %es
  pushl %fs
80106df5:	0f a0                	push   %fs
  pushl %gs
80106df7:	0f a8                	push   %gs
  pushal
80106df9:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80106dfa:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80106dfe:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106e00:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80106e02:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80106e06:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80106e08:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80106e0a:	54                   	push   %esp
  call trap
80106e0b:	e8 d8 01 00 00       	call   80106fe8 <trap>
  addl $4, %esp
80106e10:	83 c4 04             	add    $0x4,%esp

80106e13 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106e13:	61                   	popa   
  popl %gs
80106e14:	0f a9                	pop    %gs
  popl %fs
80106e16:	0f a1                	pop    %fs
  popl %es
80106e18:	07                   	pop    %es
  popl %ds
80106e19:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80106e1a:	83 c4 08             	add    $0x8,%esp
  iret
80106e1d:	cf                   	iret   

80106e1e <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80106e1e:	55                   	push   %ebp
80106e1f:	89 e5                	mov    %esp,%ebp
80106e21:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80106e24:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e27:	83 e8 01             	sub    $0x1,%eax
80106e2a:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80106e2e:	8b 45 08             	mov    0x8(%ebp),%eax
80106e31:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80106e35:	8b 45 08             	mov    0x8(%ebp),%eax
80106e38:	c1 e8 10             	shr    $0x10,%eax
80106e3b:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80106e3f:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106e42:	0f 01 18             	lidtl  (%eax)
}
80106e45:	c9                   	leave  
80106e46:	c3                   	ret    

80106e47 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80106e47:	55                   	push   %ebp
80106e48:	89 e5                	mov    %esp,%ebp
80106e4a:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80106e4d:	0f 20 d0             	mov    %cr2,%eax
80106e50:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
80106e53:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106e56:	c9                   	leave  
80106e57:	c3                   	ret    

80106e58 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80106e58:	55                   	push   %ebp
80106e59:	89 e5                	mov    %esp,%ebp
80106e5b:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106e5e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106e65:	e9 c3 00 00 00       	jmp    80106f2d <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80106e6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e6d:	8b 04 85 98 c0 10 80 	mov    -0x7fef3f68(,%eax,4),%eax
80106e74:	89 c2                	mov    %eax,%edx
80106e76:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e79:	66 89 14 c5 20 73 11 	mov    %dx,-0x7fee8ce0(,%eax,8)
80106e80:	80 
80106e81:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e84:	66 c7 04 c5 22 73 11 	movw   $0x8,-0x7fee8cde(,%eax,8)
80106e8b:	80 08 00 
80106e8e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e91:	0f b6 14 c5 24 73 11 	movzbl -0x7fee8cdc(,%eax,8),%edx
80106e98:	80 
80106e99:	83 e2 e0             	and    $0xffffffe0,%edx
80106e9c:	88 14 c5 24 73 11 80 	mov    %dl,-0x7fee8cdc(,%eax,8)
80106ea3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ea6:	0f b6 14 c5 24 73 11 	movzbl -0x7fee8cdc(,%eax,8),%edx
80106ead:	80 
80106eae:	83 e2 1f             	and    $0x1f,%edx
80106eb1:	88 14 c5 24 73 11 80 	mov    %dl,-0x7fee8cdc(,%eax,8)
80106eb8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ebb:	0f b6 14 c5 25 73 11 	movzbl -0x7fee8cdb(,%eax,8),%edx
80106ec2:	80 
80106ec3:	83 e2 f0             	and    $0xfffffff0,%edx
80106ec6:	83 ca 0e             	or     $0xe,%edx
80106ec9:	88 14 c5 25 73 11 80 	mov    %dl,-0x7fee8cdb(,%eax,8)
80106ed0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ed3:	0f b6 14 c5 25 73 11 	movzbl -0x7fee8cdb(,%eax,8),%edx
80106eda:	80 
80106edb:	83 e2 ef             	and    $0xffffffef,%edx
80106ede:	88 14 c5 25 73 11 80 	mov    %dl,-0x7fee8cdb(,%eax,8)
80106ee5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ee8:	0f b6 14 c5 25 73 11 	movzbl -0x7fee8cdb(,%eax,8),%edx
80106eef:	80 
80106ef0:	83 e2 9f             	and    $0xffffff9f,%edx
80106ef3:	88 14 c5 25 73 11 80 	mov    %dl,-0x7fee8cdb(,%eax,8)
80106efa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106efd:	0f b6 14 c5 25 73 11 	movzbl -0x7fee8cdb(,%eax,8),%edx
80106f04:	80 
80106f05:	83 ca 80             	or     $0xffffff80,%edx
80106f08:	88 14 c5 25 73 11 80 	mov    %dl,-0x7fee8cdb(,%eax,8)
80106f0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f12:	8b 04 85 98 c0 10 80 	mov    -0x7fef3f68(,%eax,4),%eax
80106f19:	c1 e8 10             	shr    $0x10,%eax
80106f1c:	89 c2                	mov    %eax,%edx
80106f1e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f21:	66 89 14 c5 26 73 11 	mov    %dx,-0x7fee8cda(,%eax,8)
80106f28:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106f29:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106f2d:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80106f34:	0f 8e 30 ff ff ff    	jle    80106e6a <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106f3a:	a1 98 c1 10 80       	mov    0x8010c198,%eax
80106f3f:	66 a3 20 75 11 80    	mov    %ax,0x80117520
80106f45:	66 c7 05 22 75 11 80 	movw   $0x8,0x80117522
80106f4c:	08 00 
80106f4e:	0f b6 05 24 75 11 80 	movzbl 0x80117524,%eax
80106f55:	83 e0 e0             	and    $0xffffffe0,%eax
80106f58:	a2 24 75 11 80       	mov    %al,0x80117524
80106f5d:	0f b6 05 24 75 11 80 	movzbl 0x80117524,%eax
80106f64:	83 e0 1f             	and    $0x1f,%eax
80106f67:	a2 24 75 11 80       	mov    %al,0x80117524
80106f6c:	0f b6 05 25 75 11 80 	movzbl 0x80117525,%eax
80106f73:	83 c8 0f             	or     $0xf,%eax
80106f76:	a2 25 75 11 80       	mov    %al,0x80117525
80106f7b:	0f b6 05 25 75 11 80 	movzbl 0x80117525,%eax
80106f82:	83 e0 ef             	and    $0xffffffef,%eax
80106f85:	a2 25 75 11 80       	mov    %al,0x80117525
80106f8a:	0f b6 05 25 75 11 80 	movzbl 0x80117525,%eax
80106f91:	83 c8 60             	or     $0x60,%eax
80106f94:	a2 25 75 11 80       	mov    %al,0x80117525
80106f99:	0f b6 05 25 75 11 80 	movzbl 0x80117525,%eax
80106fa0:	83 c8 80             	or     $0xffffff80,%eax
80106fa3:	a2 25 75 11 80       	mov    %al,0x80117525
80106fa8:	a1 98 c1 10 80       	mov    0x8010c198,%eax
80106fad:	c1 e8 10             	shr    $0x10,%eax
80106fb0:	66 a3 26 75 11 80    	mov    %ax,0x80117526
  
  initlock(&tickslock, "time");
80106fb6:	c7 44 24 04 00 92 10 	movl   $0x80109200,0x4(%esp)
80106fbd:	80 
80106fbe:	c7 04 24 e0 72 11 80 	movl   $0x801172e0,(%esp)
80106fc5:	e8 5a e7 ff ff       	call   80105724 <initlock>
}
80106fca:	c9                   	leave  
80106fcb:	c3                   	ret    

80106fcc <idtinit>:

void
idtinit(void)
{
80106fcc:	55                   	push   %ebp
80106fcd:	89 e5                	mov    %esp,%ebp
80106fcf:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80106fd2:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80106fd9:	00 
80106fda:	c7 04 24 20 73 11 80 	movl   $0x80117320,(%esp)
80106fe1:	e8 38 fe ff ff       	call   80106e1e <lidt>
}
80106fe6:	c9                   	leave  
80106fe7:	c3                   	ret    

80106fe8 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80106fe8:	55                   	push   %ebp
80106fe9:	89 e5                	mov    %esp,%ebp
80106feb:	57                   	push   %edi
80106fec:	56                   	push   %esi
80106fed:	53                   	push   %ebx
80106fee:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80106ff1:	8b 45 08             	mov    0x8(%ebp),%eax
80106ff4:	8b 40 30             	mov    0x30(%eax),%eax
80106ff7:	83 f8 40             	cmp    $0x40,%eax
80106ffa:	75 3f                	jne    8010703b <trap+0x53>
    if(proc->killed)
80106ffc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107002:	8b 40 24             	mov    0x24(%eax),%eax
80107005:	85 c0                	test   %eax,%eax
80107007:	74 05                	je     8010700e <trap+0x26>
      exit();
80107009:	e8 d4 d8 ff ff       	call   801048e2 <exit>
    proc->tf = tf;
8010700e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107014:	8b 55 08             	mov    0x8(%ebp),%edx
80107017:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
8010701a:	e8 83 ed ff ff       	call   80105da2 <syscall>
    if(proc->killed)
8010701f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107025:	8b 40 24             	mov    0x24(%eax),%eax
80107028:	85 c0                	test   %eax,%eax
8010702a:	74 0a                	je     80107036 <trap+0x4e>
      exit();
8010702c:	e8 b1 d8 ff ff       	call   801048e2 <exit>
    return;
80107031:	e9 2d 02 00 00       	jmp    80107263 <trap+0x27b>
80107036:	e9 28 02 00 00       	jmp    80107263 <trap+0x27b>
  }

  switch(tf->trapno){
8010703b:	8b 45 08             	mov    0x8(%ebp),%eax
8010703e:	8b 40 30             	mov    0x30(%eax),%eax
80107041:	83 e8 20             	sub    $0x20,%eax
80107044:	83 f8 1f             	cmp    $0x1f,%eax
80107047:	0f 87 bc 00 00 00    	ja     80107109 <trap+0x121>
8010704d:	8b 04 85 a8 92 10 80 	mov    -0x7fef6d58(,%eax,4),%eax
80107054:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
80107056:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010705c:	0f b6 00             	movzbl (%eax),%eax
8010705f:	84 c0                	test   %al,%al
80107061:	75 31                	jne    80107094 <trap+0xac>
      acquire(&tickslock);
80107063:	c7 04 24 e0 72 11 80 	movl   $0x801172e0,(%esp)
8010706a:	e8 d6 e6 ff ff       	call   80105745 <acquire>
      ticks++;
8010706f:	a1 20 7b 11 80       	mov    0x80117b20,%eax
80107074:	83 c0 01             	add    $0x1,%eax
80107077:	a3 20 7b 11 80       	mov    %eax,0x80117b20
      wakeup(&ticks);
8010707c:	c7 04 24 20 7b 11 80 	movl   $0x80117b20,(%esp)
80107083:	e8 18 dd ff ff       	call   80104da0 <wakeup>
      release(&tickslock);
80107088:	c7 04 24 e0 72 11 80 	movl   $0x801172e0,(%esp)
8010708f:	e8 13 e7 ff ff       	call   801057a7 <release>
    }
    lapiceoi();
80107094:	e8 81 bf ff ff       	call   8010301a <lapiceoi>
    break;
80107099:	e9 41 01 00 00       	jmp    801071df <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
8010709e:	e8 85 b7 ff ff       	call   80102828 <ideintr>
    lapiceoi();
801070a3:	e8 72 bf ff ff       	call   8010301a <lapiceoi>
    break;
801070a8:	e9 32 01 00 00       	jmp    801071df <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
801070ad:	e8 37 bd ff ff       	call   80102de9 <kbdintr>
    lapiceoi();
801070b2:	e8 63 bf ff ff       	call   8010301a <lapiceoi>
    break;
801070b7:	e9 23 01 00 00       	jmp    801071df <trap+0x1f7>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
801070bc:	e8 97 03 00 00       	call   80107458 <uartintr>
    lapiceoi();
801070c1:	e8 54 bf ff ff       	call   8010301a <lapiceoi>
    break;
801070c6:	e9 14 01 00 00       	jmp    801071df <trap+0x1f7>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801070cb:	8b 45 08             	mov    0x8(%ebp),%eax
801070ce:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
801070d1:	8b 45 08             	mov    0x8(%ebp),%eax
801070d4:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801070d8:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
801070db:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801070e1:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801070e4:	0f b6 c0             	movzbl %al,%eax
801070e7:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801070eb:	89 54 24 08          	mov    %edx,0x8(%esp)
801070ef:	89 44 24 04          	mov    %eax,0x4(%esp)
801070f3:	c7 04 24 08 92 10 80 	movl   $0x80109208,(%esp)
801070fa:	e8 a1 92 ff ff       	call   801003a0 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
801070ff:	e8 16 bf ff ff       	call   8010301a <lapiceoi>
    break;
80107104:	e9 d6 00 00 00       	jmp    801071df <trap+0x1f7>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80107109:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010710f:	85 c0                	test   %eax,%eax
80107111:	74 11                	je     80107124 <trap+0x13c>
80107113:	8b 45 08             	mov    0x8(%ebp),%eax
80107116:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010711a:	0f b7 c0             	movzwl %ax,%eax
8010711d:	83 e0 03             	and    $0x3,%eax
80107120:	85 c0                	test   %eax,%eax
80107122:	75 46                	jne    8010716a <trap+0x182>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107124:	e8 1e fd ff ff       	call   80106e47 <rcr2>
80107129:	8b 55 08             	mov    0x8(%ebp),%edx
8010712c:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
8010712f:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107136:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107139:	0f b6 ca             	movzbl %dl,%ecx
8010713c:	8b 55 08             	mov    0x8(%ebp),%edx
8010713f:	8b 52 30             	mov    0x30(%edx),%edx
80107142:	89 44 24 10          	mov    %eax,0x10(%esp)
80107146:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
8010714a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010714e:	89 54 24 04          	mov    %edx,0x4(%esp)
80107152:	c7 04 24 2c 92 10 80 	movl   $0x8010922c,(%esp)
80107159:	e8 42 92 ff ff       	call   801003a0 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
8010715e:	c7 04 24 5e 92 10 80 	movl   $0x8010925e,(%esp)
80107165:	e8 d0 93 ff ff       	call   8010053a <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010716a:	e8 d8 fc ff ff       	call   80106e47 <rcr2>
8010716f:	89 c2                	mov    %eax,%edx
80107171:	8b 45 08             	mov    0x8(%ebp),%eax
80107174:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107177:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010717d:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107180:	0f b6 f0             	movzbl %al,%esi
80107183:	8b 45 08             	mov    0x8(%ebp),%eax
80107186:	8b 58 34             	mov    0x34(%eax),%ebx
80107189:	8b 45 08             	mov    0x8(%ebp),%eax
8010718c:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010718f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107195:	83 c0 28             	add    $0x28,%eax
80107198:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010719b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801071a1:	8b 40 10             	mov    0x10(%eax),%eax
801071a4:	89 54 24 1c          	mov    %edx,0x1c(%esp)
801071a8:	89 7c 24 18          	mov    %edi,0x18(%esp)
801071ac:	89 74 24 14          	mov    %esi,0x14(%esp)
801071b0:	89 5c 24 10          	mov    %ebx,0x10(%esp)
801071b4:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801071b8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
801071bb:	89 74 24 08          	mov    %esi,0x8(%esp)
801071bf:	89 44 24 04          	mov    %eax,0x4(%esp)
801071c3:	c7 04 24 64 92 10 80 	movl   $0x80109264,(%esp)
801071ca:	e8 d1 91 ff ff       	call   801003a0 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
801071cf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801071d5:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
801071dc:	eb 01                	jmp    801071df <trap+0x1f7>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
801071de:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801071df:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801071e5:	85 c0                	test   %eax,%eax
801071e7:	74 24                	je     8010720d <trap+0x225>
801071e9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801071ef:	8b 40 24             	mov    0x24(%eax),%eax
801071f2:	85 c0                	test   %eax,%eax
801071f4:	74 17                	je     8010720d <trap+0x225>
801071f6:	8b 45 08             	mov    0x8(%ebp),%eax
801071f9:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801071fd:	0f b7 c0             	movzwl %ax,%eax
80107200:	83 e0 03             	and    $0x3,%eax
80107203:	83 f8 03             	cmp    $0x3,%eax
80107206:	75 05                	jne    8010720d <trap+0x225>
    exit();
80107208:	e8 d5 d6 ff ff       	call   801048e2 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
8010720d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107213:	85 c0                	test   %eax,%eax
80107215:	74 1e                	je     80107235 <trap+0x24d>
80107217:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010721d:	8b 40 0c             	mov    0xc(%eax),%eax
80107220:	83 f8 04             	cmp    $0x4,%eax
80107223:	75 10                	jne    80107235 <trap+0x24d>
80107225:	8b 45 08             	mov    0x8(%ebp),%eax
80107228:	8b 40 30             	mov    0x30(%eax),%eax
8010722b:	83 f8 20             	cmp    $0x20,%eax
8010722e:	75 05                	jne    80107235 <trap+0x24d>
    yield();
80107230:	e8 31 da ff ff       	call   80104c66 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107235:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010723b:	85 c0                	test   %eax,%eax
8010723d:	74 24                	je     80107263 <trap+0x27b>
8010723f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107245:	8b 40 24             	mov    0x24(%eax),%eax
80107248:	85 c0                	test   %eax,%eax
8010724a:	74 17                	je     80107263 <trap+0x27b>
8010724c:	8b 45 08             	mov    0x8(%ebp),%eax
8010724f:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107253:	0f b7 c0             	movzwl %ax,%eax
80107256:	83 e0 03             	and    $0x3,%eax
80107259:	83 f8 03             	cmp    $0x3,%eax
8010725c:	75 05                	jne    80107263 <trap+0x27b>
    exit();
8010725e:	e8 7f d6 ff ff       	call   801048e2 <exit>
}
80107263:	83 c4 3c             	add    $0x3c,%esp
80107266:	5b                   	pop    %ebx
80107267:	5e                   	pop    %esi
80107268:	5f                   	pop    %edi
80107269:	5d                   	pop    %ebp
8010726a:	c3                   	ret    

8010726b <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010726b:	55                   	push   %ebp
8010726c:	89 e5                	mov    %esp,%ebp
8010726e:	83 ec 14             	sub    $0x14,%esp
80107271:	8b 45 08             	mov    0x8(%ebp),%eax
80107274:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80107278:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
8010727c:	89 c2                	mov    %eax,%edx
8010727e:	ec                   	in     (%dx),%al
8010727f:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80107282:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80107286:	c9                   	leave  
80107287:	c3                   	ret    

80107288 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107288:	55                   	push   %ebp
80107289:	89 e5                	mov    %esp,%ebp
8010728b:	83 ec 08             	sub    $0x8,%esp
8010728e:	8b 55 08             	mov    0x8(%ebp),%edx
80107291:	8b 45 0c             	mov    0xc(%ebp),%eax
80107294:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107298:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010729b:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010729f:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801072a3:	ee                   	out    %al,(%dx)
}
801072a4:	c9                   	leave  
801072a5:	c3                   	ret    

801072a6 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
801072a6:	55                   	push   %ebp
801072a7:	89 e5                	mov    %esp,%ebp
801072a9:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
801072ac:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801072b3:	00 
801072b4:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
801072bb:	e8 c8 ff ff ff       	call   80107288 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
801072c0:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
801072c7:	00 
801072c8:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
801072cf:	e8 b4 ff ff ff       	call   80107288 <outb>
  outb(COM1+0, 115200/9600);
801072d4:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
801072db:	00 
801072dc:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801072e3:	e8 a0 ff ff ff       	call   80107288 <outb>
  outb(COM1+1, 0);
801072e8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801072ef:	00 
801072f0:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801072f7:	e8 8c ff ff ff       	call   80107288 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
801072fc:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80107303:	00 
80107304:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
8010730b:	e8 78 ff ff ff       	call   80107288 <outb>
  outb(COM1+4, 0);
80107310:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107317:	00 
80107318:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
8010731f:	e8 64 ff ff ff       	call   80107288 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80107324:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010732b:	00 
8010732c:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107333:	e8 50 ff ff ff       	call   80107288 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80107338:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
8010733f:	e8 27 ff ff ff       	call   8010726b <inb>
80107344:	3c ff                	cmp    $0xff,%al
80107346:	75 02                	jne    8010734a <uartinit+0xa4>
    return;
80107348:	eb 6a                	jmp    801073b4 <uartinit+0x10e>
  uart = 1;
8010734a:	c7 05 4c c6 10 80 01 	movl   $0x1,0x8010c64c
80107351:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80107354:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
8010735b:	e8 0b ff ff ff       	call   8010726b <inb>
  inb(COM1+0);
80107360:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107367:	e8 ff fe ff ff       	call   8010726b <inb>
  picenable(IRQ_COM1);
8010736c:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107373:	e8 8b cb ff ff       	call   80103f03 <picenable>
  ioapicenable(IRQ_COM1, 0);
80107378:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010737f:	00 
80107380:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107387:	e8 1b b7 ff ff       	call   80102aa7 <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
8010738c:	c7 45 f4 28 93 10 80 	movl   $0x80109328,-0xc(%ebp)
80107393:	eb 15                	jmp    801073aa <uartinit+0x104>
    uartputc(*p);
80107395:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107398:	0f b6 00             	movzbl (%eax),%eax
8010739b:	0f be c0             	movsbl %al,%eax
8010739e:	89 04 24             	mov    %eax,(%esp)
801073a1:	e8 10 00 00 00       	call   801073b6 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
801073a6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801073aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801073ad:	0f b6 00             	movzbl (%eax),%eax
801073b0:	84 c0                	test   %al,%al
801073b2:	75 e1                	jne    80107395 <uartinit+0xef>
    uartputc(*p);
}
801073b4:	c9                   	leave  
801073b5:	c3                   	ret    

801073b6 <uartputc>:

void
uartputc(int c)
{
801073b6:	55                   	push   %ebp
801073b7:	89 e5                	mov    %esp,%ebp
801073b9:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
801073bc:	a1 4c c6 10 80       	mov    0x8010c64c,%eax
801073c1:	85 c0                	test   %eax,%eax
801073c3:	75 02                	jne    801073c7 <uartputc+0x11>
    return;
801073c5:	eb 4b                	jmp    80107412 <uartputc+0x5c>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801073c7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801073ce:	eb 10                	jmp    801073e0 <uartputc+0x2a>
    microdelay(10);
801073d0:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
801073d7:	e8 63 bc ff ff       	call   8010303f <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801073dc:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801073e0:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
801073e4:	7f 16                	jg     801073fc <uartputc+0x46>
801073e6:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801073ed:	e8 79 fe ff ff       	call   8010726b <inb>
801073f2:	0f b6 c0             	movzbl %al,%eax
801073f5:	83 e0 20             	and    $0x20,%eax
801073f8:	85 c0                	test   %eax,%eax
801073fa:	74 d4                	je     801073d0 <uartputc+0x1a>
    microdelay(10);
  outb(COM1+0, c);
801073fc:	8b 45 08             	mov    0x8(%ebp),%eax
801073ff:	0f b6 c0             	movzbl %al,%eax
80107402:	89 44 24 04          	mov    %eax,0x4(%esp)
80107406:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
8010740d:	e8 76 fe ff ff       	call   80107288 <outb>
}
80107412:	c9                   	leave  
80107413:	c3                   	ret    

80107414 <uartgetc>:

static int
uartgetc(void)
{
80107414:	55                   	push   %ebp
80107415:	89 e5                	mov    %esp,%ebp
80107417:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
8010741a:	a1 4c c6 10 80       	mov    0x8010c64c,%eax
8010741f:	85 c0                	test   %eax,%eax
80107421:	75 07                	jne    8010742a <uartgetc+0x16>
    return -1;
80107423:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107428:	eb 2c                	jmp    80107456 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
8010742a:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107431:	e8 35 fe ff ff       	call   8010726b <inb>
80107436:	0f b6 c0             	movzbl %al,%eax
80107439:	83 e0 01             	and    $0x1,%eax
8010743c:	85 c0                	test   %eax,%eax
8010743e:	75 07                	jne    80107447 <uartgetc+0x33>
    return -1;
80107440:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107445:	eb 0f                	jmp    80107456 <uartgetc+0x42>
  return inb(COM1+0);
80107447:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
8010744e:	e8 18 fe ff ff       	call   8010726b <inb>
80107453:	0f b6 c0             	movzbl %al,%eax
}
80107456:	c9                   	leave  
80107457:	c3                   	ret    

80107458 <uartintr>:

void
uartintr(void)
{
80107458:	55                   	push   %ebp
80107459:	89 e5                	mov    %esp,%ebp
8010745b:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
8010745e:	c7 04 24 14 74 10 80 	movl   $0x80107414,(%esp)
80107465:	e8 43 93 ff ff       	call   801007ad <consoleintr>
}
8010746a:	c9                   	leave  
8010746b:	c3                   	ret    

8010746c <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
8010746c:	6a 00                	push   $0x0
  pushl $0
8010746e:	6a 00                	push   $0x0
  jmp alltraps
80107470:	e9 7e f9 ff ff       	jmp    80106df3 <alltraps>

80107475 <vector1>:
.globl vector1
vector1:
  pushl $0
80107475:	6a 00                	push   $0x0
  pushl $1
80107477:	6a 01                	push   $0x1
  jmp alltraps
80107479:	e9 75 f9 ff ff       	jmp    80106df3 <alltraps>

8010747e <vector2>:
.globl vector2
vector2:
  pushl $0
8010747e:	6a 00                	push   $0x0
  pushl $2
80107480:	6a 02                	push   $0x2
  jmp alltraps
80107482:	e9 6c f9 ff ff       	jmp    80106df3 <alltraps>

80107487 <vector3>:
.globl vector3
vector3:
  pushl $0
80107487:	6a 00                	push   $0x0
  pushl $3
80107489:	6a 03                	push   $0x3
  jmp alltraps
8010748b:	e9 63 f9 ff ff       	jmp    80106df3 <alltraps>

80107490 <vector4>:
.globl vector4
vector4:
  pushl $0
80107490:	6a 00                	push   $0x0
  pushl $4
80107492:	6a 04                	push   $0x4
  jmp alltraps
80107494:	e9 5a f9 ff ff       	jmp    80106df3 <alltraps>

80107499 <vector5>:
.globl vector5
vector5:
  pushl $0
80107499:	6a 00                	push   $0x0
  pushl $5
8010749b:	6a 05                	push   $0x5
  jmp alltraps
8010749d:	e9 51 f9 ff ff       	jmp    80106df3 <alltraps>

801074a2 <vector6>:
.globl vector6
vector6:
  pushl $0
801074a2:	6a 00                	push   $0x0
  pushl $6
801074a4:	6a 06                	push   $0x6
  jmp alltraps
801074a6:	e9 48 f9 ff ff       	jmp    80106df3 <alltraps>

801074ab <vector7>:
.globl vector7
vector7:
  pushl $0
801074ab:	6a 00                	push   $0x0
  pushl $7
801074ad:	6a 07                	push   $0x7
  jmp alltraps
801074af:	e9 3f f9 ff ff       	jmp    80106df3 <alltraps>

801074b4 <vector8>:
.globl vector8
vector8:
  pushl $8
801074b4:	6a 08                	push   $0x8
  jmp alltraps
801074b6:	e9 38 f9 ff ff       	jmp    80106df3 <alltraps>

801074bb <vector9>:
.globl vector9
vector9:
  pushl $0
801074bb:	6a 00                	push   $0x0
  pushl $9
801074bd:	6a 09                	push   $0x9
  jmp alltraps
801074bf:	e9 2f f9 ff ff       	jmp    80106df3 <alltraps>

801074c4 <vector10>:
.globl vector10
vector10:
  pushl $10
801074c4:	6a 0a                	push   $0xa
  jmp alltraps
801074c6:	e9 28 f9 ff ff       	jmp    80106df3 <alltraps>

801074cb <vector11>:
.globl vector11
vector11:
  pushl $11
801074cb:	6a 0b                	push   $0xb
  jmp alltraps
801074cd:	e9 21 f9 ff ff       	jmp    80106df3 <alltraps>

801074d2 <vector12>:
.globl vector12
vector12:
  pushl $12
801074d2:	6a 0c                	push   $0xc
  jmp alltraps
801074d4:	e9 1a f9 ff ff       	jmp    80106df3 <alltraps>

801074d9 <vector13>:
.globl vector13
vector13:
  pushl $13
801074d9:	6a 0d                	push   $0xd
  jmp alltraps
801074db:	e9 13 f9 ff ff       	jmp    80106df3 <alltraps>

801074e0 <vector14>:
.globl vector14
vector14:
  pushl $14
801074e0:	6a 0e                	push   $0xe
  jmp alltraps
801074e2:	e9 0c f9 ff ff       	jmp    80106df3 <alltraps>

801074e7 <vector15>:
.globl vector15
vector15:
  pushl $0
801074e7:	6a 00                	push   $0x0
  pushl $15
801074e9:	6a 0f                	push   $0xf
  jmp alltraps
801074eb:	e9 03 f9 ff ff       	jmp    80106df3 <alltraps>

801074f0 <vector16>:
.globl vector16
vector16:
  pushl $0
801074f0:	6a 00                	push   $0x0
  pushl $16
801074f2:	6a 10                	push   $0x10
  jmp alltraps
801074f4:	e9 fa f8 ff ff       	jmp    80106df3 <alltraps>

801074f9 <vector17>:
.globl vector17
vector17:
  pushl $17
801074f9:	6a 11                	push   $0x11
  jmp alltraps
801074fb:	e9 f3 f8 ff ff       	jmp    80106df3 <alltraps>

80107500 <vector18>:
.globl vector18
vector18:
  pushl $0
80107500:	6a 00                	push   $0x0
  pushl $18
80107502:	6a 12                	push   $0x12
  jmp alltraps
80107504:	e9 ea f8 ff ff       	jmp    80106df3 <alltraps>

80107509 <vector19>:
.globl vector19
vector19:
  pushl $0
80107509:	6a 00                	push   $0x0
  pushl $19
8010750b:	6a 13                	push   $0x13
  jmp alltraps
8010750d:	e9 e1 f8 ff ff       	jmp    80106df3 <alltraps>

80107512 <vector20>:
.globl vector20
vector20:
  pushl $0
80107512:	6a 00                	push   $0x0
  pushl $20
80107514:	6a 14                	push   $0x14
  jmp alltraps
80107516:	e9 d8 f8 ff ff       	jmp    80106df3 <alltraps>

8010751b <vector21>:
.globl vector21
vector21:
  pushl $0
8010751b:	6a 00                	push   $0x0
  pushl $21
8010751d:	6a 15                	push   $0x15
  jmp alltraps
8010751f:	e9 cf f8 ff ff       	jmp    80106df3 <alltraps>

80107524 <vector22>:
.globl vector22
vector22:
  pushl $0
80107524:	6a 00                	push   $0x0
  pushl $22
80107526:	6a 16                	push   $0x16
  jmp alltraps
80107528:	e9 c6 f8 ff ff       	jmp    80106df3 <alltraps>

8010752d <vector23>:
.globl vector23
vector23:
  pushl $0
8010752d:	6a 00                	push   $0x0
  pushl $23
8010752f:	6a 17                	push   $0x17
  jmp alltraps
80107531:	e9 bd f8 ff ff       	jmp    80106df3 <alltraps>

80107536 <vector24>:
.globl vector24
vector24:
  pushl $0
80107536:	6a 00                	push   $0x0
  pushl $24
80107538:	6a 18                	push   $0x18
  jmp alltraps
8010753a:	e9 b4 f8 ff ff       	jmp    80106df3 <alltraps>

8010753f <vector25>:
.globl vector25
vector25:
  pushl $0
8010753f:	6a 00                	push   $0x0
  pushl $25
80107541:	6a 19                	push   $0x19
  jmp alltraps
80107543:	e9 ab f8 ff ff       	jmp    80106df3 <alltraps>

80107548 <vector26>:
.globl vector26
vector26:
  pushl $0
80107548:	6a 00                	push   $0x0
  pushl $26
8010754a:	6a 1a                	push   $0x1a
  jmp alltraps
8010754c:	e9 a2 f8 ff ff       	jmp    80106df3 <alltraps>

80107551 <vector27>:
.globl vector27
vector27:
  pushl $0
80107551:	6a 00                	push   $0x0
  pushl $27
80107553:	6a 1b                	push   $0x1b
  jmp alltraps
80107555:	e9 99 f8 ff ff       	jmp    80106df3 <alltraps>

8010755a <vector28>:
.globl vector28
vector28:
  pushl $0
8010755a:	6a 00                	push   $0x0
  pushl $28
8010755c:	6a 1c                	push   $0x1c
  jmp alltraps
8010755e:	e9 90 f8 ff ff       	jmp    80106df3 <alltraps>

80107563 <vector29>:
.globl vector29
vector29:
  pushl $0
80107563:	6a 00                	push   $0x0
  pushl $29
80107565:	6a 1d                	push   $0x1d
  jmp alltraps
80107567:	e9 87 f8 ff ff       	jmp    80106df3 <alltraps>

8010756c <vector30>:
.globl vector30
vector30:
  pushl $0
8010756c:	6a 00                	push   $0x0
  pushl $30
8010756e:	6a 1e                	push   $0x1e
  jmp alltraps
80107570:	e9 7e f8 ff ff       	jmp    80106df3 <alltraps>

80107575 <vector31>:
.globl vector31
vector31:
  pushl $0
80107575:	6a 00                	push   $0x0
  pushl $31
80107577:	6a 1f                	push   $0x1f
  jmp alltraps
80107579:	e9 75 f8 ff ff       	jmp    80106df3 <alltraps>

8010757e <vector32>:
.globl vector32
vector32:
  pushl $0
8010757e:	6a 00                	push   $0x0
  pushl $32
80107580:	6a 20                	push   $0x20
  jmp alltraps
80107582:	e9 6c f8 ff ff       	jmp    80106df3 <alltraps>

80107587 <vector33>:
.globl vector33
vector33:
  pushl $0
80107587:	6a 00                	push   $0x0
  pushl $33
80107589:	6a 21                	push   $0x21
  jmp alltraps
8010758b:	e9 63 f8 ff ff       	jmp    80106df3 <alltraps>

80107590 <vector34>:
.globl vector34
vector34:
  pushl $0
80107590:	6a 00                	push   $0x0
  pushl $34
80107592:	6a 22                	push   $0x22
  jmp alltraps
80107594:	e9 5a f8 ff ff       	jmp    80106df3 <alltraps>

80107599 <vector35>:
.globl vector35
vector35:
  pushl $0
80107599:	6a 00                	push   $0x0
  pushl $35
8010759b:	6a 23                	push   $0x23
  jmp alltraps
8010759d:	e9 51 f8 ff ff       	jmp    80106df3 <alltraps>

801075a2 <vector36>:
.globl vector36
vector36:
  pushl $0
801075a2:	6a 00                	push   $0x0
  pushl $36
801075a4:	6a 24                	push   $0x24
  jmp alltraps
801075a6:	e9 48 f8 ff ff       	jmp    80106df3 <alltraps>

801075ab <vector37>:
.globl vector37
vector37:
  pushl $0
801075ab:	6a 00                	push   $0x0
  pushl $37
801075ad:	6a 25                	push   $0x25
  jmp alltraps
801075af:	e9 3f f8 ff ff       	jmp    80106df3 <alltraps>

801075b4 <vector38>:
.globl vector38
vector38:
  pushl $0
801075b4:	6a 00                	push   $0x0
  pushl $38
801075b6:	6a 26                	push   $0x26
  jmp alltraps
801075b8:	e9 36 f8 ff ff       	jmp    80106df3 <alltraps>

801075bd <vector39>:
.globl vector39
vector39:
  pushl $0
801075bd:	6a 00                	push   $0x0
  pushl $39
801075bf:	6a 27                	push   $0x27
  jmp alltraps
801075c1:	e9 2d f8 ff ff       	jmp    80106df3 <alltraps>

801075c6 <vector40>:
.globl vector40
vector40:
  pushl $0
801075c6:	6a 00                	push   $0x0
  pushl $40
801075c8:	6a 28                	push   $0x28
  jmp alltraps
801075ca:	e9 24 f8 ff ff       	jmp    80106df3 <alltraps>

801075cf <vector41>:
.globl vector41
vector41:
  pushl $0
801075cf:	6a 00                	push   $0x0
  pushl $41
801075d1:	6a 29                	push   $0x29
  jmp alltraps
801075d3:	e9 1b f8 ff ff       	jmp    80106df3 <alltraps>

801075d8 <vector42>:
.globl vector42
vector42:
  pushl $0
801075d8:	6a 00                	push   $0x0
  pushl $42
801075da:	6a 2a                	push   $0x2a
  jmp alltraps
801075dc:	e9 12 f8 ff ff       	jmp    80106df3 <alltraps>

801075e1 <vector43>:
.globl vector43
vector43:
  pushl $0
801075e1:	6a 00                	push   $0x0
  pushl $43
801075e3:	6a 2b                	push   $0x2b
  jmp alltraps
801075e5:	e9 09 f8 ff ff       	jmp    80106df3 <alltraps>

801075ea <vector44>:
.globl vector44
vector44:
  pushl $0
801075ea:	6a 00                	push   $0x0
  pushl $44
801075ec:	6a 2c                	push   $0x2c
  jmp alltraps
801075ee:	e9 00 f8 ff ff       	jmp    80106df3 <alltraps>

801075f3 <vector45>:
.globl vector45
vector45:
  pushl $0
801075f3:	6a 00                	push   $0x0
  pushl $45
801075f5:	6a 2d                	push   $0x2d
  jmp alltraps
801075f7:	e9 f7 f7 ff ff       	jmp    80106df3 <alltraps>

801075fc <vector46>:
.globl vector46
vector46:
  pushl $0
801075fc:	6a 00                	push   $0x0
  pushl $46
801075fe:	6a 2e                	push   $0x2e
  jmp alltraps
80107600:	e9 ee f7 ff ff       	jmp    80106df3 <alltraps>

80107605 <vector47>:
.globl vector47
vector47:
  pushl $0
80107605:	6a 00                	push   $0x0
  pushl $47
80107607:	6a 2f                	push   $0x2f
  jmp alltraps
80107609:	e9 e5 f7 ff ff       	jmp    80106df3 <alltraps>

8010760e <vector48>:
.globl vector48
vector48:
  pushl $0
8010760e:	6a 00                	push   $0x0
  pushl $48
80107610:	6a 30                	push   $0x30
  jmp alltraps
80107612:	e9 dc f7 ff ff       	jmp    80106df3 <alltraps>

80107617 <vector49>:
.globl vector49
vector49:
  pushl $0
80107617:	6a 00                	push   $0x0
  pushl $49
80107619:	6a 31                	push   $0x31
  jmp alltraps
8010761b:	e9 d3 f7 ff ff       	jmp    80106df3 <alltraps>

80107620 <vector50>:
.globl vector50
vector50:
  pushl $0
80107620:	6a 00                	push   $0x0
  pushl $50
80107622:	6a 32                	push   $0x32
  jmp alltraps
80107624:	e9 ca f7 ff ff       	jmp    80106df3 <alltraps>

80107629 <vector51>:
.globl vector51
vector51:
  pushl $0
80107629:	6a 00                	push   $0x0
  pushl $51
8010762b:	6a 33                	push   $0x33
  jmp alltraps
8010762d:	e9 c1 f7 ff ff       	jmp    80106df3 <alltraps>

80107632 <vector52>:
.globl vector52
vector52:
  pushl $0
80107632:	6a 00                	push   $0x0
  pushl $52
80107634:	6a 34                	push   $0x34
  jmp alltraps
80107636:	e9 b8 f7 ff ff       	jmp    80106df3 <alltraps>

8010763b <vector53>:
.globl vector53
vector53:
  pushl $0
8010763b:	6a 00                	push   $0x0
  pushl $53
8010763d:	6a 35                	push   $0x35
  jmp alltraps
8010763f:	e9 af f7 ff ff       	jmp    80106df3 <alltraps>

80107644 <vector54>:
.globl vector54
vector54:
  pushl $0
80107644:	6a 00                	push   $0x0
  pushl $54
80107646:	6a 36                	push   $0x36
  jmp alltraps
80107648:	e9 a6 f7 ff ff       	jmp    80106df3 <alltraps>

8010764d <vector55>:
.globl vector55
vector55:
  pushl $0
8010764d:	6a 00                	push   $0x0
  pushl $55
8010764f:	6a 37                	push   $0x37
  jmp alltraps
80107651:	e9 9d f7 ff ff       	jmp    80106df3 <alltraps>

80107656 <vector56>:
.globl vector56
vector56:
  pushl $0
80107656:	6a 00                	push   $0x0
  pushl $56
80107658:	6a 38                	push   $0x38
  jmp alltraps
8010765a:	e9 94 f7 ff ff       	jmp    80106df3 <alltraps>

8010765f <vector57>:
.globl vector57
vector57:
  pushl $0
8010765f:	6a 00                	push   $0x0
  pushl $57
80107661:	6a 39                	push   $0x39
  jmp alltraps
80107663:	e9 8b f7 ff ff       	jmp    80106df3 <alltraps>

80107668 <vector58>:
.globl vector58
vector58:
  pushl $0
80107668:	6a 00                	push   $0x0
  pushl $58
8010766a:	6a 3a                	push   $0x3a
  jmp alltraps
8010766c:	e9 82 f7 ff ff       	jmp    80106df3 <alltraps>

80107671 <vector59>:
.globl vector59
vector59:
  pushl $0
80107671:	6a 00                	push   $0x0
  pushl $59
80107673:	6a 3b                	push   $0x3b
  jmp alltraps
80107675:	e9 79 f7 ff ff       	jmp    80106df3 <alltraps>

8010767a <vector60>:
.globl vector60
vector60:
  pushl $0
8010767a:	6a 00                	push   $0x0
  pushl $60
8010767c:	6a 3c                	push   $0x3c
  jmp alltraps
8010767e:	e9 70 f7 ff ff       	jmp    80106df3 <alltraps>

80107683 <vector61>:
.globl vector61
vector61:
  pushl $0
80107683:	6a 00                	push   $0x0
  pushl $61
80107685:	6a 3d                	push   $0x3d
  jmp alltraps
80107687:	e9 67 f7 ff ff       	jmp    80106df3 <alltraps>

8010768c <vector62>:
.globl vector62
vector62:
  pushl $0
8010768c:	6a 00                	push   $0x0
  pushl $62
8010768e:	6a 3e                	push   $0x3e
  jmp alltraps
80107690:	e9 5e f7 ff ff       	jmp    80106df3 <alltraps>

80107695 <vector63>:
.globl vector63
vector63:
  pushl $0
80107695:	6a 00                	push   $0x0
  pushl $63
80107697:	6a 3f                	push   $0x3f
  jmp alltraps
80107699:	e9 55 f7 ff ff       	jmp    80106df3 <alltraps>

8010769e <vector64>:
.globl vector64
vector64:
  pushl $0
8010769e:	6a 00                	push   $0x0
  pushl $64
801076a0:	6a 40                	push   $0x40
  jmp alltraps
801076a2:	e9 4c f7 ff ff       	jmp    80106df3 <alltraps>

801076a7 <vector65>:
.globl vector65
vector65:
  pushl $0
801076a7:	6a 00                	push   $0x0
  pushl $65
801076a9:	6a 41                	push   $0x41
  jmp alltraps
801076ab:	e9 43 f7 ff ff       	jmp    80106df3 <alltraps>

801076b0 <vector66>:
.globl vector66
vector66:
  pushl $0
801076b0:	6a 00                	push   $0x0
  pushl $66
801076b2:	6a 42                	push   $0x42
  jmp alltraps
801076b4:	e9 3a f7 ff ff       	jmp    80106df3 <alltraps>

801076b9 <vector67>:
.globl vector67
vector67:
  pushl $0
801076b9:	6a 00                	push   $0x0
  pushl $67
801076bb:	6a 43                	push   $0x43
  jmp alltraps
801076bd:	e9 31 f7 ff ff       	jmp    80106df3 <alltraps>

801076c2 <vector68>:
.globl vector68
vector68:
  pushl $0
801076c2:	6a 00                	push   $0x0
  pushl $68
801076c4:	6a 44                	push   $0x44
  jmp alltraps
801076c6:	e9 28 f7 ff ff       	jmp    80106df3 <alltraps>

801076cb <vector69>:
.globl vector69
vector69:
  pushl $0
801076cb:	6a 00                	push   $0x0
  pushl $69
801076cd:	6a 45                	push   $0x45
  jmp alltraps
801076cf:	e9 1f f7 ff ff       	jmp    80106df3 <alltraps>

801076d4 <vector70>:
.globl vector70
vector70:
  pushl $0
801076d4:	6a 00                	push   $0x0
  pushl $70
801076d6:	6a 46                	push   $0x46
  jmp alltraps
801076d8:	e9 16 f7 ff ff       	jmp    80106df3 <alltraps>

801076dd <vector71>:
.globl vector71
vector71:
  pushl $0
801076dd:	6a 00                	push   $0x0
  pushl $71
801076df:	6a 47                	push   $0x47
  jmp alltraps
801076e1:	e9 0d f7 ff ff       	jmp    80106df3 <alltraps>

801076e6 <vector72>:
.globl vector72
vector72:
  pushl $0
801076e6:	6a 00                	push   $0x0
  pushl $72
801076e8:	6a 48                	push   $0x48
  jmp alltraps
801076ea:	e9 04 f7 ff ff       	jmp    80106df3 <alltraps>

801076ef <vector73>:
.globl vector73
vector73:
  pushl $0
801076ef:	6a 00                	push   $0x0
  pushl $73
801076f1:	6a 49                	push   $0x49
  jmp alltraps
801076f3:	e9 fb f6 ff ff       	jmp    80106df3 <alltraps>

801076f8 <vector74>:
.globl vector74
vector74:
  pushl $0
801076f8:	6a 00                	push   $0x0
  pushl $74
801076fa:	6a 4a                	push   $0x4a
  jmp alltraps
801076fc:	e9 f2 f6 ff ff       	jmp    80106df3 <alltraps>

80107701 <vector75>:
.globl vector75
vector75:
  pushl $0
80107701:	6a 00                	push   $0x0
  pushl $75
80107703:	6a 4b                	push   $0x4b
  jmp alltraps
80107705:	e9 e9 f6 ff ff       	jmp    80106df3 <alltraps>

8010770a <vector76>:
.globl vector76
vector76:
  pushl $0
8010770a:	6a 00                	push   $0x0
  pushl $76
8010770c:	6a 4c                	push   $0x4c
  jmp alltraps
8010770e:	e9 e0 f6 ff ff       	jmp    80106df3 <alltraps>

80107713 <vector77>:
.globl vector77
vector77:
  pushl $0
80107713:	6a 00                	push   $0x0
  pushl $77
80107715:	6a 4d                	push   $0x4d
  jmp alltraps
80107717:	e9 d7 f6 ff ff       	jmp    80106df3 <alltraps>

8010771c <vector78>:
.globl vector78
vector78:
  pushl $0
8010771c:	6a 00                	push   $0x0
  pushl $78
8010771e:	6a 4e                	push   $0x4e
  jmp alltraps
80107720:	e9 ce f6 ff ff       	jmp    80106df3 <alltraps>

80107725 <vector79>:
.globl vector79
vector79:
  pushl $0
80107725:	6a 00                	push   $0x0
  pushl $79
80107727:	6a 4f                	push   $0x4f
  jmp alltraps
80107729:	e9 c5 f6 ff ff       	jmp    80106df3 <alltraps>

8010772e <vector80>:
.globl vector80
vector80:
  pushl $0
8010772e:	6a 00                	push   $0x0
  pushl $80
80107730:	6a 50                	push   $0x50
  jmp alltraps
80107732:	e9 bc f6 ff ff       	jmp    80106df3 <alltraps>

80107737 <vector81>:
.globl vector81
vector81:
  pushl $0
80107737:	6a 00                	push   $0x0
  pushl $81
80107739:	6a 51                	push   $0x51
  jmp alltraps
8010773b:	e9 b3 f6 ff ff       	jmp    80106df3 <alltraps>

80107740 <vector82>:
.globl vector82
vector82:
  pushl $0
80107740:	6a 00                	push   $0x0
  pushl $82
80107742:	6a 52                	push   $0x52
  jmp alltraps
80107744:	e9 aa f6 ff ff       	jmp    80106df3 <alltraps>

80107749 <vector83>:
.globl vector83
vector83:
  pushl $0
80107749:	6a 00                	push   $0x0
  pushl $83
8010774b:	6a 53                	push   $0x53
  jmp alltraps
8010774d:	e9 a1 f6 ff ff       	jmp    80106df3 <alltraps>

80107752 <vector84>:
.globl vector84
vector84:
  pushl $0
80107752:	6a 00                	push   $0x0
  pushl $84
80107754:	6a 54                	push   $0x54
  jmp alltraps
80107756:	e9 98 f6 ff ff       	jmp    80106df3 <alltraps>

8010775b <vector85>:
.globl vector85
vector85:
  pushl $0
8010775b:	6a 00                	push   $0x0
  pushl $85
8010775d:	6a 55                	push   $0x55
  jmp alltraps
8010775f:	e9 8f f6 ff ff       	jmp    80106df3 <alltraps>

80107764 <vector86>:
.globl vector86
vector86:
  pushl $0
80107764:	6a 00                	push   $0x0
  pushl $86
80107766:	6a 56                	push   $0x56
  jmp alltraps
80107768:	e9 86 f6 ff ff       	jmp    80106df3 <alltraps>

8010776d <vector87>:
.globl vector87
vector87:
  pushl $0
8010776d:	6a 00                	push   $0x0
  pushl $87
8010776f:	6a 57                	push   $0x57
  jmp alltraps
80107771:	e9 7d f6 ff ff       	jmp    80106df3 <alltraps>

80107776 <vector88>:
.globl vector88
vector88:
  pushl $0
80107776:	6a 00                	push   $0x0
  pushl $88
80107778:	6a 58                	push   $0x58
  jmp alltraps
8010777a:	e9 74 f6 ff ff       	jmp    80106df3 <alltraps>

8010777f <vector89>:
.globl vector89
vector89:
  pushl $0
8010777f:	6a 00                	push   $0x0
  pushl $89
80107781:	6a 59                	push   $0x59
  jmp alltraps
80107783:	e9 6b f6 ff ff       	jmp    80106df3 <alltraps>

80107788 <vector90>:
.globl vector90
vector90:
  pushl $0
80107788:	6a 00                	push   $0x0
  pushl $90
8010778a:	6a 5a                	push   $0x5a
  jmp alltraps
8010778c:	e9 62 f6 ff ff       	jmp    80106df3 <alltraps>

80107791 <vector91>:
.globl vector91
vector91:
  pushl $0
80107791:	6a 00                	push   $0x0
  pushl $91
80107793:	6a 5b                	push   $0x5b
  jmp alltraps
80107795:	e9 59 f6 ff ff       	jmp    80106df3 <alltraps>

8010779a <vector92>:
.globl vector92
vector92:
  pushl $0
8010779a:	6a 00                	push   $0x0
  pushl $92
8010779c:	6a 5c                	push   $0x5c
  jmp alltraps
8010779e:	e9 50 f6 ff ff       	jmp    80106df3 <alltraps>

801077a3 <vector93>:
.globl vector93
vector93:
  pushl $0
801077a3:	6a 00                	push   $0x0
  pushl $93
801077a5:	6a 5d                	push   $0x5d
  jmp alltraps
801077a7:	e9 47 f6 ff ff       	jmp    80106df3 <alltraps>

801077ac <vector94>:
.globl vector94
vector94:
  pushl $0
801077ac:	6a 00                	push   $0x0
  pushl $94
801077ae:	6a 5e                	push   $0x5e
  jmp alltraps
801077b0:	e9 3e f6 ff ff       	jmp    80106df3 <alltraps>

801077b5 <vector95>:
.globl vector95
vector95:
  pushl $0
801077b5:	6a 00                	push   $0x0
  pushl $95
801077b7:	6a 5f                	push   $0x5f
  jmp alltraps
801077b9:	e9 35 f6 ff ff       	jmp    80106df3 <alltraps>

801077be <vector96>:
.globl vector96
vector96:
  pushl $0
801077be:	6a 00                	push   $0x0
  pushl $96
801077c0:	6a 60                	push   $0x60
  jmp alltraps
801077c2:	e9 2c f6 ff ff       	jmp    80106df3 <alltraps>

801077c7 <vector97>:
.globl vector97
vector97:
  pushl $0
801077c7:	6a 00                	push   $0x0
  pushl $97
801077c9:	6a 61                	push   $0x61
  jmp alltraps
801077cb:	e9 23 f6 ff ff       	jmp    80106df3 <alltraps>

801077d0 <vector98>:
.globl vector98
vector98:
  pushl $0
801077d0:	6a 00                	push   $0x0
  pushl $98
801077d2:	6a 62                	push   $0x62
  jmp alltraps
801077d4:	e9 1a f6 ff ff       	jmp    80106df3 <alltraps>

801077d9 <vector99>:
.globl vector99
vector99:
  pushl $0
801077d9:	6a 00                	push   $0x0
  pushl $99
801077db:	6a 63                	push   $0x63
  jmp alltraps
801077dd:	e9 11 f6 ff ff       	jmp    80106df3 <alltraps>

801077e2 <vector100>:
.globl vector100
vector100:
  pushl $0
801077e2:	6a 00                	push   $0x0
  pushl $100
801077e4:	6a 64                	push   $0x64
  jmp alltraps
801077e6:	e9 08 f6 ff ff       	jmp    80106df3 <alltraps>

801077eb <vector101>:
.globl vector101
vector101:
  pushl $0
801077eb:	6a 00                	push   $0x0
  pushl $101
801077ed:	6a 65                	push   $0x65
  jmp alltraps
801077ef:	e9 ff f5 ff ff       	jmp    80106df3 <alltraps>

801077f4 <vector102>:
.globl vector102
vector102:
  pushl $0
801077f4:	6a 00                	push   $0x0
  pushl $102
801077f6:	6a 66                	push   $0x66
  jmp alltraps
801077f8:	e9 f6 f5 ff ff       	jmp    80106df3 <alltraps>

801077fd <vector103>:
.globl vector103
vector103:
  pushl $0
801077fd:	6a 00                	push   $0x0
  pushl $103
801077ff:	6a 67                	push   $0x67
  jmp alltraps
80107801:	e9 ed f5 ff ff       	jmp    80106df3 <alltraps>

80107806 <vector104>:
.globl vector104
vector104:
  pushl $0
80107806:	6a 00                	push   $0x0
  pushl $104
80107808:	6a 68                	push   $0x68
  jmp alltraps
8010780a:	e9 e4 f5 ff ff       	jmp    80106df3 <alltraps>

8010780f <vector105>:
.globl vector105
vector105:
  pushl $0
8010780f:	6a 00                	push   $0x0
  pushl $105
80107811:	6a 69                	push   $0x69
  jmp alltraps
80107813:	e9 db f5 ff ff       	jmp    80106df3 <alltraps>

80107818 <vector106>:
.globl vector106
vector106:
  pushl $0
80107818:	6a 00                	push   $0x0
  pushl $106
8010781a:	6a 6a                	push   $0x6a
  jmp alltraps
8010781c:	e9 d2 f5 ff ff       	jmp    80106df3 <alltraps>

80107821 <vector107>:
.globl vector107
vector107:
  pushl $0
80107821:	6a 00                	push   $0x0
  pushl $107
80107823:	6a 6b                	push   $0x6b
  jmp alltraps
80107825:	e9 c9 f5 ff ff       	jmp    80106df3 <alltraps>

8010782a <vector108>:
.globl vector108
vector108:
  pushl $0
8010782a:	6a 00                	push   $0x0
  pushl $108
8010782c:	6a 6c                	push   $0x6c
  jmp alltraps
8010782e:	e9 c0 f5 ff ff       	jmp    80106df3 <alltraps>

80107833 <vector109>:
.globl vector109
vector109:
  pushl $0
80107833:	6a 00                	push   $0x0
  pushl $109
80107835:	6a 6d                	push   $0x6d
  jmp alltraps
80107837:	e9 b7 f5 ff ff       	jmp    80106df3 <alltraps>

8010783c <vector110>:
.globl vector110
vector110:
  pushl $0
8010783c:	6a 00                	push   $0x0
  pushl $110
8010783e:	6a 6e                	push   $0x6e
  jmp alltraps
80107840:	e9 ae f5 ff ff       	jmp    80106df3 <alltraps>

80107845 <vector111>:
.globl vector111
vector111:
  pushl $0
80107845:	6a 00                	push   $0x0
  pushl $111
80107847:	6a 6f                	push   $0x6f
  jmp alltraps
80107849:	e9 a5 f5 ff ff       	jmp    80106df3 <alltraps>

8010784e <vector112>:
.globl vector112
vector112:
  pushl $0
8010784e:	6a 00                	push   $0x0
  pushl $112
80107850:	6a 70                	push   $0x70
  jmp alltraps
80107852:	e9 9c f5 ff ff       	jmp    80106df3 <alltraps>

80107857 <vector113>:
.globl vector113
vector113:
  pushl $0
80107857:	6a 00                	push   $0x0
  pushl $113
80107859:	6a 71                	push   $0x71
  jmp alltraps
8010785b:	e9 93 f5 ff ff       	jmp    80106df3 <alltraps>

80107860 <vector114>:
.globl vector114
vector114:
  pushl $0
80107860:	6a 00                	push   $0x0
  pushl $114
80107862:	6a 72                	push   $0x72
  jmp alltraps
80107864:	e9 8a f5 ff ff       	jmp    80106df3 <alltraps>

80107869 <vector115>:
.globl vector115
vector115:
  pushl $0
80107869:	6a 00                	push   $0x0
  pushl $115
8010786b:	6a 73                	push   $0x73
  jmp alltraps
8010786d:	e9 81 f5 ff ff       	jmp    80106df3 <alltraps>

80107872 <vector116>:
.globl vector116
vector116:
  pushl $0
80107872:	6a 00                	push   $0x0
  pushl $116
80107874:	6a 74                	push   $0x74
  jmp alltraps
80107876:	e9 78 f5 ff ff       	jmp    80106df3 <alltraps>

8010787b <vector117>:
.globl vector117
vector117:
  pushl $0
8010787b:	6a 00                	push   $0x0
  pushl $117
8010787d:	6a 75                	push   $0x75
  jmp alltraps
8010787f:	e9 6f f5 ff ff       	jmp    80106df3 <alltraps>

80107884 <vector118>:
.globl vector118
vector118:
  pushl $0
80107884:	6a 00                	push   $0x0
  pushl $118
80107886:	6a 76                	push   $0x76
  jmp alltraps
80107888:	e9 66 f5 ff ff       	jmp    80106df3 <alltraps>

8010788d <vector119>:
.globl vector119
vector119:
  pushl $0
8010788d:	6a 00                	push   $0x0
  pushl $119
8010788f:	6a 77                	push   $0x77
  jmp alltraps
80107891:	e9 5d f5 ff ff       	jmp    80106df3 <alltraps>

80107896 <vector120>:
.globl vector120
vector120:
  pushl $0
80107896:	6a 00                	push   $0x0
  pushl $120
80107898:	6a 78                	push   $0x78
  jmp alltraps
8010789a:	e9 54 f5 ff ff       	jmp    80106df3 <alltraps>

8010789f <vector121>:
.globl vector121
vector121:
  pushl $0
8010789f:	6a 00                	push   $0x0
  pushl $121
801078a1:	6a 79                	push   $0x79
  jmp alltraps
801078a3:	e9 4b f5 ff ff       	jmp    80106df3 <alltraps>

801078a8 <vector122>:
.globl vector122
vector122:
  pushl $0
801078a8:	6a 00                	push   $0x0
  pushl $122
801078aa:	6a 7a                	push   $0x7a
  jmp alltraps
801078ac:	e9 42 f5 ff ff       	jmp    80106df3 <alltraps>

801078b1 <vector123>:
.globl vector123
vector123:
  pushl $0
801078b1:	6a 00                	push   $0x0
  pushl $123
801078b3:	6a 7b                	push   $0x7b
  jmp alltraps
801078b5:	e9 39 f5 ff ff       	jmp    80106df3 <alltraps>

801078ba <vector124>:
.globl vector124
vector124:
  pushl $0
801078ba:	6a 00                	push   $0x0
  pushl $124
801078bc:	6a 7c                	push   $0x7c
  jmp alltraps
801078be:	e9 30 f5 ff ff       	jmp    80106df3 <alltraps>

801078c3 <vector125>:
.globl vector125
vector125:
  pushl $0
801078c3:	6a 00                	push   $0x0
  pushl $125
801078c5:	6a 7d                	push   $0x7d
  jmp alltraps
801078c7:	e9 27 f5 ff ff       	jmp    80106df3 <alltraps>

801078cc <vector126>:
.globl vector126
vector126:
  pushl $0
801078cc:	6a 00                	push   $0x0
  pushl $126
801078ce:	6a 7e                	push   $0x7e
  jmp alltraps
801078d0:	e9 1e f5 ff ff       	jmp    80106df3 <alltraps>

801078d5 <vector127>:
.globl vector127
vector127:
  pushl $0
801078d5:	6a 00                	push   $0x0
  pushl $127
801078d7:	6a 7f                	push   $0x7f
  jmp alltraps
801078d9:	e9 15 f5 ff ff       	jmp    80106df3 <alltraps>

801078de <vector128>:
.globl vector128
vector128:
  pushl $0
801078de:	6a 00                	push   $0x0
  pushl $128
801078e0:	68 80 00 00 00       	push   $0x80
  jmp alltraps
801078e5:	e9 09 f5 ff ff       	jmp    80106df3 <alltraps>

801078ea <vector129>:
.globl vector129
vector129:
  pushl $0
801078ea:	6a 00                	push   $0x0
  pushl $129
801078ec:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801078f1:	e9 fd f4 ff ff       	jmp    80106df3 <alltraps>

801078f6 <vector130>:
.globl vector130
vector130:
  pushl $0
801078f6:	6a 00                	push   $0x0
  pushl $130
801078f8:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801078fd:	e9 f1 f4 ff ff       	jmp    80106df3 <alltraps>

80107902 <vector131>:
.globl vector131
vector131:
  pushl $0
80107902:	6a 00                	push   $0x0
  pushl $131
80107904:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107909:	e9 e5 f4 ff ff       	jmp    80106df3 <alltraps>

8010790e <vector132>:
.globl vector132
vector132:
  pushl $0
8010790e:	6a 00                	push   $0x0
  pushl $132
80107910:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80107915:	e9 d9 f4 ff ff       	jmp    80106df3 <alltraps>

8010791a <vector133>:
.globl vector133
vector133:
  pushl $0
8010791a:	6a 00                	push   $0x0
  pushl $133
8010791c:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80107921:	e9 cd f4 ff ff       	jmp    80106df3 <alltraps>

80107926 <vector134>:
.globl vector134
vector134:
  pushl $0
80107926:	6a 00                	push   $0x0
  pushl $134
80107928:	68 86 00 00 00       	push   $0x86
  jmp alltraps
8010792d:	e9 c1 f4 ff ff       	jmp    80106df3 <alltraps>

80107932 <vector135>:
.globl vector135
vector135:
  pushl $0
80107932:	6a 00                	push   $0x0
  pushl $135
80107934:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80107939:	e9 b5 f4 ff ff       	jmp    80106df3 <alltraps>

8010793e <vector136>:
.globl vector136
vector136:
  pushl $0
8010793e:	6a 00                	push   $0x0
  pushl $136
80107940:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80107945:	e9 a9 f4 ff ff       	jmp    80106df3 <alltraps>

8010794a <vector137>:
.globl vector137
vector137:
  pushl $0
8010794a:	6a 00                	push   $0x0
  pushl $137
8010794c:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80107951:	e9 9d f4 ff ff       	jmp    80106df3 <alltraps>

80107956 <vector138>:
.globl vector138
vector138:
  pushl $0
80107956:	6a 00                	push   $0x0
  pushl $138
80107958:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
8010795d:	e9 91 f4 ff ff       	jmp    80106df3 <alltraps>

80107962 <vector139>:
.globl vector139
vector139:
  pushl $0
80107962:	6a 00                	push   $0x0
  pushl $139
80107964:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80107969:	e9 85 f4 ff ff       	jmp    80106df3 <alltraps>

8010796e <vector140>:
.globl vector140
vector140:
  pushl $0
8010796e:	6a 00                	push   $0x0
  pushl $140
80107970:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80107975:	e9 79 f4 ff ff       	jmp    80106df3 <alltraps>

8010797a <vector141>:
.globl vector141
vector141:
  pushl $0
8010797a:	6a 00                	push   $0x0
  pushl $141
8010797c:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80107981:	e9 6d f4 ff ff       	jmp    80106df3 <alltraps>

80107986 <vector142>:
.globl vector142
vector142:
  pushl $0
80107986:	6a 00                	push   $0x0
  pushl $142
80107988:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
8010798d:	e9 61 f4 ff ff       	jmp    80106df3 <alltraps>

80107992 <vector143>:
.globl vector143
vector143:
  pushl $0
80107992:	6a 00                	push   $0x0
  pushl $143
80107994:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107999:	e9 55 f4 ff ff       	jmp    80106df3 <alltraps>

8010799e <vector144>:
.globl vector144
vector144:
  pushl $0
8010799e:	6a 00                	push   $0x0
  pushl $144
801079a0:	68 90 00 00 00       	push   $0x90
  jmp alltraps
801079a5:	e9 49 f4 ff ff       	jmp    80106df3 <alltraps>

801079aa <vector145>:
.globl vector145
vector145:
  pushl $0
801079aa:	6a 00                	push   $0x0
  pushl $145
801079ac:	68 91 00 00 00       	push   $0x91
  jmp alltraps
801079b1:	e9 3d f4 ff ff       	jmp    80106df3 <alltraps>

801079b6 <vector146>:
.globl vector146
vector146:
  pushl $0
801079b6:	6a 00                	push   $0x0
  pushl $146
801079b8:	68 92 00 00 00       	push   $0x92
  jmp alltraps
801079bd:	e9 31 f4 ff ff       	jmp    80106df3 <alltraps>

801079c2 <vector147>:
.globl vector147
vector147:
  pushl $0
801079c2:	6a 00                	push   $0x0
  pushl $147
801079c4:	68 93 00 00 00       	push   $0x93
  jmp alltraps
801079c9:	e9 25 f4 ff ff       	jmp    80106df3 <alltraps>

801079ce <vector148>:
.globl vector148
vector148:
  pushl $0
801079ce:	6a 00                	push   $0x0
  pushl $148
801079d0:	68 94 00 00 00       	push   $0x94
  jmp alltraps
801079d5:	e9 19 f4 ff ff       	jmp    80106df3 <alltraps>

801079da <vector149>:
.globl vector149
vector149:
  pushl $0
801079da:	6a 00                	push   $0x0
  pushl $149
801079dc:	68 95 00 00 00       	push   $0x95
  jmp alltraps
801079e1:	e9 0d f4 ff ff       	jmp    80106df3 <alltraps>

801079e6 <vector150>:
.globl vector150
vector150:
  pushl $0
801079e6:	6a 00                	push   $0x0
  pushl $150
801079e8:	68 96 00 00 00       	push   $0x96
  jmp alltraps
801079ed:	e9 01 f4 ff ff       	jmp    80106df3 <alltraps>

801079f2 <vector151>:
.globl vector151
vector151:
  pushl $0
801079f2:	6a 00                	push   $0x0
  pushl $151
801079f4:	68 97 00 00 00       	push   $0x97
  jmp alltraps
801079f9:	e9 f5 f3 ff ff       	jmp    80106df3 <alltraps>

801079fe <vector152>:
.globl vector152
vector152:
  pushl $0
801079fe:	6a 00                	push   $0x0
  pushl $152
80107a00:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107a05:	e9 e9 f3 ff ff       	jmp    80106df3 <alltraps>

80107a0a <vector153>:
.globl vector153
vector153:
  pushl $0
80107a0a:	6a 00                	push   $0x0
  pushl $153
80107a0c:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107a11:	e9 dd f3 ff ff       	jmp    80106df3 <alltraps>

80107a16 <vector154>:
.globl vector154
vector154:
  pushl $0
80107a16:	6a 00                	push   $0x0
  pushl $154
80107a18:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80107a1d:	e9 d1 f3 ff ff       	jmp    80106df3 <alltraps>

80107a22 <vector155>:
.globl vector155
vector155:
  pushl $0
80107a22:	6a 00                	push   $0x0
  pushl $155
80107a24:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107a29:	e9 c5 f3 ff ff       	jmp    80106df3 <alltraps>

80107a2e <vector156>:
.globl vector156
vector156:
  pushl $0
80107a2e:	6a 00                	push   $0x0
  pushl $156
80107a30:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107a35:	e9 b9 f3 ff ff       	jmp    80106df3 <alltraps>

80107a3a <vector157>:
.globl vector157
vector157:
  pushl $0
80107a3a:	6a 00                	push   $0x0
  pushl $157
80107a3c:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80107a41:	e9 ad f3 ff ff       	jmp    80106df3 <alltraps>

80107a46 <vector158>:
.globl vector158
vector158:
  pushl $0
80107a46:	6a 00                	push   $0x0
  pushl $158
80107a48:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107a4d:	e9 a1 f3 ff ff       	jmp    80106df3 <alltraps>

80107a52 <vector159>:
.globl vector159
vector159:
  pushl $0
80107a52:	6a 00                	push   $0x0
  pushl $159
80107a54:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107a59:	e9 95 f3 ff ff       	jmp    80106df3 <alltraps>

80107a5e <vector160>:
.globl vector160
vector160:
  pushl $0
80107a5e:	6a 00                	push   $0x0
  pushl $160
80107a60:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80107a65:	e9 89 f3 ff ff       	jmp    80106df3 <alltraps>

80107a6a <vector161>:
.globl vector161
vector161:
  pushl $0
80107a6a:	6a 00                	push   $0x0
  pushl $161
80107a6c:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80107a71:	e9 7d f3 ff ff       	jmp    80106df3 <alltraps>

80107a76 <vector162>:
.globl vector162
vector162:
  pushl $0
80107a76:	6a 00                	push   $0x0
  pushl $162
80107a78:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107a7d:	e9 71 f3 ff ff       	jmp    80106df3 <alltraps>

80107a82 <vector163>:
.globl vector163
vector163:
  pushl $0
80107a82:	6a 00                	push   $0x0
  pushl $163
80107a84:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107a89:	e9 65 f3 ff ff       	jmp    80106df3 <alltraps>

80107a8e <vector164>:
.globl vector164
vector164:
  pushl $0
80107a8e:	6a 00                	push   $0x0
  pushl $164
80107a90:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80107a95:	e9 59 f3 ff ff       	jmp    80106df3 <alltraps>

80107a9a <vector165>:
.globl vector165
vector165:
  pushl $0
80107a9a:	6a 00                	push   $0x0
  pushl $165
80107a9c:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107aa1:	e9 4d f3 ff ff       	jmp    80106df3 <alltraps>

80107aa6 <vector166>:
.globl vector166
vector166:
  pushl $0
80107aa6:	6a 00                	push   $0x0
  pushl $166
80107aa8:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107aad:	e9 41 f3 ff ff       	jmp    80106df3 <alltraps>

80107ab2 <vector167>:
.globl vector167
vector167:
  pushl $0
80107ab2:	6a 00                	push   $0x0
  pushl $167
80107ab4:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107ab9:	e9 35 f3 ff ff       	jmp    80106df3 <alltraps>

80107abe <vector168>:
.globl vector168
vector168:
  pushl $0
80107abe:	6a 00                	push   $0x0
  pushl $168
80107ac0:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107ac5:	e9 29 f3 ff ff       	jmp    80106df3 <alltraps>

80107aca <vector169>:
.globl vector169
vector169:
  pushl $0
80107aca:	6a 00                	push   $0x0
  pushl $169
80107acc:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107ad1:	e9 1d f3 ff ff       	jmp    80106df3 <alltraps>

80107ad6 <vector170>:
.globl vector170
vector170:
  pushl $0
80107ad6:	6a 00                	push   $0x0
  pushl $170
80107ad8:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107add:	e9 11 f3 ff ff       	jmp    80106df3 <alltraps>

80107ae2 <vector171>:
.globl vector171
vector171:
  pushl $0
80107ae2:	6a 00                	push   $0x0
  pushl $171
80107ae4:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107ae9:	e9 05 f3 ff ff       	jmp    80106df3 <alltraps>

80107aee <vector172>:
.globl vector172
vector172:
  pushl $0
80107aee:	6a 00                	push   $0x0
  pushl $172
80107af0:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107af5:	e9 f9 f2 ff ff       	jmp    80106df3 <alltraps>

80107afa <vector173>:
.globl vector173
vector173:
  pushl $0
80107afa:	6a 00                	push   $0x0
  pushl $173
80107afc:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107b01:	e9 ed f2 ff ff       	jmp    80106df3 <alltraps>

80107b06 <vector174>:
.globl vector174
vector174:
  pushl $0
80107b06:	6a 00                	push   $0x0
  pushl $174
80107b08:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107b0d:	e9 e1 f2 ff ff       	jmp    80106df3 <alltraps>

80107b12 <vector175>:
.globl vector175
vector175:
  pushl $0
80107b12:	6a 00                	push   $0x0
  pushl $175
80107b14:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107b19:	e9 d5 f2 ff ff       	jmp    80106df3 <alltraps>

80107b1e <vector176>:
.globl vector176
vector176:
  pushl $0
80107b1e:	6a 00                	push   $0x0
  pushl $176
80107b20:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107b25:	e9 c9 f2 ff ff       	jmp    80106df3 <alltraps>

80107b2a <vector177>:
.globl vector177
vector177:
  pushl $0
80107b2a:	6a 00                	push   $0x0
  pushl $177
80107b2c:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107b31:	e9 bd f2 ff ff       	jmp    80106df3 <alltraps>

80107b36 <vector178>:
.globl vector178
vector178:
  pushl $0
80107b36:	6a 00                	push   $0x0
  pushl $178
80107b38:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107b3d:	e9 b1 f2 ff ff       	jmp    80106df3 <alltraps>

80107b42 <vector179>:
.globl vector179
vector179:
  pushl $0
80107b42:	6a 00                	push   $0x0
  pushl $179
80107b44:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107b49:	e9 a5 f2 ff ff       	jmp    80106df3 <alltraps>

80107b4e <vector180>:
.globl vector180
vector180:
  pushl $0
80107b4e:	6a 00                	push   $0x0
  pushl $180
80107b50:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107b55:	e9 99 f2 ff ff       	jmp    80106df3 <alltraps>

80107b5a <vector181>:
.globl vector181
vector181:
  pushl $0
80107b5a:	6a 00                	push   $0x0
  pushl $181
80107b5c:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107b61:	e9 8d f2 ff ff       	jmp    80106df3 <alltraps>

80107b66 <vector182>:
.globl vector182
vector182:
  pushl $0
80107b66:	6a 00                	push   $0x0
  pushl $182
80107b68:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107b6d:	e9 81 f2 ff ff       	jmp    80106df3 <alltraps>

80107b72 <vector183>:
.globl vector183
vector183:
  pushl $0
80107b72:	6a 00                	push   $0x0
  pushl $183
80107b74:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107b79:	e9 75 f2 ff ff       	jmp    80106df3 <alltraps>

80107b7e <vector184>:
.globl vector184
vector184:
  pushl $0
80107b7e:	6a 00                	push   $0x0
  pushl $184
80107b80:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80107b85:	e9 69 f2 ff ff       	jmp    80106df3 <alltraps>

80107b8a <vector185>:
.globl vector185
vector185:
  pushl $0
80107b8a:	6a 00                	push   $0x0
  pushl $185
80107b8c:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107b91:	e9 5d f2 ff ff       	jmp    80106df3 <alltraps>

80107b96 <vector186>:
.globl vector186
vector186:
  pushl $0
80107b96:	6a 00                	push   $0x0
  pushl $186
80107b98:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107b9d:	e9 51 f2 ff ff       	jmp    80106df3 <alltraps>

80107ba2 <vector187>:
.globl vector187
vector187:
  pushl $0
80107ba2:	6a 00                	push   $0x0
  pushl $187
80107ba4:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107ba9:	e9 45 f2 ff ff       	jmp    80106df3 <alltraps>

80107bae <vector188>:
.globl vector188
vector188:
  pushl $0
80107bae:	6a 00                	push   $0x0
  pushl $188
80107bb0:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80107bb5:	e9 39 f2 ff ff       	jmp    80106df3 <alltraps>

80107bba <vector189>:
.globl vector189
vector189:
  pushl $0
80107bba:	6a 00                	push   $0x0
  pushl $189
80107bbc:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80107bc1:	e9 2d f2 ff ff       	jmp    80106df3 <alltraps>

80107bc6 <vector190>:
.globl vector190
vector190:
  pushl $0
80107bc6:	6a 00                	push   $0x0
  pushl $190
80107bc8:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107bcd:	e9 21 f2 ff ff       	jmp    80106df3 <alltraps>

80107bd2 <vector191>:
.globl vector191
vector191:
  pushl $0
80107bd2:	6a 00                	push   $0x0
  pushl $191
80107bd4:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107bd9:	e9 15 f2 ff ff       	jmp    80106df3 <alltraps>

80107bde <vector192>:
.globl vector192
vector192:
  pushl $0
80107bde:	6a 00                	push   $0x0
  pushl $192
80107be0:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107be5:	e9 09 f2 ff ff       	jmp    80106df3 <alltraps>

80107bea <vector193>:
.globl vector193
vector193:
  pushl $0
80107bea:	6a 00                	push   $0x0
  pushl $193
80107bec:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107bf1:	e9 fd f1 ff ff       	jmp    80106df3 <alltraps>

80107bf6 <vector194>:
.globl vector194
vector194:
  pushl $0
80107bf6:	6a 00                	push   $0x0
  pushl $194
80107bf8:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80107bfd:	e9 f1 f1 ff ff       	jmp    80106df3 <alltraps>

80107c02 <vector195>:
.globl vector195
vector195:
  pushl $0
80107c02:	6a 00                	push   $0x0
  pushl $195
80107c04:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107c09:	e9 e5 f1 ff ff       	jmp    80106df3 <alltraps>

80107c0e <vector196>:
.globl vector196
vector196:
  pushl $0
80107c0e:	6a 00                	push   $0x0
  pushl $196
80107c10:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107c15:	e9 d9 f1 ff ff       	jmp    80106df3 <alltraps>

80107c1a <vector197>:
.globl vector197
vector197:
  pushl $0
80107c1a:	6a 00                	push   $0x0
  pushl $197
80107c1c:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107c21:	e9 cd f1 ff ff       	jmp    80106df3 <alltraps>

80107c26 <vector198>:
.globl vector198
vector198:
  pushl $0
80107c26:	6a 00                	push   $0x0
  pushl $198
80107c28:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107c2d:	e9 c1 f1 ff ff       	jmp    80106df3 <alltraps>

80107c32 <vector199>:
.globl vector199
vector199:
  pushl $0
80107c32:	6a 00                	push   $0x0
  pushl $199
80107c34:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107c39:	e9 b5 f1 ff ff       	jmp    80106df3 <alltraps>

80107c3e <vector200>:
.globl vector200
vector200:
  pushl $0
80107c3e:	6a 00                	push   $0x0
  pushl $200
80107c40:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107c45:	e9 a9 f1 ff ff       	jmp    80106df3 <alltraps>

80107c4a <vector201>:
.globl vector201
vector201:
  pushl $0
80107c4a:	6a 00                	push   $0x0
  pushl $201
80107c4c:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80107c51:	e9 9d f1 ff ff       	jmp    80106df3 <alltraps>

80107c56 <vector202>:
.globl vector202
vector202:
  pushl $0
80107c56:	6a 00                	push   $0x0
  pushl $202
80107c58:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107c5d:	e9 91 f1 ff ff       	jmp    80106df3 <alltraps>

80107c62 <vector203>:
.globl vector203
vector203:
  pushl $0
80107c62:	6a 00                	push   $0x0
  pushl $203
80107c64:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107c69:	e9 85 f1 ff ff       	jmp    80106df3 <alltraps>

80107c6e <vector204>:
.globl vector204
vector204:
  pushl $0
80107c6e:	6a 00                	push   $0x0
  pushl $204
80107c70:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80107c75:	e9 79 f1 ff ff       	jmp    80106df3 <alltraps>

80107c7a <vector205>:
.globl vector205
vector205:
  pushl $0
80107c7a:	6a 00                	push   $0x0
  pushl $205
80107c7c:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107c81:	e9 6d f1 ff ff       	jmp    80106df3 <alltraps>

80107c86 <vector206>:
.globl vector206
vector206:
  pushl $0
80107c86:	6a 00                	push   $0x0
  pushl $206
80107c88:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107c8d:	e9 61 f1 ff ff       	jmp    80106df3 <alltraps>

80107c92 <vector207>:
.globl vector207
vector207:
  pushl $0
80107c92:	6a 00                	push   $0x0
  pushl $207
80107c94:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107c99:	e9 55 f1 ff ff       	jmp    80106df3 <alltraps>

80107c9e <vector208>:
.globl vector208
vector208:
  pushl $0
80107c9e:	6a 00                	push   $0x0
  pushl $208
80107ca0:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80107ca5:	e9 49 f1 ff ff       	jmp    80106df3 <alltraps>

80107caa <vector209>:
.globl vector209
vector209:
  pushl $0
80107caa:	6a 00                	push   $0x0
  pushl $209
80107cac:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80107cb1:	e9 3d f1 ff ff       	jmp    80106df3 <alltraps>

80107cb6 <vector210>:
.globl vector210
vector210:
  pushl $0
80107cb6:	6a 00                	push   $0x0
  pushl $210
80107cb8:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80107cbd:	e9 31 f1 ff ff       	jmp    80106df3 <alltraps>

80107cc2 <vector211>:
.globl vector211
vector211:
  pushl $0
80107cc2:	6a 00                	push   $0x0
  pushl $211
80107cc4:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107cc9:	e9 25 f1 ff ff       	jmp    80106df3 <alltraps>

80107cce <vector212>:
.globl vector212
vector212:
  pushl $0
80107cce:	6a 00                	push   $0x0
  pushl $212
80107cd0:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107cd5:	e9 19 f1 ff ff       	jmp    80106df3 <alltraps>

80107cda <vector213>:
.globl vector213
vector213:
  pushl $0
80107cda:	6a 00                	push   $0x0
  pushl $213
80107cdc:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107ce1:	e9 0d f1 ff ff       	jmp    80106df3 <alltraps>

80107ce6 <vector214>:
.globl vector214
vector214:
  pushl $0
80107ce6:	6a 00                	push   $0x0
  pushl $214
80107ce8:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80107ced:	e9 01 f1 ff ff       	jmp    80106df3 <alltraps>

80107cf2 <vector215>:
.globl vector215
vector215:
  pushl $0
80107cf2:	6a 00                	push   $0x0
  pushl $215
80107cf4:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107cf9:	e9 f5 f0 ff ff       	jmp    80106df3 <alltraps>

80107cfe <vector216>:
.globl vector216
vector216:
  pushl $0
80107cfe:	6a 00                	push   $0x0
  pushl $216
80107d00:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107d05:	e9 e9 f0 ff ff       	jmp    80106df3 <alltraps>

80107d0a <vector217>:
.globl vector217
vector217:
  pushl $0
80107d0a:	6a 00                	push   $0x0
  pushl $217
80107d0c:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107d11:	e9 dd f0 ff ff       	jmp    80106df3 <alltraps>

80107d16 <vector218>:
.globl vector218
vector218:
  pushl $0
80107d16:	6a 00                	push   $0x0
  pushl $218
80107d18:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80107d1d:	e9 d1 f0 ff ff       	jmp    80106df3 <alltraps>

80107d22 <vector219>:
.globl vector219
vector219:
  pushl $0
80107d22:	6a 00                	push   $0x0
  pushl $219
80107d24:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107d29:	e9 c5 f0 ff ff       	jmp    80106df3 <alltraps>

80107d2e <vector220>:
.globl vector220
vector220:
  pushl $0
80107d2e:	6a 00                	push   $0x0
  pushl $220
80107d30:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107d35:	e9 b9 f0 ff ff       	jmp    80106df3 <alltraps>

80107d3a <vector221>:
.globl vector221
vector221:
  pushl $0
80107d3a:	6a 00                	push   $0x0
  pushl $221
80107d3c:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80107d41:	e9 ad f0 ff ff       	jmp    80106df3 <alltraps>

80107d46 <vector222>:
.globl vector222
vector222:
  pushl $0
80107d46:	6a 00                	push   $0x0
  pushl $222
80107d48:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80107d4d:	e9 a1 f0 ff ff       	jmp    80106df3 <alltraps>

80107d52 <vector223>:
.globl vector223
vector223:
  pushl $0
80107d52:	6a 00                	push   $0x0
  pushl $223
80107d54:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107d59:	e9 95 f0 ff ff       	jmp    80106df3 <alltraps>

80107d5e <vector224>:
.globl vector224
vector224:
  pushl $0
80107d5e:	6a 00                	push   $0x0
  pushl $224
80107d60:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80107d65:	e9 89 f0 ff ff       	jmp    80106df3 <alltraps>

80107d6a <vector225>:
.globl vector225
vector225:
  pushl $0
80107d6a:	6a 00                	push   $0x0
  pushl $225
80107d6c:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80107d71:	e9 7d f0 ff ff       	jmp    80106df3 <alltraps>

80107d76 <vector226>:
.globl vector226
vector226:
  pushl $0
80107d76:	6a 00                	push   $0x0
  pushl $226
80107d78:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107d7d:	e9 71 f0 ff ff       	jmp    80106df3 <alltraps>

80107d82 <vector227>:
.globl vector227
vector227:
  pushl $0
80107d82:	6a 00                	push   $0x0
  pushl $227
80107d84:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80107d89:	e9 65 f0 ff ff       	jmp    80106df3 <alltraps>

80107d8e <vector228>:
.globl vector228
vector228:
  pushl $0
80107d8e:	6a 00                	push   $0x0
  pushl $228
80107d90:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80107d95:	e9 59 f0 ff ff       	jmp    80106df3 <alltraps>

80107d9a <vector229>:
.globl vector229
vector229:
  pushl $0
80107d9a:	6a 00                	push   $0x0
  pushl $229
80107d9c:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80107da1:	e9 4d f0 ff ff       	jmp    80106df3 <alltraps>

80107da6 <vector230>:
.globl vector230
vector230:
  pushl $0
80107da6:	6a 00                	push   $0x0
  pushl $230
80107da8:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80107dad:	e9 41 f0 ff ff       	jmp    80106df3 <alltraps>

80107db2 <vector231>:
.globl vector231
vector231:
  pushl $0
80107db2:	6a 00                	push   $0x0
  pushl $231
80107db4:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80107db9:	e9 35 f0 ff ff       	jmp    80106df3 <alltraps>

80107dbe <vector232>:
.globl vector232
vector232:
  pushl $0
80107dbe:	6a 00                	push   $0x0
  pushl $232
80107dc0:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80107dc5:	e9 29 f0 ff ff       	jmp    80106df3 <alltraps>

80107dca <vector233>:
.globl vector233
vector233:
  pushl $0
80107dca:	6a 00                	push   $0x0
  pushl $233
80107dcc:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80107dd1:	e9 1d f0 ff ff       	jmp    80106df3 <alltraps>

80107dd6 <vector234>:
.globl vector234
vector234:
  pushl $0
80107dd6:	6a 00                	push   $0x0
  pushl $234
80107dd8:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80107ddd:	e9 11 f0 ff ff       	jmp    80106df3 <alltraps>

80107de2 <vector235>:
.globl vector235
vector235:
  pushl $0
80107de2:	6a 00                	push   $0x0
  pushl $235
80107de4:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107de9:	e9 05 f0 ff ff       	jmp    80106df3 <alltraps>

80107dee <vector236>:
.globl vector236
vector236:
  pushl $0
80107dee:	6a 00                	push   $0x0
  pushl $236
80107df0:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80107df5:	e9 f9 ef ff ff       	jmp    80106df3 <alltraps>

80107dfa <vector237>:
.globl vector237
vector237:
  pushl $0
80107dfa:	6a 00                	push   $0x0
  pushl $237
80107dfc:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107e01:	e9 ed ef ff ff       	jmp    80106df3 <alltraps>

80107e06 <vector238>:
.globl vector238
vector238:
  pushl $0
80107e06:	6a 00                	push   $0x0
  pushl $238
80107e08:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107e0d:	e9 e1 ef ff ff       	jmp    80106df3 <alltraps>

80107e12 <vector239>:
.globl vector239
vector239:
  pushl $0
80107e12:	6a 00                	push   $0x0
  pushl $239
80107e14:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107e19:	e9 d5 ef ff ff       	jmp    80106df3 <alltraps>

80107e1e <vector240>:
.globl vector240
vector240:
  pushl $0
80107e1e:	6a 00                	push   $0x0
  pushl $240
80107e20:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107e25:	e9 c9 ef ff ff       	jmp    80106df3 <alltraps>

80107e2a <vector241>:
.globl vector241
vector241:
  pushl $0
80107e2a:	6a 00                	push   $0x0
  pushl $241
80107e2c:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80107e31:	e9 bd ef ff ff       	jmp    80106df3 <alltraps>

80107e36 <vector242>:
.globl vector242
vector242:
  pushl $0
80107e36:	6a 00                	push   $0x0
  pushl $242
80107e38:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80107e3d:	e9 b1 ef ff ff       	jmp    80106df3 <alltraps>

80107e42 <vector243>:
.globl vector243
vector243:
  pushl $0
80107e42:	6a 00                	push   $0x0
  pushl $243
80107e44:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107e49:	e9 a5 ef ff ff       	jmp    80106df3 <alltraps>

80107e4e <vector244>:
.globl vector244
vector244:
  pushl $0
80107e4e:	6a 00                	push   $0x0
  pushl $244
80107e50:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80107e55:	e9 99 ef ff ff       	jmp    80106df3 <alltraps>

80107e5a <vector245>:
.globl vector245
vector245:
  pushl $0
80107e5a:	6a 00                	push   $0x0
  pushl $245
80107e5c:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80107e61:	e9 8d ef ff ff       	jmp    80106df3 <alltraps>

80107e66 <vector246>:
.globl vector246
vector246:
  pushl $0
80107e66:	6a 00                	push   $0x0
  pushl $246
80107e68:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80107e6d:	e9 81 ef ff ff       	jmp    80106df3 <alltraps>

80107e72 <vector247>:
.globl vector247
vector247:
  pushl $0
80107e72:	6a 00                	push   $0x0
  pushl $247
80107e74:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80107e79:	e9 75 ef ff ff       	jmp    80106df3 <alltraps>

80107e7e <vector248>:
.globl vector248
vector248:
  pushl $0
80107e7e:	6a 00                	push   $0x0
  pushl $248
80107e80:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80107e85:	e9 69 ef ff ff       	jmp    80106df3 <alltraps>

80107e8a <vector249>:
.globl vector249
vector249:
  pushl $0
80107e8a:	6a 00                	push   $0x0
  pushl $249
80107e8c:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80107e91:	e9 5d ef ff ff       	jmp    80106df3 <alltraps>

80107e96 <vector250>:
.globl vector250
vector250:
  pushl $0
80107e96:	6a 00                	push   $0x0
  pushl $250
80107e98:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80107e9d:	e9 51 ef ff ff       	jmp    80106df3 <alltraps>

80107ea2 <vector251>:
.globl vector251
vector251:
  pushl $0
80107ea2:	6a 00                	push   $0x0
  pushl $251
80107ea4:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80107ea9:	e9 45 ef ff ff       	jmp    80106df3 <alltraps>

80107eae <vector252>:
.globl vector252
vector252:
  pushl $0
80107eae:	6a 00                	push   $0x0
  pushl $252
80107eb0:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80107eb5:	e9 39 ef ff ff       	jmp    80106df3 <alltraps>

80107eba <vector253>:
.globl vector253
vector253:
  pushl $0
80107eba:	6a 00                	push   $0x0
  pushl $253
80107ebc:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80107ec1:	e9 2d ef ff ff       	jmp    80106df3 <alltraps>

80107ec6 <vector254>:
.globl vector254
vector254:
  pushl $0
80107ec6:	6a 00                	push   $0x0
  pushl $254
80107ec8:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80107ecd:	e9 21 ef ff ff       	jmp    80106df3 <alltraps>

80107ed2 <vector255>:
.globl vector255
vector255:
  pushl $0
80107ed2:	6a 00                	push   $0x0
  pushl $255
80107ed4:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107ed9:	e9 15 ef ff ff       	jmp    80106df3 <alltraps>

80107ede <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80107ede:	55                   	push   %ebp
80107edf:	89 e5                	mov    %esp,%ebp
80107ee1:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107ee4:	8b 45 0c             	mov    0xc(%ebp),%eax
80107ee7:	83 e8 01             	sub    $0x1,%eax
80107eea:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107eee:	8b 45 08             	mov    0x8(%ebp),%eax
80107ef1:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107ef5:	8b 45 08             	mov    0x8(%ebp),%eax
80107ef8:	c1 e8 10             	shr    $0x10,%eax
80107efb:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80107eff:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107f02:	0f 01 10             	lgdtl  (%eax)
}
80107f05:	c9                   	leave  
80107f06:	c3                   	ret    

80107f07 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107f07:	55                   	push   %ebp
80107f08:	89 e5                	mov    %esp,%ebp
80107f0a:	83 ec 04             	sub    $0x4,%esp
80107f0d:	8b 45 08             	mov    0x8(%ebp),%eax
80107f10:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107f14:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107f18:	0f 00 d8             	ltr    %ax
}
80107f1b:	c9                   	leave  
80107f1c:	c3                   	ret    

80107f1d <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80107f1d:	55                   	push   %ebp
80107f1e:	89 e5                	mov    %esp,%ebp
80107f20:	83 ec 04             	sub    $0x4,%esp
80107f23:	8b 45 08             	mov    0x8(%ebp),%eax
80107f26:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80107f2a:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107f2e:	8e e8                	mov    %eax,%gs
}
80107f30:	c9                   	leave  
80107f31:	c3                   	ret    

80107f32 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80107f32:	55                   	push   %ebp
80107f33:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80107f35:	8b 45 08             	mov    0x8(%ebp),%eax
80107f38:	0f 22 d8             	mov    %eax,%cr3
}
80107f3b:	5d                   	pop    %ebp
80107f3c:	c3                   	ret    

80107f3d <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80107f3d:	55                   	push   %ebp
80107f3e:	89 e5                	mov    %esp,%ebp
80107f40:	8b 45 08             	mov    0x8(%ebp),%eax
80107f43:	05 00 00 00 80       	add    $0x80000000,%eax
80107f48:	5d                   	pop    %ebp
80107f49:	c3                   	ret    

80107f4a <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80107f4a:	55                   	push   %ebp
80107f4b:	89 e5                	mov    %esp,%ebp
80107f4d:	8b 45 08             	mov    0x8(%ebp),%eax
80107f50:	05 00 00 00 80       	add    $0x80000000,%eax
80107f55:	5d                   	pop    %ebp
80107f56:	c3                   	ret    

80107f57 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80107f57:	55                   	push   %ebp
80107f58:	89 e5                	mov    %esp,%ebp
80107f5a:	53                   	push   %ebx
80107f5b:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80107f5e:	e8 5f b0 ff ff       	call   80102fc2 <cpunum>
80107f63:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80107f69:	05 a0 33 11 80       	add    $0x801133a0,%eax
80107f6e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80107f71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f74:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80107f7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f7d:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80107f83:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f86:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80107f8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f8d:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107f91:	83 e2 f0             	and    $0xfffffff0,%edx
80107f94:	83 ca 0a             	or     $0xa,%edx
80107f97:	88 50 7d             	mov    %dl,0x7d(%eax)
80107f9a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f9d:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107fa1:	83 ca 10             	or     $0x10,%edx
80107fa4:	88 50 7d             	mov    %dl,0x7d(%eax)
80107fa7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107faa:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107fae:	83 e2 9f             	and    $0xffffff9f,%edx
80107fb1:	88 50 7d             	mov    %dl,0x7d(%eax)
80107fb4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fb7:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107fbb:	83 ca 80             	or     $0xffffff80,%edx
80107fbe:	88 50 7d             	mov    %dl,0x7d(%eax)
80107fc1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fc4:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107fc8:	83 ca 0f             	or     $0xf,%edx
80107fcb:	88 50 7e             	mov    %dl,0x7e(%eax)
80107fce:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fd1:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107fd5:	83 e2 ef             	and    $0xffffffef,%edx
80107fd8:	88 50 7e             	mov    %dl,0x7e(%eax)
80107fdb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fde:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107fe2:	83 e2 df             	and    $0xffffffdf,%edx
80107fe5:	88 50 7e             	mov    %dl,0x7e(%eax)
80107fe8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107feb:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107fef:	83 ca 40             	or     $0x40,%edx
80107ff2:	88 50 7e             	mov    %dl,0x7e(%eax)
80107ff5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ff8:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107ffc:	83 ca 80             	or     $0xffffff80,%edx
80107fff:	88 50 7e             	mov    %dl,0x7e(%eax)
80108002:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108005:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80108009:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010800c:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80108013:	ff ff 
80108015:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108018:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
8010801f:	00 00 
80108021:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108024:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
8010802b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010802e:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108035:	83 e2 f0             	and    $0xfffffff0,%edx
80108038:	83 ca 02             	or     $0x2,%edx
8010803b:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108041:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108044:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010804b:	83 ca 10             	or     $0x10,%edx
8010804e:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108054:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108057:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010805e:	83 e2 9f             	and    $0xffffff9f,%edx
80108061:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108067:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010806a:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108071:	83 ca 80             	or     $0xffffff80,%edx
80108074:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010807a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010807d:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108084:	83 ca 0f             	or     $0xf,%edx
80108087:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010808d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108090:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108097:	83 e2 ef             	and    $0xffffffef,%edx
8010809a:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801080a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080a3:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801080aa:	83 e2 df             	and    $0xffffffdf,%edx
801080ad:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801080b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080b6:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801080bd:	83 ca 40             	or     $0x40,%edx
801080c0:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801080c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080c9:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801080d0:	83 ca 80             	or     $0xffffff80,%edx
801080d3:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801080d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080dc:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
801080e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080e6:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
801080ed:	ff ff 
801080ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080f2:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
801080f9:	00 00 
801080fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080fe:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80108105:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108108:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010810f:	83 e2 f0             	and    $0xfffffff0,%edx
80108112:	83 ca 0a             	or     $0xa,%edx
80108115:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010811b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010811e:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108125:	83 ca 10             	or     $0x10,%edx
80108128:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010812e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108131:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108138:	83 ca 60             	or     $0x60,%edx
8010813b:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108141:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108144:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010814b:	83 ca 80             	or     $0xffffff80,%edx
8010814e:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108154:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108157:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010815e:	83 ca 0f             	or     $0xf,%edx
80108161:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108167:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010816a:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108171:	83 e2 ef             	and    $0xffffffef,%edx
80108174:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010817a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010817d:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108184:	83 e2 df             	and    $0xffffffdf,%edx
80108187:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010818d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108190:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108197:	83 ca 40             	or     $0x40,%edx
8010819a:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801081a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081a3:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801081aa:	83 ca 80             	or     $0xffffff80,%edx
801081ad:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801081b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081b6:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
801081bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081c0:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
801081c7:	ff ff 
801081c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081cc:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
801081d3:	00 00 
801081d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081d8:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
801081df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081e2:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801081e9:	83 e2 f0             	and    $0xfffffff0,%edx
801081ec:	83 ca 02             	or     $0x2,%edx
801081ef:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801081f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081f8:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801081ff:	83 ca 10             	or     $0x10,%edx
80108202:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108208:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010820b:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108212:	83 ca 60             	or     $0x60,%edx
80108215:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010821b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010821e:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108225:	83 ca 80             	or     $0xffffff80,%edx
80108228:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010822e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108231:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108238:	83 ca 0f             	or     $0xf,%edx
8010823b:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108241:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108244:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010824b:	83 e2 ef             	and    $0xffffffef,%edx
8010824e:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108254:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108257:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010825e:	83 e2 df             	and    $0xffffffdf,%edx
80108261:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108267:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010826a:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108271:	83 ca 40             	or     $0x40,%edx
80108274:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010827a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010827d:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108284:	83 ca 80             	or     $0xffffff80,%edx
80108287:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010828d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108290:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80108297:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010829a:	05 b4 00 00 00       	add    $0xb4,%eax
8010829f:	89 c3                	mov    %eax,%ebx
801082a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082a4:	05 b4 00 00 00       	add    $0xb4,%eax
801082a9:	c1 e8 10             	shr    $0x10,%eax
801082ac:	89 c1                	mov    %eax,%ecx
801082ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082b1:	05 b4 00 00 00       	add    $0xb4,%eax
801082b6:	c1 e8 18             	shr    $0x18,%eax
801082b9:	89 c2                	mov    %eax,%edx
801082bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082be:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
801082c5:	00 00 
801082c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082ca:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
801082d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082d4:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
801082da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082dd:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801082e4:	83 e1 f0             	and    $0xfffffff0,%ecx
801082e7:	83 c9 02             	or     $0x2,%ecx
801082ea:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801082f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082f3:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801082fa:	83 c9 10             	or     $0x10,%ecx
801082fd:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108303:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108306:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010830d:	83 e1 9f             	and    $0xffffff9f,%ecx
80108310:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108316:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108319:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108320:	83 c9 80             	or     $0xffffff80,%ecx
80108323:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108329:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010832c:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108333:	83 e1 f0             	and    $0xfffffff0,%ecx
80108336:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010833c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010833f:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108346:	83 e1 ef             	and    $0xffffffef,%ecx
80108349:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010834f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108352:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108359:	83 e1 df             	and    $0xffffffdf,%ecx
8010835c:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108362:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108365:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010836c:	83 c9 40             	or     $0x40,%ecx
8010836f:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108375:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108378:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010837f:	83 c9 80             	or     $0xffffff80,%ecx
80108382:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108388:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010838b:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80108391:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108394:	83 c0 70             	add    $0x70,%eax
80108397:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
8010839e:	00 
8010839f:	89 04 24             	mov    %eax,(%esp)
801083a2:	e8 37 fb ff ff       	call   80107ede <lgdt>
  loadgs(SEG_KCPU << 3);
801083a7:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
801083ae:	e8 6a fb ff ff       	call   80107f1d <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
801083b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083b6:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
801083bc:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
801083c3:	00 00 00 00 
}
801083c7:	83 c4 24             	add    $0x24,%esp
801083ca:	5b                   	pop    %ebx
801083cb:	5d                   	pop    %ebp
801083cc:	c3                   	ret    

801083cd <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
801083cd:	55                   	push   %ebp
801083ce:	89 e5                	mov    %esp,%ebp
801083d0:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
801083d3:	8b 45 0c             	mov    0xc(%ebp),%eax
801083d6:	c1 e8 16             	shr    $0x16,%eax
801083d9:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801083e0:	8b 45 08             	mov    0x8(%ebp),%eax
801083e3:	01 d0                	add    %edx,%eax
801083e5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
801083e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801083eb:	8b 00                	mov    (%eax),%eax
801083ed:	83 e0 01             	and    $0x1,%eax
801083f0:	85 c0                	test   %eax,%eax
801083f2:	74 17                	je     8010840b <walkpgdir+0x3e>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
801083f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801083f7:	8b 00                	mov    (%eax),%eax
801083f9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801083fe:	89 04 24             	mov    %eax,(%esp)
80108401:	e8 44 fb ff ff       	call   80107f4a <p2v>
80108406:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108409:	eb 4b                	jmp    80108456 <walkpgdir+0x89>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
8010840b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010840f:	74 0e                	je     8010841f <walkpgdir+0x52>
80108411:	e8 16 a8 ff ff       	call   80102c2c <kalloc>
80108416:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108419:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010841d:	75 07                	jne    80108426 <walkpgdir+0x59>
      return 0;
8010841f:	b8 00 00 00 00       	mov    $0x0,%eax
80108424:	eb 47                	jmp    8010846d <walkpgdir+0xa0>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80108426:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010842d:	00 
8010842e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108435:	00 
80108436:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108439:	89 04 24             	mov    %eax,(%esp)
8010843c:	e8 58 d5 ff ff       	call   80105999 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80108441:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108444:	89 04 24             	mov    %eax,(%esp)
80108447:	e8 f1 fa ff ff       	call   80107f3d <v2p>
8010844c:	83 c8 07             	or     $0x7,%eax
8010844f:	89 c2                	mov    %eax,%edx
80108451:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108454:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80108456:	8b 45 0c             	mov    0xc(%ebp),%eax
80108459:	c1 e8 0c             	shr    $0xc,%eax
8010845c:	25 ff 03 00 00       	and    $0x3ff,%eax
80108461:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108468:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010846b:	01 d0                	add    %edx,%eax
}
8010846d:	c9                   	leave  
8010846e:	c3                   	ret    

8010846f <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
8010846f:	55                   	push   %ebp
80108470:	89 e5                	mov    %esp,%ebp
80108472:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80108475:	8b 45 0c             	mov    0xc(%ebp),%eax
80108478:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010847d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80108480:	8b 55 0c             	mov    0xc(%ebp),%edx
80108483:	8b 45 10             	mov    0x10(%ebp),%eax
80108486:	01 d0                	add    %edx,%eax
80108488:	83 e8 01             	sub    $0x1,%eax
8010848b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108490:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80108493:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
8010849a:	00 
8010849b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010849e:	89 44 24 04          	mov    %eax,0x4(%esp)
801084a2:	8b 45 08             	mov    0x8(%ebp),%eax
801084a5:	89 04 24             	mov    %eax,(%esp)
801084a8:	e8 20 ff ff ff       	call   801083cd <walkpgdir>
801084ad:	89 45 ec             	mov    %eax,-0x14(%ebp)
801084b0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801084b4:	75 07                	jne    801084bd <mappages+0x4e>
      return -1;
801084b6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801084bb:	eb 48                	jmp    80108505 <mappages+0x96>
    if(*pte & PTE_P)
801084bd:	8b 45 ec             	mov    -0x14(%ebp),%eax
801084c0:	8b 00                	mov    (%eax),%eax
801084c2:	83 e0 01             	and    $0x1,%eax
801084c5:	85 c0                	test   %eax,%eax
801084c7:	74 0c                	je     801084d5 <mappages+0x66>
      panic("remap");
801084c9:	c7 04 24 30 93 10 80 	movl   $0x80109330,(%esp)
801084d0:	e8 65 80 ff ff       	call   8010053a <panic>
    *pte = pa | perm | PTE_P;
801084d5:	8b 45 18             	mov    0x18(%ebp),%eax
801084d8:	0b 45 14             	or     0x14(%ebp),%eax
801084db:	83 c8 01             	or     $0x1,%eax
801084de:	89 c2                	mov    %eax,%edx
801084e0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801084e3:	89 10                	mov    %edx,(%eax)
    if(a == last)
801084e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084e8:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801084eb:	75 08                	jne    801084f5 <mappages+0x86>
      break;
801084ed:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
801084ee:	b8 00 00 00 00       	mov    $0x0,%eax
801084f3:	eb 10                	jmp    80108505 <mappages+0x96>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
801084f5:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
801084fc:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80108503:	eb 8e                	jmp    80108493 <mappages+0x24>
  return 0;
}
80108505:	c9                   	leave  
80108506:	c3                   	ret    

80108507 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
80108507:	55                   	push   %ebp
80108508:	89 e5                	mov    %esp,%ebp
8010850a:	53                   	push   %ebx
8010850b:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
8010850e:	e8 19 a7 ff ff       	call   80102c2c <kalloc>
80108513:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108516:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010851a:	75 0a                	jne    80108526 <setupkvm+0x1f>
    return 0;
8010851c:	b8 00 00 00 00       	mov    $0x0,%eax
80108521:	e9 98 00 00 00       	jmp    801085be <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80108526:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010852d:	00 
8010852e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108535:	00 
80108536:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108539:	89 04 24             	mov    %eax,(%esp)
8010853c:	e8 58 d4 ff ff       	call   80105999 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80108541:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80108548:	e8 fd f9 ff ff       	call   80107f4a <p2v>
8010854d:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80108552:	76 0c                	jbe    80108560 <setupkvm+0x59>
    panic("PHYSTOP too high");
80108554:	c7 04 24 36 93 10 80 	movl   $0x80109336,(%esp)
8010855b:	e8 da 7f ff ff       	call   8010053a <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108560:	c7 45 f4 a0 c4 10 80 	movl   $0x8010c4a0,-0xc(%ebp)
80108567:	eb 49                	jmp    801085b2 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108569:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010856c:	8b 48 0c             	mov    0xc(%eax),%ecx
8010856f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108572:	8b 50 04             	mov    0x4(%eax),%edx
80108575:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108578:	8b 58 08             	mov    0x8(%eax),%ebx
8010857b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010857e:	8b 40 04             	mov    0x4(%eax),%eax
80108581:	29 c3                	sub    %eax,%ebx
80108583:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108586:	8b 00                	mov    (%eax),%eax
80108588:	89 4c 24 10          	mov    %ecx,0x10(%esp)
8010858c:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108590:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108594:	89 44 24 04          	mov    %eax,0x4(%esp)
80108598:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010859b:	89 04 24             	mov    %eax,(%esp)
8010859e:	e8 cc fe ff ff       	call   8010846f <mappages>
801085a3:	85 c0                	test   %eax,%eax
801085a5:	79 07                	jns    801085ae <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
801085a7:	b8 00 00 00 00       	mov    $0x0,%eax
801085ac:	eb 10                	jmp    801085be <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801085ae:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801085b2:	81 7d f4 e0 c4 10 80 	cmpl   $0x8010c4e0,-0xc(%ebp)
801085b9:	72 ae                	jb     80108569 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
801085bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801085be:	83 c4 34             	add    $0x34,%esp
801085c1:	5b                   	pop    %ebx
801085c2:	5d                   	pop    %ebp
801085c3:	c3                   	ret    

801085c4 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
801085c4:	55                   	push   %ebp
801085c5:	89 e5                	mov    %esp,%ebp
801085c7:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
801085ca:	e8 38 ff ff ff       	call   80108507 <setupkvm>
801085cf:	a3 78 7b 11 80       	mov    %eax,0x80117b78
  switchkvm();
801085d4:	e8 02 00 00 00       	call   801085db <switchkvm>
}
801085d9:	c9                   	leave  
801085da:	c3                   	ret    

801085db <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
801085db:	55                   	push   %ebp
801085dc:	89 e5                	mov    %esp,%ebp
801085de:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
801085e1:	a1 78 7b 11 80       	mov    0x80117b78,%eax
801085e6:	89 04 24             	mov    %eax,(%esp)
801085e9:	e8 4f f9 ff ff       	call   80107f3d <v2p>
801085ee:	89 04 24             	mov    %eax,(%esp)
801085f1:	e8 3c f9 ff ff       	call   80107f32 <lcr3>
}
801085f6:	c9                   	leave  
801085f7:	c3                   	ret    

801085f8 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
801085f8:	55                   	push   %ebp
801085f9:	89 e5                	mov    %esp,%ebp
801085fb:	53                   	push   %ebx
801085fc:	83 ec 14             	sub    $0x14,%esp
  pushcli();
801085ff:	e8 95 d2 ff ff       	call   80105899 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80108604:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010860a:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108611:	83 c2 08             	add    $0x8,%edx
80108614:	89 d3                	mov    %edx,%ebx
80108616:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010861d:	83 c2 08             	add    $0x8,%edx
80108620:	c1 ea 10             	shr    $0x10,%edx
80108623:	89 d1                	mov    %edx,%ecx
80108625:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010862c:	83 c2 08             	add    $0x8,%edx
8010862f:	c1 ea 18             	shr    $0x18,%edx
80108632:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80108639:	67 00 
8010863b:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80108642:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80108648:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
8010864f:	83 e1 f0             	and    $0xfffffff0,%ecx
80108652:	83 c9 09             	or     $0x9,%ecx
80108655:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
8010865b:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108662:	83 c9 10             	or     $0x10,%ecx
80108665:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
8010866b:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108672:	83 e1 9f             	and    $0xffffff9f,%ecx
80108675:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
8010867b:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108682:	83 c9 80             	or     $0xffffff80,%ecx
80108685:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
8010868b:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108692:	83 e1 f0             	and    $0xfffffff0,%ecx
80108695:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010869b:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801086a2:	83 e1 ef             	and    $0xffffffef,%ecx
801086a5:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801086ab:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801086b2:	83 e1 df             	and    $0xffffffdf,%ecx
801086b5:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801086bb:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801086c2:	83 c9 40             	or     $0x40,%ecx
801086c5:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801086cb:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801086d2:	83 e1 7f             	and    $0x7f,%ecx
801086d5:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801086db:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
801086e1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801086e7:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
801086ee:	83 e2 ef             	and    $0xffffffef,%edx
801086f1:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
801086f7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801086fd:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80108703:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108709:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80108710:	8b 52 08             	mov    0x8(%edx),%edx
80108713:	81 c2 00 10 00 00    	add    $0x1000,%edx
80108719:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
8010871c:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80108723:	e8 df f7 ff ff       	call   80107f07 <ltr>
  if(p->pgdir == 0)
80108728:	8b 45 08             	mov    0x8(%ebp),%eax
8010872b:	8b 40 04             	mov    0x4(%eax),%eax
8010872e:	85 c0                	test   %eax,%eax
80108730:	75 0c                	jne    8010873e <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80108732:	c7 04 24 47 93 10 80 	movl   $0x80109347,(%esp)
80108739:	e8 fc 7d ff ff       	call   8010053a <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
8010873e:	8b 45 08             	mov    0x8(%ebp),%eax
80108741:	8b 40 04             	mov    0x4(%eax),%eax
80108744:	89 04 24             	mov    %eax,(%esp)
80108747:	e8 f1 f7 ff ff       	call   80107f3d <v2p>
8010874c:	89 04 24             	mov    %eax,(%esp)
8010874f:	e8 de f7 ff ff       	call   80107f32 <lcr3>
  popcli();
80108754:	e8 84 d1 ff ff       	call   801058dd <popcli>
}
80108759:	83 c4 14             	add    $0x14,%esp
8010875c:	5b                   	pop    %ebx
8010875d:	5d                   	pop    %ebp
8010875e:	c3                   	ret    

8010875f <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
8010875f:	55                   	push   %ebp
80108760:	89 e5                	mov    %esp,%ebp
80108762:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80108765:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
8010876c:	76 0c                	jbe    8010877a <inituvm+0x1b>
    panic("inituvm: more than a page");
8010876e:	c7 04 24 5b 93 10 80 	movl   $0x8010935b,(%esp)
80108775:	e8 c0 7d ff ff       	call   8010053a <panic>
  mem = kalloc();
8010877a:	e8 ad a4 ff ff       	call   80102c2c <kalloc>
8010877f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80108782:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108789:	00 
8010878a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108791:	00 
80108792:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108795:	89 04 24             	mov    %eax,(%esp)
80108798:	e8 fc d1 ff ff       	call   80105999 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
8010879d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087a0:	89 04 24             	mov    %eax,(%esp)
801087a3:	e8 95 f7 ff ff       	call   80107f3d <v2p>
801087a8:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801087af:	00 
801087b0:	89 44 24 0c          	mov    %eax,0xc(%esp)
801087b4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801087bb:	00 
801087bc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801087c3:	00 
801087c4:	8b 45 08             	mov    0x8(%ebp),%eax
801087c7:	89 04 24             	mov    %eax,(%esp)
801087ca:	e8 a0 fc ff ff       	call   8010846f <mappages>
  memmove(mem, init, sz);
801087cf:	8b 45 10             	mov    0x10(%ebp),%eax
801087d2:	89 44 24 08          	mov    %eax,0x8(%esp)
801087d6:	8b 45 0c             	mov    0xc(%ebp),%eax
801087d9:	89 44 24 04          	mov    %eax,0x4(%esp)
801087dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087e0:	89 04 24             	mov    %eax,(%esp)
801087e3:	e8 80 d2 ff ff       	call   80105a68 <memmove>
}
801087e8:	c9                   	leave  
801087e9:	c3                   	ret    

801087ea <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
801087ea:	55                   	push   %ebp
801087eb:	89 e5                	mov    %esp,%ebp
801087ed:	53                   	push   %ebx
801087ee:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
801087f1:	8b 45 0c             	mov    0xc(%ebp),%eax
801087f4:	25 ff 0f 00 00       	and    $0xfff,%eax
801087f9:	85 c0                	test   %eax,%eax
801087fb:	74 0c                	je     80108809 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
801087fd:	c7 04 24 78 93 10 80 	movl   $0x80109378,(%esp)
80108804:	e8 31 7d ff ff       	call   8010053a <panic>
  for(i = 0; i < sz; i += PGSIZE){
80108809:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108810:	e9 a9 00 00 00       	jmp    801088be <loaduvm+0xd4>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80108815:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108818:	8b 55 0c             	mov    0xc(%ebp),%edx
8010881b:	01 d0                	add    %edx,%eax
8010881d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108824:	00 
80108825:	89 44 24 04          	mov    %eax,0x4(%esp)
80108829:	8b 45 08             	mov    0x8(%ebp),%eax
8010882c:	89 04 24             	mov    %eax,(%esp)
8010882f:	e8 99 fb ff ff       	call   801083cd <walkpgdir>
80108834:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108837:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010883b:	75 0c                	jne    80108849 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
8010883d:	c7 04 24 9b 93 10 80 	movl   $0x8010939b,(%esp)
80108844:	e8 f1 7c ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80108849:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010884c:	8b 00                	mov    (%eax),%eax
8010884e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108853:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80108856:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108859:	8b 55 18             	mov    0x18(%ebp),%edx
8010885c:	29 c2                	sub    %eax,%edx
8010885e:	89 d0                	mov    %edx,%eax
80108860:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80108865:	77 0f                	ja     80108876 <loaduvm+0x8c>
      n = sz - i;
80108867:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010886a:	8b 55 18             	mov    0x18(%ebp),%edx
8010886d:	29 c2                	sub    %eax,%edx
8010886f:	89 d0                	mov    %edx,%eax
80108871:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108874:	eb 07                	jmp    8010887d <loaduvm+0x93>
    else
      n = PGSIZE;
80108876:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
8010887d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108880:	8b 55 14             	mov    0x14(%ebp),%edx
80108883:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80108886:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108889:	89 04 24             	mov    %eax,(%esp)
8010888c:	e8 b9 f6 ff ff       	call   80107f4a <p2v>
80108891:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108894:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108898:	89 5c 24 08          	mov    %ebx,0x8(%esp)
8010889c:	89 44 24 04          	mov    %eax,0x4(%esp)
801088a0:	8b 45 10             	mov    0x10(%ebp),%eax
801088a3:	89 04 24             	mov    %eax,(%esp)
801088a6:	e8 ec 94 ff ff       	call   80101d97 <readi>
801088ab:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801088ae:	74 07                	je     801088b7 <loaduvm+0xcd>
      return -1;
801088b0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801088b5:	eb 18                	jmp    801088cf <loaduvm+0xe5>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
801088b7:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801088be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088c1:	3b 45 18             	cmp    0x18(%ebp),%eax
801088c4:	0f 82 4b ff ff ff    	jb     80108815 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
801088ca:	b8 00 00 00 00       	mov    $0x0,%eax
}
801088cf:	83 c4 24             	add    $0x24,%esp
801088d2:	5b                   	pop    %ebx
801088d3:	5d                   	pop    %ebp
801088d4:	c3                   	ret    

801088d5 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801088d5:	55                   	push   %ebp
801088d6:	89 e5                	mov    %esp,%ebp
801088d8:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
801088db:	8b 45 10             	mov    0x10(%ebp),%eax
801088de:	85 c0                	test   %eax,%eax
801088e0:	79 0a                	jns    801088ec <allocuvm+0x17>
    return 0;
801088e2:	b8 00 00 00 00       	mov    $0x0,%eax
801088e7:	e9 c1 00 00 00       	jmp    801089ad <allocuvm+0xd8>
  if(newsz < oldsz)
801088ec:	8b 45 10             	mov    0x10(%ebp),%eax
801088ef:	3b 45 0c             	cmp    0xc(%ebp),%eax
801088f2:	73 08                	jae    801088fc <allocuvm+0x27>
    return oldsz;
801088f4:	8b 45 0c             	mov    0xc(%ebp),%eax
801088f7:	e9 b1 00 00 00       	jmp    801089ad <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
801088fc:	8b 45 0c             	mov    0xc(%ebp),%eax
801088ff:	05 ff 0f 00 00       	add    $0xfff,%eax
80108904:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108909:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
8010890c:	e9 8d 00 00 00       	jmp    8010899e <allocuvm+0xc9>
    mem = kalloc();
80108911:	e8 16 a3 ff ff       	call   80102c2c <kalloc>
80108916:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80108919:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010891d:	75 2c                	jne    8010894b <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
8010891f:	c7 04 24 b9 93 10 80 	movl   $0x801093b9,(%esp)
80108926:	e8 75 7a ff ff       	call   801003a0 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010892b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010892e:	89 44 24 08          	mov    %eax,0x8(%esp)
80108932:	8b 45 10             	mov    0x10(%ebp),%eax
80108935:	89 44 24 04          	mov    %eax,0x4(%esp)
80108939:	8b 45 08             	mov    0x8(%ebp),%eax
8010893c:	89 04 24             	mov    %eax,(%esp)
8010893f:	e8 6b 00 00 00       	call   801089af <deallocuvm>
      return 0;
80108944:	b8 00 00 00 00       	mov    $0x0,%eax
80108949:	eb 62                	jmp    801089ad <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
8010894b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108952:	00 
80108953:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010895a:	00 
8010895b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010895e:	89 04 24             	mov    %eax,(%esp)
80108961:	e8 33 d0 ff ff       	call   80105999 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108966:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108969:	89 04 24             	mov    %eax,(%esp)
8010896c:	e8 cc f5 ff ff       	call   80107f3d <v2p>
80108971:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108974:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010897b:	00 
8010897c:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108980:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108987:	00 
80108988:	89 54 24 04          	mov    %edx,0x4(%esp)
8010898c:	8b 45 08             	mov    0x8(%ebp),%eax
8010898f:	89 04 24             	mov    %eax,(%esp)
80108992:	e8 d8 fa ff ff       	call   8010846f <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80108997:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010899e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089a1:	3b 45 10             	cmp    0x10(%ebp),%eax
801089a4:	0f 82 67 ff ff ff    	jb     80108911 <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
801089aa:	8b 45 10             	mov    0x10(%ebp),%eax
}
801089ad:	c9                   	leave  
801089ae:	c3                   	ret    

801089af <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801089af:	55                   	push   %ebp
801089b0:	89 e5                	mov    %esp,%ebp
801089b2:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801089b5:	8b 45 10             	mov    0x10(%ebp),%eax
801089b8:	3b 45 0c             	cmp    0xc(%ebp),%eax
801089bb:	72 08                	jb     801089c5 <deallocuvm+0x16>
    return oldsz;
801089bd:	8b 45 0c             	mov    0xc(%ebp),%eax
801089c0:	e9 a4 00 00 00       	jmp    80108a69 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
801089c5:	8b 45 10             	mov    0x10(%ebp),%eax
801089c8:	05 ff 0f 00 00       	add    $0xfff,%eax
801089cd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801089d2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
801089d5:	e9 80 00 00 00       	jmp    80108a5a <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
801089da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089dd:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801089e4:	00 
801089e5:	89 44 24 04          	mov    %eax,0x4(%esp)
801089e9:	8b 45 08             	mov    0x8(%ebp),%eax
801089ec:	89 04 24             	mov    %eax,(%esp)
801089ef:	e8 d9 f9 ff ff       	call   801083cd <walkpgdir>
801089f4:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
801089f7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801089fb:	75 09                	jne    80108a06 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
801089fd:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80108a04:	eb 4d                	jmp    80108a53 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80108a06:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108a09:	8b 00                	mov    (%eax),%eax
80108a0b:	83 e0 01             	and    $0x1,%eax
80108a0e:	85 c0                	test   %eax,%eax
80108a10:	74 41                	je     80108a53 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80108a12:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108a15:	8b 00                	mov    (%eax),%eax
80108a17:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108a1c:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80108a1f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108a23:	75 0c                	jne    80108a31 <deallocuvm+0x82>
        panic("kfree");
80108a25:	c7 04 24 d1 93 10 80 	movl   $0x801093d1,(%esp)
80108a2c:	e8 09 7b ff ff       	call   8010053a <panic>
      char *v = p2v(pa);
80108a31:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108a34:	89 04 24             	mov    %eax,(%esp)
80108a37:	e8 0e f5 ff ff       	call   80107f4a <p2v>
80108a3c:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80108a3f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108a42:	89 04 24             	mov    %eax,(%esp)
80108a45:	e8 49 a1 ff ff       	call   80102b93 <kfree>
      *pte = 0;
80108a4a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108a4d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80108a53:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108a5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a5d:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108a60:	0f 82 74 ff ff ff    	jb     801089da <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80108a66:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108a69:	c9                   	leave  
80108a6a:	c3                   	ret    

80108a6b <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80108a6b:	55                   	push   %ebp
80108a6c:	89 e5                	mov    %esp,%ebp
80108a6e:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80108a71:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80108a75:	75 0c                	jne    80108a83 <freevm+0x18>
    panic("freevm: no pgdir");
80108a77:	c7 04 24 d7 93 10 80 	movl   $0x801093d7,(%esp)
80108a7e:	e8 b7 7a ff ff       	call   8010053a <panic>
  deallocuvm(pgdir, KERNBASE, 0);
80108a83:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108a8a:	00 
80108a8b:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80108a92:	80 
80108a93:	8b 45 08             	mov    0x8(%ebp),%eax
80108a96:	89 04 24             	mov    %eax,(%esp)
80108a99:	e8 11 ff ff ff       	call   801089af <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80108a9e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108aa5:	eb 48                	jmp    80108aef <freevm+0x84>
    if(pgdir[i] & PTE_P){
80108aa7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108aaa:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108ab1:	8b 45 08             	mov    0x8(%ebp),%eax
80108ab4:	01 d0                	add    %edx,%eax
80108ab6:	8b 00                	mov    (%eax),%eax
80108ab8:	83 e0 01             	and    $0x1,%eax
80108abb:	85 c0                	test   %eax,%eax
80108abd:	74 2c                	je     80108aeb <freevm+0x80>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80108abf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ac2:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108ac9:	8b 45 08             	mov    0x8(%ebp),%eax
80108acc:	01 d0                	add    %edx,%eax
80108ace:	8b 00                	mov    (%eax),%eax
80108ad0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108ad5:	89 04 24             	mov    %eax,(%esp)
80108ad8:	e8 6d f4 ff ff       	call   80107f4a <p2v>
80108add:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108ae0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108ae3:	89 04 24             	mov    %eax,(%esp)
80108ae6:	e8 a8 a0 ff ff       	call   80102b93 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80108aeb:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108aef:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80108af6:	76 af                	jbe    80108aa7 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80108af8:	8b 45 08             	mov    0x8(%ebp),%eax
80108afb:	89 04 24             	mov    %eax,(%esp)
80108afe:	e8 90 a0 ff ff       	call   80102b93 <kfree>
}
80108b03:	c9                   	leave  
80108b04:	c3                   	ret    

80108b05 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80108b05:	55                   	push   %ebp
80108b06:	89 e5                	mov    %esp,%ebp
80108b08:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108b0b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108b12:	00 
80108b13:	8b 45 0c             	mov    0xc(%ebp),%eax
80108b16:	89 44 24 04          	mov    %eax,0x4(%esp)
80108b1a:	8b 45 08             	mov    0x8(%ebp),%eax
80108b1d:	89 04 24             	mov    %eax,(%esp)
80108b20:	e8 a8 f8 ff ff       	call   801083cd <walkpgdir>
80108b25:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108b28:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108b2c:	75 0c                	jne    80108b3a <clearpteu+0x35>
    panic("clearpteu");
80108b2e:	c7 04 24 e8 93 10 80 	movl   $0x801093e8,(%esp)
80108b35:	e8 00 7a ff ff       	call   8010053a <panic>
  *pte &= ~PTE_U;
80108b3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b3d:	8b 00                	mov    (%eax),%eax
80108b3f:	83 e0 fb             	and    $0xfffffffb,%eax
80108b42:	89 c2                	mov    %eax,%edx
80108b44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b47:	89 10                	mov    %edx,(%eax)
}
80108b49:	c9                   	leave  
80108b4a:	c3                   	ret    

80108b4b <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80108b4b:	55                   	push   %ebp
80108b4c:	89 e5                	mov    %esp,%ebp
80108b4e:	53                   	push   %ebx
80108b4f:	83 ec 44             	sub    $0x44,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80108b52:	e8 b0 f9 ff ff       	call   80108507 <setupkvm>
80108b57:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108b5a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108b5e:	75 0a                	jne    80108b6a <copyuvm+0x1f>
    return 0;
80108b60:	b8 00 00 00 00       	mov    $0x0,%eax
80108b65:	e9 fd 00 00 00       	jmp    80108c67 <copyuvm+0x11c>
  for(i = 0; i < sz; i += PGSIZE){
80108b6a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108b71:	e9 d0 00 00 00       	jmp    80108c46 <copyuvm+0xfb>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108b76:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b79:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108b80:	00 
80108b81:	89 44 24 04          	mov    %eax,0x4(%esp)
80108b85:	8b 45 08             	mov    0x8(%ebp),%eax
80108b88:	89 04 24             	mov    %eax,(%esp)
80108b8b:	e8 3d f8 ff ff       	call   801083cd <walkpgdir>
80108b90:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108b93:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108b97:	75 0c                	jne    80108ba5 <copyuvm+0x5a>
      panic("copyuvm: pte should exist");
80108b99:	c7 04 24 f2 93 10 80 	movl   $0x801093f2,(%esp)
80108ba0:	e8 95 79 ff ff       	call   8010053a <panic>
    if(!(*pte & PTE_P))
80108ba5:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108ba8:	8b 00                	mov    (%eax),%eax
80108baa:	83 e0 01             	and    $0x1,%eax
80108bad:	85 c0                	test   %eax,%eax
80108baf:	75 0c                	jne    80108bbd <copyuvm+0x72>
      panic("copyuvm: page not present");
80108bb1:	c7 04 24 0c 94 10 80 	movl   $0x8010940c,(%esp)
80108bb8:	e8 7d 79 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80108bbd:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108bc0:	8b 00                	mov    (%eax),%eax
80108bc2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108bc7:	89 45 e8             	mov    %eax,-0x18(%ebp)
    flags = PTE_FLAGS(*pte);
80108bca:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108bcd:	8b 00                	mov    (%eax),%eax
80108bcf:	25 ff 0f 00 00       	and    $0xfff,%eax
80108bd4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if((mem = kalloc()) == 0)
80108bd7:	e8 50 a0 ff ff       	call   80102c2c <kalloc>
80108bdc:	89 45 e0             	mov    %eax,-0x20(%ebp)
80108bdf:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80108be3:	75 02                	jne    80108be7 <copyuvm+0x9c>
      goto bad;
80108be5:	eb 70                	jmp    80108c57 <copyuvm+0x10c>
    memmove(mem, (char*)p2v(pa), PGSIZE);
80108be7:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108bea:	89 04 24             	mov    %eax,(%esp)
80108bed:	e8 58 f3 ff ff       	call   80107f4a <p2v>
80108bf2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108bf9:	00 
80108bfa:	89 44 24 04          	mov    %eax,0x4(%esp)
80108bfe:	8b 45 e0             	mov    -0x20(%ebp),%eax
80108c01:	89 04 24             	mov    %eax,(%esp)
80108c04:	e8 5f ce ff ff       	call   80105a68 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
80108c09:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
80108c0c:	8b 45 e0             	mov    -0x20(%ebp),%eax
80108c0f:	89 04 24             	mov    %eax,(%esp)
80108c12:	e8 26 f3 ff ff       	call   80107f3d <v2p>
80108c17:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108c1a:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80108c1e:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108c22:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108c29:	00 
80108c2a:	89 54 24 04          	mov    %edx,0x4(%esp)
80108c2e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108c31:	89 04 24             	mov    %eax,(%esp)
80108c34:	e8 36 f8 ff ff       	call   8010846f <mappages>
80108c39:	85 c0                	test   %eax,%eax
80108c3b:	79 02                	jns    80108c3f <copyuvm+0xf4>
      goto bad;
80108c3d:	eb 18                	jmp    80108c57 <copyuvm+0x10c>
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80108c3f:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108c46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c49:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108c4c:	0f 82 24 ff ff ff    	jb     80108b76 <copyuvm+0x2b>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
      goto bad;
  }
  return d;
80108c52:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108c55:	eb 10                	jmp    80108c67 <copyuvm+0x11c>

bad:
  freevm(d);
80108c57:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108c5a:	89 04 24             	mov    %eax,(%esp)
80108c5d:	e8 09 fe ff ff       	call   80108a6b <freevm>
  return 0;
80108c62:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108c67:	83 c4 44             	add    $0x44,%esp
80108c6a:	5b                   	pop    %ebx
80108c6b:	5d                   	pop    %ebp
80108c6c:	c3                   	ret    

80108c6d <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80108c6d:	55                   	push   %ebp
80108c6e:	89 e5                	mov    %esp,%ebp
80108c70:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108c73:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108c7a:	00 
80108c7b:	8b 45 0c             	mov    0xc(%ebp),%eax
80108c7e:	89 44 24 04          	mov    %eax,0x4(%esp)
80108c82:	8b 45 08             	mov    0x8(%ebp),%eax
80108c85:	89 04 24             	mov    %eax,(%esp)
80108c88:	e8 40 f7 ff ff       	call   801083cd <walkpgdir>
80108c8d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
80108c90:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c93:	8b 00                	mov    (%eax),%eax
80108c95:	83 e0 01             	and    $0x1,%eax
80108c98:	85 c0                	test   %eax,%eax
80108c9a:	75 07                	jne    80108ca3 <uva2ka+0x36>
    return 0;
80108c9c:	b8 00 00 00 00       	mov    $0x0,%eax
80108ca1:	eb 25                	jmp    80108cc8 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80108ca3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ca6:	8b 00                	mov    (%eax),%eax
80108ca8:	83 e0 04             	and    $0x4,%eax
80108cab:	85 c0                	test   %eax,%eax
80108cad:	75 07                	jne    80108cb6 <uva2ka+0x49>
    return 0;
80108caf:	b8 00 00 00 00       	mov    $0x0,%eax
80108cb4:	eb 12                	jmp    80108cc8 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80108cb6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cb9:	8b 00                	mov    (%eax),%eax
80108cbb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108cc0:	89 04 24             	mov    %eax,(%esp)
80108cc3:	e8 82 f2 ff ff       	call   80107f4a <p2v>
}
80108cc8:	c9                   	leave  
80108cc9:	c3                   	ret    

80108cca <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80108cca:	55                   	push   %ebp
80108ccb:	89 e5                	mov    %esp,%ebp
80108ccd:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80108cd0:	8b 45 10             	mov    0x10(%ebp),%eax
80108cd3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80108cd6:	e9 87 00 00 00       	jmp    80108d62 <copyout+0x98>
    va0 = (uint)PGROUNDDOWN(va);
80108cdb:	8b 45 0c             	mov    0xc(%ebp),%eax
80108cde:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108ce3:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80108ce6:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108ce9:	89 44 24 04          	mov    %eax,0x4(%esp)
80108ced:	8b 45 08             	mov    0x8(%ebp),%eax
80108cf0:	89 04 24             	mov    %eax,(%esp)
80108cf3:	e8 75 ff ff ff       	call   80108c6d <uva2ka>
80108cf8:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80108cfb:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108cff:	75 07                	jne    80108d08 <copyout+0x3e>
      return -1;
80108d01:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108d06:	eb 69                	jmp    80108d71 <copyout+0xa7>
    n = PGSIZE - (va - va0);
80108d08:	8b 45 0c             	mov    0xc(%ebp),%eax
80108d0b:	8b 55 ec             	mov    -0x14(%ebp),%edx
80108d0e:	29 c2                	sub    %eax,%edx
80108d10:	89 d0                	mov    %edx,%eax
80108d12:	05 00 10 00 00       	add    $0x1000,%eax
80108d17:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80108d1a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d1d:	3b 45 14             	cmp    0x14(%ebp),%eax
80108d20:	76 06                	jbe    80108d28 <copyout+0x5e>
      n = len;
80108d22:	8b 45 14             	mov    0x14(%ebp),%eax
80108d25:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80108d28:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d2b:	8b 55 0c             	mov    0xc(%ebp),%edx
80108d2e:	29 c2                	sub    %eax,%edx
80108d30:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108d33:	01 c2                	add    %eax,%edx
80108d35:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d38:	89 44 24 08          	mov    %eax,0x8(%esp)
80108d3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d3f:	89 44 24 04          	mov    %eax,0x4(%esp)
80108d43:	89 14 24             	mov    %edx,(%esp)
80108d46:	e8 1d cd ff ff       	call   80105a68 <memmove>
    len -= n;
80108d4b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d4e:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80108d51:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d54:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
80108d57:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d5a:	05 00 10 00 00       	add    $0x1000,%eax
80108d5f:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80108d62:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80108d66:	0f 85 6f ff ff ff    	jne    80108cdb <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
80108d6c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108d71:	c9                   	leave  
80108d72:	c3                   	ret    
