os-autoinst/openQA tests for OpenIndiana
=================================================================================================================================================================================================================================

For more details on openQA see http://open.qa.


## How to contribute

Setup your local openQA instance. Read the documentation on http://open.qa.

Fork following repositories on GitHub:

https://github.com/Mno-hime/os-autoinst-distri-openindiana

https://github.com/Mno-hime/os-autoinst 

https://github.com/Mno-hime/os-autoinst-needles-openindiana

Clone them locally:

git clone git@github.com:$YOU/os-autoinst-distri-openindiana.git

git clone git@github.com:$YOU/os-autoinst.git os-autoinst-distri-openindiana/os-autoinst/

git clone git@github.com:$YOU/os-autoinst-needles-openindiana.git os-autoinst-distri-openindiana/products/openindiana/needles/

chmod 0777 os-autoinst-distri-openindiana/products/openindiana/needles/
cd os-autoinst-distri-openindiana/

Prepare environment:

cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)

make prepare

Switch to new branch, do changes, test then in your openQA instance. Before you commit the changes, run `make test` to verify, that the changes are valid and conform to coding style. Create Pull Request.

Providing Pull Request means you agree to the license.

If you have questions, ask `mnowak_` on #oi-dev (Freenode).

### Coding style

The project follows the rules of the parent project
[os-autoinst](https://github.com/os-autoinst/os-autoinst#how-to-contribute).
and additionally the following rules:

* Take
  [example boot.pm](https://github.com/os-autoinst/os-autoinst-distri-example/blob/master/tests/boot.pm)
  as a template for new files
* The test code should use simple perl statements, not overly hacky
  approaches, to encourage contributions by newcomers and test writers which
  are not programmers or perl experts
* Update the copyright information with the current year. For new files make
  sure to only state the year during which the code was written.
* Use `my ($self) = @_;` for parameter parsing in methods when accessing the
  `$self` object. Do not parse any parameter if you do not need any.
* [DRY](https://en.wikipedia.org/wiki/Don't_repeat_yourself)
* Run `make test` on the tests. It is recommended to call `tools/tidy` locally
  to fix the style of your changes before providing a pull request.

## License

Files are minimal copyleft, but please check the license within the files.
