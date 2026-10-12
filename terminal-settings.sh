defaults write com.apple.Terminal "Window Settings" -dict-add "Coding" '{
  name = Coding;
  type = "Window Settings";
  CommandString = "tmux a || tmux";
  shellExitAction = 1;
  FontSize = 18;
  FontAntialias = 1;
  BlinkText = 1;
  DisableANSIColor = 0;
  RunCommandAsShell = 0;
  TerminalType = "xterm-256colour";
  UseBoldFonts = 1;
  UseBrightBold = 0;
}'

defaults write com.apple.Terminal "Startup Window Settings" "Coding"
defaults write com.apple.Terminal "Default Window Settings" "Coding"
