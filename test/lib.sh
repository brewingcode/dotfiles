setup() {
    source init.sh
    cd lib && yarn build
}

test:cache() {
    cache set foo bar
    assert_equal "$(cache get foo)" bar
}
