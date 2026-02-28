#ifndef ACA_GDBSTUB_H
#define ACA_GDBSTUB_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define ACA_GDBSTUB_ACK_PACKET "+"
#define ACA_GDBSTUB_RESEND_PACKET "-"
#define ACA_GDBSTUB_EMPTY_PACKET "$#00"
#define ACA_GDBSTUB_ERROR_PACKET "$E00#96"
#define ACA_GDBSTUB_OK_PACKET "$OK#9a"

// Log/trace/debug macros
#define ACA_GDBSTUB_FILENAME (strrchr(__FILE__, '/') ? strrchr(__FILE__, '/') + 1 : __FILE__)
#define ACA_GDBSTUB_LOG_I(msg, ...)                                                                \
    printf("[aca_gdbstub] INFO  [ %12s:%-6d ]%20s : " msg,                                         \
           ACA_GDBSTUB_FILENAME,                                                                   \
           __LINE__,                                                                               \
           __func__,                                                                               \
           ##__VA_ARGS__)
#define ACA_GDBSTUB_LOG_W(msg, ...)                                                                \
    printf("[aca_gdbstub] WARN  [ %12s:%-6d ]%20s : " msg,                                         \
           ACA_GDBSTUB_FILENAME,                                                                   \
           __LINE__,                                                                               \
           __func__,                                                                               \
           ##__VA_ARGS__)
#define ACA_GDBSTUB_LOG_E(msg, ...)                                                                \
    printf("[aca_gdbstub] ERROR [ %12s:%-6d ]%20s : " msg,                                         \
           ACA_GDBSTUB_FILENAME,                                                                   \
           __LINE__,                                                                               \
           __func__,                                                                               \
           ##__VA_ARGS__)
#define ACA_GDBSTUB_LOG_TRACE(msg, ...) printf("[aca_gdbstub] : " msg, ##__VA_ARGS__)
#define ACA_GDBSTUB_SEND "GDB <--- ACA_GDBSTUB"
#define ACA_GDBSTUB_RECV "GDB ---> ACA_GDBSTUB"

#define ACA_GDBSTUB_HEX_DECODE_ASCII(in, out) out = strtol(in, NULL, 16)
#define ACA_GDBSTUB_HEX_ENCODE_ASCII(in, len, out) snprintf(out, len, "%x", in)
#define ACA_GDBSTUB_DEC_ENCODE_ASCII(in, len, out) snprintf(out, len, "%d", in)

// Set if error and return early
#define ACA_GDBSTUB_CHECK_RET(ret, gdbstubObj)                                                     \
    do {                                                                                           \
        gdbstubObj->err = ret;                                                                     \
        if (gdbstubObj->err != ACA_GDBSTUB_SUCCESS) {                                              \
            return;                                                                                \
        }                                                                                          \
    } while (0)

enum { ACA_GDBSTUB_SUCCESS, ACA_GDBSTUB_ALLOC_FAILED };
enum {
    ACA_GDBSTUB_SOFT_BREAKPOINT = (1 << 0),
    ACA_GDBSTUB_HARD_BREAKPOINT = (1 << 1),

    ACA_GDBSTUB_SET_BREAKPOINT   = (1 << 2),
    ACA_GDBSTUB_CLEAR_BREAKPOINT = (1 << 3)
};

// Basic dynamic char array utility for reading GDB packets
typedef struct {
    char  *buffer;
    size_t used;
    size_t size;
} aca_dynamic_char_buffer;

// GDB Remote Serial Protocol packet objects
typedef struct {
    char                    commandType;
    aca_dynamic_char_buffer pktData;
    char                    checksum[3];
} aca_gdb_packet;

typedef struct {
    unsigned int o_signalOnEntry : 1;
    unsigned int o_enableLogging : 1;
} aca_gdbstub_opts;

typedef struct {
    char            *regs;      // Pointer to register array
    size_t           regsSize;  // Size of register array in bytes
    size_t           regsCount; // Total number of registers
    int              signalNum; // Signal that can be sent to GDB on certain operations
    aca_gdbstub_opts opts;      // Options bitfield
    int              err;       // Return-error code
    void            *usrData;   // Optional handle to opaque user data
} aca_gdbstub_context;

// User-implemented functions for target-specific operations - these must be implemented by the user
// of the aca_gdbstub library to handle interactions with the target system
// (e.g. reading/writing memory, continuing execution, etc.)
void          acaGdbstubPutcharStub(char data, void *usrData);
char          acaGdbstubGetcharStub(void *usrData);
void          acaGdbstubWriteMemStub(size_t addr, unsigned char data, void *usrData);
unsigned char acaGdbstubReadMemStub(size_t addr, void *usrData);
void          acaGdbstubContinueStub(void *usrData);
void          acaGdbstubStepStub(void *usrData);
void          acaGdbstubProcessBreakpointStub(int type, size_t addr, void *usrData);
void          acaGdbstubKillSessionStub(void *usrData);

// aca_gdbstub library main API
void acaGdbstubComputeChecksum(char *buffer, size_t len, char *outBuf);
void acaGdbstubSend(const char *data, aca_gdbstub_context *gdbstubObj);
void acaGdbstubRecv(aca_gdbstub_context *gdbstubObj, aca_gdb_packet *gdbPkt);
void acaGdbstubWriteRegs(aca_gdbstub_context *gdbstubObj, aca_gdb_packet *recvPkt);
void acaGdbstubWriteReg(aca_gdbstub_context *gdbstubObj, aca_gdb_packet *recvPkt);
void acaGdbstubSendRegs(aca_gdbstub_context *gdbstubObj);
void acaGdbstubSendReg(aca_gdbstub_context *gdbstubObj, aca_gdb_packet *recvPkt);
void acaGdbstubWriteMem(aca_gdbstub_context *gdbstubObj, aca_gdb_packet *recvPkt);
void acaGdbstubReadMem(aca_gdbstub_context *gdbstubObj, aca_gdb_packet *recvPkt);
void acaGdbstubSendSignal(aca_gdbstub_context *gdbstubObj);
void acaGdbstubProcessBreakpoint(aca_gdbstub_context *gdbstubObj,
                                 aca_gdb_packet      *recvPkt,
                                 int                  type);
void acaGdbstubProcess(aca_gdbstub_context *gdbstubObj);
int  acaDynamicCharBufferInit(aca_dynamic_char_buffer *buf, size_t startSize);
int  acaDynamicCharBufferInsert(aca_dynamic_char_buffer *buf, char item);
void acaDynamicCharBufferFree(aca_dynamic_char_buffer *buf);

#ifdef ACA_GDBSTUB_IMPLEMENTATION

int acaDynamicCharBufferInit(aca_dynamic_char_buffer *buf, size_t startSize) {
    buf->buffer = (char *)malloc(startSize * sizeof(char));
    if (buf->buffer == NULL) {
        ACA_GDBSTUB_LOG_E("Failed to alloc memory!\n");
        return ACA_GDBSTUB_ALLOC_FAILED;
    }
    buf->used = 0;
    buf->size = startSize;
    return ACA_GDBSTUB_SUCCESS;
}
int acaDynamicCharBufferInsert(aca_dynamic_char_buffer *buf, char item) {
    // Realloc if buffer is full - double the array size
    if (buf->used == buf->size) {
        buf->size *= 2;
        buf->buffer = (char *)realloc(buf->buffer, buf->size);
        if (buf->buffer == NULL) {
            ACA_GDBSTUB_LOG_E("Failed to realloc memory!\n");
            return ACA_GDBSTUB_ALLOC_FAILED;
        }
    }
    buf->buffer[buf->used++] = item;
    return ACA_GDBSTUB_SUCCESS;
}
void acaDynamicCharBufferFree(aca_dynamic_char_buffer *buf) {
    free(buf->buffer);
    buf->buffer = NULL;
    buf->used = buf->size = 0;
}

void acaGdbstubComputeChecksum(char *buffer, size_t len, char *outBuf) {
    unsigned int checksum = 0;
    for (size_t i = 0; i < len; ++i) {
        checksum = (checksum + buffer[i]) % 256;
    }
    ACA_GDBSTUB_HEX_ENCODE_ASCII(checksum, 3, outBuf);

    // If the value is single digit
    if (outBuf[1] == 0) {
        outBuf[1] = outBuf[0];
        outBuf[0] = '0';
    }
}

void acaGdbstubSend(const char *data, aca_gdbstub_context *gdbstubObj) {
    size_t len = strlen(data);
    if (gdbstubObj->opts.o_enableLogging) {
        ACA_GDBSTUB_LOG_TRACE(ACA_GDBSTUB_SEND " : packet = %s\n", data);
    }
    for (size_t i = 0; i < len; ++i) {
        acaGdbstubPutcharStub(data[i], gdbstubObj->usrData);
    }
}

void acaGdbstubRecv(aca_gdbstub_context *gdbstubObj, aca_gdb_packet *gdbPkt) {
    int  currentOffset = 0;
    char c;
    while (1) {
        // Get the beginning of the packet data '$'
        while (1) {
            c = acaGdbstubGetcharStub(gdbstubObj->usrData);
            if (c == '$') {
                break;
            }
        }

        // Read packet data until the end '#' - then read the remaining 2 checksum digits
        while (1) {
            c = acaGdbstubGetcharStub(gdbstubObj->usrData);
            if (c == '#') {
                gdbPkt->checksum[0] = acaGdbstubGetcharStub(gdbstubObj->usrData);
                gdbPkt->checksum[1] = acaGdbstubGetcharStub(gdbstubObj->usrData);
                gdbPkt->checksum[2] = 0;
                ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInsert(&gdbPkt->pktData, 0), gdbstubObj);
                break;
            }
            ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInsert(&gdbPkt->pktData, c), gdbstubObj);
            ++currentOffset;
        }

        // Compute checksum and compare with expected checksum
        // Request retransmission if checksum verification fails
        char actualChecksum[8] = {0, 0, 0, 0, 0, 0, 0, 0};
        acaGdbstubComputeChecksum(gdbPkt->pktData.buffer, currentOffset, actualChecksum);
        if (strcmp(gdbPkt->checksum, actualChecksum) != 0) {
            gdbPkt->pktData.used = 0;
            acaGdbstubSend(ACA_GDBSTUB_RESEND_PACKET, gdbstubObj);
            continue;
        }

        gdbPkt->commandType = gdbPkt->pktData.buffer[0];
        if (gdbstubObj->opts.o_enableLogging) {
            ACA_GDBSTUB_LOG_TRACE(
                ACA_GDBSTUB_RECV " : packet = $%s#%s\n", gdbPkt->pktData.buffer, gdbPkt->checksum);
        }
        acaGdbstubSend(ACA_GDBSTUB_ACK_PACKET, gdbstubObj);
        return;
    }
}

void acaGdbstubWriteRegs(aca_gdbstub_context *gdbstubObj, aca_gdb_packet *recvPkt) {
    char tmpBuf[8];
    int  decodedHex;
    for (size_t i = 0; i < recvPkt->pktData.size - 1; ++i) {
        tmpBuf[i % 2] = recvPkt->pktData.buffer[i];
        if ((i % 2) != 0) {
            ACA_GDBSTUB_HEX_DECODE_ASCII(tmpBuf, decodedHex);
            gdbstubObj->regs[i / 2] = (char)decodedHex;
        }
    }
}

void acaGdbstubWriteReg(aca_gdbstub_context *gdbstubObj, aca_gdb_packet *recvPkt) {
    int    index, valOffset = 0;
    size_t regWidth = gdbstubObj->regsSize / gdbstubObj->regsCount;
    for (int i = 0; recvPkt->pktData.buffer[i] != 0; ++i) {
        if (recvPkt->pktData.buffer[i] == '=') {
            recvPkt->pktData.buffer[i] = 0;
            ++valOffset;
            break;
        }
        ++valOffset;
    }
    ACA_GDBSTUB_HEX_DECODE_ASCII(&recvPkt->pktData.buffer[1], index);

    aca_gdbstub_context tmpProcObj = *gdbstubObj;
    tmpProcObj.regsCount           = 1;
    tmpProcObj.regs                = &gdbstubObj->regs[index * regWidth];
    tmpProcObj.regsSize            = regWidth;

    aca_gdb_packet tmpRecPkt = *recvPkt;
    tmpRecPkt.pktData.buffer = &recvPkt->pktData.buffer[valOffset];

    acaGdbstubWriteRegs(&tmpProcObj, &tmpRecPkt);
    if (tmpProcObj.err != ACA_GDBSTUB_SUCCESS) {
        gdbstubObj->err = tmpProcObj.err;
    }
}

void acaGdbstubSendRegs(aca_gdbstub_context *gdbstubObj) {
    aca_dynamic_char_buffer sendPkt;
    ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInit(&sendPkt, 512), gdbstubObj);
    ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInsert(&sendPkt, '$'), gdbstubObj);

    for (size_t i = 0; i < gdbstubObj->regsSize; ++i) {
        char itoaBuff[8];
        ACA_GDBSTUB_HEX_ENCODE_ASCII((unsigned char)gdbstubObj->regs[i], 3, itoaBuff);

        // Swap if single digit
        if (itoaBuff[1] == 0) {
            itoaBuff[1] = itoaBuff[0];
            itoaBuff[0] = '0';
        }

        ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInsert(&sendPkt, itoaBuff[0]), gdbstubObj);
        ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInsert(&sendPkt, itoaBuff[1]), gdbstubObj);
    }

    // Compute and append the checksum
    char   checksum[8];
    size_t len = sendPkt.used - 1;
    acaGdbstubComputeChecksum(&sendPkt.buffer[1], len, checksum);
    ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInsert(&sendPkt, '#'), gdbstubObj);
    ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInsert(&sendPkt, checksum[0]), gdbstubObj);
    ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInsert(&sendPkt, checksum[1]), gdbstubObj);
    ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInsert(&sendPkt, 0), gdbstubObj);

    acaGdbstubSend((const char *)sendPkt.buffer, gdbstubObj);
    acaDynamicCharBufferFree(&sendPkt);
}

