Describe 'git-transfer.sh'
  It 'prints Hello World'
    When call "$SHELLSPEC_PROJECT_ROOT/git-transfer.sh"
    The output should equal 'Hello World'
    The status should be success
  End
End