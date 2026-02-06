{ config, pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  environment.systemPackages = with pkgs; [
    ghostty        # terminal
    wofi           # app launcher
    waybar         # status bar
    dunst          # notifications
    swww           # wallpaper
  ];

}
