pragma circom 2.0.0;

include "./mimcsponge.circom";

template MerkleHashGenerator(N) {  
    signal input in[N];
    signal input k;
    signal output out;
    signal nodeHashes[(N*2)-1];

    component mimc1[N];

    for(var i = 0; i < N; i++) {
        mimc1[i] = MiMCSponge(1, 220, 1);
        mimc1[i].ins[0] <== in[i];
        mimc1[i].k <== k;
        nodeHashes[i] <== mimc1[i].outs[0];
    }

    component mimc2[N-1];

    var n = N;
    var offset = 0;
    var j = N;
    var q = 0;
    while( n > 0 ) {
        for (var i = 0; i < n - 1; i += 2) {
            mimc2[q] = MiMCSponge(2, 220, 1);
            mimc2[q].ins[0] <== nodeHashes[offset + i];
            mimc2[q].ins[1] <== nodeHashes[offset + i + 1];
            mimc2[q].k <== k;
            nodeHashes[j] <== mimc2[q].outs[0];
            j++;
            q++;
        }
        offset += n;
        n = n / 2;
    }

    out <== nodeHashes[j-1];
}

component main = MerkleHashGenerator(8);
