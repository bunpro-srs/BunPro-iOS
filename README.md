# BunPuro

This is the iOS companion app for the [BunPro](https://www.bunpro.jp) Japanese grammar learning service.

This app is currently being beta tested via TestFlight. If you would like to try it, you can access it here:
https://testflight.apple.com/join/jx9i7aPp

## Contributing

Bug reports and pull requests are welcome. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

### Getting Started

Here's a few simple steps to configure this project after checking it out:

1. Run `brew bundle` in the command line and wait for tools to be installed (requires [Homebrew](https://brew.sh/))
2. Run `beak run link` to link the Beak scripts properly for execution, then restart your terminal
3. Run `project install` to make sure you have all required tools and dependencies installed

That's it, you should now be able to build the project successfully.

### Scripts

Once the project is set up as above, the following script commands should be available in the root of the project:

* `tools install`: Installes missing tools & updates all existing to their latest versions.
* `ci lint`: Lints the project with all configured linters like it would on the CI.

Feel free to add more scripts in the `Scripts` folder. To edit them, run `beak edit -p Scripts/<file>.swift` which will start [Beak's edit mode](https://github.com/yonaskolb/Beak#edit-the-swift-file). Once you are done and saved your changes, make sure to run `beak run link` to ensure all scripts are still executables. (The edit mode of Beak will destroy the rights on save.)

### Commit Messages

Please try to follow the same syntax and semantic in your **commit messages** (see rationale [here](http://chris.beams.io/posts/git-commit/)).

## License

This app is released under the [MIT License](http://opensource.org/licenses/MIT). See LICENSE for details.
