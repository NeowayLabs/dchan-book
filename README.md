<div id="table-of-contents">
<h2>Table of Contents</h2>
<div id="text-table-of-contents">
<ul>
<li><a href="#sec-1">1. dchan</a>
<ul>
<li><a href="#sec-1-1">1.1. Why dchan?</a></li>
<li><a href="#sec-1-2">1.2. Desired goals</a></li>
<li><a href="#sec-1-3">1.3. API</a>
<ul>
<li><a href="#sec-1-3-1">1.3.1. CSP Communication Semantics</a></li>
<li><a href="#sec-1-3-2">1.3.2. Atomic communication</a></li>
<li><a href="#sec-1-3-3">1.3.3. Non-deterministic choice</a></li>
<li><a href="#sec-1-3-4">1.3.4. Client interface</a></li>
<li><a href="#sec-1-3-5">1.3.5. Trade-offs</a></li>
<li><a href="#sec-1-3-6">1.3.6. Messaging</a></li>
</ul>
</li>
<li><a href="#sec-1-4">1.4. Text messages</a></li>
<li><a href="#sec-1-5">1.5. Composability</a></li>
<li><a href="#sec-1-6">1.6. Testing</a></li>
<li><a href="#sec-1-7">1.7. Building</a></li>
<li><a href="#sec-1-8">1.8. Implementation</a></li>
<li><a href="#sec-1-9">1.9. Test cases</a>
<ul>
<li><a href="#sec-1-9-1">1.9.1. Network partitions</a></li>
</ul>
</li>
</ul>
</li>
</ul>
</div>
</div>


# dchan<a id="sec-1" name="sec-1"></a>

Dchan is a server that exposes channels for inter-process
communications (IPC) over a file tree interface.  The channels are
much like Go channels and can be used in the same way but between
processes.  Instead of implementing a new protocol for data exchange
like AMQP, Dchan uses a simple file interface.  There's no need for
client libraries for each language (every language knows how to read
and write from files).

Dchan is able to share the files in the network with the help of the
9P protocol.

