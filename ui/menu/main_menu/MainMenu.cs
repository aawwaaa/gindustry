using Godot;
using System;
using System.Collections.Generic;

namespace builtin.ui;

public partial class MainMenu : Control
{
    public VBoxContainer buttons;
    public PanelContainer contentContainer;

    public Dictionary<string, Control> contents = new();

    public override void _Ready()
    {
        contentContainer = GetNode<PanelContainer>("%ContentContainer");
        buttons = GetNode<VBoxContainer>("%Buttons");
    }

    public Button AddButton(string text, Action action)
    {
        var button = new Button();
        button.Text = text;
        button.Pressed += () => action();
        buttons.AddChild(button);
        return button;
    }
    public Button AddButton(string text, Callable action)
    {
        return AddButton(text, () => action.Call());
    }
    public void AddContent(string id, Control content)
    {
        contents[id] = content;
        contentContainer.AddChild(content);
        content.Visible = false;
    }
    public void ShowContent(string? id = null)
    {
        contentContainer.Visible = true;
        foreach (var content in contents.Values)
        {
            content.Visible = false;
        }
        if (id is not null && contents.TryGetValue(id, out Control value))
        {
            value.Visible = true;
        } else {
            contentContainer.Visible = false;
        }
    }
}