void acaGdbstubSendReg(aca_gdbstub_context *gdbstubObj, aca_gdb_packet *recvPkt) {
    int    index;
    size_t regWidth = gdbstubObj->regsSize / gdbstubObj->regsCount;
    ACA_GDBSTUB_HEX_DECODE_ASCII(&recvPkt->pktData.buffer[2], index);

    aca_gdbstub_context tmpProcObj = *gdbstubObj;
    tmpProcObj.regsCount           = 1;
    tmpProcObj.regs                = &gdbstubObj->regs[index * regWidth];
    tmpProcObj.regsSize            = regWidth;

    acaGdbstubSendRegs(&tmpProcObj);
    if (tmpProcObj.err != ACA_GDBSTUB_SUCCESS) {
        gdbstubObj->err = tmpProcObj.err;
    }
}

void acaGdbstubWriteMem(aca_gdbstub_context *gdbstubObj, aca_gdb_packet *recvPkt) {
    size_t address, length;
    int    lengthOffset = 0;
    int    valOffset    = 0;

    // Grab the length offset
    for (int i = 0; recvPkt->pktData.buffer[i] != 0; ++i) {
        if ((recvPkt->pktData.buffer[i] == ',') || (recvPkt->pktData.buffer[i] == ';') ||
            (recvPkt->pktData.buffer[i] == ':')) {
            recvPkt->pktData.buffer[i] = 0;
            ++lengthOffset;
            valOffset = lengthOffset;
            break;
        }
        ++lengthOffset;
    }
    // Grab the data value offset
    for (int i = 0; recvPkt->pktData.buffer[i] != 0; ++i) {
        if ((recvPkt->pktData.buffer[i] == ',') || (recvPkt->pktData.buffer[i] == ';') ||
            (recvPkt->pktData.buffer[i] == ':')) {
            recvPkt->pktData.buffer[i] = 0;
            ++valOffset;
            break;
        }
        ++valOffset;
    }
    ACA_GDBSTUB_HEX_DECODE_ASCII(&recvPkt->pktData.buffer[1], address);
    ACA_GDBSTUB_HEX_DECODE_ASCII(&recvPkt->pktData.buffer[lengthOffset], length);

    // Call user write memory handler
    for (size_t i = 0; i < length; ++i) {
        int  decodedVal;
        char atoiBuf[8];
        atoiBuf[0] = recvPkt->pktData.buffer[valOffset + (i * 2)];
        atoiBuf[1] = recvPkt->pktData.buffer[valOffset + (i * 2) + 1];
        ACA_GDBSTUB_HEX_DECODE_ASCII(atoiBuf, decodedVal);
        acaGdbstubWriteMemStub(address + i, (unsigned char)decodedVal, gdbstubObj->usrData);
    }

    // Send ACK to GDB
    acaGdbstubSend(ACA_GDBSTUB_ACK_PACKET, gdbstubObj);
}