This project uses the concept of [Literate Programming](https://en.wikipedia.org/wiki/Literate_programming) of Donald
Knuth.

> Let us change our traditional attitude to the construction of
> programs: Instead of imagining that our main task is to instruct a
> computer what to do, let us concentrate rather on explaining to human
> beings what we want a computer to do.  <div
> align="right"><i>Donald Knuth - Literate Programming
> (1984).</i></div>

This book is the only source for design ideas, code, documentation and
tests. From here, we build everything.

## Why dchan?<a id="sec-1-1" name="sec-1-1"></a>

   Neoway organizational structure reflects it's software architecture
(or the other way around?)  and then good communication between teams
and architectures is a must!  Each team is free to choose the IPC
technology that makes more sense for the kind of problems they're
solving, but exists inter-teams communications that requires a common
protocol. Today we use RabbitMQ service for message passing
inter-teams and at various places of architecture and this proved
problematic for three reasons.

-   Hard to achieve quality software;
-   No mechanism to synchronize publishers and consumers;
-   It doesn't scale;

AMQP (Advanced Message Queue Protocol) is a complex bad designed
specification protocol and because of that, client libraries are huge
and sometimes buggy. On top of a huge library, the specification still
imposes a lot of client code to achieve durability and
reliability. That big amount of code (and tests) needs to be written
in the correct manner and must be correctly tested. Testing is hard
because the need for a central complete broker (not easy to mock with
libraries) and some way to start/stop the broker for test
re-connection and guarantees (durability). In simple words: hard to
achieve quality code.

For more information about this kind of problems, read the article
below from one of the AMQP creators:

<http://www.imatix.com/articles:whats-wrong-with-amqp/>

The second problem is that AMQP does not say any words about
synchronism between publishers and consumers of queues, and the
broker is designed to be a complete database to store the difference
between throughput of clients. Sometimes this is a
desired behavior, but sometimes it is not. If you have a low traffic
messaging, it works, but using the message broker as
a database for a large dataset processing requires much more strong
database capabilities in the broker than messaging (and AMQP is a
messaging protocol).

The third problem is a consequence of the the second problem.

## Desired goals<a id="sec-1-2" name="sec-1-2"></a>

Dchan have the goals below:

-   It must have a simple API;
-   It must support text messages over the wire;
-   It must support composability or inter-dchan communications;
-   It must support unicast and multicast;
-   It must be easy for testing;
-   It must scale;

## API<a id="sec-1-3" name="sec-1-3"></a>

To achieve the first goal dchan uses a file tree interface over
network. Simple files (real disk files) aren't suitable for IPC
because of the global nature of the disk incurring races in concurrent
access between processes. But UNIX operating systems supports the idea
of virtual file systems (VFS), an abstraction layer on top of a more
concrete file system, to make possible client applications to
interact with different kind of concrete file systems in a uniform
way. In practical, VFS is a kernel interface (or contract) to file
system drivers.

On linux, every file system driver implements the VFS contract, and
then it's possible to every program that read and write to files to
use any file system without code changes. It's good because old tools
like cat, sed, tail, and so on, can be used for network file systems
without changes. The VFS is useful to build stackable (or union fs
mounts) file systems and this will be explained in the Composability
section.

Network file systems are a class of file systems that (commonly) map
userspace IO operations into remote procedure calls, turning possible
interact with remote resources as if it were local. NFS (Network File
System) and 9P operate this way, the former being a very complex
protocol commonly used with kernel drivers on client and server side,
but the latter being very simple, allowing userspace file servers. For
9P exists tons of libraries for various programming languages to
develop clients and servers. For NFS exists only one server side
implementation in userspace and no library for creating new file
servers.

Dchan uses the 9P as network file system protocol behind the
scenes. This mean that you can mount the dchan file-tree
locally and interact with channels as if it were simple files in the
mounted directory.

Linux kernel have native support in the kernel to create 9P clients
(not servers), making easy to mount dchan file trees in each linux box.

For more information on 9P implementation see the link below:

<http://9p.cat-v.org/implementations>

### CSP Communication Semantics<a id="sec-1-3-1" name="sec-1-3-1"></a>

Dchan uses the Concurrent Sequential Processing semantics on top of
the virtual file interface. At core of the CSP semantics are two
fundamental ideas:

-   Atomic communication
-   Non-deterministic choice.

It's the same concepts as independently defined by Robin Milner in the
Calculus of Communicating Systems (CCS).

### Atomic communication<a id="sec-1-3-2" name="sec-1-3-2"></a>

Atomic communication is obtained by rendezvous points. Rendezvous
points are places in time and space that processes trying to
communicate meet in order to occur the communication. During
rendezvous both the sender and receiver processes block until the
other side is ready to communicate and implies that the sending and
receiving of a message occurs simultaneously.

> A real world analogy to rendezvous can be found in telephone
> communications (without answering machines). Both the caller and
> callee must be simultaneously present for a phone conversation to
> occur.
> Neil Smith at [CSP Domain](http://ptolemy.eecs.berkeley.edu/papers/99/HMAD/html/csp.html)

### Non-deterministic choice<a id="sec-1-3-3" name="sec-1-3-3"></a>

TODO

### Client interface<a id="sec-1-3-4" name="sec-1-3-4"></a>

To mount a new dchan file server is required only few commands.
On a stock linux kernel, what you need to type is:

    mkdir -p /n/dchan
    mount -t 9p -o port=6666,dfltuid=`id -u`,dfltgid=`id -g` \
        192.168.10.56 /n/dchan <ip-of-dchan-server> /n/dchan

The mount command above will use the linux kernel to establish a new
client connection to the file server. Once established, the kernel
will present the remote file system in the /n/dchan directory. After
that you can use traditional unix tools (file, cat, sed, etc) to
interact with the files on it.

### Trade-offs<a id="sec-1-3-5" name="sec-1-3-5"></a>

Using a file interface have various benefits, but some problems
too.

-   Error handling: The network is much more unreliable than local disk
    and this can be a source of problems if programmers do not
    understand this correctly. The majority of software does not handle
    disk failures, does not try to remount the file system if the
    hardware enter in a failure state, but when using network, failures
    happens all the time and programs needs to be aware of that.

-   Framing: Each software in the conversation needs to agree in what it
    understand of a message. If no convention is used between all of the
    softwares, then some kind of framing protocol must be used to ensure
    only complete messages are interpreted. The problem arises from two
    facts: First, each software can use whatever value it want in the
    amount of bytes of the read and write syscalls, leading to some
    programs processing incomplete messages if the amount of bytes
    disagree. Second, sending bytes over the network link isn't an
    atomic operation, and for that reason, send/write syscalls for
    socket commonly returns the amount of bytes completely sent. If the
    other end cannot identify that the packets received aren't a
    complete message then it can process corrupt or incomplete data.

Solution to the problems above are proposed in the section
Implementation.

### Messaging<a id="sec-1-3-6" name="sec-1-3-6"></a>

Using a file interface messaging is simpler:

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="left" />

<col  class="left" />
</colgroup>
<thead>
<tr>
<th scope="col" class="left">syscall</th>
<th scope="col" class="left">dchan semantics / effect</th>
</tr>
</thead>

<tbody>
<tr>
<td class="left">open</td>
<td class="left">Open an existing channel</td>
</tr>


<tr>
<td class="left">open(OCREAT)</td>
<td class="left">Create a new channel</td>
</tr>


<tr>
<td class="left">read</td>
<td class="left">Read messages from channel</td>
</tr>


<tr>
<td class="left">write</td>
<td class="left">Write a message into channel</td>
</tr>


<tr>
<td class="left">stat</td>
<td class="left">Get info of channel</td>
</tr>


<tr>
<td class="left">close</td>
<td class="left">Close the channel</td>
</tr>


<tr>
<td class="left">unlink</td>
<td class="left">Remove an existing channel</td>
</tr>
</tbody>
</table>

## Text messages<a id="sec-1-4" name="sec-1-4"></a>

Dchan has the principle of being simple and easy to debug. To the
latter be possible, it's strongly encouraged the use of text-based
messages instead of binary or compacted text. We'll not optimize for
performance until we really reach that point.

Using a text message format we can simplify both the clients and
server.

-   No need for libraries to encode/decode messages;
-   Easy to debug in the network;
-   Easy to testing;

## Composability<a id="sec-1-5" name="sec-1-5"></a>

It's possible to create a virtual file system representation of
multiple dchan file servers. It's useful for inter-teams
communications without the need of using a central dchan server.
This feature is given by union file system capabilities of the
Operating System.

The Linux and BSD kernels supports various flavours of union file
system drivers, but this section will demonstrate the use of the most
recent union file system of the Linux Kernel called \`overlayfs\`.

From Linux documentation:

> An overlay filesystem combines two filesystems - an 'upper' filesystem
> and a 'lower' filesystem.  When a name exists in both filesystems, the
> object in the 'upper' filesystem is visible while the object in the
> 'lower' filesystem is either hidden or, in the case of directories,
> merged with the 'upper' object. <div
> align="right"><i>Neil Brown in [OverlayFS Documentation](https://www.kernel.org/doc/Documentation/filesystems/overlayfs.txt).</i></div>

Using this concept it's possible to create file trees composed of
multiple dchan servers without the needs of implementing anything in it.

## Testing<a id="sec-1-6" name="sec-1-6"></a>

Developing a distributed software involves lots of testing because
failures occurs very frequently. When you build a local software, with
the entire business logic running at one local memory address space,
we can ignore the majority of operating system and hardware faults and
focus only in testing the logic inside the program source code. But
when the software logic is spread in the network, various classes of
bugs can arises.

On linux, any file system syscall executed on a mounted 9P file system
that is disconnected from server will result in a -EIO error (Input/Output
error). Applications using dchan should verify the return value of
read/write functions and, if the value returned is -EIO, then it
should re-open the file when re-connection with the file server is
finished. To re-connect, a new mount syscall, establishing a new
client connection with the file server is required. Linux mount supports the
remount option, enabling then to reuse the mount point already used by
applications (no need to cwd again to directory). The remount can be
done explicitly by the application using dchan or by an external
software. This topic will be more detailed in the section dchan-proxy.

## Building<a id="sec-1-7" name="sec-1-7"></a>

To build the software you can execute:

    make

The Makefile follows

    ### -*- Makefile -*- Dchan build options

    # To install `dchan', type `make' and then `make install'.

    BIN_DIR=/usr/local/bin
    ORG_FILE=dchan.org

    .PHONY: all build test clean doc

    all: clean tangle build test doc
            @echo "build successfully"

    tangle:
            org-tangle main.go

    build:
            go build -v

    test:
            go test -v ./...

    install:
            cp dchan $(BIN_DIR)

    clean:
            -rm dchan *.tex *.pdf *.html *.go *.txt *~

    doc:
            org2pdf dchan.org

## Implementation<a id="sec-1-8" name="sec-1-8"></a>

Main

    package main

    import "fmt"

    func main() {
            fmt.Printf("dchan running")
    }

## Test cases<a id="sec-1-9" name="sec-1-9"></a>

### Network partitions<a id="sec-1-9-1" name="sec-1-9-1"></a>

Network partition is the most frequent problem that can affect
Dchan. There's some cases that needs to be covered in order to achieve
reliability in the exchange of messages.

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="left" />

<col  class="left" />

<col  class="left" />

<col  class="left" />

<col  class="left" />
</colgroup>
<thead>
<tr>
<th scope="col" class="left">Description</th>
<th scope="col" class="left">steps of events</th>
<th scope="col" class="left">&#xa0;</th>
<th scope="col" class="left">&#xa0;</th>
<th scope="col" class="left">&#xa0;</th>
</tr>
</thead>

<tbody>
<tr>
<td class="left">&#xa0;</td>
<td class="left">&#xa0;</td>
<td class="left">&#xa0;</td>
<td class="left">&#xa0;</td>
<td class="left">&#xa0;</td>
</tr>
</tbody>
</table>

<div id="footnotes">
<h2 class="footnotes">Footnotes: </h2>
<div id="text-footnotes">

<div class="footdef"><sup><a id="fn.1" name="fn.1" class="footnum" href="#fnr.1">1</a></sup> R. Milner, "A Calculus of Communicating Systems", Lecture Notes
in Computer Science, Vol. 92, Springer-Verlag, 1980.</div>


</div>
</div>
