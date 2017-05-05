os-autoinst/openQA tests for OpenIndiana
=================================================================================================================================================================================================================================

For more details on openQA see http://open.qa.


## How to contribute

Fork the repository and make some changes.
Once you're done with your changes send a pull request. You have to agree to
the license. Thanks!
If you have questions, ask `mnowak_` on irc.freenode.net in #oi-dev.

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
