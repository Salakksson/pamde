#include <stdio.h>
#include <stdbool.h>
#include <unistd.h>
#include <sys/wait.h>

#define CONFIG_H_IMPLEMENTATION
#include "config.h"

#include <tcl.h>

char* read_entire_file(const char* file)
{
	FILE* fp = fopen(file, "r");

	if (!fp) {
		fprintf(stderr, "file is not readable: %s\n", file);
		return calloc(0, 0);
	}
	fseek(fp, 0, SEEK_END);
	size_t sz = ftell(fp);
	fseek(fp, 0, SEEK_SET);

	char* buf = malloc(sz + 1);
	if (!buf) {
		fprintf(stderr, "malloc failed: %s\n", strerror(errno));
		exit(1);
	}
	fread(buf, 1, sz, fp);
	buf[sz] = 0;

	return buf;
}

int cmd_run_bash(
	ClientData clientData,
	Tcl_Interp *interp,
	int objc,
	Tcl_Obj *const objv[]
) {
	puts("running bash command");
	if (objc < 2)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "script ?arg ...?");
		return TCL_ERROR;
	}

	const char* bash_block = Tcl_GetString(objv[1]);

	int inpipe[2];
	int outpipe[2];

	pipe(inpipe);
	pipe(outpipe);

	pid_t pid = fork();

	if (pid == 0)
	{
		dup2(inpipe[0], STDIN_FILENO);
		dup2(outpipe[1], STDOUT_FILENO);

		close(inpipe[1]);
		close(outpipe[0]);

		char** argv = malloc(sizeof(char*) * (objc + 2));
		argv[0] = "bash";
		for(int i = 2; i < objc; i++)
		{
			argv[i-1] = Tcl_GetString(objv[i]);
		}

		argv[objc-1] = NULL;

		execvp("bash", argv);
		exit(1);
	}

	close(inpipe[0]);
	close(outpipe[1]);

	write(inpipe[1], bash_block, strlen(bash_block));
	close(inpipe[1]);

	Tcl_Obj* result = Tcl_NewStringObj("", 0);

	char buffer[1024];
	ssize_t n;

	while ((n = read(outpipe[0], buffer, sizeof(buffer))) > 0)
	{
		Tcl_AppendToObj(result, buffer, n);
	}

	close(outpipe[0]);
	waitpid(pid, NULL, 0);

	Tcl_SetObjResult(interp, result);
	return TCL_OK;
}

void cmd_get_env(
	ClientData clientData,
	Tcl_Interp *interp,
	int objc,
	Tcl_Obj *const objv[]
) {

}

void add_cmd(Tcl_Interp* interp, const char* name, Tcl_ObjCmdProc cmd)
{
	Tcl_CreateObjCommand(interp, name, cmd, NULL, NULL);
}

int main(int argc, char** argv)
{
	config conf = {0};
	da_construct(conf.args, 5);
	da_construct(conf.flags, 5);
	for (int i = 1; i < argc; i++)
	{
		if (!parse_arg(&conf, argv[i]))
			display_help(conf.mode, 1);
	}

	da_append(conf.flags, '\0');
	if (strchr(conf.flags.items, 'h'))
		display_help(conf.mode, 0);

	Tcl_Interp* interp = Tcl_CreateInterp();

	if (Tcl_Init(interp) != TCL_OK)
	{
		fprintf(
			stderr,
			"Tcl_Init error: %s\n",
			Tcl_GetStringResult(interp)
		);
		return 1;
	}

	Tcl_CreateNamespace(interp, "-", NULL, NULL);
	add_cmd(interp, "-::run-bash", cmd_run_bash);

	if (Tcl_EvalFile(interp, "init.tcl") != TCL_OK)
	{
		fprintf(
			stderr,
			"Tcl_Eval error: %s\n",
			Tcl_GetStringResult(interp)
		);
		return 1;
	}
	Tcl_DeleteInterp(interp);

	da_delete(conf.flags);
	da_delete(conf.args);

}
