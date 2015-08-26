/**@file xmpprecv.c
 * @author Craig Hesling <craig@hesling.com>
 * @date August 5, 2015
 * This is program is a utility to receive xmpp stanzas.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stddef.h> /* NULL */
#include <string.h>
#include <signal.h>
#include <assert.h>
#include <ctype.h>

#include <strophe.h>

#define XMPP_MESSAGE_SIZE_MAX 4096

int ready = 0;
int recv_response = 0;
int doExit = 0;

/**
 * The blob of data to transfer to filter handlers
 */
struct handler_data {
	xmpp_ctx_t *ctx;
	const char *op1;
	const char *op2;
	const char *op3;
};

/**
 * Interprets NULL given as a string.
 * @param filter The commandline argument to interpret
 * @return The interpreted argument
 */
const char *interpret_filter(const char *filter) {
	assert(filter);
	if (strcmp(filter, "NULL") == 0) {
		return NULL ;
	}
	return filter;
}

/* define a handler for connection events */
void conn_handler(	xmpp_conn_t * const conn,
					const xmpp_conn_event_t status,
					const int error,
					xmpp_stream_error_t * const stream_error,
					void * const userdata) {
	xmpp_ctx_t *ctx = (xmpp_ctx_t *) userdata;

	if (status == XMPP_CONN_CONNECT) {
		xmpp_stanza_t *pres;
		fprintf(stderr, "DEBUG: connected\n");
		//xmpp_disconnect(conn);

		/* Send initial <presence/> so that we appear online to contacts */
		pres = xmpp_stanza_new(ctx);
		xmpp_stanza_set_name(pres, "presence");
		xmpp_send(conn, pres);
		xmpp_stanza_release(pres);

		ready = 1;
	} else {
		fprintf(stderr, "DEBUG: disconnected\n");
		xmpp_stop(ctx);
	}
}

/**
 * Prints the given stanza.
 * @param ctx The context to free from
 * @param stanza The stanza to display
 */
void print_stanza(xmpp_ctx_t *ctx, xmpp_stanza_t * const stanza) {
	char *rawtext;
	size_t rawtext_size;
	xmpp_stanza_to_text(stanza, &rawtext, &rawtext_size);
	fprintf(stdout, "%s\n", rawtext);
	fflush(stdout);
	xmpp_free(ctx, rawtext);
}

int handler_dump(	xmpp_conn_t * const conn,
					xmpp_stanza_t * const stanza,
					void * const userdata) {
	struct handler_data *hdata = (struct handler_data *) userdata;
	print_stanza(hdata->ctx, stanza);
	return 1;
}

int handler_pubsub(	xmpp_conn_t * const conn,
					xmpp_stanza_t * const stanza,
					void * const userdata) {
	xmpp_stanza_t *event;
	xmpp_stanza_t *items;
	struct handler_data *hdata = (struct handler_data *) userdata;
	const char *node = hdata->op1;
	assert(hdata->op2 == NULL);
	assert(hdata->op3 == NULL);

	event = xmpp_stanza_get_child_by_ns(stanza, "http://jabber.org/protocol/pubsub#event");
	if(event == NULL) {
		/* not PubSub */
		return 1;
	}

	if(node == NULL) {
		print_stanza(hdata->ctx, stanza);
		return 1;
	}

	items = xmpp_stanza_get_children(event);
	while (items) {
		/* check that it is an item */
		if(strcmp(xmpp_stanza_get_name(items), "items") == 0) {
			/* check node id */
			if(strcmp(xmpp_stanza_get_attribute(items, "node"), node) == 0) {
				print_stanza(hdata->ctx, items);
			}
		}
		items = xmpp_stanza_get_next(items);
	}

	return 1;
}

/**
 * Signal to main loop to exit gracefully
 * @param[in] sig The signal number passed in from libc
 */
void sigint_handler(int sig) {
	fprintf(stderr, "# Attempting exit\n");
	doExit = 1;
}


