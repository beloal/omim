#pragma once

#include "search/result.hpp"

#include "indexer/mwm_set.hpp"

#include <initializer_list>
#include <memory>
#include <string>
#include <utility>
#include <vector>

class FeatureType;
class Index;

namespace generator
{
namespace tests_support
{
class TestFeature;
}
}

namespace search
{
namespace tests_support
{
class MatchingRule
{
public:
  virtual ~MatchingRule() = default;

  virtual bool Matches(FeatureType const & feature) const = 0;
  virtual std::string ToString() const = 0;
};

class ExactMatchingRule : public MatchingRule
{
public:
  ExactMatchingRule(MwmSet::MwmId const & mwmId,
                    generator::tests_support::TestFeature const & feature);

  // MatchingRule overrides:
  bool Matches(FeatureType const & feature) const override;
  std::string ToString() const override;

private:
  MwmSet::MwmId m_mwmId;
  generator::tests_support::TestFeature const & m_feature;
};

class AlternativesMatchingRule : public MatchingRule
{
public:
  AlternativesMatchingRule(std::initializer_list<std::shared_ptr<MatchingRule>> rules);

  // MatchingRule overrides:
  bool Matches(FeatureType const & feature) const override;
  std::string ToString() const override;

private:
  std::vector<std::shared_ptr<MatchingRule>> m_rules;
};

template <typename... TArgs>
std::shared_ptr<MatchingRule> ExactMatch(TArgs &&... args)
{
  return std::make_shared<ExactMatchingRule>(forward<TArgs>(args)...);
}

template <typename... TArgs>
std::shared_ptr<MatchingRule> AlternativesMatch(TArgs &&... args)
{
  return std::make_shared<AlternativesMatchingRule>(std::forward<TArgs>(args)...);
}

bool MatchResults(Index const & index, std::vector<std::shared_ptr<MatchingRule>> rules,
                  std::vector<search::Result> const & actual);
bool MatchResults(Index const & index, std::vector<std::shared_ptr<MatchingRule>> rules,
                  search::Results const & actual);
bool ResultMatches(Index const & index, std::shared_ptr<MatchingRule> rule,
                   search::Result const & result);

std::string DebugPrint(MatchingRule const & rule);
}  // namespace tests_support
}  // namespace search
