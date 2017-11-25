# openQA tests for OpenIndiana

openQA dashboard: https://openqa.oi.mnowak.cz/.

Complete openQA documentation is at http://open.qa/.

Setup your [local openQA instance](https://github.com/os-autoinst/openQA/blob/master/docs/Installing.asciidoc).

## Get the test code

### Fork following repositories on GitHub

```
https://github.com/OpenIndiana/os-autoinst-distri-openindiana
https://github.com/OpenIndiana/os-autoinst
https://github.com/OpenIndiana/os-autoinst-needles-openindiana
```

### Clone your forks locally

```
YOU="Mno-hime"           # your GitHub handle
git clone git@github.com:${YOU}/os-autoinst-distri-openindiana.git
git clone git@github.com:${YOU}/os-autoinst.git os-autoinst-distri-openindiana/os-autoinst/
git clone git@github.com:${YOU}/os-autoinst-needles-openindiana.git os-autoinst-distri-openindiana/products/openindiana/needles/
# Make sure 'geekotest' user and your login user can access the needles directory
chown geekotest os-autoinst-distri-openindiana/products/openindiana/needles/
cd os-autoinst-distri-openindiana/
```

### Prepare your environment

Install necessary Perl libraries locally:
```
cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
```

Setup the project:
```
make prepare
```

Create new branch, do changes, test them in your local openQA instance, run `make test` to verify that the changes are valid and conform to coding style, and finally create a Pull Request on GitHub.

Providing Pull Request means you agree with license of this project, which is to be found in each respective file. Some of the tests are derived from [openSUSE openQA tests](https://github.com/os-autoinst/os-autoinst-distri-opensuse), hence the SUSE LLC copyright.

If you have questions, ask `mnowak_` on `#oi-dev` at Freenode.

### Coding style

The project follows the rules of the [os-autoinst](https://github.com/os-autoinst/os-autoinst#how-to-contribute) project
and additionally the following rules:

* The test code should use simple Perl statements, not overly hacky
  approaches, to encourage contributions by newcomers and test writers which
  are not programmers or Perl experts.
* Update the copyright information with the current year. For new files make
  sure to only state the year during which the code was written.
* Use `my ($self) = @_;` for parameter parsing in methods when accessing the
  `$self` object. Do not parse any parameter if you do not need any.
* [Don't repeat yourself](https://en.wikipedia.org/wiki/Don't_repeat_yourself)
* Run `make test` on the tests. It is recommended to call `tools/tidy` locally
  to fix the style of your changes before providing a pull request.

## License

Files are minimal copyleft, but please check the license within the files.
