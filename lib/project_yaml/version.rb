module ProjectYaML
  # Define the Project YaML version, and stash it in a constant.  When we
  # build a package for shipping we burn the version directly into this file,
  # by modifying the text on the fly during package building.
  #
  # That "burns in" the value, but if that hasn't happened we do our best to
  # work out a reasonable version number: If we are running from a git
  # checkout, and we have git installed, determine this with `git describe`,
  #
  # If we don't have git, or it fails, but have the metadata, parse out some
  # useful information directly from the checkout; this isn't great, but does
  # give some guidance as to where the user was working.
  #
  # Finally, fall back to a default version placeholder.
  #
  #
  # The next line is the one that our packaging tools modify, so please make
  # sure that any change to it is discussed and agreed first.
  version = "DEVELOPMENT"

  if version == "DEVELOPMENT"
    root = File.expand_path("../..", File.dirname(__FILE__))
    if File.directory? File.join(root, ".git")
      # In theory we can recover if git isn't installed, and read the HEAD and
      # ref by hand, but that feels like way too much trouble right now.
      git_version = %x{cd '#{root}' && git describe --tags --dirty --always 2>&1}
      if $?.success?
        version = 'v' + git_version
      else                      # try to read manually...
        head = File.read(File.join(root, ".git", "HEAD")) rescue nil
        if head and match = %r{^ref: (refs/heads/(.[^\n]+))$}.match(head.lines.first)
          version = 'git-' + match[2]
          if sha = File.read(File.join(root, ".git", match[1]))[0,8] rescue nil
            version += '-' + sha
          end
        end
      end
    end
  end

  # The running version of Project YaML.  YaML follows the tenets of
  # [semantic versioning](http://semver.org), and this version number reflects
  # the rules as of SemVer 2.0.0-rc.1
  VERSION = version
end
