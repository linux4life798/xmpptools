/**@file xmppsend.c
 * @author Craig Hesling <craig@hesling.com>
 * @date June 30, 2015
 * This is program is a utility to send and receive xmpp stanzas.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <strophe.h>

#define XMPP_MESSAGE_SIZE_MAX 8192

int ready = 0;
int recv_response = 0;

/* define a handler for connection events */
void conn_handler(xmpp_conn_t * const conn, const xmpp_conn_event_t status,
                  const int error, xmpp_stream_error_t * const stream_error,
                  void * const userdata)
{
	xmpp_ctx_t *ctx = (xmpp_ctx_t *)userdata;

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
	}
	else {
		fprintf(stderr, "DEBUG: disconnected\n");
		xmpp_stop(ctx);
	}
}

int all_message_handler(xmpp_conn_t * const conn,
					xmpp_stanza_t * const stanza,
					void * const userdata)
{
	char *rawtext;
	size_t rawtext_size;
	xmpp_ctx_t *ctx = (xmpp_ctx_t *)userdata;
	xmpp_stanza_to_text(stanza, &rawtext, &rawtext_size);
	fprintf(stdout, "%s\n", rawtext);
	fflush(stdout);
	xmpp_free(ctx, rawtext);

	return 1;
}

int message_handler(xmpp_conn_t * const conn,
					xmpp_stanza_t * const stanza,
					void * const userdata)
{
	char *rawtext;
	size_t rawtext_size;
	xmpp_ctx_t *ctx = (xmpp_ctx_t *)userdata;
	xmpp_stanza_to_text(stanza, &rawtext, &rawtext_size);
	fprintf(stdout, "%s\n", rawtext);
	xmpp_free(ctx, rawtext);

	recv_response = 1;
	return 0;
}

/**
 * xmppsend <jid> <pass> [stanza_id]
 */
int main(int argc, char **argv)
{
	xmpp_ctx_t *ctx;
	xmpp_conn_t *conn;
	xmpp_log_t *log;
	char *jid, *pass, *host, *stanza_id;
	unsigned short port = 0;
	char *xml;
	size_t xml_count;

	/* take a jid, password, and optionally a stanza_id on the command line */
	if (argc < 3 || argc > 4) {
		fprintf(stderr, "Usage: xmppsend <jid> <pass> [stanza_id]\n\n");
		return 1;
	}

	jid = argv[1];
	pass = argv[2];
	host = NULL;

	/* if we should wait for response stanza id */
	stanza_id = NULL;
	if (argc == 4) {
		stanza_id = argv[3];
	}

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

	/* enter the event loop -
	our connect handler will trigger an exit */
	//xmpp_run(ctx);
	while(!ready) {
		xmpp_run_once(ctx, 10);
	}

	if (stanza_id) {
		xmpp_id_handler_add(conn, message_handler, stanza_id, (void *)ctx);
	}
//	xmpp_handler_add(conn, all_message_handler, NULL, "message", NULL, (void *)ctx);

	xml = (char *) calloc(XMPP_MESSAGE_SIZE_MAX, sizeof('\0'));
	while((xml_count = fread(xml, sizeof('\0'), XMPP_MESSAGE_SIZE_MAX-1, stdin))) {
		xml[XMPP_MESSAGE_SIZE_MAX-1] = '\0';
		/* we must omit the trailing '\0' */
		xmpp_send_raw(conn, xml, strlen(xml));
//		xmpp_send_raw_string(conn, xml);
		fprintf(stderr, "Sending (%lu bytes):\n%s\n", strlen(xml), xml);
	}
	free(xml);

	xmpp_run_once(ctx, 10);

	/* wait for response if we are suposed to */
	if (stanza_id) {
		while(!recv_response) {
			xmpp_run_once(ctx, 10);
		}
	}

//	xmpp_run(ctx);
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
