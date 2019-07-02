﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class GoalScript : MonoBehaviour
{
    [SerializeField] GameObject _endMenu;
    [SerializeField] GameObject _gameUI;
    [SerializeField] GameObject _feedbackForm;
    [SerializeField] Text _endScoreText;
    [SerializeField] Image _highscoreButton;
    [SerializeField] Sprite _highlightHighscore;
    [SerializeField] ScoreScript _scoreScript;
    [SerializeField] StarScript _starScript;
    [SerializeField] ObstacleCountScript _obstacleCountScript;
    [SerializeField] HighscoreScript _highscoreScript;
    [SerializeField] int _level = 1;

    bool _startScoreAnimation = false;
    float _score;
    float _currentAnimationScore;
    float _scoreIncrease;

    void OnTriggerEnter(Collider other)
    {
        if (other.tag.ToUpper() == "MAINCAMERA")
        {
            Time.timeScale = 0f;
            _score = _scoreScript.GetScore();


            other.transform.parent.GetComponent<Animator>().speed = 0;
            other.gameObject.GetComponentInChildren<ShootScript>().DisableGun();
            _gameUI.SetActive(false);
            if (!StatsTrackerScript.FeedbackGiven)
            {
                _feedbackForm.SetActive(true);
            }
            else{
                ShowEndscreen();
            }

        }
    }

    public void ShowEndscreen(){
        _currentAnimationScore = 0f;
        _startScoreAnimation = true;

        _feedbackForm.SetActive(false);
        _endMenu.SetActive(true);

        _starScript.CheckStarScore(_score, _level);
        _highscoreScript.SetScore(_score);
        _highscoreScript.SetLevel(_level);
        _highscoreScript.AddEntry();

        int starAmount = _starScript.GetStarScore();
        if (starAmount > 0)
        {
            _scoreIncrease = _score / 100 / starAmount;
        }
        else
        {
            _scoreIncrease = _score;
        }
    }

    void Update()
    {
        if(Input.GetKeyDown(KeyCode.F9)){
            PlayerPrefs.DeleteAll();
        }

        if(_startScoreAnimation){
            if (_currentAnimationScore < _score)
            {
                if (_currentAnimationScore + _scoreIncrease >= _score)
                {
                    _currentAnimationScore = _score; // make sure it doesn't go above the actual score
                }
                else
                {
                    _currentAnimationScore += _scoreIncrease;
                }
                _endScoreText.text = "Score: " + (int)_currentAnimationScore;
            }
            else{
                int place = _highscoreScript.CheckDailySpot(_score);
                if (place < 11)
                {
                    _highscoreButton.sprite = _highlightHighscore;
                    //_endScoreText.color = Color.yellow;
                }
            }
        }
    }
}
