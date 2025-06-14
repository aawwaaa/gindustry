using Godot;

[GlobalClass]
public partial class StateMachine : Node
{
    public const int KeepCurrentState = -1;

    [Signal]
    public delegate void StateChangedEventHandler(int newState, int oldState);

    private int _state = -1;

    public StateMachine(int defaultState = -1)
    {
        _state = defaultState;
    }

    public int GetState()
    {
        return _state;
    }

    protected virtual int _GetNextState(int currentState, float delta)
    {
        return KeepCurrentState;
    }

    public void UpdateState(float delta)
    {
        int newState = _GetNextState(_state, delta);
        if (newState == KeepCurrentState)
            return;
        do {
            SetState(newState);
            newState = _GetNextState(_state, 0);
        } while (newState != KeepCurrentState);
    }

    public void SetState(int newState)
    {
        int oldState = _state;
        _state = newState;
        _OnStateChanged(_state, oldState);
        EmitSignal(SignalName.StateChanged, _state, oldState);
    }

    protected virtual void _OnStateChanged(int newState, int oldState)
    {
    }
}
