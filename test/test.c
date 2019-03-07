#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
    int *c = malloc(10);
    free(c);
    return EXIT_SUCCESS;
}