void acaGdbstubReadMem(aca_gdbstub_context *gdbstubObj, aca_gdb_packet *recvPkt) {
    size_t address, length;
    int    valOffset = 0;
    for (int i = 0; recvPkt->pktData.buffer[i] != 0; ++i) {
        if ((recvPkt->pktData.buffer[i] == ',') || (recvPkt->pktData.buffer[i] == ';') ||
            (recvPkt->pktData.buffer[i] == ':')) {
            recvPkt->pktData.buffer[i] = 0;
            ++valOffset;
            break;
        }
        ++valOffset;
    }
    ACA_GDBSTUB_HEX_DECODE_ASCII(&recvPkt->pktData.buffer[1], address);
    ACA_GDBSTUB_HEX_DECODE_ASCII(&recvPkt->pktData.buffer[valOffset], length);

    // Alloc a packet w/ the requested data to send as a response to GDB
    aca_dynamic_char_buffer memBuf;
    ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInit(&memBuf, length), gdbstubObj);
    ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInsert(&memBuf, '$'), gdbstubObj);

    // Call user read memory handler
    for (size_t i = 0; i < length; ++i) {
        char          itoaBuff[8];
        unsigned char c = acaGdbstubReadMemStub(address + i, gdbstubObj->usrData);
        ACA_GDBSTUB_HEX_ENCODE_ASCII(c, 3, itoaBuff);

        // Swap if single digit
        if (itoaBuff[1] == 0) {
            itoaBuff[1] = itoaBuff[0];
            itoaBuff[0] = '0';
        }

        ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInsert(&memBuf, itoaBuff[0]), gdbstubObj);
        ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInsert(&memBuf, itoaBuff[1]), gdbstubObj);
    }

    // Compute and append the checksum
    char   checksum[8];
    size_t len = memBuf.used - 1;
    acaGdbstubComputeChecksum(&memBuf.buffer[1], len, checksum);
    ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInsert(&memBuf, '#'), gdbstubObj);
    ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInsert(&memBuf, checksum[0]), gdbstubObj);
    ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInsert(&memBuf, checksum[1]), gdbstubObj);
    ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInsert(&memBuf, 0), gdbstubObj);

    acaGdbstubSend((const char *)memBuf.buffer, gdbstubObj);
    acaDynamicCharBufferFree(&memBuf);
}

