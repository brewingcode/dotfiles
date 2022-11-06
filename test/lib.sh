setup() {
    source init.sh
    cd lib && yarn build
}

test:cache() {
    cache set foo bar
    assert_equal "$(cache get foo)" bar
}

test:cache-ttl() {
    cache set foo-ttl baz 2
    assert_equal "$(cache get foo-ttl)" baz
    sleep 2
    assert_equal "$(cache get foo-ttl)" ''
}