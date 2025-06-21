using Godot;
using System;

namespace Gindustry.Utils;

public class StateMachineGeneric<T>
{
    public delegate void StateChangeEventHandler<A>(A newState, A oldState);
    public event StateChangeEventHandler<T> StateChanged;

    private bool keepCurrentState = false;
    protected void KeepCurrentState() => keepCurrentState = true;

    private T _state = default;

    public StateMachineGeneric(T defaultState = default)
    {
        _state = defaultState;
    }

    public T GetState()
    {
        return _state;
    }

    protected virtual T _GetNextState(T currentState, float delta)
    {
        KeepCurrentState();
        return currentState;
    }

    public void UpdateState(float delta)
    {
        keepCurrentState = false;
        T newState = _GetNextState(_state, delta);
        if (keepCurrentState)
            return;
        do {
            SetState(newState);
            keepCurrentState = false;
            newState = _GetNextState(_state, 0);
        } while (!keepCurrentState);
    }

    public void SetState(T newState)
    {
        T oldState = _state;
        _state = newState;
        _OnStateChanged(_state, oldState);
        StateChanged?.Invoke(_state, oldState);
    }

    protected virtual void _OnStateChanged(T newState, T oldState)
    {
    }
}