void acaGdbstubSendSignal(aca_gdbstub_context *gdbstubObj) {
    aca_dynamic_char_buffer sendPkt;
    ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInit(&sendPkt, 32), gdbstubObj);
    ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInsert(&sendPkt, '$'), gdbstubObj);
    ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInsert(&sendPkt, 'S'), gdbstubObj);

    // Convert signal num to hex char array
    char itoaBuff[8] = {0, 0, 0, 0, 0, 0, 0, 0};
    ACA_GDBSTUB_DEC_ENCODE_ASCII(gdbstubObj->signalNum, 8, itoaBuff);

    // Swap if single digit
    if (itoaBuff[1] == 0) {
        itoaBuff[1] = itoaBuff[0];
        itoaBuff[0] = '0';
    }

    int bufferPtr = 0;
    while (itoaBuff[bufferPtr] != 0) {
        ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInsert(&sendPkt, itoaBuff[bufferPtr]),
                              gdbstubObj);
        ++bufferPtr;
    }
    ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInsert(&sendPkt, '#'), gdbstubObj);

    // Add the two checksum hex chars
    char checksumHex[8] = {0, 0, 0, 0, 0, 0, 0, 0};
    acaGdbstubComputeChecksum(&sendPkt.buffer[1], bufferPtr + 1, checksumHex);
    ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInsert(&sendPkt, checksumHex[0]), gdbstubObj);
    ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInsert(&sendPkt, checksumHex[1]), gdbstubObj);
    ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInsert(&sendPkt, 0), gdbstubObj);

    acaGdbstubSend((const char *)sendPkt.buffer, gdbstubObj);
    acaDynamicCharBufferFree(&sendPkt);
}

