using Gindustry;
using Godot;
using System;
using System.Collections.Generic;

public partial class Tests : PanelContainer
{
	public Dictionary<string, Dictionary<string, UiTest>> tests = new();
	public string currentGroup = "";

	public VBoxContainer testGroups;
	public VBoxContainer groupContents;

	public PackedScene uiTest;

	public override void _Ready()
	{
		base._Ready();
		testGroups = GetNode<VBoxContainer>("%TestGroups");
		groupContents = GetNode<VBoxContainer>("%GroupContents");
	}
	public void LoadUi()
	{
		uiTest = GD.Load<PackedScene>("uid://bgsl4fx87ek2b" /* test.tscn */);
		foreach (var group in Vars.Tests.groups.Values) {
			var groupButton = new Button
			{
				Text = group.name
			};
			var dict = new Dictionary<string, UiTest>();
			tests[group.name] = dict;
			groupButton.Pressed += () => {
				ToggleToGroup(group.name);
			};
			testGroups.AddChild(groupButton);
			foreach (var test in group.tests.Values) {
				var testNode = uiTest.Instantiate<UiTest>();
				testNode.test = test;
				testNode.Visible = false;
				groupContents.AddChild(testNode);
				dict[test.name] = testNode;
			}
		}
	}
	public void ToggleToGroup(string target)
	{
		if (currentGroup == target) {
			return;
		}
		currentGroup = target;
		foreach (var group in tests.Keys) {
			foreach (var test in tests[group].Values) {
				test.Visible = group == target;
			}
		}
	}
	public void _OnRunAllPressed()
	{
		foreach (var group in tests.Values) {
			foreach (var test in group.Values) {
				if (test.run != null) continue;
				test._OnActionPressed();
			}
		}
	}
	public void _OnRunGroupPressed()
	{
		foreach (var test in tests[currentGroup].Values) {
			if (test.run != null) continue;
			test._OnActionPressed();
		}
	}
	public void _OnResetAllPressed()
	{
		foreach (var group in tests.Values) {
			foreach (var test in group.Values) {
				test.Reset();
			}
		}
	}
}
