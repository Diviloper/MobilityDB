//
// Created by Victor on 30/3/2024.
//


#include <stdio.h>
#include <meos.h>

/* Main program */
int main(void) {
    meos_initialize(NULL, NULL);

    Temporal *tint = tint_in("[1@2020-03-01, 10@2020-03-10]");
    Temporal *intdiv = div_tint_int(tint, 2);

    printf("Original: %s\n", tint_out(tint));
    printf("Divided by 2: %s\n", tint_out(intdiv));

    Temporal *tfloat = tfloat_in("[1@2020-03-01, 10@2020-03-10]");
    Temporal *div = div_tfloat_float(tfloat, 2.0);

    printf("Original: %s\n", tfloat_out(tfloat, 3));
    printf("Divided by 2: %s\n", tfloat_out(div, 3));

    meos_finalize();

    return 0;
}

