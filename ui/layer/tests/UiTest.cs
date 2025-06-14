using Godot;
using System;

public partial class UiTest : HBoxContainer
{
	public Gindustry.Test.Test test;
	public Gindustry.Test.TestRun? run;
	public Label status;
	public Button action;
	public override void _Ready()
	{
		base._Ready();
		GetNode<Label>("Name").Text = test.name;
		status = GetNode<Label>("Status");
		status.Text = "Waiting";
		action = GetNode<Button>("Action");
		action.Text = "Run";
	}

	public void _OnActionPressed()
	{
		if (run != null) {
			run.Inspect();
			return;
		}
		status.Text = "Running";
		action.Text = "Inspect";
		run = test.Run(result => {
			status.Text = result.failed ? "Failed" : "Passed";
		});
	}

	public void Reset()
	{
		if (run != null) {
			run.Reset();
			run = null;
			status.Text = "Waiting";
			action.Text = "Run";
		}
	}
}