/**
 * Standard Handler Filter:
 * xmpprecv <jid> <pass> -s [name [type [ns]]]
 * PubSub Filter:
 * xmpprecv <jid> <pass> -p <node>
 */
int main(int argc, char **argv) {
	xmpp_ctx_t *ctx;
	xmpp_conn_t *conn;
	xmpp_log_t *log;
	/* command line options */
	char *jid, *pass, *host, *action;
	const char *op1, *op2, *op3;
	struct handler_data hdata;
	unsigned short port = 0;

	/* take a jid, password, action and options on the command line */
	if (argc < 4 || argc > 7 || (strcmp(argv[1], "--help")==0)) {
		fprintf(stderr,
				"Usage: xmpprecv <jid> <pass> [ -s [name [type [ns]]] | -p [node] ]\n\n");
		return 1;
	}

	jid = argv[1];
	pass = argv[2];
	host = NULL;
	action = argv[3];

	if ((strlen(action) != 2) || (action[0] != '-') || (!isalpha(action[1]))) {
		fprintf(stderr, "Error - Invalid action specifier\n");
		return 1;
	}

	/* setup action options/filters */
	switch (action[1]) {
	case 's':
		fprintf(stderr, "Handler filter specified\n");
		op1 = op2 = op3 = NULL;

		if (argc > 4) {
			op1 = interpret_filter(argv[4]);
		}
		if (argc > 5) {
			op2 = interpret_filter(argv[5]);
		}
		if (argc > 6) {
			op3 = interpret_filter(argv[6]);
		}
		break;
	case 'p':
		fprintf(stderr, "PubSub filter specified\n");
		op1 = op2 = op3 = NULL;

		if (argc == 5) {
			op1 = interpret_filter(argv[4]);
		}
		break;
	default:
		fprintf(stderr, "Error - Invalid action\n");
		exit(1);
		break;
	}

	/* setup handler data  */
	hdata.op1 = op1;
	hdata.op2 = op2;
	hdata.op3 = op3;

	signal(SIGINT, sigint_handler);

	/* init library */
	xmpp_initialize();

	/* create a context */
	//log = xmpp_get_default_logger(XMPP_LEVEL_DEBUG); /* pass NULL instead to silence output */
	//log = xmpp_get_default_logger(XMPP_LEVEL_INFO); /* pass NULL instead to silence output */
	log = xmpp_get_default_logger(XMPP_LEVEL_WARN); /* pass NULL instead to silence output */
	//log = xmpp_get_default_logger(XMPP_LEVEL_ERROR); /* pass NULL instead to silence output */
	ctx = xmpp_ctx_new(NULL, log);

	/* create a connection */
	conn = xmpp_conn_new(ctx);

	/* setup authentication information */
	xmpp_conn_set_jid(conn, jid);
	xmpp_conn_set_pass(conn, pass);

	/* initiate connection */
	xmpp_connect_client(conn, host, port, conn_handler, ctx);

	hdata.ctx = ctx;

	/*-------- Opened Connection --------*/

	switch (action[1]) {
	case 's':
		xmpp_handler_add(conn, handler_dump, op3, op1, op2, (void *) &hdata);
		//xmpp_id_handler_add(conn, message_handler, stanza_id, (void *)ctx);
		break;
	case 'p':
		xmpp_handler_add(conn, handler_pubsub, NULL, "message", "headline",
							(void *) &hdata);
		break;
	default:
		fprintf(stderr, "Error - Invalid option\n");
		return 1;
		break;
	}

	while(!doExit) {
		xmpp_run_once(ctx, 10);
	}

	/*-------- Close Connection --------*/

	xmpp_stop(ctx);
	xmpp_disconnect(conn);

	/* release our connection and context */
	xmpp_conn_release(conn);
	xmpp_ctx_free(ctx);

	/* final shutdown of the library */
	xmpp_shutdown();

	return 0;
}

/* vim: set noexpandtab ts=4 : */
