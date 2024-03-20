#ifndef SOCKET_H
#define SOCKET_H

#include "risa.h"

void stopServer(rv32iHart_t *cpu);
int startServer(rv32iHart_t *cpu);
int readSocket(int clientSocket, char *packet, size_t len);
int writeSocket(int clientSocket, const char *packet, size_t len);

enum read_socket_err {
    READ_SOCKET_OK,
    READ_SOCKET_ERR_INVALID_ARG,
    READ_SOCKET_ERR_RECV,
    READ_SOCKET_SHUTDOWN
};

#endif // SOCKET_H
