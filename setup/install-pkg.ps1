foreach ($pkg in get-content packages.txt) {
  if (winget list $pkg | sls $pkg) {
    write-host "$pkg already installed"
  } else {
    winget install $pkg
  }
}
