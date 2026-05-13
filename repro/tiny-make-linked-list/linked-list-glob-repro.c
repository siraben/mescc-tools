/* Minimal repro for the tiny-make glob linked-list accumulator.
 *
 * The "bad" mode reproduces the tiny-make failure shape: getdents returns at
 * least one real entry, the entry is copied into a Word node, and append then
 * stores through a NULL tail pointer.  The "good" mode uses the same getdents
 * parser and list layout but initializes the empty list correctly.
 */

#ifdef __GNUC__
#define _GNU_SOURCE
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/syscall.h>
#include <unistd.h>

static int stage0_open(char* name)
{
	return open(name, O_RDONLY, 0);
}

static int stage0_getdents(int fd, char* dirp, int count)
{
	return syscall(SYS_getdents, fd, dirp, count);
}
#else
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static int stage0_open(char* name)
{
	return _open(name, O_RDONLY, 0);
}

static int stage0_getdents(int fd, char* dirp, int count)
{
	asm("lea_ebx,[esp+DWORD] %12"
	    "mov_ebx,[ebx]"
	    "lea_ecx,[esp+DWORD] %8"
	    "mov_ecx,[ecx]"
	    "lea_edx,[esp+DWORD] %4"
	    "mov_edx,[edx]"
	    "mov_eax, %141"
	    "int !0x80");
}
#endif

#define DIRENT_BUF 4096
#define MAX_WORDS 32

struct Word
{
	char* text;
	struct Word* next;
};

static int read_u16(char* p)
{
	int lo = p[0];
	int hi = p[1];
	if(0 > lo) lo = lo + 256;
	if(0 > hi) hi = hi + 256;
	return lo + (hi * 256);
}

static char* copy_string(char* source)
{
	char* out = calloc(strlen(source) + 1, sizeof(char));
	strcpy(out, source);
	return out;
}

static void print_int(int value)
{
	if(10 <= value) print_int(value / 10);
	fputc((value % 10) + '0', stdout);
}

static void append_word_good(struct Word** head, struct Word** tail, char* text)
{
	struct Word* word = calloc(1, sizeof(struct Word));
	word->text = copy_string(text);
	word->next = NULL;
	if(NULL == *head) *head = word;
	if(NULL != *tail) (*tail)->next = word;
	*tail = word;
}

static void append_word_bad(struct Word** head, struct Word** tail, char* text)
{
	struct Word* word = calloc(1, sizeof(struct Word));
	word->text = copy_string(text);
	word->next = NULL;
	if(NULL == *head) *head = word;
	(*tail)->next = word;
	*tail = word;
}

static int flatten_words(struct Word* head, char** argv)
{
	int count = 0;
	while(NULL != head)
	{
		argv[count] = head->text;
		count = count + 1;
		head = head->next;
	}
	argv[count] = NULL;
	return count;
}

static int append_dir_words(char* dir, struct Word** out_head, struct Word** out_tail, int use_bad_append)
{
	char* buffer = calloc(DIRENT_BUF, sizeof(char));
	int fd = stage0_open(dir);
	int count = 0;
	int read_count;
	int offset;
	int reclen;
	char* name;

	if(0 > fd) return -1;

	read_count = stage0_getdents(fd, buffer, DIRENT_BUF);
	while(0 < read_count)
	{
		offset = 0;
		while(offset < read_count)
		{
			reclen = read_u16(buffer + offset + 8);
			name = buffer + offset + 10;
			if((0 != strcmp(name, ".")) && (0 != strcmp(name, "..")))
			{
				if(use_bad_append) append_word_bad(out_head, out_tail, name);
				else append_word_good(out_head, out_tail, name);
				count = count + 1;
			}
			offset = offset + reclen;
		}
		read_count = stage0_getdents(fd, buffer, DIRENT_BUF);
	}

	close(fd);
	return count;
}

int main(int argc, char** argv)
{
	char* dir = ".";
	int use_bad_append = 1;
	struct Word* head = NULL;
	struct Word* tail = NULL;
	char** words = calloc(MAX_WORDS, sizeof(char*));
	int count;
	int i;

	if(1 < argc) dir = argv[1];
	if(2 < argc)
	{
		if(0 == strcmp(argv[2], "good")) use_bad_append = 0;
	}

	count = append_dir_words(dir, &head, &tail, use_bad_append);
	if(0 > count)
	{
		fputs("open failed\n", stderr);
		return 2;
	}
	count = flatten_words(head, words);

	fputs("count=", stdout);
	print_int(count);
	fputs("\n", stdout);
	i = 0;
	while((i < count) && (i < 4))
	{
		fputs(words[i], stdout);
		fputs("\n", stdout);
		i = i + 1;
	}
	return 0;
}
