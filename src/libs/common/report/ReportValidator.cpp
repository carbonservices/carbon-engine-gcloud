#include "ReportValidator.h"
#include <QString>
#include <nlohmann/json.hpp>
#include <cmath>

namespace {

bool tryParseNumber(const nlohmann::json& value, double& outNumber)
{
    if (value.is_number()) {
        outNumber = value.get<double>();
        return true;
    }
    if (value.is_string()) {
        try {
            std::string s = value.get<std::string>();
            std::string clean;
            for (char c : s) {
                if ((c >= '0' && c <= '9') || c == '.' || c == '-') {
                    clean += c;
                }
            }
            if (!clean.empty()) {
                outNumber = std::stod(clean);
                return true;
            }
        } catch (...) {
            return false;
        }
    }
    return false;
}

void checkMissingAndRangeIssues(const QString& groupId, const nlohmann::json& data, QVector<ValidationIssue>& issues)
{
    for (auto& [key, value] : data.items()) {
        QString fieldName = QString::fromStdString(key);

        bool isMissing = value.is_null() ||
            (value.is_string() && (value.get<std::string>().empty() || value.get<std::string>() == "N/A"));
        if (isMissing) {
            ValidationIssue issue;
            issue.groupId = groupId;
            issue.fieldKey = fieldName;
            issue.message = QString("field \"%1\" has no extracted value").arg(fieldName);
            issue.severity = "WARNING";
            issues.append(issue);
            continue;
        }

        if (fieldName.endsWith("_pct")) {
            double number = 0.0;
            if (tryParseNumber(value, number) && (number < 0.0 || number > 100.0)) {
                ValidationIssue issue;
                issue.groupId = groupId;
                issue.fieldKey = fieldName;
                issue.message = QString("field \"%1\" is %2, outside expected 0-100%% range")
                    .arg(fieldName).arg(number);
                issue.severity = "WARNING";
                issues.append(issue);
            }
        }
    }
}

void checkWorkforceConsistency(const QString& groupId, const nlohmann::json& data, QVector<ValidationIssue>& issues)
{
    if (data.contains("emp_total_male_pct") && data.contains("emp_total_female_pct")) {
        double malePct = 0.0;
        double femalePct = 0.0;
        if (tryParseNumber(data["emp_total_male_pct"], malePct) && tryParseNumber(data["emp_total_female_pct"], femalePct)) {
            double total = malePct + femalePct;
            if (total < 95.0 || total > 105.0) {
                ValidationIssue issue;
                issue.groupId = groupId;
                issue.fieldKey = "emp_total_male_pct";
                issue.message = QString("employee gender breakdown sum (%1% + %2% = %3%) deviates from 100%")
                    .arg(malePct).arg(femalePct).arg(total);
                issue.severity = "WARNING";
                issues.append(issue);
            }
        }
    }

    if (data.contains("emp_perm_total") && data.contains("emp_other_total") && data.contains("emp_total_total")) {
        double perm = 0.0;
        double other = 0.0;
        double total = 0.0;
        if (tryParseNumber(data["emp_perm_total"], perm) && tryParseNumber(data["emp_other_total"], other) && tryParseNumber(data["emp_total_total"], total)) {
            if (total > 0.0 && std::abs((perm + other) - total) > 1.0) {
                ValidationIssue issue;
                issue.groupId = groupId;
                issue.fieldKey = "emp_total_total";
                issue.message = QString("employee headcount mismatch: permanent (%1) + other (%2) != total (%3)")
                    .arg(perm).arg(other).arg(total);
                issue.severity = "WARNING";
                issues.append(issue);
            }
        }
    }
}

} // namespace

QVector<ValidationIssue> ReportValidator::validateIssues(const QVector<ReportSection>& sections)
{
    QVector<ValidationIssue> issues;
    for (const ReportSection& section : sections) {
        if (section.status == "FAILED") {
            ValidationIssue issue;
            issue.groupId = section.groupId;
            issue.fieldKey = "";
            issue.message = "extraction failed, no values available";
            issue.severity = "ERROR";
            issues.append(issue);
            continue;
        }

        try {
            nlohmann::json data = nlohmann::json::parse(section.dataJson.toStdString());
            checkMissingAndRangeIssues(section.groupId, data, issues);
            if (section.groupId == "section_a_employees" || section.groupId == "section_a_workforce" || section.groupId == "employees_workers") {
                checkWorkforceConsistency(section.groupId, data, issues);
            }
        } catch (...) {
            ValidationIssue issue;
            issue.groupId = section.groupId;
            issue.fieldKey = "";
            issue.message = "stored data could not be parsed";
            issue.severity = "ERROR";
            issues.append(issue);
        }
    }
    return issues;
}

QStringList ReportValidator::validate(const QVector<ReportSection>& sections)
{
    QStringList warnings;
    const QVector<ValidationIssue> issues = validateIssues(sections);
    for (const ValidationIssue& issue : issues) {
        warnings.append(QString("%1: %2").arg(issue.groupId, issue.message));
    }
    return warnings;
}