void acaGdbstubProcessBreakpoint(aca_gdbstub_context *gdbstubObj,
                                 aca_gdb_packet      *recvPkt,
                                 int                  type) {
    int    offset = 0;
    size_t address;
    for (int i = 0; recvPkt->pktData.buffer[i] != 0; ++i) {
        if ((recvPkt->pktData.buffer[i] == ',') || (recvPkt->pktData.buffer[i] == ';') ||
            (recvPkt->pktData.buffer[i] == ':')) {
            if (offset > 0) {
                recvPkt->pktData.buffer[i] = 0;
                break;
            }
            offset = i + 1;
        }
    }
    ACA_GDBSTUB_HEX_DECODE_ASCII(&recvPkt->pktData.buffer[offset], address);

    switch (recvPkt->pktData.buffer[2]) {
        case '0': // Software breakpoint
            type |= ACA_GDBSTUB_SOFT_BREAKPOINT;
            break;
        case '1': // Hardware breakpoint
            type |= ACA_GDBSTUB_HARD_BREAKPOINT;
            break;
        default: // Other breakpoint/watchpoint type (unsupported)
            break;
    }
    acaGdbstubProcessBreakpointStub(type, address, gdbstubObj->usrData);

    // Send ACK + OK to GDB
    acaGdbstubSend(ACA_GDBSTUB_ACK_PACKET, gdbstubObj);
    acaGdbstubSend(ACA_GDBSTUB_OK_PACKET, gdbstubObj);
}

