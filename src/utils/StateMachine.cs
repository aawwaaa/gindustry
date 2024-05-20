using Godot;
using System;

public partial class StateMachine: Node
{
    public static readonly int NOT_INITIALZIED = -1;
    public static readonly int KEEP_CURRENT = -1;

    public int State{ get; protected set; } = NOT_INITIALZIED;

    [Signal]
    public delegate void StateChangedEventHandler(int state, int from);

    public void SetState(int newState)
    {
        int oldState = State;
        State = newState;
        EmitSignal("StateChanged", newState, oldState);
    }

    public virtual int _GetNextState() => KEEP_CURRENT;
    public virtual void _ProcessState(double delta)
    {

    }
    public virtual void _ProcessStateChanged(int state, int from)
    {

    }

    public override void _Process(double delta)
    {
        int nextState = KEEP_CURRENT;
        do
        {
            nextState = _GetNextState();
            int currentState = State;
            if (nextState != KEEP_CURRENT)
            {
                SetState(nextState);
                _ProcessStateChanged(State, currentState);
            }
        } while (nextState != KEEP_CURRENT);
        _ProcessState(delta);
    }
}
