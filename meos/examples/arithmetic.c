//
// Created by Victor on 30/3/2024.
//


#include <stdio.h>
#include <meos.h>

/* Main program */
int main(void) {
    meos_initialize(NULL, NULL);

    Temporal *tint = tint_in("[1@2020-03-01, 10@2020-03-10]");
    fprintf(stderr, "Original: %s\n", tint_out(tint));

    Temporal *intadd = add_tint_int(tint, 2);
    fprintf(stderr, "Added by 2: %s\n", tint_out(intadd));

    Temporal *intdiv = div_tint_int(tint, 2);
    fprintf(stderr, "Divided by 2: %s\n", tint_out(intdiv));

    Temporal *tfloat = tfloat_in("[1@2020-03-01, 10@2020-03-10]");
    fprintf(stderr, "Original: %s\n", tfloat_out(tfloat, 3));

    Temporal *add = add_tfloat_float(tfloat, 2.0);
    fprintf(stderr, "Added by 2: %s\n", tfloat_out(add, 3));

    Temporal *div = div_tfloat_float(tfloat, 2.0);
    fprintf(stderr, "Divided by 2: %s\n", tfloat_out(div, 3));

    meos_finalize();

    return 0;
}