// Main gdb stub process call
void acaGdbstubProcess(aca_gdbstub_context *gdbstubObj) {
    if (gdbstubObj->opts.o_signalOnEntry) {
        acaGdbstubSendSignal(gdbstubObj);
    }
    // Poll and reply to packets from GDB until exit-related command
    while (1) {
        aca_gdb_packet recvPkt;
        ACA_GDBSTUB_CHECK_RET(acaDynamicCharBufferInit(&recvPkt.pktData, 256), gdbstubObj);
        acaGdbstubRecv(gdbstubObj, &recvPkt);

        switch (recvPkt.commandType) {
            case 'g': { // Read registers
                acaGdbstubSendRegs(gdbstubObj);
                break;
            }
            case 'G': { // Write registers
                acaGdbstubWriteRegs(gdbstubObj, &recvPkt);
                break;
            }
            case 'p': { // Read one register
                acaGdbstubSendReg(gdbstubObj, &recvPkt);
                break;
            }
            case 'P': { // Write one register
                acaGdbstubWriteReg(gdbstubObj, &recvPkt);
                break;
            }
            case 'm': { // Read mem
                acaGdbstubReadMem(gdbstubObj, &recvPkt);
                break;
            }
            case 'M': { // Write mem
                acaGdbstubWriteMem(gdbstubObj, &recvPkt);
                break;
            }
            case 'c': { // Continue
                acaGdbstubContinueStub(gdbstubObj->usrData);
                return;
            }
            case 's': { // Step
                acaGdbstubStepStub(gdbstubObj->usrData);
                return;
            }
            case 'Z': { // Place breakpoint
                acaGdbstubProcessBreakpoint(gdbstubObj, &recvPkt, ACA_GDBSTUB_SET_BREAKPOINT);
                break;
            }
            case 'z': { // Remove breakpoint
                acaGdbstubProcessBreakpoint(gdbstubObj, &recvPkt, ACA_GDBSTUB_CLEAR_BREAKPOINT);
                break;
            }
            case 'k': { // Kill session
                acaGdbstubKillSessionStub(gdbstubObj->usrData);
                return;
            }
            case '?': { // Indicate reason why target halted
                acaGdbstubSendSignal(gdbstubObj);
                break;
                ;
            }
            default: { // Command unsupported
                acaGdbstubSend(ACA_GDBSTUB_EMPTY_PACKET, gdbstubObj);
                break;
            }
        }
        // Cleanup packet mem
        acaDynamicCharBufferFree(&recvPkt.pktData);
    }
}

#endif // ACA_GDBSTUB_IMPLEMENTATION

#endif // ACA_GDBSTUB_H
