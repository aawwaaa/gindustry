using Godot;
using System;
using System.Collections.Generic;

interface IStandaloneEntity
{
    public World World{get; set;}

    public HashSet<Chunk> Chunks {get; protected set;}
}
