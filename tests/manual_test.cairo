use core::pedersen::pedersen;

#[test]
fn test_pedersen_binding() {
    let vote: u8 = 1;
    let salt: felt252 = 12345;
    let c = pedersen(vote.into(), salt);

    assert(c == pedersen(vote.into(), salt), 'deterministic');
    assert(c != pedersen(vote.into(), 54321), 'different salt');
    assert(c != pedersen(2_u8.into(), salt), 'different vote');
}

#[test]
fn test_pedersen_hiding() {
    let h0 = pedersen(0_u8.into(), 99999);
    let h1 = pedersen(1_u8.into(), 99999);
    assert(h0 != h1, 'different votes differ');
    assert(h0 != 0_u8.into(), 'hash != vote');
    assert(h0 != 99999, 'hash != salt');
}

#[test]
fn test_all_options_produce_unique_hashes() {
    let salt: felt252 = 42;
    let h0 = pedersen(0_u8.into(), salt);
    let h1 = pedersen(1_u8.into(), salt);
    let h2 = pedersen(2_u8.into(), salt);
    let h3 = pedersen(3_u8.into(), salt);
    let h4 = pedersen(4_u8.into(), salt);

    assert(h0 != h1, '0!=1');
    assert(h1 != h2, '1!=2');
    assert(h2 != h3, '2!=3');
    assert(h3 != h4, '3!=4');
    assert(h0 != h4, '0!=4');
}
