# Demo GIF for README.md, recorded with vhs (https://github.com/charmbracelet/vhs):
#   brew install vhs
#   cd <a Drupal project with DDEV running: ddev start> && vhs <path to kit>/docs/media/demo.tape
# Then copy demo.gif to docs/media/ in the kit and add it to README.md.

Output demo.gif

Set Shell "bash"
Set FontSize 18
Set Width 1200
Set Height 640
Set Padding 24
Set Theme "Dracula"
Set TypingSpeed 40ms

Type "ddev composer require --dev slivorezka/drupal-ai-kit"
Enter
Wait+Screen@90s /Using version/
Sleep 1.5s

Type "vendor/bin/drupal-ai-kit init claude"
Enter
Wait+Screen@30s /Next:/
Sleep 2s

Type "ls .claude/agents .claude/skills"
Enter
Sleep 2.5s

Type "claude -p --permission-mode acceptEdits '/create-drupal-service ExchangeRates in my_module - fetch rates with http_client, cache for 1 hour'"
# The agent needs a minute or two: keep that wait out of the GIF.
Hide
Enter
Wait@300s
Type "clear"
Enter
Sleep 500ms
Show

Type "git status --short web/modules"
Enter
Sleep 2s
Type "cat web/modules/custom/my_module/my_module.services.yml"
Enter
Sleep 5s
