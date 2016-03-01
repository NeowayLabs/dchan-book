
package main

import (
	"errors"
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/lionkov/go9p/p"
	"github.com/lionkov/go9p/p/srv"
)

type DchanFile struct {
	srv.File
	id int
}

type Dchan struct {
	srv.File
}




var addr = flag.String("addr", ":6666", "network address")
var debug = flag.Bool("d", false, "print debug messages")

var root *srv.File

func (file *DchanFile) Read(fid *srv.FFid, buf []byte, offset uint64) (int, error) {
	b := []byte("hacked by i4k")
	n := len(b)

	if offset >= uint64(n) {
		return 0, nil
	}

	b = b[int(offset):n]
	n -= int(offset)
	if len(buf) < n {
		n = len(buf)
	}

	copy(buf[offset:int(offset)+n], b[offset:])
	return n, nil
}

func (file *DchanFile) Write(fid *srv.FFid, data []byte, offset uint64) (int, error) {
	return 0, errors.New("permission denied")
}

func (file *DchanFile) Wstat(fid *srv.FFid, dir *p.Dir) error {
	return nil
}

func (file *DchanFile) Remove(fid *srv.FFid) error {
	return nil
}

func main() {
	var err error
	var ctl *DchanFile
	var s *srv.Fsrv

	flag.Parse()
	user := p.OsUsers.Uid2User(os.Geteuid())
	root = new(srv.File)
	err = root.Add(nil, "/", user, nil, p.DMDIR|0777, nil)
	if err != nil {
		goto error
	}

	ctl = new(DchanFile)
	err = ctl.Add(root, "ctl", p.OsUsers.Uid2User(os.Geteuid()), nil, 0444, ctl)
	if err != nil {
		goto error
	}

	s = srv.NewFileSrv(root)
	s.Dotu = true

	if *debug {
		s.Debuglevel = 1
	}

	s.Start(s)
	err = s.StartNetListener("tcp", *addr)
	if err != nil {
		goto error
	}
	return

error:
	log.Println(fmt.Sprintf("Error: %s", err))
}
