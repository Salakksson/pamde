#include <stdio.h>
#include <stdbool.h>

#define CONFIG_H_IMPLEMENTATION
#include "config.h"
#include "pacman.h"

#include <tcl8.6/tcl.h>

void pamde(config* conf)
{

}

int RunBashCmd(
	ClientData clientData,
	Tcl_Interp *interp,
	int objc,
	Tcl_Obj *const objv[]
) {
    if (objc != 2) {
        Tcl_WrongNumArgs(interp, 1, objv, "bash_command_string");
        return TCL_ERROR;
    }

    // Extract the string argument from the Tcl object
    const char *shell_script = Tcl_GetString(objv[1]);

    // Execute the string using the system shell
    int status = system(shell_script);

    if (status == -1) {
        Tcl_SetObjResult(interp, Tcl_NewStringObj("Failed to execute shell command", -1));
        return TCL_ERROR;
    }

    return TCL_OK;
}

char* read_entire_file(const char* file)
{
	FILE* fp = fopen(file, "r");

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

int test(int argc, char *argv[]) {
    // Create the Tcl Interpreter
    Tcl_Interp *interp = Tcl_CreateInterp();

    if (Tcl_Init(interp) != TCL_OK) {
        fprintf(stderr, "Tcl_Init error: %s\n", Tcl_GetStringResult(interp));
        return EXIT_FAILURE;
    }

    // Register our custom 'run_bash' command
    Tcl_CreateObjCommand(interp, "run_bash", RunBashCmd, NULL, NULL);

    // The Tcl script we want to run
    char *script = read_entire_file("test.tcl");

    // Execute the script
    if (Tcl_Eval(interp, script) != TCL_OK) {
        fprintf(stderr, "Tcl_Eval error: %s\n", Tcl_GetStringResult(interp));
	free(script);
        return EXIT_FAILURE;
    }

    // Cleanup
    Tcl_DeleteInterp(interp);
    free(script);
    return EXIT_SUCCESS;
}

int main(int argc, char** argv)
{
	return test(argc, argv);
	config conf = {0};
	da_construct(conf.args, 5);
	da_construct(conf.flags, 5);
	da_construct(conf.config_packages, 50);
	da_construct(conf.installed_packages, 50);
	da_construct(conf.add_packages, 10);
	da_construct(conf.remove_packages, 10);
	for (int i = 1; i < argc; i++)
	{
		if (!parse_arg(&conf, argv[i]))
			display_help(conf.mode, 1);
	}

	// Display help
	da_append(conf.flags, '\0');
	if (strchr(conf.flags.items, 'h'))
		display_help(conf.mode, 0);

	pamde(&conf);

	int exit_code = 1;
	switch (conf.mode)
	{
	case 'S':
		exit_code = handle_sync(&conf);
		break;
	case 'Q':
		exit_code = handle_query(&conf);
		break;
	case 'T':
		exit_code = handle_temp(&conf);
		break;
	case 'C':
		exit_code = handle_container(&conf);
		break;
	case 'P':
		exit_code = handle_push(&conf);
		break;
	default: puts("unimplemented mode");
		exit_code = 1;
		break;
	}

	da_delete(conf.flags);
	da_delete(conf.args);
	da_delete(conf.config_packages);
	da_delete(conf.installed_packages);
	da_delete(conf.add_packages);
	da_delete(conf.remove_packages);

	return exit_code;
}
