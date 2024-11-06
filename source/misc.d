module tenuki.misc;

import std.algorithm.iteration;
import std.random;

int weightedRandom(int[] weights)
{
    const int sum = weights.sum();
    int value = uniform(1, sum + 1);
    for (int i = 0; i < weights.length; i++) {
        if (weights[i] >= value) {
            return i;
        }
        value -= weights[i];
    }
    return -1;
}
