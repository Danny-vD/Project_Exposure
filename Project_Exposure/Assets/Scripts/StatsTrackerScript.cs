﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

static public class StatsTrackerScript
{
    static public int TechnologyKnowledge = -1;
    static public int KnowledgeLearned = -1;
    static public int PointsLevel1 = -1;
    static public int PointsLevel2 = -1;
    static public int PointsLevel3 = -1;
    static public string Name = "Naamloos";
    static public bool FeedbackGiven = false;

    static public void ResetStats(){
        StatsTrackerScript.TechnologyKnowledge = -1;
        StatsTrackerScript.KnowledgeLearned = -1;
        StatsTrackerScript.PointsLevel1 = -1;
        StatsTrackerScript.PointsLevel2 = -1;
        StatsTrackerScript.PointsLevel3 = -1;
        StatsTrackerScript.Name = "Naamloos";
        StatsTrackerScript.FeedbackGiven = false;
    }
}
