Name
====

AB-test-http, test http requests between two systems.

Table of Contents
=================

* [Name](#name)
* [Synopsis](#synopsis)
* [Dependency](#dependency)

Synopsis
========

1. put urls into a file, like `url.txt`.

```bash
$ tail -n 2 url.txt
http://openresty.org/
https://openresty.org/cn/
```

2. specify the two IPs that we want to compare between them, run test like this:

```
TEST_OLD_IP=$OLD_IP TEST_NEW_IP=$NEW_IP perl test-http.pl url.txt
```

3. it will compare the response status, the `Content-Type` response header and the `Location` response header, we can get the the output like this:

```
ok 1 - GET http://openresty.org/ status matched
ok 2 - GET http://openresty.org/ content-type matched
ok 3 - GET http://openresty.org/ location matched
ok 4 - GET https://openresty.org/cn/ status matched
ok 5 - GET https://openresty.org/cn/ content-type matched
1..5
```

Dependency
==========

```bash
# use perl5
cpan Test::More
```
