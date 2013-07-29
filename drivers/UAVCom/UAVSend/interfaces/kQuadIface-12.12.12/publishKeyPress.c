#include "ipc.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <time.h>

typedef struct KeyPress {
        char c;
} KeyPress;

void KeyPressHandler(MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
        KeyPress *key = (KeyPress*)callData;

        printf("got keypress! %c \n",key->c);
        IPC_freeByteArray(callData);
}

char getkey() {
        char character;
        struct termios orig_term_attr;
        struct termios new_term_attr;

        /* set the terminal to raw mode */
        tcgetattr(fileno(stdin), &orig_term_attr);
        memcpy(&new_term_attr, &orig_term_attr, sizeof(struct termios));
        new_term_attr.c_lflag &= ~(ECHO|ICANON);
        new_term_attr.c_cc[VTIME] = 0;
        new_term_attr.c_cc[VMIN] = 0;
        tcsetattr(fileno(stdin), TCSANOW, &new_term_attr);

        /* read a character from the stdin stream without blocking */
        /*   returns EOF (-1) if no character is available */
        character = fgetc(stdin);

        /* restore the original terminal attributes */
        tcsetattr(fileno(stdin), TCSANOW, &orig_term_attr);

        return character;
}

int main() {
        char c;
        KeyPress* key;
        IPC_setVerbosity(IPC_Print_Errors);
        if (IPC_connectModule("KeyPress",NULL) != IPC_OK) {
                printf("Error connecting to IPC\n");
                exit(1);
        }
        if (IPC_defineMsg("KeyPress",IPC_VARIABLE_LENGTH,"{ubyte}") != IPC_OK) {
                printf("ERROR defining message\n");
                exit(1);
        }
        if (IPC_subscribeData("KeyPress",KeyPressHandler,NULL) != IPC_OK) {
                printf("Error subscribing\n");
                exit(1);
        }
                
        while (1) {
//                IPC_listen(0);
                if((c=getkey())!=EOF) {
                        key->c=c;
                        if (IPC_publishData("KeyPress",key) != IPC_OK) {
                                printf("Error publishing\n");
                                exit(1);
                        }
                }
        }
        return 0;
}
